# Submission Guide

This guide is for turning the repository into a clean public GitHub project and a strong Kaggle submission package.

## 1. What should be public on GitHub

The public repository should include:

- `README.md`
- `LICENSE`
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `android/`
- `assets/`
- `docs/`
- `lib/`
- `test/`
- `tools/`
- `.gitignore`

That set is enough for judges to understand the product, run the code, inspect the architecture, and verify the reasoning behind the build.

## 2. What should never be committed

Do not push:

- model weights
- `build/`
- `.dart_tool/`
- `android/local.properties`
- Authentication tokens
- API secrets of any kind
- signing keys or keystores
- PEM files
- raw release ZIPs
- raw video exports unless you intentionally want them versioned

The repository `.gitignore` has been tightened to block the most common accidental leaks.

## 3. Public repo checklist before pushing

- README is complete and accurate
- no personal machine paths remain in docs
- no temporary debug files remain
- no tokens are hardcoded
- no generated APKs are committed
- docs match the current product behavior
- tests pass on the release candidate

## 4. Recommended GitHub presentation

For this project, the repo should feel like a real product repo, not a rough hackathon dump.

Recommended top-level experience:

1. Clear README headline and product description
2. Strong explanation of the user problem
3. Honest explanation of Gemma 4's role
4. Architecture notes in `docs/ARCHITECTURE.md`
5. Test coverage present in `test/`

Optional but useful if you want to polish further:

- app screenshots or demo GIFs in `docs/` or `assets/`

## 5. What to prepare for the Kaggle submission

Re-check the exact form fields on Kaggle before final submission. At minimum, prepare these items:

- public GitHub repository URL
- live demo URL
- video pitch URL
- written submission / writeup

Corroborated public summaries also indicate:

- the video should be treated as the primary storytelling asset
- the writeup should stay concise
- the repo must be public
- the demo must be real, not just slides

## 6. Recommended Kaggle handoff package

Even if Kaggle asks for links rather than file uploads, prepare a local submission folder with these assets:

```text
submission/
  writeup.md
  repo-url.txt
  demo-url.txt
  video-url.txt
  screenshots/
  apk/
    app-arm64-v8a-release.apk
```

Why only the `arm64-v8a` APK here:

- it is the most relevant build for modern Android phones
- it is the version most judges are likely to use if they install a build

## 7. Writeup structure that fits this project

Recommended writeup sections:

1. Problem
2. Who gets harmed
3. Why existing workflows fail
4. What Before You Sign does
5. Why Gemma 4 is essential here
6. Privacy and offline design
7. OCR and handwriting handling
8. Grounded verdict design
9. Limits and safety boundaries
10. Demo link

## 8. The one build to hand to judges

If you are sharing exactly one APK with a judge or mentor, use:

`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

## 9. Sources used for the competition summary

- [Kaggle competition page](https://www.kaggle.com/competitions/gemma-4-good-hackathon)
- [Kaggle official launch post](https://www.linkedin.com/posts/kaggle_now-available-on-kaggle-gemma-4-in-partnership-activity-7445505784228073472-QYnt)
- [Google DeepMind Gemma 4 overview](https://deepmind.google/models/gemma/gemma-4/)
- [Public competition summary with submission details](https://www.linkedin.com/posts/ibrahimqasmi313_google-deepmind-just-launched-another-200000-activity-7448606286893604864-YDOv)
