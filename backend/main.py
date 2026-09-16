import os
import json
import uuid
import sqlite3
import logging
from contextlib import asynccontextmanager
from datetime import datetime
from dotenv import load_dotenv
import fitz
from google import genai
from fastapi import FastAPI, UploadFile, File, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('roast_my_resume.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

load_dotenv()
api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    raise ValueError("GEMINI_API_KEY must be set in .env file")

client = genai.Client(api_key=api_key)
limiter = Limiter(key_func=get_remote_address)
DB_PATH = "roasts.db"

# ---------------------------------------------------------------------------
# Modes — keys are the API values, personas are injected into the prompt.
# Names shown in the UI are controlled by the frontend (config.dart).
# ---------------------------------------------------------------------------
MODES = {
    "normal": (
        "You are an honest resume reviewer with a sharp eye and dry wit. "
        "Be direct and fair — acknowledge what works, call out what doesn't."
    ),
    "savage": (
        "You are a brutally savage resume critic. No sugarcoating, no mercy, no diplomacy. "
        "If it's bad, say it's bad. Be scathing but specific."
    ),
    "recruiter": (
        "You are a senior recruiter at a top-tier firm who has reviewed 10,000 resumes. "
        "Be professional but cutting. Evaluate purely on hiring criteria."
    ),
}

FORMAT_INSTRUCTION = """Return ONLY a raw JSON object — no markdown, no code blocks, just the JSON itself:
{
  "score": <integer 0-100>,
  "grade": "<letter grade: A+, A, A-, B+, B, B-, C+, C, C-, D, F>",
  "summary": "<2-3 sentence overall assessment>",
  "roast": "<main feedback 100-150 words in your persona's voice>",
  "sections": {
    "experience": {"score": <0-100>, "comment": "<one sharp sentence>"},
    "skills": {"score": <0-100>, "comment": "<one sharp sentence>"},
    "education": {"score": <0-100>, "comment": "<one sharp sentence>"},
    "presentation": {"score": <0-100>, "comment": "<one sharp sentence>"}
  },
  "verdict": "<one closing line that lands>"
}"""


def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS roasts (
            id          TEXT PRIMARY KEY,
            mode        TEXT NOT NULL,
            score       INTEGER,
            grade       TEXT,
            result_json TEXT NOT NULL,
            created_at  TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    logger.info("DB initialized — roasts.db ready")
    yield


app = FastAPI(title="Roast My Resume API", version="2.0.0", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

ALLOWED_ORIGINS = os.environ.get(
    "ALLOWED_ORIGINS", "http://localhost:*,http://127.0.0.1:*"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
    allow_credentials=True,
)


# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------
class SectionScore(BaseModel):
    score: int
    comment: str


class RoastSections(BaseModel):
    experience: SectionScore
    skills: SectionScore
    education: SectionScore
    presentation: SectionScore


class RoastResult(BaseModel):
    score: int
    grade: str
    summary: str
    roast: str
    sections: RoastSections
    verdict: str


class RoastResponse(BaseModel):
    id: str
    mode: str
    result: RoastResult


class StatsResponse(BaseModel):
    total_roasted: int
    average_score: Optional[float]


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------
@app.post("/roast", response_model=RoastResponse)
@limiter.limit("5/minute")
async def roast_resume(
    request: Request,
    file: UploadFile = File(...),
    mode: str = "normal",
):
    if mode not in MODES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid mode. Choose from: {list(MODES.keys())}",
        )

    request_id = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    logger.info(f"[{request_id}] mode={mode} file={file.filename}")

    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are accepted.")

    pdf_bytes = await file.read()
    if len(pdf_bytes) / (1024 * 1024) > 10:
        raise HTTPException(status_code=400, detail="File size must be less than 10MB.")

    try:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        text = "\n".join(page.get_text() for page in doc)
        doc.close()
    except Exception:
        raise HTTPException(status_code=400, detail="Failed to read PDF. Make sure it's a valid PDF.")

    if not text.strip():
        raise HTTPException(status_code=400, detail="No text found in PDF.")

    prompt = (
        f"{MODES[mode]}\n\n"
        f"Analyze the resume below.\n\n"
        f"{FORMAT_INSTRUCTION}\n\n"
        f"Resume:\n{text}"
    )

    try:
        response = client.models.generate_content(
            model="gemini-2.0-flash-exp",
            contents=prompt,
        )
        raw = response.text.strip()
        # Strip markdown fences if Gemini wraps the JSON
        if raw.startswith("```"):
            parts = raw.split("```")
            raw = parts[1]
            if raw.startswith("json"):
                raw = raw[4:]
            raw = raw.strip()
        parsed = json.loads(raw)
        result = RoastResult(**parsed)
    except json.JSONDecodeError:
        logger.error(f"[{request_id}] Gemini returned non-JSON: {response.text[:200]}")
        raise HTTPException(status_code=500, detail="AI returned a malformed response. Please try again.")
    except Exception as e:
        logger.error(f"[{request_id}] Gemini error: {e}")
        raise HTTPException(status_code=500, detail="AI service unavailable. Please try again.")

    result_id = str(uuid.uuid4())
    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        "INSERT INTO roasts (id, mode, score, grade, result_json, created_at) VALUES (?, ?, ?, ?, ?, ?)",
        (result_id, mode, result.score, result.grade, result.model_dump_json(), datetime.now().isoformat()),
    )
    conn.commit()
    conn.close()

    logger.info(f"[{request_id}] Saved result id={result_id} score={result.score}")
    return RoastResponse(id=result_id, mode=mode, result=result)


@app.get("/result/{result_id}", response_model=RoastResponse)
async def get_result(result_id: str):
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute(
        "SELECT id, mode, result_json FROM roasts WHERE id = ?", (result_id,)
    ).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Result not found.")
    return RoastResponse(id=row[0], mode=row[1], result=RoastResult(**json.loads(row[2])))


@app.get("/stats", response_model=StatsResponse)
async def get_stats():
    conn = sqlite3.connect(DB_PATH)
    row = conn.execute("SELECT COUNT(*), AVG(score) FROM roasts").fetchone()
    conn.close()
    return StatsResponse(
        total_roasted=row[0] or 0,
        average_score=round(row[1], 1) if row[1] is not None else None,
    )


@app.get("/health")
async def health():
    return {"status": "ok", "version": "2.0.0", "timestamp": datetime.now().isoformat()}
