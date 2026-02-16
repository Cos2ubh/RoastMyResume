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
   ALLOWED_ORIGINS=http://localhost:*,http://127.0.0.1:*
   ```

   ⚠️ **SECURITY NOTE**:
   - Never commit your `.env` file to version control
   - The `.env` file is already in `.gitignore` to prevent accidental commits
   - If you need to regenerate your API key, visit [Google AI Studio](https://aistudio.google.com/app/apikey)

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
│   ├── main.py              # FastAPI server & endpoints with logging
│   ├── requirements.txt     # Python dependencies
│   ├── list_models.py       # Utility to list available Gemini models
│   ├── .env                 # Environment variables (not in repo)
│   └── roast_my_resume.log  # Request logs (generated at runtime)
├── frontend/
│   ├── lib/
│   │   ├── main.dart        # Flutter web app UI & logic
│   │   └── config.dart      # API configuration (environment-based)
│   ├── pubspec.yaml         # Flutter dependencies
│   └── web/                 # Web assets
├── app/
│   ├── lib/
│   │   ├── main.dart        # Flutter mobile app UI & logic
│   │   └── config.dart      # API configuration (environment-based)
│   ├── pubspec.yaml         # Flutter dependencies
│   ├── android/             # Android platform files
│   └── ios/                 # iOS platform files
├── README.md
└── FIXES_APPLIED.md         # Summary of recent improvements
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

## 🔒 Security Best Practices

### API Key Security
- ✅ **DO**: Store API keys in `.env` file (already in `.gitignore`)
- ✅ **DO**: Use environment variables for sensitive data
- ✅ **DO**: Rotate API keys if you suspect they've been exposed
- ❌ **DON'T**: Hardcode API keys in source code
- ❌ **DON'T**: Commit `.env` files to Git
- ❌ **DON'T**: Share API keys in screenshots or logs

### If Your API Key Was Compromised
1. Immediately regenerate it at [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Update your local `.env` file with the new key
3. Restart your backend server
4. If the key was committed to Git, consider it permanently exposed

### CORS Configuration
The backend uses environment-based CORS configuration:
- **Development**: `ALLOWED_ORIGINS=http://localhost:*,http://127.0.0.1:*`
- **Production**: Update to your actual domain (e.g., `https://yourdomain.com`)

## 🚀 Production Deployment

### Backend (FastAPI)
1. Update `.env` with production settings:
   ```bash
   GEMINI_API_KEY=your_production_key
   ALLOWED_ORIGINS=https://yourdomain.com
   ```

2. Deploy to your preferred platform:
   - **Railway**: Easy deployment with automatic HTTPS
   - **Heroku**: Classic PaaS option
   - **DigitalOcean**: VPS with full control
   - **AWS/GCP/Azure**: Enterprise cloud options

3. Update production command:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

### Frontend (Flutter Web)
1. Build for production:
   ```bash
   flutter build web --release --dart-define=API_BASE_URL=https://your-backend-url.com
   ```

2. Deploy the `build/web` directory to:
   - **Netlify**: Drag-and-drop deployment
   - **Vercel**: Git-based deployment
   - **Firebase Hosting**: Google's hosting solution
   - **GitHub Pages**: Free static hosting

### Mobile App
For Android release:
1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=your-store-password
   keyPassword=your-key-password
   keyAlias=upload
   storeFile=/path/to/upload-keystore.jks
   ```

3. Build release APK:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://your-backend-url.com
   ```

## ⚠️ Important Notes

- **API Key Security**: Never commit your `.env` file or expose your API key (see Security section above)
- **Rate Limits**: Google Gemini has rate limits - use responsibly
- **PDF Support**: Currently only supports text-based PDFs (no image extraction)
- **File Size Limit**: Backend enforces 10MB maximum file size
- **Logging**: Backend logs all requests to `roast_my_resume.log` for debugging

## 📝 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Google Gemini AI for the language model
- Flutter team for the amazing framework
- FastAPI for the backend framework

---

**Built with ❤️ and a lot of roasting**

*Want your resume roasted? Clone this repo and give it a try!*
