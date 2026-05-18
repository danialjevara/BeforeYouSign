import 'package:beforeyousign/services/document_focus_cropper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cropper = DocumentFocusCropper();

  test('returns a focused crop when text occupies the center of the page', () {
    final decision = cropper.decide(
      imageWidth: 1200,
      imageHeight: 1800,
      preferHandwriting: false,
      regions: const [
        DetectedTextRegion(left: 210, top: 320, right: 980, bottom: 410),
        DetectedTextRegion(left: 220, top: 470, right: 970, bottom: 560),
        DetectedTextRegion(left: 215, top: 620, right: 975, bottom: 710),
        DetectedTextRegion(left: 230, top: 770, right: 965, bottom: 860),
      ],
    );

    expect(decision, isNotNull);
    expect(decision!.width, lessThan(1200));
    expect(decision.height, lessThan(1800));
    expect(decision.areaReduction, greaterThan(0.1));
  });

  test('skips auto crop when text already fills nearly the entire image', () {
    final decision = cropper.decide(
      imageWidth: 1200,
      imageHeight: 1800,
      preferHandwriting: false,
      regions: const [
        DetectedTextRegion(left: 24, top: 20, right: 1170, bottom: 1765),
      ],
    );

    expect(decision, isNull);
  });

  test('skips auto crop when detected text is too small to trust', () {
    final decision = cropper.decide(
      imageWidth: 1200,
      imageHeight: 1800,
      preferHandwriting: true,
      regions: const [
        DetectedTextRegion(left: 560, top: 820, right: 640, bottom: 860),
      ],
    );

    expect(decision, isNull);
  });
}
