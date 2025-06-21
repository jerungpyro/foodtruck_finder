# FoodTruck Finder (Crowdsourced)

FoodTruck Finder is a mobile application designed to help users discover and report the locations of food trucks in real-time. The application features a crowdsourced reporting system where user submissions are verified by administrators through a web-based admin panel.

## Features

**Mobile Application (Flutter - Android):**
*   **Real-Time Map:** Displays food truck locations on a Google Map.
*   **User Authentication:** Secure login and registration for users.
*   **Crowdsourced Reporting:**
    *   Users can report new food truck locations.
    *   Users can suggest updates or corrections for existing food trucks.
*   **Food Truck Details:** Tapping a marker shows:
    *   Truck name and type.
    *   Location description.
    *   Who reported it and when.
    *   (Future: Menus, promotional news).
*   **Search & Filter:**
    *   Search food trucks by name or type.
    *   Filter food trucks by type.
*   **Directions:** Get directions to a selected food truck via the device's native map application.
*   **Custom Map Styles:** Users can choose between different Google Map visual styles (Normal, Satellite, etc.).
*   **Profile Management:** Users can view their basic profile and log out.
*   **Auxiliary Pages:** Includes an "About Us" page.

**Admin Web Panel (Flutter Web):**
*   **Secure Admin Login:** Separate authentication for administrators.
*   **Dashboard:** Overview of admin functionalities.
*   **Food Truck Management (CRUD):**
    *   View, add, edit, and delete food truck listings directly.
    *   Input/update name, type, location description, GPS coordinates.
    *   (Future: Manage menus, promotions).
*   **Report Management:**
    *   View pending user submissions for new trucks or updates to existing ones.
    *   Approve reports: Adds/updates verified food trucks to the main map.
    *   Reject reports: Marks reports as rejected.
*   **User Management:**
    *   View a list of registered users and their details (email, display name, role, joined date).
    *   Change user roles (e.g., promote to admin, demote to user).

## Core Technologies
*   **Mobile & Web Frontend:** Flutter
*   **Backend & Database:** Firebase
    *   **Firebase Authentication:** User login/registration.
    *   **Cloud Firestore:** NoSQL database for all application data.
    *   **(Planned/Optional) Cloud Functions for Firebase:** For server-side logic like data sync on auth deletion.
*   **Mapping:** Google Maps Platform (via `google_maps_flutter` for mobile).

## Project Structure (Key Directories in `lib/`)
*   `main.dart`: Main application entry point, routes to user or admin app.
*   `models/`: Contains data model classes (e.g., `food_truck_model.dart`, `report_model.dart`).
*   `screens/`: Contains UI screen widgets for the mobile app and admin panel.
    *   `admin/`: Screens specific to the admin panel.
        *   `sections/`: Widgets for individual sections of the admin dashboard.
*   `services/`: Houses service classes (e.g., `auth_service.dart`).
*   `widgets/`: Contains reusable UI components.
    *   `auth_wrapper.dart`: Handles initial routing based on user authentication state.
    *   `admin_auth_wrapper.dart`: Handles initial routing for the admin panel.
    *   `map_screen_widgets/`: Widgets specific to the `MapScreen`.

## Setup and Configuration

### Prerequisites
*   Flutter SDK: [Install Flutter](https://flutter.dev/docs/get-started/install)
*   Firebase Account: [Create a Firebase project](https://firebase.google.com/)
*   Firebase CLI: `npm install -g firebase-tools`
*   Node.js and npm (if planning to use Cloud Functions)
*   An editor like VS Code or Android Studio.

### Firebase Project Setup
1.  Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2.  **Authentication:** Enable "Email/Password" sign-in method.
3.  **Firestore Database:**
    *   Create a Firestore database.
    *   Start in **Test Mode** for initial development, then update security rules for production.
    *   **Required Collections:**
        *   `foodTrucks`: Stores verified food truck details.
        *   `reports`: Stores user submissions for new/updated food trucks.
        *   `users`: Stores user profile information (created on registration), including a `role` field (`user` or `admin`).
4.  **Google Maps Platform:**
    *   In Google Cloud Console, enable "Maps SDK for Android" (and "Maps JavaScript API" if using JS maps for web admin, though we use Flutter Web's Google Maps plugin).
    *   Create an API Key.
    *   Restrict the API key to your Android package name and SHA-1 fingerprint, and for web, to your web app's URL.

### Flutter Project Configuration
1.  **Clone the repository (if applicable) or create a new Flutter project.**
    ```bash
    git clone [your-repo-url]
    cd foodtruck_finder
    # OR
    # flutter create foodtruck_finder
    # cd foodtruck_finder
    ```
2.  **Add Web Support (if not already enabled):**
    ```bash
    flutter create . --platforms=web
    ```
3.  **Configure Firebase for Flutter:**
    *   Login to Firebase: `firebase login`
    *   Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
    *   Configure the project:
        ```bash
        flutterfire configure
        ```
        Follow the prompts to select your Firebase project and the platforms (Android, Web). This will generate `lib/firebase_options.dart` and platform-specific configuration files.
4.  **Add Google Maps API Key to Android:**
    *   Open `android/app/src/main/AndroidManifest.xml`.
    *   Add within the `<application>` tag:
        ```xml
        <meta-data android:name="com.google.android.geo.API_KEY"
                   android:value="YOUR_API_KEY_HERE"/>
        ```
    *   Replace `YOUR_API_KEY_HERE` with your actual Google Maps API key.
5.  **Update Android `minSdkVersion`:**
    *   Open `android/app/build.gradle`.
    *   Ensure `minSdkVersion` is at least `21` (or as required by `google_maps_flutter`).
6.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
7.  **Firestore Security Rules:**
    *   Update your `firestore.rules` file in the Firebase console with appropriate security rules. Example rules are provided throughout the development phases, especially for `foodTrucks`, `users`, and `reports` collections, distinguishing between admin and regular user permissions.
    *   **Crucial for Admin Panel:** Ensure an admin user has a document in the `users` collection with `role: "admin"`.

8.  **Running the Application**

### Mobile App (Android Emulator/Device)
```bash
flutter run
```

### Admin Web Panel (Chrome)
```bash
flutter run -d chrome
```

### Key Development Phases Completed

   *   Phase 1-8: Core mobile app setup, map integration, user authentication, basic food truck display, real-time updates, auxiliary pages.

   *   Phase 9: Comprehensive Web-Based Admin Panel (Food Truck CRUD, Report Review, User Role Management).

   *   Phase 10: Essential Mobile App User Features (Search, Filtering by Type, Directions).

   *   Phase 11 (formerly 12): Advanced Mobile App Features (Custom Map Styles, User Submissions for new/existing trucks).
   

### Future Enhancements / TODO
    
Admin Panel:

   *   More sophisticated report approval (linking to existing trucks for updates) for managing food truck menus and promotional news.

   *   Advanced user management (suspend, detailed view).

   *   Dashboard analytics.

   *   Mobile App:

   *   Display menus and promotional news.

   *   User ratings and reviews for food trucks.

   *   "Open Now" / Operating hours for food trucks and filtering.
     
   *   User favorites system.

   *   Notifications (FCM).

   *   Advanced search (by menu items, distance).

   *   Custom map markers based on food type.

   *   UI/UX polish and dark mode.
     
Backend:

   *   Cloud Function for automatic Firestore data cleanup on Firebase Auth user deletion.

   *   (Optional) Server-side search indexing (e.g., Algolia) for large datasets.

   *   Contributing
     
   *   (Add guidelines here if this is an open-source project or if you expect contributions.)

### Fork the Project
    
   *   Create your Feature Branch (git checkout -b feature/AmazingFeature)

   *   Commit your Changes (git commit -m 'Add some AmazingFeature')

   *   Push to the Branch (git push origin feature/AmazingFeature)

   *   Open a Pull Request
