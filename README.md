# 🔥 Roast My Resume

> Get your resume brutally roasted by AI. Built with Flutter and Google Gemini.

A full-stack web application that uses Google's Gemini AI to generate hilarious, brutally honest roasts of your resume. Upload a PDF, get roasted, and have a good laugh!

## ✨ Features

- 📄 **PDF Upload** - Drag and drop or select your resume PDF
- 🤖 **AI-Powered Roasting** - Uses Google Gemini 2.5 Flash for creative roasts
- 🎨 **Modern UI** - Beautiful gradient design with smooth animations
- 📋 **Copy to Clipboard** - Easily share your roast with friends
- 🔒 **Secure** - API keys are never exposed or committed to the repo

## 🛠️ Tech Stack

### Backend
- **FastAPI** - Modern, fast web framework for Python
- **Google Gemini AI** - Advanced language model for generating roasts
- **PyMuPDF** - PDF text extraction
- **Python 3.10+**

### Frontend
- **Flutter Web** - Beautiful, responsive UI
- **Material Design 3** - Modern design system
- **Dart** - Client-side language

## 📸 Screenshots

<!-- Add screenshots here -->
*Coming soon!*

## 🚀 Getting Started

### Prerequisites

- Python 3.10 or higher
- Flutter SDK 3.38.9 or higher
- Google Gemini API key ([Get one here](https://aistudio.google.com/app/apikey))

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/imkaustubhh/RoastMyResume.git
   cd RoastMyResume/backend
   ```

2. **Create a virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**

   Create a `.env` file in the `backend` folder:
   ```bash
   GEMINI_API_KEY=your_api_key_here
   ```

5. **Run the server**
   ```bash
   uvicorn main:app --reload
   ```

   The backend will be available at `http://localhost:8000`

### Frontend Setup

1. **Navigate to the frontend directory**
   ```bash
   cd ../frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run -d chrome
   ```

   The app will open in your default browser.

## 📁 Project Structure

```
RoastMyResume/
├── backend/
│   ├── main.py              # FastAPI server & endpoints
│   ├── requirements.txt     # Python dependencies
│   ├── list_models.py       # Utility to list available Gemini models
│   └── .env                 # Environment variables (not in repo)
├── frontend/
│   ├── lib/
│   │   └── main.dart       # Flutter web app UI & logic
│   ├── pubspec.yaml        # Flutter dependencies
│   └── web/                # Web assets
├── app/
│   ├── lib/
│   │   └── main.dart       # Flutter mobile app UI & logic
│   ├── pubspec.yaml        # Flutter dependencies
│   ├── android/            # Android platform files
│   └── ios/                # iOS platform files
└── README.md
```

## 🎯 Usage

1. Start the backend server (see Backend Setup)
2. Launch the Flutter app (see Frontend Setup)
3. Click "Upload Resume" and select a PDF file
4. Wait for the AI to generate your roast
5. Enjoy the brutally honest feedback!
6. Click the copy icon to share with friends

## 🔑 API Endpoints

### `POST /roast`
Accepts a PDF file and returns an AI-generated roast.

**Request:**
- Content-Type: `multipart/form-data`
- Body: PDF file

**Response:**
```json
{
  "roast": "Your hilarious roast here..."
}
```

### `GET /health`
Health check endpoint.

**Response:**
```json
{
  "status": "ok"
}
```

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests

## ⚠️ Important Notes

- **API Key Security**: Never commit your `.env` file or expose your API key
- **Rate Limits**: Google Gemini has rate limits - use responsibly
- **PDF Support**: Currently only supports text-based PDFs (no image extraction)

## 📝 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Google Gemini AI for the language model
- Flutter team for the amazing framework
- FastAPI for the backend framework

---

**Built with ❤️ and a lot of roasting**

*Want your resume roasted? Clone this repo and give it a try!*
