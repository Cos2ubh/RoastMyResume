import os
from dotenv import load_dotenv
import fitz  # PyMuPDF
from google import genai
from google.genai import types
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ---------------------------------------------------------------------------
# 1.  Load .env then configure Gemini
# ---------------------------------------------------------------------------
load_dotenv()
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))

app = FastAPI()

# ---------------------------------------------------------------------------
# 2.  CORS  –  lets the Flutter frontend talk to this server
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# 3.  Data model for the JSON response
# ---------------------------------------------------------------------------
class RoastResponse(BaseModel):
    roast: str

# ---------------------------------------------------------------------------
# 4.  The main endpoint  –  POST /roast
#     Expects a single PDF file in the multipart body.
# ---------------------------------------------------------------------------
@app.post("/roast", response_model=RoastResponse)
async def roast_resume(file: UploadFile = File(...)):
    # --- validate extension ---
    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are accepted.")

    # --- extract text with PyMuPDF (no disk write needed) ---
    pdf_bytes = await file.read()
    doc = fitz.open(stream=pdf_bytes, filetype="pdf")
    text = "\n".join(page.get_text() for page in doc)
    doc.close()

    if not text.strip():
        raise HTTPException(status_code=400, detail="Could not extract any text from the PDF.")

    # --- send to Gemini ---
    prompt = (
        "You are a brutally honest but hilarious resume roaster. "
        "Roast the following resume in a funny, sarcastic way. "
        "Be brutal but entertaining. Keep it under 200 words.\n\n"
        f"Resume:\n{text}\n\nRoast:"
    )

    response = client.models.generate_content(
        model="gemini-2.0-flash-exp",
        contents=prompt
    )

    return RoastResponse(roast=response.text)

# ---------------------------------------------------------------------------
# 5.  Health-check  –  useful for confirming the server is alive
# ---------------------------------------------------------------------------
@app.get("/health")
async def health():
    return {"status": "ok"}
