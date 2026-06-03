# 🤝 Contributing to Krishi Drishti

Thank you for your interest in contributing to **Krishi Drishti** — the free satellite-based crop health monitoring platform for Indian farmers!  🌾🛰️

We welcome contributions from **developers, agriculturists, translators, UI/UX designers, satellite data scientists, and domain experts**.

---

## 📋 Table of Contents

- [🌱 How to Contribute](#-how-to-contribute)
- [🚀 Getting Started](#-getting-started)
- [📝 Code Style Guidelines](#-code-style-guidelines)
- [🧪 Testing](#-testing)
- [🗂️ Project Structure](#️-project-structure)
- [🔍 Focus Areas](#-focus-areas)
- [💬 Communication](#-communication)
- [📜 Code of Conduct](#-code-of-conduct)
- [🙏 Thank You](#-thank-you)

---

## 🌱 How to Contribute

### 🎯 High Priority Areas

| Priority | Area | Skills Needed | Impact |
|----------|------|---------------|--------|
| 🔴 **Critical** | 🌐 **Language Support** — Hindi, Tamil, Telugu, Marathi | Translation | 🎯 Reaches thousands of farmers |
| 🔴 **Critical** | 🛰️ **Satellite Integration** — New ISRO/NASA data sources | Python, Remote Sensing | 🚀 Adds new analysis capabilities |
| 🔴 **Critical** | 📱 **Flutter Mobile App** — Improve UI/UX | Flutter, Dart | 🎯 Helps farmers in the field |
| 🟡 **High** | 🧪 **Pest & Disease Models** | ML, Agronomy | 🌿 Early detection saves crops |
| 🟡 **High** | 🗺️ **Map & Layer Features** | Leaflet.js, GIS | 📊 Better visualization |
| 🟡 **High** | ⚡ **Quantum Computing** | Qiskit, Python | 🔬 Next-gen analysis |
| 🟢 **Medium** | 📖 **Documentation** | Technical Writing | 🎯 Helps all users |
| 🟢 **Medium** | 🎨 **UI/UX Design** | Figma, Design | 📱 Better farmer experience |
| 🟢 **Medium** | 🐛 **Bug Fixes** | Python, JS, Dart | ✅ Improves reliability |

### Other Ways to Help

- ⭐ **Star the repository** — helps others discover the project
- 🐛 **Report bugs** — open an issue with detailed reproduction steps
- 💡 **Suggest features** — start a discussion with your idea
- 📢 **Share with farmers** — spread the word in farming communities
- 🌐 **Translate** — add your language to the translation files

---

## 🚀 Getting Started

### Step 1: Fork & Clone

```bash
# Fork the repository on GitHub
# Then clone your fork:
git clone https://github.com/YOUR_USERNAME/Krishi-Drishti.git
cd Krishi-Drishti
```

### Step 2: Create a Branch

```bash
# Use descriptive branch names:
git checkout -b feature/add-tamil-translations
git checkout -b fix/csv-upload-error
git checkout -b docs/improve-setup-guide
```

### Step 3: Make Your Changes

- Follow the [Code Style Guidelines](#-code-style-guidelines) below
- Keep changes focused — one feature/fix per branch
- Write meaningful commit messages

### Step 4: Commit & Push

```bash
git add .
git commit -m "feat: add Tamil (தமிழ்) language support"
# Use conventional commits:
# feat:     New feature
# fix:      Bug fix
# docs:     Documentation
# style:    Formatting
# refactor: Code restructuring
# test:     Adding tests
# chore:    Maintenance

git push origin feature/add-tamil-translations
```

### Step 5: Open a Pull Request

1. Go to [github.com/virahitvin8/Krishi-Drishti](https://github.com/virahitvin8/Krishi-Drishti)
2. Click **"Compare & pull request"**
3. Describe your changes clearly
4. Reference any related issues
5. Submit your PR 🚀

---

## 📝 Code Style Guidelines

### General

- Write **clean, commented code**
- Use **meaningful** variable and function names
- Follow the existing patterns in the codebase
- Keep functions **small and focused**

### Python (Backend)

```python
# ✅ Good
def calculate_ndvi(nir_band: float, red_band: float) -> float:
    """Calculate Normalized Difference Vegetation Index."""
    return (nir_band - red_band) / (nir_band + red_band + 1e-10)

# ❌ Avoid
def calc(x, y):
    return (x-y)/(x+y)
```

- Follow [PEP 8](https://peps.python.org/pep-0008/) style guide
- Use type hints for all function parameters and returns
- Write docstrings for all public functions

### JavaScript (Frontend)

```javascript
// ✅ Good
function updateWeatherDisplay(temperature, humidity, windSpeed) {
    // Updates the weather section with live data
    const weatherEl = document.getElementById('weatherContent');
    weatherEl.innerHTML = `${temperature}°C • ${humidity}% humidity`;
}

// ❌ Avoid
function up(a,b,c) { document.getElementById('x').innerHTML = a+b+c; }
```

- Use modern ES6+ syntax
- Prefer `const` over `let` (use `let` only for reassignment)
- Use template literals for string interpolation

### Flutter/Dart

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart)
- Use `const` constructors where possible
- Prefer named parameters for widget constructors

---

## 🧪 Testing

Before submitting a PR, please verify:

### Web App
- ✅ Open `frontend/index.html` in browser
- ✅ Test with **"🎯 Demo"** farm button
- ✅ Verify hotspot grid renders correctly
- ✅ Test language switching (English → Hindi → Telugu)
- ✅ Check all modals open/close properly
- ✅ Verify responsive layout on mobile viewport

### Flutter App
- ✅ `flutter analyze` passes with no errors
- ✅ `flutter build apk --debug` builds successfully
- ✅ Test on actual Android device (emulator is okay)

### Backend
- ✅ `python -m pytest` passes (if tests exist)
- ✅ `uvicorn main:app` starts without errors
- ✅ `/health` endpoint returns 200

---

## 🗂️ Project Structure

```
KrishiDrishti_Final_v4/
├── .github/            # GitHub config, workflows, assets
│   ├── workflows/      # GitHub Actions CI/CD
│   └── screenshots/    # App screenshots for README
├── frontend/           # 🌐 Web PWA (HTML + Leaflet.js)
│   └── index.html      # Main web application
├── flutter_app/        # 📱 Native Android (Flutter)
│   └── lib/            # Dart source code
├── backend/            # 🖥️ Python API (FastAPI)
│   ├── routers/        # API endpoint handlers
│   └── services/       # Business logic
├── README.md           # 📖 Project documentation
└── SETUP_GUIDE.md      # 📘 Complete setup guide
```

---

## 🔍 Focus Areas

### 🌐 Translations
Add your language to `frontend/index.html`:
```javascript
const TRANSLATIONS = {
    en: { ... },
    hi: { ... },
    te: { ... },
    // ADD YOUR LANGUAGE HERE
    ta: { app_name: 'கிருஷி திருஷ்டி', ... },
};
```

### 🛰️ Satellite Integration
Add new satellite sources in `backend/routers/analysis.py`:
- ISRO Oceansat-3 (OCM-3)
- NASA ECOSTRESS
- GCOM-C (JAXA)

### 📱 Flutter UI
Improve the mobile experience:
- Offline map support
- GPS-based auto-farm detection
- Push notifications for satellite passes
- Widget for Android home screen

### ⚡ Quantum Computing
Enhance `backend/services/quantum_service.py`:
- Add more quantum algorithms
- Implement QAOA for irrigation routing
- Create quantum-enhanced pest prediction

---

## 💬 Communication

- **🐛 Bug Reports:** [Open an issue](https://github.com/virahitvin8/Krishi-Drishti/issues/new)
- **💡 Feature Requests:** [Start a discussion](https://github.com/virahitvin8/Krishi-Drishti/discussions)
- **📧 Direct Contact:** akshitvinay4636@gmail.com

### Guidelines
- Be **respectful and constructive** in all communications
- Search existing issues before creating new ones
- Provide **detailed reproduction steps** for bugs
- Include **screenshots** if relevant

---

## 📜 Code of Conduct

### Our Pledge

We are committed to providing a **welcoming, inclusive, and harassment-free** experience for everyone, regardless of:
- Age, body size, disability, ethnicity
- Gender identity and expression
- Level of experience
- Nationality, personal appearance
- Race, religion, or sexual identity

### Our Standards

**Positive behavior:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what's best for the community and farmers

**Unacceptable behavior:**
- Harassment, trolling, or insults
- Publishing others' private information
- Other conduct which could reasonably be considered inappropriate

---

## 🙏 Thank You

Every contribution — big or small — helps Indian farmers get better tools. Whether you're fixing a typo, adding a translation, writing code, or reporting a bug, you're making a difference.

> **"जय किसान • जय विज्ञान"** — Victory to farmers, victory to science

**Let's build the best free farming tool for India! 🌾🛰️🇮🇳**

---

<div align="center">
  
  [![Star](https://img.shields.io/github/stars/virahitvin8/Krishi-Drishti?style=social&label=⭐%20Star%20this%20repo)](https://github.com/virahitvin8/Krishi-Drishti)
  
  <br>
  
  *Maintained with ❤️ by [Akshit](https://github.com/virahitvin8)*
  
  <br>
  
  <sub>MIT License • Free & Open Source</sub>
  
</div>
