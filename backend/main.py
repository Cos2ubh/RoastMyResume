import os
import logging
from dotenv import load_dotenv
import fitz  # PyMuPDF
from google import genai
from google.genai import types
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime

# ---------------------------------------------------------------------------
# 1.  Configure logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('roast_my_resume.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# 2.  Load .env then configure Gemini
# ---------------------------------------------------------------------------
load_dotenv()
api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    logger.error("GEMINI_API_KEY not found in environment variables!")
    raise ValueError("GEMINI_API_KEY must be set in .env file")

client = genai.Client(api_key=api_key)
logger.info("Gemini API client initialized successfully")

app = FastAPI(
    title="Roast My Resume API",
    description="AI-powered resume roasting service",
    version="1.0.0"
)

# ---------------------------------------------------------------------------
# 3.  CORS  –  Configure allowed origins
# ---------------------------------------------------------------------------
# Environment-based CORS configuration
ALLOWED_ORIGINS = os.environ.get("ALLOWED_ORIGINS", "http://localhost:*,http://127.0.0.1:*").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
    allow_credentials=True,
)

# ---------------------------------------------------------------------------
# 4.  Data model for the JSON response
# ---------------------------------------------------------------------------
class RoastResponse(BaseModel):
    roast: str

# ---------------------------------------------------------------------------
# 5.  The main endpoint  –  POST /roast
#     Expects a single PDF file in the multipart body.
# ---------------------------------------------------------------------------
@app.post("/roast", response_model=RoastResponse)
async def roast_resume(file: UploadFile = File(...)):
    request_id = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    logger.info(f"[{request_id}] Received roast request for file: {file.filename}")

    try:
        # --- validate extension ---
        if not file.filename or not file.filename.lower().endswith(".pdf"):
            logger.warning(f"[{request_id}] Invalid file type: {file.filename}")
            raise HTTPException(status_code=400, detail="Only PDF files are accepted.")

        # --- validate file size (10MB limit) ---
        pdf_bytes = await file.read()
        file_size_mb = len(pdf_bytes) / (1024 * 1024)
        if file_size_mb > 10:
            logger.warning(f"[{request_id}] File too large: {file_size_mb:.2f}MB")
            raise HTTPException(status_code=400, detail="File size must be less than 10MB.")

        logger.info(f"[{request_id}] Processing PDF ({file_size_mb:.2f}MB)")

        # --- extract text with PyMuPDF (no disk write needed) ---
        try:
            doc = fitz.open(stream=pdf_bytes, filetype="pdf")
            text = "\n".join(page.get_text() for page in doc)
            doc.close()
        except Exception as e:
            logger.error(f"[{request_id}] PDF extraction error: {str(e)}")
            raise HTTPException(status_code=400, detail="Failed to read PDF file. Ensure it's a valid PDF.")

        if not text.strip():
            logger.warning(f"[{request_id}] No text extracted from PDF")
            raise HTTPException(status_code=400, detail="Could not extract any text from the PDF.")

        logger.info(f"[{request_id}] Extracted {len(text)} characters from PDF")

        # --- send to Gemini ---
        prompt = (
            "You are a brutally honest but hilarious resume roaster. "
            "Roast the following resume in a funny, sarcastic way. "
            "Be brutal but entertaining. Keep it under 200 words.\n\n"
            f"Resume:\n{text}\n\nRoast:"
        )

        logger.info(f"[{request_id}] Sending request to Gemini API")
        try:
            response = client.models.generate_content(
                model="gemini-2.0-flash-exp",
                contents=prompt
            )
            roast_text = response.text
            logger.info(f"[{request_id}] Successfully generated roast ({len(roast_text)} chars)")
        except Exception as e:
            logger.error(f"[{request_id}] Gemini API error: {str(e)}")
            raise HTTPException(status_code=500, detail="AI service temporarily unavailable. Please try again.")

        return RoastResponse(roast=roast_text)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[{request_id}] Unexpected error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="An unexpected error occurred.")

# ---------------------------------------------------------------------------
# 6.  Health-check  –  useful for confirming the server is alive
# ---------------------------------------------------------------------------
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "service": "Roast My Resume API",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }

# ---------------------------------------------------------------------------
# 7.  Startup event
# ---------------------------------------------------------------------------
@app.on_event("startup")
async def startup_event():
    logger.info("=" * 50)
    logger.info("Roast My Resume API starting...")
    logger.info(f"Allowed CORS origins: {ALLOWED_ORIGINS}")
    logger.info("=" * 50)
