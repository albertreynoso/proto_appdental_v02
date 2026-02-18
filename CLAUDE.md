# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DentLink — a dental practice management app built with Flutter and Firebase. Manages patients, treatments, appointments, employees, and payments for dental clinics. The app is in Spanish.

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run in debug mode
flutter run -d <device>  # Run on specific device
flutter build apk        # Build Android APK
flutter analyze          # Run static analysis
flutter test             # Run tests (none exist yet)
```

## Architecture

**State management:** StatefulWidget + setState (no Provider/BLoC/GetX).

**Navigation:** Direct MaterialPageRoute pushes, no named routes. Main shell (`AppPrincipal` in `lib/main_app.dart`) uses a bottom navigation bar with three tabs: Home, Patients, Calendar.

**Data layer:** Views query Firestore directly — no repository or service abstraction layer. Firebase Auth handles authentication.

**Feature-based folder structure under `lib/`:**
- `core/` — Auth service (Firebase Auth wrapper) and PIN service (secure storage + SHA256 hashing)
- `models/` — `CitaModel` (appointments) and `TratamientoModel` (treatments)
- `views/auth/` — Full auth flow: splash → login/signup → email verification → PIN setup
- `views/pacientes/` — Patient list, detail (tabbed: history, treatments, payments), edit
- `views/tratamientos/` — Treatment CRUD with budget line items and payment tracking
- `views/citas/` — Appointment creation with patient/treatment linking
- `views/calendario/` — Calendar-based appointment view
- `views/empleados/` — Employee profiles and attendance tracking
- `views/perfil/` — User profile, notification preferences, about
- `views/home/` — Dashboard
- `widgets/` — Reusable components (PIN keyboard)

## Firestore Collections

- `usuarios` — user profiles (estado: 'pending'|'active')
- `pacientes` — patient records with treatment references
- `citas` — appointments with status history, costs, patient/treatment links
- `tratamientos` — treatments with diagnosis, budget items, payment tracking

## Key Dependencies

- `firebase_core`, `firebase_auth`, `cloud_firestore` — Firebase stack
- `flutter_secure_storage` + `crypto` — PIN security
- `google_fonts` — Typography
- `intl` — Date formatting (Spanish locale)
- `cached_network_image` — Image caching
- `another_flushbar`, `fluttertoast` — Notifications/toasts

## Conventions

- All UI text, variable names, and Firestore field names are in **Spanish**
- Material Design 3 with white seed color
- Dart SDK ≥3.9.2
- App entry: `lib/main.dart` initializes Firebase, then launches `LogoInicio` splash screen
