# SafeZone Marketplace

## Overview
SafeZone Marketplace is a neighbourhood-focused marketplace application designed to promote sustainable local commerce and strengthen community connections. This project is developed for GLB205 course, addressing UN Sustainable Development Goal 11 (Sustainable Cities and Communities).

Built upon the foundation of the [original SafeZone neighbourhood report app](https://github.com/EmreA3810/SafeZoneApp) (developed for Mobile Programming course), this marketplace transforms community safety awareness into economic empowerment by enabling local buying and selling within trusted neighbourhoods.

## SDG 11 Alignment
This app contributes to SDG 11: Sustainable Cities and Communities by:
- **Reducing Carbon Footprint**: Encouraging local trade reduces transportation and delivery distances
- **Strengthening Community Bonds**: Building trust and connections between neighbours
- **Supporting Local Economy**: Keeping economic activity within the neighbourhood
- **Promoting Sustainable Consumption**: Facilitating reuse and exchange of goods locally

## Features
- 🏘️ **Neighbourhood-Based**: Items and sellers filtered by local proximity
- 📱 **User Authentication**: Secure Firebase authentication
- 🛍️ **Marketplace Listings**: Post and browse items for sale
- 🔍 **Search & Filter**: Find items easily by category and location
- 🔔 **Notifications**: Stay updated on messages and offers
- 🖥️ **Web Platform**: Full marketplace access via web browser with enhanced admin features

## Tech Stack
- **Framework**: Flutter
- **Backend**: Firebase (Firestore, Authentication, Cloud Storage)
- **Platform**: Android, iOS & Web
- **Language**: Dart

## Project Structure
```
lib/
  ├── main.dart                 # App entry point
  ├── firebase_options.dart     # Firebase configuration
  ├── models/                   # Data models
  ├── screens/                  # UI screens
  ├── widgets/                  # Reusable widgets
  ├── services/                 # Business logic & API calls
  └── utils/                    # Helper functions
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Firebase account
- Android Studio / Xcode for mobile development

### Installation
1. Clone the repository
```bash
git clone https://github.com/yourusername/safezonemarketplace.git
cd safezonemarketplace
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
```bash
flutterfire configure --project=safezonemarketplace
```

4. Run the app
```bash
flutter run
```

## Development Team
This project is developed as part of GLB205 coursework, building upon the original SafeZone app created for Mobile Programming course.

**Original SafeZone Team:**
- Emre Akdağ
- Mustafa Yeşil
- Mahmut Sami Başkal

**Marketplace Transformation:**
- Mahmut Sami Başkal

## License
This project is developed for educational purposes.

## Acknowledgments
Special thanks to Emre Akdağ and Mustafa Yeşil from the [original SafeZone team](https://github.com/EmreA3810/SafeZoneApp) for their permission to transform the neighbourhood report app into this marketplace platform.