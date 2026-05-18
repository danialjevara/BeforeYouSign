# Benchmark Notes

This repository includes a first-pass automated benchmark for the safety and trust layer behind Before You Sign.

## What is covered now

- `test/rules_benchmark_test.dart`
  - 10 multilingual heuristic cases
  - Languages: English, Arabic, Spanish, Portuguese, French, Hindi, Chinese
  - Signals covered:
    - guarantor / surety language
    - debt and repayment terms
    - waiver / arbitration language
    - collateral / salary exposure
    - pressure-to-sign language
    - blank-space detection
    - benign control text

- `test/gemma_service_test.dart`
  - recommended action selection
  - trust-layer grading
  - grounded evidence extraction
  - locale-aware legal-context hints

## Why this matters

The product does not treat every model warning as equally trustworthy.

- Findings are grounded against the document text or spoken context when possible.
- Findings with weaker support are surfaced as inferred or needing review.
- The verdict screen exposes this trust breakdown directly to the user.

## Current automated benchmark set

| Case family | Example languages | What it verifies |
| --- | --- | --- |
| Guarantor + debt | EN, AR, HI | Personal-liability detection and evidence grounding |
| Waiver + arbitration | ES, FR | One-sided dispute language |
| Collateral + salary | PT, ZH | Asset-exposure detection |
| Pressure language | EN, PT, ZH | Social pressure and coercive framing |
| Blank spaces | ES | Unsafe incomplete forms |
| Benign control | EN | Low-risk baseline behavior |

## What still needs manual evaluation

For Kaggle submission quality, this automated suite should be paired with a manual review set:

1. 30 to 50 real document samples
2. at least 6 languages
3. printed text and handwriting separated
4. latency measured on the demo device
5. false positives and false negatives recorded honestly

## Recommended submission framing

Use this benchmark as the "automated regression layer" in the writeup, then add a separate table for live-device evaluation:

- OCR quality by capture mode
- Gemma verdict quality by language
- trust-layer grounding rate
- action-plan usefulness in high-risk cases

This keeps the submission honest, reproducible, and easy for judges to trust.

## Minimum live-device table for final submission

If time is tight, collect at least this smaller smoke set before submitting:

| Case | Language | Input type | Device | OCR result | Gemma latency | Verdict quality | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Employment guarantor clause | English | Printed photo |  |  |  |  |  |
| Rental blank spaces | Spanish | Printed photo |  |  |  |  |  |
| Debt / guarantor text | Arabic | Manual paste or reviewed OCR text |  |  |  |  |  |
| Salary collateral clause | Portuguese | Printed photo |  |  |  |  |  |
| Waiver / arbitration clause | French | Printed photo |  |  |  |  |  |
| Loan repayment clause | Hindi | Printed photo |  |  |  |  |  |
| Collateral / pressure clause | Chinese | Printed photo |  |  |  |  |  |

Use simple labels for verdict quality: `correct`, `partially correct`, or `missed`. Judges will trust an honest small table more than an unsupported broad claim.
