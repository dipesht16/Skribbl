# Skribbl.io Flutter Clone - Project Context

This document provides a comprehensive overview of the `skribbl_io` project, its architecture, feature sets, technical stack, and data flow. It is designed to give AI models and developers immediate context on how the application functions and how to extend it.

---

## 1. Project Overview

`skribbl_io` is a multiplayer drawing and guessing game built with Flutter and Firebase. It mimics the popular web-based game *skribbl.io*. 

### Core Game Loop
1. **Lobby Phase**: Players gather in a lobby. The host configures game settings (number of rounds, draw time, and custom word pools) and starts the game.
2. **Choosing Phase**: A designated "Drawer" is chosen. They are presented with 3 word choices and have 15 seconds to select one.
3. **Drawing Phase**: The Drawer paints on a canvas while all other players guess the word in the chat box in real time.
4. **Round End Phase**: The secret word is revealed, scores are calculated and awarded (based on guess speed and drawer performance), and a recap screen is shown.
5. **Game End Phase**: After all rounds complete, a podium displays the 1st, 2nd, and 3rd place players.

---

## 2. Technology Stack & Dependencies

The project is built using the following core technologies and libraries (defined in `pubspec.yaml`):

*   **Framework**: Flutter (Dart SDK version `^3.12.0`).
*   **Database & Networking**:
    *   `firebase_core` & `firebase_database`: Connects the app to Firebase Realtime Database for all live multiplayer synchronizations.
    *   `web_socket_channel`: Available for network sockets (though current multiplayer synchronization uses Firebase Realtime Database).
*   **UI & Styling**:
    *   `google_fonts`: Uses the **Fredoka** font family for a cartoon-like aesthetic.
    *   `cupertino_icons`: Standard iOS-style icons.
*   **Asset Management**:
    *   `flutter_launcher_icons`: Used for generating adaptive launcher icons.

---

## 3. Directory Structure

```
lib/
├── main.dart                  # App initialization (Firebase setup, theme, landing screen entry)
├── models/                    # Data transfer objects and structures
│   ├── avatar.dart            # Avatar structure (color, eyes, and mouth indices)
│   ├── chat_message.dart      # Chat message structure (types: chat, correct, close, system)
│   ├── draw_point.dart        # Canvas stroke coordinates and meta-information
│   ├── game_room.dart         # Game room settings and game state representation
│   └── player.dart            # Player stats (isBot, hasGuessed, score, isHost)
├── screens/                   # High-level screens
│   ├── game_screen.dart       # Main drawing board, chat, scores, and status layout
│   ├── landing_screen.dart    # Setup profile (name, avatar, language) and join/create room
│   └── lobby_screen.dart      # Game parameter customization and player ready status
├── services/                  # Business logic and network connections
│   ├── bot_manager.dart       # Simulates bot guessing and bot canvas drawing presets
│   ├── firebase_game_service.dart  # Direct Firebase Realtime DB helper actions
│   ├── game_state_controller.dart  # App-wide ChangeNotifier controlling state changes
│   ├── room_code_helper.dart  # Room code generation utility
│   └── word_list.dart         # Word dictionary, hint formatter, and typo detection
└── widgets/                   # Modular reusable components
    ├── avatar_customizer.dart # UI to change eyes/mouth/color indices of avatars
    ├── avatar_renderer.dart   # Procedural avatar drawings (CustomPainter)
    ├── chat_panel.dart        # Chat list display
    ├── drawing_canvas.dart    # Paint canvas and color palette controls
    ├── floating_chat.dart     # Responsive mobile chat drawer
    ├── player_list.dart       # Horizontal/Vertical listing of players and current scores
    └── skribbl_logo.dart      # Custom retro font rendering of the skribbl.io logo
```

---

## 4. Architectural Patterns & State Management

The project uses a clean **Controller-Service-Model** pattern.

### State Controller (`GameStateController`)
*   Inherits from `ChangeNotifier`. It acts as the single source of truth for the active client.
*   Consumed via `ListenableBuilder` inside screen widgets (`GameScreen`, `LobbyScreen`) to rebuild UI components when state shifts.
*   Handles game loop phase transitions locally (if Host) and pushes updates to Firebase.
*   Listens to database node events (if Joiner) and populates local variables (`_room`, `_players`, `_chatMessages`, `_drawingPoints`).

### Firebase Synchronization Protocol
The multiplayer interaction uses a **Host/Client** architecture synced through Firebase Realtime Database:
*   **Host Duties**:
    *   Spawns a unique 6-character room code (e.g., `FG89JK`).
    *   Saves the initial room structure under `rooms/{ROOM_CODE}`.
    *   Subscribes to `/guesses` node. When a client pushes a guess, the Host pops it, runs logic (correct/close/incorrect), updates the score, logs system chat messages, and updates the core room object.
    *   Runs the local `Timer` that decrements remaining seconds and pushes the timestamp updates to Firebase.
*   **Joiner (Client) Duties**:
    *   Subscribes directly to `rooms/{ROOM_CODE}` and updates their local layout when the database fields change.
    *   Subscribes to `/drawingPoints` to paint drawing paths created by the Drawer.
    *   Pushes guesses to the Host's guess processor via `rooms/{ROOM_CODE}/guesses`.
*   **Normalized Canvas Mapping**:
    *   Since players use various device screens (mobile, tablets, desktops), drawing points are normalized before sync.
    *   `DrawPoint` converts mouse/touch offsets into percentages relative to the canvas dimensions ($x, y \in [0.0, 1.0]$).
    *   Receiving clients scale these values back up to match their respective canvas width and height.

---

## 5. Feature Deep Dive

### 1. Custom Avatar Generator
*   **Structure (`Avatar`)**: Consists of three integers: `bodyColorIndex` (mapped to 18 custom colors), `eyesIndex` (10 styles), and `mouthIndex` (10 styles).
*   **Renderer (`AvatarRenderer` / `_AvatarPainter`)**: Uses a `CustomPainter` to draw vectors on a Canvas:
    *   **Body**: A capsule/egg-shaped round rect.
    *   **Eyes**: Procedural shapes for: *Normal*, *Sleepy* (tired lids), *Angry* (slanted brows), *Wide/Stunned* (small pupils), *Crossed* (dead/dizzy crosses), *Glasses* (bridge frame overlay), *Happy* (^ ^ arches), *Wink*, *Sparkle* (white reflection highlights), and *Sunglasses*.
    *   **Mouth**: Vector lines and curves for: *Smile*, *Wide Open* (with tongue path), *Flat*, *Sad*, *Tongue Out* (hanging rect), *Teeth Grill* (vertical lines), *Shocked O*, *Smirk*, *Mustache* (dual curved wings), and *Screaming Triangle*.

### 2. Canvas & Color Palette
*   **whiteboard canvas**: Enabled only for the active Drawer during the `GameStatus.drawing` phase.
*   **Controls**: Includes 22 colors (the official Skribbl.io color palette), 4 brush stroke sizes (`S` = 4.0, `M` = 8.0, `L` = 16.0, `XL` = 24.0), a canvas clearing tool, and an eraser mode.
*   **Paths**: Lines are drawn smoothly by connecting successive points. If `isStart` is true, a circle is drawn (representing a single tap).

### 3. Guessing & Typing Assistance
*   **Levenshtein Distance Check**: Used to identify close guesses. If a guess has an edit distance of exactly `1` compared to the secret word, the game sends a private system chat indicating the guesser "is close!", preventing them from giving away the answer while giving helpful feedback.
*   **Score Calculations**:
    *   **Guessers**: Points are awarded depending on how quickly they guess the word. The first correct guess gets `300` pts, second gets `250` pts, third gets `200` pts, and subsequent guessers get `150` pts (plus a baseline of `100` pts).
    *   **Drawer**: Points are awarded proportionally to the percentage of active players who successfully guess the word (maximum of `200` pts).

### 4. Interactive Word Hints
*   At the start of a drawing turn, a hint is displayed as blank characters (e.g., `_ _ _ _ _`).
*   During the drawing phase, letters are automatically revealed to help guessers:
    *   At **2/3** of the remaining draw time, a random letter is revealed.
    *   At **1/3** of the remaining draw time, another random letter is revealed (revealing up to 60% of the word's letters).

### 5. Bot Simulation System (`bot_manager.dart`)
*   *Note: Bot interaction has been disabled/commented out within `GameStateController` per user request. However, the files and logic remain in the codebase.*
*   **Guess Generation**: Generates guesses periodically based on remaining time and letters revealed. Has a 35% chance to output the correct word, a 20% chance to generate a close word (typo or letter-swap), and a 45% chance to output a random word from the dictionary.
*   **Drawing Presets**: Simulates realistic vector coordinates for specific words (like `house`, `sun`, `car`, `tree`, `smiley`, `cloud`, `star`, `umbrella`, and `balloon`). For other words, it generates a procedural spiral doodle.

---

## 6. Development & Execution Instructions

### Running the App Locally
Ensure a Flutter-compatible environment is installed. Run the app in debug mode:
```bash
flutter pub get
flutter run
```

### Firebase Setup Requirement
To host network rooms, the app must be linked to a Firebase project:
1. Initialize Firebase CLI in the workspace: `flutterfire configure`.
2. Ensure the Realtime Database is enabled.
3. Configure the database rules to allow public read/write or user-authenticated updates:
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```
