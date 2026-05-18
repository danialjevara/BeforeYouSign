# Before You Sign

Before You Sign is an Android-first Flutter app that helps people understand risky paperwork before they sign it. The core experience stays local to the device: capture a document, review the extracted text, add spoken or typed context, and get a plain-language risk verdict powered by on-device Gemma 4 analysis.

This project was built for the [Gemma 4 Good Hackathon](https://www.kaggle.com/competitions/gemma-4-good-hackathon) with a focus on `Safety & Trust` and `Digital Equity`.

## What It Does

Before You Sign is designed for moments when users are under pressure, far from legal help, or unsure whether a document is harmless or dangerous. The app helps the user slow down and make a safer choice.

The main flow is:

1. Capture a document with the camera or paste the text manually.
2. Review and correct the extracted text.
3. Add the real-world context by voice or typing.
4. Run a full on-device Gemma 4 analysis.
5. Receive a risk score, grounded evidence, plain-language explanations, practical questions to ask, and a safer next step.


## Why Gemma 4 Matters Here

This is not a generic chatbot wrapper.

Gemma 4 is the primary reasoning engine behind the product:

- It turns OCR text and user context into structured risk scenarios.
- It produces grounded evidence instead of vague warnings.
- It explains risk in plain language for non-expert users.
- It preserves privacy by keeping the main review flow on-device.

That local-first design is central to the product story: many risky signing moments happen in low-connectivity environments, under time pressure, and around highly sensitive personal documents.

## Core Capabilities

- On-device OCR using Google ML Kit
- Printed and handwriting-oriented capture modes
- Auto-crop around the detected document region when that improves OCR quality
- Typed or spoken user context
- Gemma-first document analysis on the device
- Grounded evidence snippets tied back to document text or user context
- Clause highlighting inside the verdict experience
- Practical "question to ask before signing" guidance
- "Safer next step" recommendation for immediate action
- Encrypted local assessment storage with device-unlock enforcement
- Nearby legal-help lookup and official country-aware legal resource links

## Product Principles

- `Privacy first`: sensitive documents do not need to leave the device.
- `Honest by default`: the limited scan is labeled as limited.
- `Grounded output`: verdicts should point back to evidence, not just generate fear.
- `Actionable UX`: the user should leave with a safer question or next move.
- `Global reach`: the UI supports multiple languages and region-aware hints.

## Supported Languages

The current UI supports:

- English
- Spanish
- Portuguese
- French
- Arabic
- Hindi
- Chinese

Unsupported locales fall back to English UI copy while preserving locale-aware OCR, speech, and analysis hints where possible.

## Repository Layout

```text
android/           Android runner and Gradle configuration
assets/branding/   App icon source assets
docs/              Architecture and submission guidance
lib/
  data/            Official legal-resource seeds
  localization/    Locale-aware copy
  models/          App data models
  screens/         Product flows and UI
  services/        OCR, Gemma, storage, voice, and legal-help services
test/              Widget, localization, OCR, and heuristic coverage
tools/branding/    Icon generation script
```

## Technical Overview

- Flutter + Dart
- Riverpod
- Google ML Kit OCR
- Flutter Gemma
- Speech-to-text and text-to-speech
- Hive + local encrypted storage
- OpenStreetMap / Overpass / Nominatim for legal-help lookup

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the system flow and component design.

## Getting Started

### Requirements

- Flutter 3.41 or later
- Android device or Android emulator
- A Gemma 4 LiteRT-LM model URL for the full on-device path

### Install

```bash
flutter pub get
```

### Run

```bash
flutter run --dart-define=GEMMA_MODEL_URL=https://...
```

## Verification

The release path used during validation:

```bash
flutter analyze lib test --no-fatal-infos
flutter test
flutter build apk --debug
flutter build apk --release --split-per-abi
```

## Submission Notes

If you are packaging this project for the hackathon, use [docs/SUBMISSION_GUIDE.md](docs/SUBMISSION_GUIDE.md). It includes:

- what should be public in the GitHub repository
- what must not be committed
- what to prepare for the Kaggle submission form
- the recommended final deliverables package

## Safety Notice

Before You Sign is a risk-awareness tool, not a substitute for licensed legal advice. It can be wrong, incomplete, or jurisdictionally imperfect. The product is designed to help users slow down, ask better questions, and seek qualified help sooner.