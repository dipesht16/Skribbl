# 🎨 Skribbl.io Flutter Clone

A real-time multiplayer drawing and guessing game built with **Flutter** and **Firebase Realtime Database**.

---

## 🚀 Key Features

*   **Real-Time Multiplayer**: Seamless room creation and joining via a 6-character room code. Fully synced game phases (Lobby, Choosing Word, Drawing, Score Reveal, and Podium).
*   **Normalized Canvas**: Brush strokes are sent to Firebase as normalized percentages ($0.0 - 1.0$) and scaled locally, ensuring perfect rendering across all device screen sizes.
*   **Typo-Tolerant Chat**: Utilizes Levenshtein Distance to detect close guesses (within 2 characters). It privately notifies the guesser they are **"Close!"** without leaking the answer to others.
*   **Dynamic Scoring**: Correct guessers are scored based on elapsed time (up to 150 pts) with active streak multipliers. The drawer is scored proportionally to the number of successful guessers.
*   **Procedural Avatars**: Built-in visual editor using `CustomPainter` to procedurally render player avatars (18 colors, 10 eye types, 10 mouth shapes).
*   **Bot Simulation**: Simulates automated guesses and preset drawing coordinates for solo practice sessions.

---

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart SDK `^3.12.0`)
*   **Database**: Firebase Realtime Database
*   **Typography**: Google Fonts (Fredoka)

---

## ⚙️ Quick Start

### 1. Firebase Configuration
1. Enable **Realtime Database** in the [Firebase Console](https://console.firebase.google.com/).
2. Set the Realtime Database Rules to:
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```
3. Run `flutterfire configure` to generate `lib/firebase_options.dart`.

### 2. Run the Application
```bash
# Fetch dependencies
flutter pub get

# Run on connected device
flutter run
```

### 3. Run Tests
```bash
flutter test
```
