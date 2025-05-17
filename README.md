# SMGuitar: Interactive Music Sequencer App

## Project Overview

SMGuitar is an interactive Flutter application designed for musicians, educators, and learners to explore, compose, and play chord progressions and scales using a step sequencer interface. The app leverages the [flutter_Sequencer](https://github.com/RBeato/flutter_sequencer_plus) package for real-time audio synthesis and sequencing, enabling users to experiment with musical ideas in a highly responsive environment.

### Key Features
- **Step Sequencer:** Compose and play back chord progressions, bass lines, and drum patterns using a grid-based sequencer.
- **Multi-Track Support:** Separate tracks for drums, piano/keys, and bass, each with independent step sequencing and velocity control.
- **SoundFont Integration:** Uses a single high-quality SoundFont (`FluidR3_GM.sf2`) for all instrument sounds, ensuring consistent and realistic playback.
- **Chord and Scale Exploration:** Visualize and select chords and scales, with support for custom chord voicings and scale modes.
- **Real-Time Playback:** Immediate audio feedback with tempo, looping, and metronome controls.
- **State Management:** Built with Riverpod for robust, scalable state management.
- **Customizable Instruments:** Users can select different instrument sounds for each track (drums, keys, bass) via the app settings.

### Architecture & Backend Logic
- **Clean Architecture:** The codebase is organized into modules for UI, models, utilities, and sequencer logic, following best practices for maintainability and testability.
- **Sequencer Engine:**
  - The core sequencing logic is managed by the `SequencerManager` class (`lib/UI/player_page/logic/sequencer_manager.dart`).
  - It orchestrates the creation and management of `Sequence` and `Track` objects from flutter_Sequencer, handles playback, looping, tempo changes, and synchronizes UI state with audio events.
  - Each track (drums, piano, bass) is represented by a `StepSequencerState` object, which maps steps to MIDI note numbers and velocities.
  - The sequencer state can be initialized, cleared, or updated in response to user actions (e.g., changing chords, toggling play/stop, adjusting tempo).
- **Data Models:**
  - Chords, scales, and project state are encapsulated in dedicated model classes (`ChordModel`, `ScaleModel`, `ProjectState`, etc.), supporting complex musical logic and UI interactions.
  - Utility classes (e.g., `MusicUtils`, `SoundPlayerUtils`) provide functions for music theory operations, instrument selection, and note processing.
- **Audio Backend:**
  - All audio playback is routed through flutter_Sequencer, which loads the SoundFont and manages MIDI event scheduling for each track.
  - The app supports real-time changes to sequence parameters (tempo, loop points, track volumes) and provides immediate feedback.
- **UI Integration:**
  - The main player UI (`PlayerWidget`) initializes and interacts with the sequencer, updating the UI in sync with playback state and user input.
  - Riverpod providers are used to manage reactive state across the app, ensuring a responsive and robust user experience.

### Technology Stack
- **Flutter** (cross-platform UI)
- **Riverpod** (state management)
- **flutter_Sequencer** (audio engine, SoundFont/MIDI sequencing)
- **SoundFont**: FluidR3_GM.sf2 (not included in repo, see below)
- **Other:** Tonic (music theory), Google Fonts, device info, purchases_flutter, and more (see `pubspec.yaml`)

---

## Detailed Feature Breakdown

### 1. Step Sequencer & Playback Engine
- **Multi-Track Sequencing:**
  The app provides a grid-based step sequencer for three main tracks: drums, piano/keys, and bass. Each track is managed by a `StepSequencerState` object, which maps steps (beats) to MIDI note numbers and velocities.
- **Real-Time Playback:**
  Playback is handled by the `flutter_Sequencer` engine, which schedules MIDI events for each track and provides immediate audio feedback. The sequencer supports:
  - Play/Stop controls (with debounced UI to prevent accidental double triggers)
  - Looping (set/unset loop points)
  - Dynamic tempo changes (via a BPM selector dialog)
  - Track volume control (per-track, real-time)
  - Metronome toggle and visual indicator
- **Chord Progression Editing:**
  Users can build chord progressions by tapping/double-tapping on chord buttons. Each chord is represented by a `ChordModel` and can have a custom duration (single tap = short, double tap = long). The progression is visualized as a colored bar, with each chord's color reflecting its harmonic function.

### 2. Chord and Scale Exploration
- **Scale & Mode Selection:**
  Users can select musical scales and modes using dropdowns. The available modes are dynamically updated based on the selected scale. This selection drives the available chords and notes throughout the app.
- **Chord Selection:**
  Chords are displayed as colored buttons, each corresponding to a degree of the selected scale/mode. Tapping a chord adds it to the progression; double-tapping adds a longer-duration chord. Chord color and label reflect its harmonic function and degree.
- **Chord Info:**
  An info button provides additional details about the selected chords, including their notes and function.

### 3. Instrument Customization
- **SoundFont-Based Instruments:**
  All instrument sounds are generated using a single SoundFont file (`FluidR3_GM.sf2`). Users can select the type of sound for each track (e.g., Piano, Rhodes, Organ, Pad for keys; Double Bass, Electric, Synth for bass; Acoustic/Electronic for drums) via dropdowns in the app drawer.
- **Instrument Selection UI:**
  The drawer provides dropdowns for each instrument type, allowing users to customize the timbre of their sequencer tracks.

### 4. Fretboard Visualization
- **Interactive Fretboard:**
  The app includes a custom fretboard painter that visualizes scale notes, chord tones, and finger positions. Roman numerals indicate fret positions, and colored dots show scale/chord notes. The fretboard adapts to the selected scale and highlights relevant notes.
- **Scale Degree Display:**
  Optionally, the fretboard can display scale degrees instead of note names, aiding in music theory education.

### 5. Piano Keyboard Visualization
- **Custom Piano Widget:**
  A horizontally scrollable, multi-octave piano keyboard is provided. Keys are colored to indicate their presence in the current scale, and the tonic/root is highlighted. Users can tap keys to trigger notes, which are played using the selected SoundFont instrument.

### 6. Chromatic Wheel & Scale Chart
- **Chromatic Wheel:**
  An interactive, rotatable chromatic wheel allows users to visualize and select the tonic/root note. The wheel displays all 12 chromatic notes, and users can rotate it to set the top note, which updates the scale and chord options throughout the app.
- **Scale Chart:**
  The scale chart provides a visual overview of the selected scale, showing all notes and their relationships.

### 7. Metronome
- **Visual & Audio Metronome:**
  The metronome can be toggled on/off. When active, it provides both a visual indicator (highlighting the current beat) and an audio click, synchronized with the sequencer's tempo.
- **BPM Selector:**
  Users can tap the tempo display to open a dialog and select a new BPM, which updates the sequencer in real time.

### 8. State Management & Persistence
- **Riverpod State Management:**
  All app state (selected chords, scale, mode, instrument settings, playback state, etc.) is managed using Riverpod providers, ensuring robust and reactive UI updates.
- **Settings Persistence:**
  User preferences (instrument sounds, scale/mode, etc.) are persisted and can be reset via the drawer.

### 9. Premium Features & Paywall
- **Entitlement Checks:**
  Some features (e.g., certain instrument sounds, advanced options) are gated behind a premium entitlement, managed via RevenueCat. The drawer includes an upgrade button and a paywall page for purchasing premium access.

### 10. User Experience & UI
- **Responsive, Modern UI:**
  The app uses a dark theme, rounded corners, and modern UI patterns. All controls are touch-friendly and optimized for both phones and tablets.
- **Error Handling & Feedback:**
  The app provides clear feedback for invalid actions (e.g., too many beats, locked premium features) via dialogs and snackbars.
- **Loading Indicators:**
  Circular progress indicators are shown during loading states (e.g., when initializing the sequencer or loading settings).

---

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## SoundFont Usage

This project uses a single SoundFont file, `FluidR3_GM.sf2`, for all instrument sounds (drums, keys, bass, etc.).

- All code references to `.sf2` files now use `assets/sounds/sf2/FluidR3_GM.sf2`.
- The file is **not included in the main repository** because it is larger than 100MB.
- `FluidR3_GM.sf2` is tracked with [Git LFS](https://git-lfs.github.com/). If you clone the repo, make sure you have Git LFS installed:

```sh
git lfs install
git lfs pull
```

If you do not see the file after cloning, download it manually and place it in `assets/sounds/sf2/`.

**Note:** If you add other large audio files, use Git LFS or exclude them from the main repo.
