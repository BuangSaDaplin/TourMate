# TourMate - Cebu Tourist Booking & Guide App

A Flutter application that connects tourists visiting Cebu, Philippines with freelance local tour guides. The app allows users to browse top-rated Cebu tours, book guides, and get recommendations tailored to local attractions.

## Features Implemented

- **User Account Management:** Social logins (Google, Facebook, Apple) + Email/Password, profile picture upload, and hard delete for accounts.
- **Guide Verification:** Guides can upload valid ID + LGU Certificate for manual admin approval.
- **Tour Listings:** Guides can create/edit/delete tours with details like title, description, price, category, schedule, meeting point, and participant limit.
- **Tour Booking:** Tourists can book tours with mock payments and real-time availability tracking.
- **Payments:** Tourists can view their payment history.
- **Messaging:** In-app 1-on-1 chat between tourists and guides.
- **Itinerary Planning:** Auto-generated itineraries that guides can edit.
- **Reviews & Ratings:** Tourists can submit reviews and ratings after tour completion.
- **Analytics Dashboard (Admin):** Admin dashboard with mock data visualization.
- **Notifications:** In-app notifications for bookings, cancellations, etc.
- **Admin Tools:** User management (ban/unban) and system configuration.
- **LGU Integration:** Guides can upload LGU documents for verification.
- **Multilingual Support:** English, Tagalog, and Cebuano language support.
- **Tour Recommendations:** Mock recommendation algorithm.

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / VS Code with Flutter extensions
- An Android/iOS device or emulator
- Firebase CLI

### Installation

1. Clone the repository or copy the project files

2. Navigate to the project directory:
```bash
cd tourmate_app
```

3. Install dependencies:
```bash
flutter pub get
```

4. Configure Firebase:
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`.
   - Place your `google-services.json` file in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
   - Update `android/build.gradle` and `android/app/build.gradle` to apply google services per Firebase docs.

5. Run the app:
```bash
flutter run
```

### Local Testing with Firebase Emulators

1. Install the Firebase CLI.

2. Start the emulators:
```bash
firebase emulators:start --only firestore,auth,storage
```

3. In `lib/main.dart`, uncomment the following lines to point the app to the emulators:
```dart
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';

// ...

// await Firebase.initializeApp(
//   options: DefaultFirebaseOptions.currentPlatform,
// );

// if (const bool.fromEnvironment('USE_EMULATOR')) {
//   FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
//   await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
//   await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
// }
```

### Seed Demo Data

To seed the database with demo data, run the following command:
```bash
flutter run lib/tools/seed_demo_data.dart
```

### Social Login Setup

- **Google Sign-In:**
  - Follow the instructions in the `google_sign_in` package to configure Google Sign-In for your project.
  - You will need to provide your `SHA-1` fingerprint to the Firebase console.
- **Facebook Sign-In:**
  - Follow the instructions in the `flutter_facebook_auth` package to configure Facebook Sign-In for your project.
  - You will need to create a Facebook App and provide the App ID and other details.
- **Sign in with Apple:**
  - Follow the instructions in the `sign_in_with_apple` package to configure Sign in with Apple for your project.

## License

This project is created for demonstration purposes.
