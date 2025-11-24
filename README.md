# 🚚 FoodTruck Finder (Crowdsourced)

FoodTruck Finder is a modern mobile cloud computing application designed to help users discover and report the locations of food trucks in real-time. The application features a crowdsourced reporting system where user submissions are verified by administrators through a web-based admin panel.

## ✨ Features

### 📱 Mobile Application (Flutter - Android)
*   **🗺️ Real-Time Interactive Map:** 
    *   Displays food truck locations on Google Maps with custom markers
    *   Interactive map picker for precise location selection (tap or drag)
    *   Multiple map style options (Normal, Satellite, Terrain, Hybrid)
    *   Current location tracking with "Use My Current Location" feature
*   **🔒 Modern User Authentication:** 
    *   Secure login and registration with Material Design 3 UI
    *   Password visibility toggle
    *   Elegant card-based input fields with validation
*   **📢 Enhanced Crowdsourced Reporting:**
    *   Report new food truck locations with interactive map picker
    *   Suggest updates or corrections for existing food trucks
    *   Predefined food type dropdown (18 categories) to prevent duplicates
    *   Card-based form sections with gradient headers
    *   Real-time validation and user-friendly error messages
*   **ℹ️ Food Truck Details:** Tapping a marker shows:
    *   Truck name and type
    *   Location description
    *   Reporter information and timestamp
    *   *(Future: Menus, promotional news)*
*   **🔍 Advanced Search & Filter:**
    *   Real-time search by name or type with pill-shaped search bar
    *   Filter food trucks by predefined type categories
    *   Active filter indicator with quick clear option
    *   Frosted glass effect search interface
*   **🚗 Directions:** Get directions to a selected food truck via the device's native map application
*   **🎨 Modern UI/UX Design:**
    *   Material Design 3 with orange/brown color scheme
    *   Card-based layouts with rounded corners (12-20px)
    *   Gradient headers with white text
    *   Consistent iconography using rounded variants
    *   Proper dark mode support
    *   Elevation and shadows for visual depth
*   **👤 Enhanced Profile Management:** 
    *   Gradient header with circular avatar
    *   White card layout with shadow effects
    *   Logout confirmation dialog
    *   Clean user information display
*   **📄 Redesigned About Us Page:** 
    *   Hero section with gradient background
    *   Separate card sections (Features, Team, Links)
    *   Team member profiles with circular avatars
    *   Clickable social/external links

### 🖥️ Admin Web Panel (Flutter Web)
*   **🛡️ Secure Admin Login:** Separate authentication for administrators.
*   **📊 Dashboard:** Overview of admin functionalities.
*   **🍔 Food Truck Management (CRUD):**
    *   View, add, edit, and delete food truck listings directly.
    *   Input/update name, type, location description, GPS coordinates.
    *   *(Future: Manage menus, promotions).*
*   **📝 Report Management:**
    *   View pending user submissions for new trucks or updates to existing ones.
    *   Approve reports: Adds/updates verified food trucks to the main map.
    *   Reject reports: Marks reports as rejected.
*   **👥 User Management:**
    *   View a list of registered users and their details (email, display name, role, joined date).
    *   Change user roles (e.g., promote to admin, demote to user).

## 🛠️ Core Technologies
*   **Frontend (Mobile & Web):** Flutter 3.7.2
*   **Backend & Database:** Firebase (Cloud Services)
    *   **Firebase Authentication:** User login/registration with email/password
    *   **Cloud Firestore:** NoSQL database for real-time data storage
    *   **(Planned) Cloud Functions for Firebase:** For push notifications and server-side logic
*   **Mapping:** Google Maps Platform
    *   `google_maps_flutter` 2.12.3 for mobile interactive maps
    *   Geocoding and location services
*   **UI/UX Framework:** Material Design 3
    *   Custom orange (#FF9800) and brown (#8B4513) color scheme
    *   Card-based layouts with consistent 12-20px rounded corners
    *   Gradient headers and modern iconography
*   **Location Services:** Geolocator 14.0.1 for device positioning

## 🎨 Design Features
*   **Consistent Color Palette:**
    *   Primary: Orange (#FF9800)
    *   Accent: Brown (#8B4513)
    *   Background: Grey[50] with white cards
    *   Status bar: Light overlay for optimal contrast
*   **Modern UI Patterns:**
    *   Rounded corners (12-20px radius) on all interactive elements
    *   Card elevation with subtle shadows (1-2px)
    *   Frosted glass effects on overlays
    *   Icon-prefixed input fields
    *   Gradient headers with white text
    *   Pill-shaped buttons and search bars
*   **Typography:**
    *   Bold headings with proper weight hierarchy
    *   Consistent icon sizing (20-26px)
    *   Letter spacing for modern feel (0.3-0.5)
*   **Accessibility:**
    *   Proper contrast ratios
    *   Touch targets sized appropriately
    *   Error states with clear visual feedback
    *   Dark mode support

## 📂 Project Structure (Key Directories in `lib/`)
*   `main.dart`: Main application entry point.
*   `models/`: Data model classes (e.g., `food_truck_model.dart`, `report_model.dart`).
*   `screens/`: UI screen widgets.
    *   `admin/`: Screens specific to the admin panel.
        *   `sections/`: Widgets for admin dashboard sections.
*   `services/`: Service classes (e.g., `auth_service.dart`).
*   `widgets/`: Reusable UI components (e.g., `auth_wrapper.dart`, `admin_auth_wrapper.dart`, `map_screen_widgets/`).

## 🚀 Setup and Configuration

### Prerequisites
*   Flutter SDK: [Install Flutter](https://flutter.dev/docs/get-started/install)
*   Firebase Account: [Create a Firebase project](https://firebase.google.com/)
*   Firebase CLI: `npm install -g firebase-tools`
*   Node.js and npm (Optional, for Cloud Functions)
*   An editor like VS Code or Android Studio.

### Firebase Project Setup
1.  Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2.  **Authentication:** Enable "Email/Password" sign-in.
3.  **Firestore Database:**
    *   Create a Firestore database (start in Test Mode, then secure rules).
    *   **Required Collections:** `foodTrucks`, `reports`, `users` (with `role` field).
4.  **Google Maps Platform:**
    *   Enable "Maps SDK for Android" (and "Maps JavaScript API" if needed).
    *   Create and restrict an API Key.

### Flutter Project Configuration
1.  **Clone/Create Project:**
    ```bash
    # git clone [your-repo-url]
    # cd foodtruck_finder
    # OR
    flutter create foodtruck_finder
    cd foodtruck_finder
    ```
2.  **Add Web Support:**
    ```bash
    flutter create . --platforms=web
    ```
3.  **Configure Firebase for Flutter:**
    ```bash
    firebase login
    dart pub global activate flutterfire_cli
    flutterfire configure
    ```
    (Select your Firebase project and platforms: Android, Web).
4.  **Add Google Maps API Key (Android):**
    *   In `android/app/src/main/AndroidManifest.xml`, within `<application>`:
        ```xml
        <meta-data android:name="com.google.android.geo.API_KEY"
                   android:value="YOUR_API_KEY_HERE"/>
        ```
5.  **Update Android `minSdkVersion`:**
    *   In `android/app/build.gradle`, ensure `minSdkVersion` is `21` or higher.
6.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
7.  **Firestore Security Rules:**
    *   Implement appropriate rules in the Firebase console, especially for admin vs. user access to `foodTrucks`, `users`, and `reports`.
    *   Ensure admin users have `role: "admin"` in their Firestore `users` document.

## 🏃 Running the Application

### 📱 Mobile App (Android)
```bash
flutter run
```

### 🌐 Admin Web Panel (Chrome)
```bash
flutter run -d chrome
```

(Log in with an admin user.)


### ✅ Key Development Phases Completed

**Phase 1-8:** Core mobile app setup, map, auth, basic display, real-time updates, auxiliary pages.

**Phase 9:** Web Admin Panel (Food Truck CRUD, Report Review, User Role Management).

**Phase 10:** Mobile App User Features (Search, Type Filtering, Directions).

**Phase 11:** Advanced Mobile App Features (Map Styles, User Submissions for new/existing trucks).

**Phase 12:** Major UI/UX Overhaul (Material Design 3 Implementation):
  *   Modern login screen with card-based inputs and password visibility toggle
  *   Interactive map location picker with drag-and-drop marker
  *   Redesigned report form with gradient headers and predefined food type dropdown
  *   Enhanced map screen app bar with pill-shaped search and simplified branding
  *   Modern filter and map style dialogs with card layouts
  *   Redesigned profile screen with gradient header and logout confirmation
  *   Completely redesigned About Us page with hero section and card sections
  *   Consistent Material Design 3 aesthetic across all screens
  *   Fixed food type duplicates by implementing predefined categories dropdown

## 💡 Future Enhancements / TODO

### Mobile App:

  *   **Push Notifications (FCM):**
    *   Location-based proximity alerts when trucks enter user's area
    *   Favorite truck notifications
    *   Report status updates
    *   New truck discovery alerts
  *   Display menus and promotional news
  *   User ratings and reviews for food trucks
  *   Filter by "Open Now" / Operating hours
  *   User favorites system
  *   Advanced search (menu items, distance)

  *   Custom map markers per food type
  *   Additional dark mode refinements

### Admin Panel:

  *   Advanced report approval (linking updates to existing trucks)
  *   Manage food truck menus & promotions
  *   Detailed user views & advanced actions (suspend, etc.)
  *   Dashboard analytics with charts and statistics

### Backend:

  *   Cloud Functions for Firebase:
    *   Scheduled functions for proximity-based push notifications
    *   Auto-delete user data on account deletion
    *   Server-side report validation
  *   Server-side search indexing (e.g., Algolia) for larger datasets
  *   Image upload and storage for food truck photos

## 📱 Mobile Cloud Computing Features

This application fulfills mobile cloud computing requirements with:

1. **Firebase Authentication** - Cloud-based user authentication and session management
2. **Cloud Firestore** - NoSQL cloud database with real-time synchronization
3. **Google Maps Platform** - Cloud-based mapping, geocoding, and directions services
4. **Firebase Hosting** - Cloud deployment for web admin panel
5. **(Planned) Firebase Cloud Messaging** - Cloud-to-device push notifications
6. **(Planned) Cloud Functions** - Serverless backend logic execution

All services operate over the internet, enabling seamless data synchronization, real-time updates, and scalable infrastructure.

## 🤝 Contributing

   *   Fork the Project
   *   Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
   *   Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
   *   Push to the Branch (`git push origin feature/AmazingFeature`)
   *   Open a Pull Request


## 📞 Contact & Contributors

-   [Badrul](https://github.com/jerungpyro)
-   [Muhammad Sufyan](https://github.com/pyunk)
-   [Azwar Ansori](https://github.com/AzwarAns61)
-   [Wan Muhammad Azlan](https://github.com/Lannnzzz)

---

**License:** This project is developed for academic purposes (ITT632 Mobile Cloud Computing).

**Last Updated:** November 2025
