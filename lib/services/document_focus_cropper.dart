import 'dart:math' as math;

import 'package:image/image.dart' as img;

class DetectedTextRegion {
  const DetectedTextRegion({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => math.max(0.0, right - left);
  double get height => math.max(0.0, bottom - top);
  double get area => width * height;
}

class DocumentFocusCropDecision {
  const DocumentFocusCropDecision({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.coverage,
    required this.areaReduction,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final double coverage;
  final double areaReduction;
}

class DocumentFocusCropper {
  const DocumentFocusCropper();

  DocumentFocusCropDecision? decide({
    required int imageWidth,
    required int imageHeight,
    required List<DetectedTextRegion> regions,
    required bool preferHandwriting,
  }) {
    if (imageWidth < 2 || imageHeight < 2) {
      return null;
    }

    final minRegionArea = imageWidth * imageHeight * 0.00035;
    final minRegionWidth = imageWidth * 0.025;
    final minRegionHeight = imageHeight * 0.009;
    final filtered = regions.where((region) {
      return region.area >= minRegionArea &&
          region.width >= minRegionWidth &&
          region.height >= minRegionHeight;
    }).toList();

    if (filtered.isEmpty) {
      return null;
    }

    var left = filtered.first.left;
    var top = filtered.first.top;
    var right = filtered.first.right;
    var bottom = filtered.first.bottom;

    for (final region in filtered.skip(1)) {
      left = math.min(left, region.left);
      top = math.min(top, region.top);
      right = math.max(right, region.right);
      bottom = math.max(bottom, region.bottom);
    }

    final unionWidth = math.max(1.0, right - left);
    final unionHeight = math.max(1.0, bottom - top);
    final coverage = (unionWidth * unionHeight) / (imageWidth * imageHeight);

    final minCoverage = preferHandwriting ? 0.02 : 0.035;
    if (coverage < minCoverage || coverage > 0.9) {
      return null;
    }

    final padX = math.max(
      imageWidth * 0.045,
      unionWidth * (preferHandwriting ? 0.22 : 0.14),
    );
    final padTop = math.max(
      imageHeight * 0.035,
      unionHeight * (preferHandwriting ? 0.18 : 0.12),
    );
    final padBottom = math.max(
      imageHeight * 0.04,
      unionHeight * (preferHandwriting ? 0.22 : 0.16),
    );

    var cropLeft = (left - padX).floor();
    var cropTop = (top - padTop).floor();
    var cropRight = (right + padX).ceil();
    var cropBottom = (bottom + padBottom).ceil();

    final minCropWidth =
        (imageWidth * (preferHandwriting ? 0.42 : 0.52)).round();
    final minCropHeight =
        (imageHeight * (preferHandwriting ? 0.24 : 0.34)).round();

    if ((cropRight - cropLeft) < minCropWidth) {
      final extra = ((minCropWidth - (cropRight - cropLeft)) / 2).ceil();
      cropLeft -= extra;
      cropRight += extra;
    }
    if ((cropBottom - cropTop) < minCropHeight) {
      final extra = ((minCropHeight - (cropBottom - cropTop)) / 2).ceil();
      cropTop -= extra;
      cropBottom += extra;
    }

    cropLeft = cropLeft.clamp(0, imageWidth - 1).toInt();
    cropTop = cropTop.clamp(0, imageHeight - 1).toInt();
    cropRight = cropRight.clamp(cropLeft + 1, imageWidth).toInt();
    cropBottom = cropBottom.clamp(cropTop + 1, imageHeight).toInt();

    final cropWidth = cropRight - cropLeft;
    final cropHeight = cropBottom - cropTop;
    final cropArea = cropWidth * cropHeight;
    final areaReduction = 1 - (cropArea / (imageWidth * imageHeight));

    if (cropWidth >= imageWidth - 8 ||
        cropHeight >= imageHeight - 8 ||
        areaReduction < 0.1) {
      return null;
    }

    return DocumentFocusCropDecision(
      x: cropLeft,
      y: cropTop,
      width: cropWidth,
      height: cropHeight,
      coverage: coverage,
      areaReduction: areaReduction,
    );
  }

  img.Image apply(img.Image source, DocumentFocusCropDecision decision) {
    return img.copyCrop(
      source,
      x: decision.x,
      y: decision.y,
      width: decision.width,
      height: decision.height,
    );
  }
}
