# 🚴 RideTrack — Your Personal Cycling Companion

> Track every ride, crush your goals, and discover new routes with intelligent GPS tracking and performance insights.

A modern Flutter bike tracking application that helps cyclists monitor their rides, set goals, analyze performance, and explore new routes with real-time GPS navigation.

## ✨ Key Features

- **📍 Real-Time GPS Tracking** — Record your rides with accurate location tracking and live statistics
- **🗺️ Route Planning** — Plan bike-friendly routes with turn-by-turn navigation
- **📊 Performance Analytics** — Detailed statistics, charts, and progress tracking
- **🎯 Goal Setting** — Set and track distance, frequency, and time-based cycling goals
- **📱 Beautiful UI** — Modern, intuitive interface optimized for cyclists
- **☁️ Cloud Sync** — Securely store and sync your rides across devices with Firebase
- **📈 Progress Insights** — Weekly and monthly performance trends and achievements

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0 or higher)
- [Firebase Account](https://firebase.google.com/) (for authentication and cloud storage)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ridetrack.git
   cd bikeapp
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Create a new Firebase project
   - Add your Firebase configuration files
   - Update `lib/firebase_options.dart`

4. Run the app:
   ```bash
   flutter run
   ```

## 🏗️ Architecture

RideTrack follows **Clean Architecture** principles with clear separation of concerns:

- **`data/`** — Models, repositories, and data sources
- **`presentation/`** — UI components, pages, and widgets  
- **`core/`** — Services, utilities, and constants
- **`providers/`** — State management (Riverpod/Provider)

## 📱 Screenshots

<!-- Add screenshots here -->

## 🛠️ Built With

- [Flutter](https://flutter.dev/) — Cross-platform UI framework
- [Firebase](https://firebase.google.com/) — Authentication, Firestore, Cloud Storage
- [OpenStreetMap](https://www.openstreetmap.org/) — Maps and routing
- [Geolocator](https://pub.dev/packages/geolocator) — GPS location services
- [FL Chart](https://pub.dev/packages/fl_chart) — Beautiful charts and graphs

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

**Made with ❤️ by cyclists, for cyclists**
