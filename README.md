# KrishiDrishti 🌾

[![GitHub release](https://img.shields.io/github/v/release/virahitvin8/Krishi-Drishti)](https://github.com/virahitvin8/Krishi-Drishti/releases)
[![GitHub All Releases](https://img.shields.io/github/downloads/virahitvin8/Krishi-Drishti/total)](https://github.com/virahitvin8/Krishi-Drishti/releases)
[![GitHub issues](https://img.shields.io/github/issues/virahitvin8/Krishi-Drishti)](https://github.com/virahitvin8/Krishi-Drishti/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/virahitvin8/Krishi-Drishti)](https://github.com/virahitvin8/Krishi-Drishti/pulls)
[![License](https://img.shields.io/github/license/virahitvin8/Krishi-Drishti)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D%203.0.0-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D%202.17.0-blue)](https://dart.dev)
[![Build APK](https://github.com/virahitvin8/Krishi-Drishti/actions/workflows/build-apk.yml/badge.svg)](https://github.com/virahitvin8/Krishi-Drishti/actions/workflows/build-apk.yml)

## Revolutionizing Agriculture with AI-Powered Crop Disease Detection

KrishiDrishti is an innovative mobile application designed to empower farmers with instant crop disease detection and treatment recommendations using artificial intelligence. Simply capture or upload an image of a crop leaf, and our AI model analyzes it to identify diseases and provide actionable solutions.

## 🌟 Key Features

- **Instant Disease Detection**: Take a photo or upload an image of crop leaves
- **AI-Powered Analysis**: Advanced convolutional neural network models for accurate diagnosis
- **Multilingual Support**: Available in multiple Indian languages (Hindi, Tamil, Telugu, etc.)
- **Offline Capability**: Core functionality works without internet connectivity
- **Treatment Recommendations**: Get organic and chemical treatment options
- **Disease Information**: Learn about symptoms, causes, and prevention
- **Farmer Community**: Connect with other farmers and experts
- **Weather Integration**: Get local weather forecasts for better farm planning
- **Voice Assistance**: Hands-free operation for field use
- **Export Reports**: Share diagnosis reports via WhatsApp, email, etc.

## 📱 Screenshots

| Home Screen | Disease Detection | Results |
|-------------|-------------------|---------|
| ![Home](assets/screenshots/home.png) | ![Detection](assets/screenshots/detection.png) | ![Results](assets/screenshots/results.png) |

*Note: Screenshots are placeholders. Actual UI may vary.*

## 📲 Download & Installation

### Android APK
Download the latest release from the [Releases page](https://github.com/virahitvin8/Krishi-Drishti/releases):

1. Go to [KrishiDrishti Releases](https://github.com/virahitvin8/Krishi-Drishti/releases)
2. Download the `app-debug.apk` from the latest release
3. Install on your Android device (enable "Install from unknown sources" in settings if required)

### From Source (For Developers)
```bash
# Clone the repository
git clone https://github.com/virahitvin8/Krishi-Drishti.git
cd KrishiDrishti

# Get Flutter dependencies
flutter pub get

# Run the app
flutter run
```

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.0+ (Cross-platform mobile framework)
- **Backend**: Node.js/Express with RESTful APIs
- **AI Model**: TensorFlow Lite optimized for mobile devices
- **Database**: SQLite for local storage, PostgreSQL for cloud sync
- **State Management**: Provider/Riverpod
- **Authentication**: Firebase Auth (optional)
- **Cloud Services**: AWS/GCP for model hosting and analytics

## 🧪 How It Works

1. **Image Capture**: User captures or selects an image of crop leaves
2. **Preprocessing**: Image is resized and normalized for model input
3. **AI Inference**: TensorFlow Lite model runs on device (or cloud fallback)
4. **Analysis**: Model outputs disease probabilities and confidence scores
5. **Results**: Top predictions displayed with treatment recommendations
6. **Feedback**: User can confirm accuracy to improve the model over time

## 🌍 Supported Crops & Diseases

| Crop | Diseases Detected |
|------|-------------------|
| Rice | Blast, Blight, Tungro, Brown Spot |
| Wheat | Rust, Smut, Powdery Mildew, Fusarium |
| Cotton | Leaf Spot, Bollworm, Whitefly, Leaf Curl |
| Tomato | Blight, Curl Virus, Spot Wilt, Mosaic |
| Potato | Blight, Scab, Virus Y, Rhizoctonia |
| Sugarcane | Red Rot, Smut, Wilt, Grassyshoot |
| ... and many more | ...

## 👥 For Farmers

- No prior technical knowledge required
- Works on low-end Android devices (Android 5.0+)
- Regular model updates with new disease patterns
- Voice guidance for visually impaired farmers
- Integration with government agricultural schemes

## 👨‍🌾 For Agricultural Experts

- Contribute disease images to improve model accuracy
- Access anonymized analytics for regional outbreak tracking
- Provide expert advice through the community forum
- Integrate with existing farm management systems

## 🔧 Development & Contribution

We welcome contributions from developers, agriculturists, and designers!

### Setting Up Development Environment
1. Install [Flutter SDK](https://flutter.dev/docs/get-started/install)
2. Install Android Studio or VS Code with Flutter/Dart plugins
3. Configure an Android emulator or connect a physical device
4. Fork the repository and create a feature branch

### Contribution Guidelines
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- TensorFlow Lite team for mobile ML solutions
- Flutter community for excellent framework
- Agricultural research institutions for disease datasets
- Early farmer testers for invaluable feedback
- Open source contributors worldwide

## 📞 Support & Contact

- **Email**: support@krishidrishti.in
- **Website**: https://krishidrishti.in
- **Twitter**: @KrishiDrishti
- **WhatsApp**: +91 XXXXXXXXXX (for farmer support groups)

---

<div align="center">
  Made with ❤️ for farmers worldwide
  <br>
  <sup>© 2023-2026 KrishiDrishti. All rights reserved.</sup>
</div>