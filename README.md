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
- 📱 **User Authentication**: Secure Firebase authentication with Google Sign-In
- 🛍️ **Marketplace Listings**: Post and browse items for sale with detailed descriptions
- 💬 **Direct Contact**: Direct email and phone contact with sellers for seamless communication
- 🔍 **Search & Filter**: Find items easily by category, condition, status, and location
- 📍 **Map Integration**: View products on an interactive map and click locations to open Google Maps
- ❤️ **Favorites**: Save your favorite products for quick access later
- 🔔 **Notifications**: Customizable notifications by product category (disabled by default)
- 🖼️ **Photo Management**: Upload multiple photos for products (web and mobile support)
- 💾 **Product Status**: Available, Free, Reserved, On Sale, or Sold Out tracking
- 🖥️ **Web Platform**: Full marketplace access via web browser with enhanced admin features
- 📱 **Responsive Design**: Optimized for desktop (navigation rail) and mobile (bottom navigation)

## Tech Stack
- **Framework**: Flutter 3.9+
- **Backend**: Firebase (Realtime Database, Firestore, Authentication, Cloud Storage, Cloud Messaging)
- **Platform**: Android, iOS & Web
- **Language**: Dart
- **State Management**: Provider
- **Maps**: flutter_map with OpenStreetMap
- **Image Processing**: flutter_image_compress, image_picker, file_picker
- **URL Handling**: url_launcher (email & phone contact, maps navigation)

## Project Structure
```
lib/
  ├── main.dart                     # App entry point & Firebase setup
  ├── firebase_options.dart         # Firebase configuration
  ├── config/                       # Configuration files
  ├── models/
  │   └── product_model.dart        # Product data model with contact fields
  ├── screens/
  │   ├── home_screen.dart          # Main navigation hub
  │   ├── feed_screen.dart          # Infinite scroll product feed
  │   ├── map_screen.dart           # Interactive product map
  │   ├── product_detail_screen.dart # Product details with contact options
  │   ├── add_product_screen.dart   # Create/edit products with contact info
  │   ├── my_products_screen.dart   # User's product listings
  │   ├── favorites_screen.dart     # Saved favorite products
  │   ├── profile_screen.dart       # User profile & settings
  │   └── notification_settings_screen.dart # Category notification preferences
  ├── widgets/
  │   └── image_from_string.dart    # Image display from base64
  ├── services/
  │   ├── auth_service.dart         # Firebase auth & user management
  │   ├── product_service.dart      # Product CRUD & Firebase sync
  │   └── notification_service.dart # Firebase Cloud Messaging setup
  └── utils/
      └── image_utils.dart          # Image compression & encoding
```

## Getting Started

### Key Features Explained

#### Contact Information
Sellers can optionally share their **email** and **phone number** when posting products. Buyers can:
- Click the email chip to open their default email app (or copy the email address)
- Click the phone chip to make a call (or copy the phone number)
- This feature is completely optional for sellers to reduce friction

#### Product Listing
Create products with:
- Title and detailed description
- Multiple photos (with automatic compression)
- Category, condition, and status
- Location (auto-detect or manual selection)
- Optional contact information (email & phone)

#### Navigation
- **Desktop**: Sidebar navigation rail with all sections
- **Mobile**: Bottom navigation bar for easy thumb access
- **Favorites**: Accessible from main navigation for quick access
- **Map**: View all products on an interactive map with click-to-Google-Maps functionality

#### Prerequisites
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

## Development Status
✅ **Core Features**: Marketplace listing, product details, search & filter
✅ **User Features**: Authentication, favorites, product management, notifications
✅ **Contact Features**: Email/phone direct contact with sellers
✅ **Map Integration**: Interactive maps with location-based browsing
✅ **Web Support**: Full web version with responsive design
✅ **Image Handling**: Upload, compression, and storage
⚠️ **In Development**: Advanced messaging system, ratings & reviews, payment integration

## Development Team
This project is developed as part of GLB205 coursework, transforming the original SafeZone neighbourhood report app into a full marketplace platform.

**Original SafeZone Team:**
- Emre Akdağ
- Mustafa Yeşil
- Mahmut Sami Başkal

**Marketplace Enhancement & Implementation:**
- Mahmut Sami Başkal

## License
This project is developed for educational purposes.

## Acknowledgments
Special thanks to Emre Akdağ and Mustafa Yeşil from the [original SafeZone team](https://github.com/EmreA3810/SafeZoneApp) for their innovative neighbourhood report concept and permission to transform it into this marketplace platform.

## Support & Feedback
For issues, feature requests, or feedback, please reach out to the development team or open an issue in the repository.