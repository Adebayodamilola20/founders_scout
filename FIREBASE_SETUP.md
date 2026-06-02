# Scoutify Firebase Setup

This project now expects:

- `Firebase Auth`
- `Cloud Firestore`
- `Google Sign-In`
- `Sign in with Apple`

Official references used:

- Firebase Auth for Flutter: https://firebase.google.com/docs/auth/flutter/start
- Firebase federated auth for Flutter: https://firebase.google.com/docs/auth/flutter/federated-auth
- Firestore quickstart: https://firebase.google.com/docs/firestore/quickstart
- Apple sign-in requirements: https://firebase.google.com/docs/auth/ios/apple

## 1. Flutter packages

Run this from the project root:

```bash
flutter pub get
```

## 2. Firebase Console

Open your Firebase project:

- Project: `founders-scout-4fd54`

Then do the following.

### Authentication

Go to:

- `Build -> Authentication -> Sign-in method`

Enable these providers:

- `Email/Password`
- `Google`
- `Apple`

### Firestore

Go to:

- `Build -> Firestore Database`

Create the database if it is not already created.

Recommended for now:

- Start in `production mode`
- Choose the region closest to your users

## 3. Android manual steps

`google-services.json` is already present, so the app is already connected.

Still verify:

- package name in Firebase Android app matches:
  - `com.foundersscout.founders_scout`

### Google Sign-In on Android

Firebase’s Flutter federated auth docs note that Google Sign-In on Android needs your SHA-1 configured.

In Firebase console:

- `Project settings -> Your apps -> Android app`
- add SHA-1
- add SHA-256 too if available

To get the debug SHA-1 locally:

```bash
cd android
./gradlew signingReport
```

Copy the `SHA1` and `SHA-256` values into Firebase.

Then download the updated `google-services.json` only if Firebase asks you to refresh it.

## 4. iPhone manual steps

`GoogleService-Info.plist` is already present.

Still verify in Firebase:

- iOS bundle ID matches:
  - `com.foundersscout.foundersScout`

### Google Sign-In on iPhone

In Firebase console:

- `Authentication -> Sign-in method -> Google`
- make sure Google is enabled

In Xcode:

- open `ios/Runner.xcworkspace`
- confirm the `URL Types` / reversed client ID exists after Firebase/Google setup

If Google Sign-In fails on iPhone, the usual missing piece is the reversed client ID URL scheme from `GoogleService-Info.plist`.

### Apple Sign-In

Apple Sign-In requires manual Apple Developer setup.

In Apple Developer:

1. Join the Apple Developer Program if you have not already.
2. Open `Certificates, Identifiers & Profiles`.
3. Open your App ID for the iOS app.
4. Enable `Sign In with Apple`.
5. Create a `Services ID` if Firebase asks for web-style Apple OAuth configuration.
6. Create a `Sign in with Apple key`.
7. Note these values:
   - Apple Team ID
   - Apple Key ID
   - Apple private key `.p8`
   - Service ID / client ID

Then in Firebase console:

- `Authentication -> Sign-in method -> Apple`

Fill in:

- `Service ID`
- `Apple Team ID`
- `Key ID`
- upload or paste the `.p8` private key contents as required by Firebase

In Xcode for the iOS target:

- `Signing & Capabilities`
- add `Sign In with Apple`

That Xcode capability is required for Apple login itself.

## 5. Firestore rules

This repo includes a starter file:

- `firestore.rules`

Publish it in Firebase console:

- `Build -> Firestore Database -> Rules`

Or with Firebase CLI if you use that workflow.

## 6. Expected Firestore structure

Main user document:

- `users/{uid}`

Fields:

- `email`
- `fullName`
- `homeCity`
- `selectedCountry`
- `selectedLocation`
- `selectedCategories`
- `selectedDigitalGaps`
- `stats.contactedCount`
- `stats.repliedCount`
- `stats.closedCount`
- `joinedAt`
- `updatedAt`

Subcollections:

- `users/{uid}/savedLeads`
- `users/{uid}/outreachHistory`
- `users/{uid}/pitchThreads`

## 7. What is already wired in code

- Firebase initialization in `main.dart`
- auth state gate
- email/password signup and login
- Google sign-in trigger
- Apple sign-in trigger
- Firestore profile bootstrap on signup/social login
- setup preferences saved to Firestore
- profile updates saved to Firestore
- saved leads persistence
- outreach history persistence
- AI pitch conversation persistence

## 8. What you should test first

1. Create account with email/password
2. Confirm `users/{uid}` appears in Firestore
3. Finish setup and confirm:
   - `selectedCountry`
   - `selectedLocation`
   - `selectedCategories`
   - `selectedDigitalGaps`
4. Save a lead and confirm `savedLeads`
5. Send a pitch and confirm `pitchThreads`
6. Contact a lead and confirm `outreachHistory`

## 9. If Firebase app IDs change

If you create new Firebase app registrations or change bundle/package IDs, rerun:

```bash
flutterfire configure
```

That will regenerate `lib/firebase_options.dart`.
