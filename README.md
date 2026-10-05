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
4. Create a Cloud Firestore database.
5. Deploy the tracked rules to your Firebase project:

   ```sh
   npx --yes firebase-tools deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
   ```

6. Download `GoogleService-Info.plist`.
7. Place it at `TriTranslator/GoogleService-Info.plist`.

The Xcode project already includes that path in the app's resources. The downloaded file is ignored by Git so clones and forks do not automatically connect to the original Firebase project.

Translations are stored under `users/{firebaseUID}/translations`. Each new, distinct translation creates one document containing `sourceText`, `sourceLanguage` (detected by DeepL), `createdAt` (device time), and an ordered `translations` array of `{targetLanguage, text}` results. Both target translations must succeed before saving.

New records use a versioned SHA-256 document ID derived from the source language/text and both target-language/text pairs. Duplicate detection ignores target order, surrounding whitespace, and equivalent Unicode encodings; it preserves case, accents, punctuation, numbers, internal whitespace, and changes to either translated result. A Firestore transaction creates the record only when that ID is absent. Repeated translations show “Already in history” and leave the existing record and timestamp unchanged. This check applies only to records saved with the new IDs; older records are not migrated or deduplicated. Near-duplicate similarity prompts are not implemented.

Saving history requires connectivity because Firestore transactions do not run offline. If saving fails, the translated results remain visible with a history-save error. Duplicate detection happens after DeepL returns, so repeated requests still call DeepL.

History displays the original text once with both translations beneath it, newest requests first. The app retrieves that user's history when the History page opens; it does not keep a real-time Firestore listener active.

This format replaces the previous individual-result records; existing records must be cleared or migrated before use.

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

## License

Licensed under the [MIT License](LICENSE). Copyright (c) 2026 Carlos Reyes.

Third-party dependencies remain subject to their own licenses.
