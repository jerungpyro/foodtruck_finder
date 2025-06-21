Generated code
# 🚚 FoodTruck Finder (Crowdsourced)

FoodTruck Finder is a mobile application designed to help users discover and report the locations of food trucks in real-time. The application features a crowdsourced reporting system where user submissions are verified by administrators through a web-based admin panel.

## ✨ Features

### 📱 Mobile Application (Flutter - Android)
*   **🗺️ Real-Time Map:** Displays food truck locations on a Google Map.
*   **🔒 User Authentication:** Secure login and registration for users.
*   **📢 Crowdsourced Reporting:**
    *   Users can report new food truck locations.
    *   Users can suggest updates or corrections for existing food trucks.
*   **ℹ️ Food Truck Details:** Tapping a marker shows:
    *   Truck name and type.
    *   Location description.
    *   Who reported it and when.
    *   *(Future: Menus, promotional news).*
*   **🔍 Search & Filter:**
    *   Search food trucks by name or type.
    *   Filter food trucks by type.
*   **🚗 Directions:** Get directions to a selected food truck via the device's native map application.
*   **🎨 Custom Map Styles:** Users can choose between different Google Map visual styles (Normal, Satellite, etc.).
*   **👤 Profile Management:** Users can view their basic profile and log out.
*   **📄 Auxiliary Pages:** Includes an "About Us" page.

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
*   **Frontend (Mobile & Web):** Flutter
*   **Backend & Database:** Firebase
    *   **Firebase Authentication:** User login/registration.
    *   **Cloud Firestore:** NoSQL database for all application data.
    *   **(Planned/Optional) Cloud Functions for Firebase:** For server-side logic.
*   **Mapping:** Google Maps Platform (via `google_maps_flutter` for mobile).

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


Phase 1-8: Core mobile app setup, map, auth, basic display, real-time updates, auxiliary pages.

Phase 9: Web Admin Panel (Food Truck CRUD, Report Review, User Role Management).

Phase 10: Mobile App User Features (Search, Type Filtering, Directions).

Phase 11: Advanced Mobile App Features (Map Styles, User Submissions for new/existing trucks).


## 💡 Future Enhancements / TODO

**Admin Panel:**

   *   Advanced report approval (linking updates to existing trucks).

   *   Manage food truck menus & promotions.

   *   Detailed user views & advanced actions (suspend, etc.).

   *   Dashboard analytics.

**Mobile App:**

   *   Display menus and promotional news.

   *   User ratings and reviews for food trucks.

   *   Filter by "Open Now" / Operating hours.

   *   User favorites system.

   *   Notifications (FCM).

   *   Advanced search (menu items, distance).

   *   Custom map markers per food type.

   *   UI/UX polish, dark mode.

**Backend:**

   *   Cloud Function for auto-deleting user data from Firestore on Auth account deletion.

   *   Server-side search indexing (e.g., Algolia) for larger datasets.


## 🤝 Contributing

(This is a placeholder. Update if you have specific contribution guidelines.)

   *   Fork the Project.

   *   Create your Feature Branch (git checkout -b feature/AmazingFeature).

   *   Commit your Changes (git commit -m 'Add some AmazingFeature').

   *   Push to the Branch (git push origin feature/AmazingFeature).

   *   Open a Pull Request.


## 📞 Contact

-   [Badrul](https://github.com/jerungpyro)
-   [Muhammad Sufyan](https://github.com/pyunk)
-   [Azwar Ansori](https://github.com/AzwarAns61)
-   [Wan Muhammad Azlan](https://github.com/Lannnzzz)
