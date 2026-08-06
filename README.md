# TriTranslator

TriTranslator is a SwiftUI iOS app that translates text into two target languages using DeepL. It uses Firebase Authentication for email/password sign-in and Cloud Firestore for translation history.

## Requirements

- Xcode 26 or later
- An iOS 26 simulator or device
- A Firebase project
- A DeepL API Free account

## Local configuration

The repository includes the non-sensitive configuration files required by Xcode. Service-specific values remain local and are ignored by Git.

### 1. Configure DeepL

Create the local configuration file from the tracked example:

```sh
cp TriTranslator/Secrets.xcconfig.example TriTranslator/Secrets.xcconfig
```

Open `TriTranslator/Secrets.xcconfig` and replace the placeholder with your DeepL API key:

```xcconfig
DEEPL_API_KEY = your-deepl-api-key
```

`AppConfig.xcconfig` supplies an empty default value and optionally loads this local override. The key is inserted into the built app through `Info.plist`.

### 2. Configure Firebase

1. Create or select a project in the Firebase console.
2. Add an iOS app with bundle identifier `com.carlosreyes.TriTranslator`.
3. Enable Email/Password under Authentication > Sign-in method.
4. Create a Cloud Firestore database and configure rules appropriate for authenticated users.
5. Download `GoogleService-Info.plist`.
6. Place it at `TriTranslator/GoogleService-Info.plist`.

The Xcode project already includes that path in the app's resources. The downloaded file is ignored by Git so clones and forks do not automatically connect to the original Firebase project.

## Build and run

After adding both local configuration files, open `TriTranslator.xcodeproj`, select the `TriTranslator` scheme, and run the app.

From the command line, an unsigned simulator build can be run with:

```sh
xcodebuild \
  -project TriTranslator.xcodeproj \
  -scheme TriTranslator \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Configuration safety

Do not commit either of these local files:

- `TriTranslator/Secrets.xcconfig`
- `TriTranslator/GoogleService-Info.plist`

Keeping the DeepL key out of Git prevents source-control exposure, but it does not make the key secret inside a distributed iOS app. The compiled app contains the value. Before production distribution, DeepL requests should move behind an authenticated backend that stores the credential server-side and applies rate limiting.
