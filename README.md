

<h1 align="center">Natroff AIO</h1>

<p align="center">
  <b>All-in-One Desktop Companion for PALE League</b><br/>
  <sub>Player management, match simulation, mini-games, AI chatbot, system utilities — all in one app.</sub>
</p>

<img width="1280" height="770" alt="n3" src="https://github.com/user-attachments/assets/afa34504-391c-4d2b-9ab4-9b5b51e04eeb" />


<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white" alt="Windows"/>
  <img src="https://img.shields.io/badge/Version-6.0.0-brightgreen" alt="Version"/>
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License"/>
</p>

---

## Overview

**Natroff AIO** is a feature-rich Flutter desktop application built for the **PALE League** HaxBall community. It combines league management tools, an Ultimate Team card system, mini-games, AI-powered features, and system optimization utilities into a single polished desktop experience.

## Features

### League Management
| Module | Description |
|--------|-------------|
| **Players View** | Browse, search, and manage all registered league players with detailed stat profiles |
| **Standings** | Live league standings with points, wins, draws, losses, and goal difference |
| **Squad Builder** | Drag-and-drop formation builder with Team of the Week (TOTW) support |
| **Tier List** | Community-driven player tier ranking system |
| **Strategy Board** | Interactive tactical whiteboard for drawing formations and play strategies |
| **Match Engine** | Simulated match system with realistic outcome calculation |

### Ultimate Team
- FIFA-style card collecting and team-building experience adapted for HaxBall
- Animated player cards with premium, golden, and icon tiers
- Transfer market, pack opening, match simulation, and ranking system
- Token-based economy with match rewards

### Mini-Games Hub
| Game | Description |
|------|-------------|
| **NatBall 3D** | Perspective 3D football game with AI opponents, goal-net physics, and unlimited FPS |
| **Okey 101** | Classic Turkish tile-based card game |
| **UNO** | The classic color & number matching card game |
| **Batak** | Turkish trick-taking card game |
| **Papaz Kaçtı** | "Old Maid" — avoid holding the last unpaired card |
| **Speed Clicker** | Reflex-based clicking challenge |
| **Vampire & Villager** | Social deduction party game |

### AI & Smart Features
- **AI Chatbot** — Conversational assistant powered by Groq LLM with persistent memory
- **AI Photo Module** — AI-powered image generation and manipulation
- **Google Generative AI** integration for enhanced content features

### System Utilities
| Tool | Description |
|------|-------------|
| **DNS Optimizer** | Switch between popular DNS providers for faster browsing |
| **System Cleaner** | Remove temp files, cache, and system junk |
| **Power Manager** | Configure power plans for gaming or battery saving |
| **WiFi Scanner** | Scan & analyze nearby wireless networks |
| **Keyboard Tester** | Full keyboard input testing and diagnostics |
| **Optimization Suite** | One-click system performance tweaks |
| **Security Check** | Basic system security audit |

### Additional Features
- **Custom FPS Browser** — Built-in Chromium-based browser with fullscreen mode (F11)
- **Turkey Interactive Map** — Explore Turkey with Syncfusion maps and regional data
- **Charts & Analytics** — Visual data charts powered by FL Chart
- **Theme System** — Dark/Light mode with particle background effects
- **Multi-language Support** — Turkish & English with extensible locale system
- **Spatial UI Mode** — Alternative 3D-style sidebar navigation
- **Background Music** — Ambient music player with controls
- **Movable Windows** — Draggable floating panels within the app

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.x (Dart ≥3.0) |
| **State Management** | Provider + GetX |
| **Local Database** | Hive (NoSQL) + Drift (SQLite) |
| **AI** | Groq API, Google Generative AI |
| **UI** | Google Fonts, custom glassmorphism, animated cards |
| **Window Management** | window_manager, bitsdojo_window |
| **Web Content** | webview_windows (Chromium-based) |
| **Maps** | Syncfusion Flutter Maps |
| **Charts** | FL Chart |
| **Installer** | Inno Setup (Windows `.exe` installer) |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0.0
- Windows 10 or later (primary target)
- Visual Studio 2022 with C++ desktop workload (for Windows build)

### Installation

```bash
# Clone the repository
git clone https://github.com/ca1ik/PALE-League-App.git
cd PALE-League-App/aio2_tool

# Install dependencies
flutter pub get

# Generate code (Hive adapters, Drift database)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run -d windows
```

### Building for Release

```bash
flutter build windows --release
```

The release binary will be located at `build/windows/x64/runner/Release/`.

### Creating the Installer

1. Install [Inno Setup](https://jrsoftware.org/isinfo.php)
2. Open `installer.iss` in Inno Setup Compiler
3. Click **Build → Compile**
4. Output: `Output/NatroffAIO_Setup.exe`

---

## Project Structure

```
lib/
├── main.dart                 # App entry point, Hive init, window setup
├── splash_screen.dart        # Animated splash screen
├── data/                     # Data models
│   ├── card_types.dart       # Card type definitions (Spade, Heart, etc.)
│   ├── player_data.dart      # Player & Strategy models + Hive adapters
│   └── team_data.dart        # Team data structures
├── games/                    # Standalone mini-games
│   ├── batak_game.dart
│   ├── okey101_game.dart
│   ├── papazkacti_game.dart
│   ├── speed_clicker_game.dart
│   ├── uno_game.dart
│   └── vampire_villager.dart
├── modules/                  # Feature modules
│   ├── palehax_ultimate.dart # Ultimate Team card system
│   ├── palehax_games.dart    # Games hub launcher
│   ├── palehax_players_view.dart
│   ├── palehax_tierlist.dart
│   ├── palehax_match_engine.dart
│   ├── squad_builder_module.dart
│   ├── strategy_maker_module.dart
│   ├── challenge_hub.dart
│   ├── natball3d_game.dart   # 3D perspective football game
│   ├── charts_module.dart
│   ├── turkey_map_module.dart
│   ├── ai_photo_module.dart
│   ├── cleaning_module.dart
│   ├── optimization_module.dart
│   ├── wifi_module.dart
│   ├── keyboard_module.dart
│   ├── system_tools.dart
│   └── custom_browser_module.dart
├── providers/                # State management
│   ├── theme_provider.dart
│   ├── music_provider.dart
│   ├── language_provider.dart
│   └── ui_provider.dart
├── screens/                  # Standalone screens
├── services/                 # Backend services
│   ├── database_service.dart # Drift SQLite database
│   ├── haxball_service.dart  # HaxBall integration
│   └── scraper_service.dart  # Web scraping utilities
├── ui/                       # Shared UI components
│   ├── sidebar.dart          # Classic & Modern sidebar
│   ├── spatial_sidebar.dart  # 3D spatial sidebar
│   ├── background.dart       # Particle background
│   ├── chatbot.dart          # AI chatbot widget
│   ├── glass_box.dart        # Glassmorphism container
│   └── fc_animated_card.dart # Animated player card
└── widgets/                  # Reusable widgets
    ├── icon_card.dart        # Icon card with shimmer effects
    ├── golden_card.dart      # Golden premium card
    ├── create_card_dialog.dart
    └── premium_cards/        # Premium card variants
```

---

## Seed Database

The app ships with optional pre-built Hive databases in `assets/seed_db/`. On first launch, these are copied to the user's documents folder so new users start with sample data. To update the seed:

1. Populate data through the app
2. Copy `.hive` files from `%APPDATA%/../Documents/natroff_aio/` to `assets/seed_db/`
3. Rebuild the app

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `F11` | Toggle fullscreen / Unlimited FPS mode |
| `←` / `→` (title bar) | Navigate back / forward through module history |

---

## Contributing

This is a community-driven project for the PALE League. Contributions are welcome:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-module`)
3. Commit your changes (`git commit -m "Add new module"`)
4. Push to the branch (`git push origin feature/new-module`)
5. Open a Pull Request

---

## Author

**ca1ik** — [github.com/ca1ik](https://github.com/ca1ik)

---

## IN APP: 
<p align="center">
  <img src="https://github.com/user-attachments/assets/b4ae57c8-8881-48c5-b705-954e531b8db4" width="40%" />
  <img src="https://github.com/user-attachments/assets/75177b4b-513e-42da-bcc0-a0f23df5c28f" width="40%" />
  <img src="https://github.com/user-attachments/assets/d5c67775-6bb4-47bf-b985-edf0b6fc04f3" width="40%" />
  <img src="https://github.com/user-attachments/assets/38a4a223-97fa-4bde-8fb8-0e7f81858784" width="40%" />
  <img src="https://github.com/user-attachments/assets/76d79c6e-1e43-412f-96cd-37ce7864b142" width="40%" />
  <img src="https://github.com/user-attachments/assets/44887b77-f446-46ee-a60d-e523f8cf8aa2" width="40%" />
  <img src="https://github.com/user-attachments/assets/98f1fe4d-1da9-4c01-89d3-f50a8f026643" width="40%" />
</p>

<p align="center">
  Built with Flutter & passion for the PALE League community.
</p>
