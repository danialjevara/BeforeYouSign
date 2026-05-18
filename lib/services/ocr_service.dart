import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import 'document_focus_cropper.dart';

class OcrException implements Exception {
  OcrException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OcrService {
  static const int _maxFastOcrDimension = 1800;

  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};
  final DocumentFocusCropper _documentFocusCropper =
      const DocumentFocusCropper();

  Future<OcrResult> processImage(
    String imagePath, {
    String localeTag = 'en',
    bool preferHandwriting = false,
    bool allowEnhancedPass = false,
  }) async {
    Directory? tempDir;

    try {
      final baseAnalysis = await _analyzeSourceImage(imagePath);
      final scripts = _scriptsForLocale(localeTag);
      final recognitionPath = baseAnalysis?.imagePath ?? imagePath;
      final attempts = <_OcrAttempt>[
        ...await _recognizeAcrossScripts(
          recognitionPath,
          source: OcrSource.original,
          sourceImage: baseAnalysis?.normalizedImage,
          scripts: scripts,
          preferHandwriting: preferHandwriting,
        ),
      ];
      final bestOriginal = _bestAttempt(
        attempts,
        preferHandwriting: preferHandwriting,
      );

      if (bestOriginal.cleanedText.trim().isEmpty || bestOriginal.charCount < 20) {
        try {
          return await _processImageWithTesseract(recognitionPath);
        } catch (_) {
          // Fallthrough to standard pipeline if Tesseract fails
        }
      }

      if (baseAnalysis != null) {
        final documentFocusInput = await _buildDocumentFocusInput(
          imagePath: imagePath,
          baseAnalysis: baseAnalysis,
          attempt: bestOriginal,
          preferHandwriting: preferHandwriting,
        );

        if (documentFocusInput != null) {
          attempts.addAll(
            await _recognizeAcrossScripts(
              documentFocusInput.path,
              source: documentFocusInput.source,
              sourceImage: documentFocusInput.previewImage,
              scripts: scripts,
              preferHandwriting: preferHandwriting,
            ),
          );
        }
      }

      if (allowEnhancedPass &&
          (bestOriginal.quality != OcrQuality.good || preferHandwriting) &&
          baseAnalysis != null) {
        tempDir = await Directory.systemTemp.createTemp('beforeyousign_ocr_');
        final enhancedInputs = await _buildEnhancedInputs(
          imagePath: baseAnalysis.imagePath,
          baseAnalysis: baseAnalysis,
          tempDir: tempDir,
        );

        for (final input in enhancedInputs) {
          attempts.addAll(
            await _recognizeAcrossScripts(
              input.path,
              source: input.source,
              sourceImage: input.previewImage,
              scripts: scripts,
              preferHandwriting: preferHandwriting,
            ),
          );
        }
      }

      attempts.sort(
        (left, right) => _compareAttempts(
          left,
          right,
          preferHandwriting: preferHandwriting,
        ),
      );
      final best = attempts.first;

      if (best.cleanedText.trim().isEmpty) {
        throw OcrException(
          'No readable text was detected in the captured document.',
        );
      }

      return OcrResult(
        fullText: best.cleanedText,
        blocks: _mapBlocks(best.recognizedText),
        quality: best.quality,
        qualityScore: best.score,
        charCount: best.charCount,
        lineCount: best.lineCount,
        wordCount: best.wordCount,
        notices: _buildNotices(
          best: best,
          baseAnalysis: baseAnalysis,
        ),
        previewImagePath: best.source == OcrSource.documentFocusCrop
            ? best.imagePath
            : imagePath,
        didAutoCrop: best.source == OcrSource.documentFocusCrop,
        usedEnhancedPass: best.usedEnhancedPass,
      );
    } on OcrException {
      rethrow;
    } catch (_) {
      throw OcrException(
        'Document text extraction failed. Capture a clearer image or paste the text manually.',
      );
    } finally {
      if (tempDir != null && await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  Future<List<_OcrAttempt>> _recognizeAcrossScripts(
    String imagePath, {
    required OcrSource source,
    required img.Image? sourceImage,
    required List<TextRecognitionScript> scripts,
    required bool preferHandwriting,
  }) async {
    final attempts = <_OcrAttempt>[];

    for (final script in scripts) {
      attempts.add(
        await _recognizeAttempt(
          imagePath,
          source: source,
          sourceImage: sourceImage,
          script: script,
          preferHandwriting: preferHandwriting,
        ),
      );
    }
    return attempts;
  }

  Future<_SourceImageAnalysis?> _analyzeSourceImage(String imagePath) async {
    return Isolate.run(() => _prepareFastSourceImage(imagePath));
  }

  static _SourceImageAnalysis? _prepareFastSourceImage(String imagePath) {
    final bytes = File(imagePath).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }

    final normalized = img.bakeOrientation(decoded);
    final prepared = _resizeForFastOcr(normalized);
    final preparedPath = _fastOcrImagePath(imagePath);
    File(preparedPath).writeAsBytesSync(img.encodeJpg(prepared, quality: 90));

    return _SourceImageAnalysis(
      imagePath: preparedPath,
      normalizedImage: prepared,
      brightness: _averageLuminance(prepared),
      contrast: _contrastEstimate(prepared),
    );
  }

  static img.Image _resizeForFastOcr(img.Image source) {
    final largestSide = math.max(source.width, source.height);
    if (largestSide <= _maxFastOcrDimension) {
      return source;
    }

    final scale = _maxFastOcrDimension / largestSide;
    return img.copyResize(
      source,
      width: math.max(1, (source.width * scale).round()),
      height: math.max(1, (source.height * scale).round()),
      interpolation: img.Interpolation.linear,
    );
  }

  static String _fastOcrImagePath(String imagePath) {
    final file = File(imagePath);
    final directory = file.parent.path;
    final name =
        file.uri.pathSegments.isEmpty ? 'capture' : file.uri.pathSegments.last;
    final dotIndex = name.lastIndexOf('.');
    final stem = dotIndex > 0 ? name.substring(0, dotIndex) : name;
    return '$directory${Platform.pathSeparator}${stem}_ocr.jpg';
  }

  Future<_PreparedInput?> _buildDocumentFocusInput({
    required String imagePath,
    required _SourceImageAnalysis baseAnalysis,
    required _OcrAttempt attempt,
    required bool preferHandwriting,
  }) async {
    final decision = _documentFocusCropper.decide(
      imageWidth: baseAnalysis.normalizedImage.width,
      imageHeight: baseAnalysis.normalizedImage.height,
      regions: attempt.textRegions,
      preferHandwriting: preferHandwriting,
    );
    if (decision == null) {
      return null;
    }

    final cropped = _documentFocusCropper.apply(
      baseAnalysis.normalizedImage,
      decision,
    );
    final croppedPath = _documentFocusImagePath(imagePath);
    await File(croppedPath).writeAsBytes(img.encodeJpg(cropped, quality: 96));

    return _PreparedInput(
      path: croppedPath,
      source: OcrSource.documentFocusCrop,
      previewImage: cropped,
    );
  }

  Future<List<_PreparedInput>> _buildEnhancedInputs({
    required String imagePath,
    required _SourceImageAnalysis baseAnalysis,
    required Directory tempDir,
  }) async {
    final normalized = baseAnalysis.normalizedImage;
    final enhancedColor = img.adjustColor(
      img.copyResize(
        normalized,
        width: _resizeWidth(normalized.width),
        interpolation: img.Interpolation.linear,
      ),
      contrast: _contrastBoost(baseAnalysis),
      brightness: _brightnessBoost(baseAnalysis),
      gamma: _gammaBoost(baseAnalysis),
      exposure: _exposureBoost(baseAnalysis),
    );
    final monochrome = img.histogramStretch(
      img.grayscale(
        img.adjustColor(
          img.copyResize(
            normalized,
            width: _resizeWidth(normalized.width),
            interpolation: img.Interpolation.linear,
          ),
          contrast: 1.4,
          brightness: _brightnessBoost(baseAnalysis),
          gamma: 0.94,
        ),
      ),
      stretchClipRatio: 0.01,
    );
    final handwritingFocus = _buildHandwritingFocusedImage(normalized);
    final handwritingBinary = _buildHandwritingBinaryImage(handwritingFocus);

    final enhancedPath =
        '${tempDir.path}${Platform.pathSeparator}enhanced_color.jpg';
    final monochromePath =
        '${tempDir.path}${Platform.pathSeparator}enhanced_mono.jpg';
    final handwritingPath =
        '${tempDir.path}${Platform.pathSeparator}handwriting_focus.jpg';
    final handwritingBinaryPath =
        '${tempDir.path}${Platform.pathSeparator}handwriting_binary.jpg';

    await File(enhancedPath)
        .writeAsBytes(img.encodeJpg(enhancedColor, quality: 95));
    await File(monochromePath)
        .writeAsBytes(img.encodeJpg(monochrome, quality: 95));
    await File(handwritingPath)
        .writeAsBytes(img.encodeJpg(handwritingFocus, quality: 96));
    await File(handwritingBinaryPath)
        .writeAsBytes(img.encodeJpg(handwritingBinary, quality: 96));

    return [
      _PreparedInput(
        path: enhancedPath,
        source: OcrSource.enhancedColor,
        previewImage: enhancedColor,
      ),
      _PreparedInput(
        path: monochromePath,
        source: OcrSource.highContrastMono,
        previewImage: monochrome,
      ),
      _PreparedInput(
        path: handwritingPath,
        source: OcrSource.handwritingFocus,
        previewImage: handwritingFocus,
      ),
      _PreparedInput(
        path: handwritingBinaryPath,
        source: OcrSource.handwritingBinary,
        previewImage: handwritingBinary,
      ),
    ];
  }

  String _documentFocusImagePath(String imagePath) {
    final file = File(imagePath);
    final directory = file.parent.path;
    final name =
        file.uri.pathSegments.isEmpty ? 'capture' : file.uri.pathSegments.last;
    final dotIndex = name.lastIndexOf('.');
    final stem = dotIndex > 0 ? name.substring(0, dotIndex) : name;
    return '$directory${Platform.pathSeparator}${stem}_autocrop.jpg';
  }

  Future<_OcrAttempt> _recognizeAttempt(
    String imagePath, {
    required OcrSource source,
    required img.Image? sourceImage,
    required TextRecognitionScript script,
    required bool preferHandwriting,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText =
        await _recognizerFor(script).processImage(inputImage);
    return _processRecognizedText(
      imagePath: imagePath,
      source: source,
      sourceImage: sourceImage,
      script: script,
      preferHandwriting: preferHandwriting,
      recognizedText: recognizedText,
    );
  }

  _OcrAttempt _processRecognizedText({
    required String imagePath,
    required OcrSource source,
    required img.Image? sourceImage,
    required TextRecognitionScript script,
    required bool preferHandwriting,
    required RecognizedText recognizedText,
  }) {
    final cleanedText = _normalizeRecognizedText(recognizedText.text);
    final textRegions = _extractTextRegions(recognizedText);
    final lineCount = _countLines(recognizedText);
    final wordCount = _countWords(cleanedText);
    final charCount = cleanedText.replaceAll(RegExp(r'\s+'), '').length;
    final textLikeCount = _countTextLikeCharacters(cleanedText);

    var score = 0.0;
    score += math.min(32, charCount * 0.16);
    score += math.min(22, wordCount * 0.9);
    score += math.min(20, lineCount * 3.3);
    score += math.min(12, recognizedText.blocks.length * 2.0);
    score += math.min(14, textLikeCount * 0.08);

    if (charCount < 40) {
      score -= 28;
    } else if (charCount < 110) {
      score -= 12;
    }
    if (wordCount < 8) {
      score -= 14;
    }
    if (lineCount <= 1) {
      score -= 16;
    }
    if (_textDensity(cleanedText, charCount) < 0.55) {
      score -= 8;
    }
    if (source == OcrSource.handwritingFocus && lineCount >= 2) {
      score += 6;
    }
    if (source == OcrSource.handwritingBinary && lineCount >= 2) {
      score += 4;
    }
    if ((source == OcrSource.handwritingFocus ||
            source == OcrSource.handwritingBinary) &&
        wordCount >= 4) {
      score += 4;
    }
    if (source == OcrSource.documentFocusCrop) {
      if (lineCount >= 2) {
        score += 6;
      }
      if (wordCount >= 10) {
        score += 4;
      }
    }
    if (preferHandwriting) {
      if (source == OcrSource.handwritingFocus) {
        score += 10;
      } else if (source == OcrSource.handwritingBinary) {
        score += 8;
      }
    }

    final clampedScore = score.clamp(0, 100).round();
    final quality = clampedScore >= 78
        ? OcrQuality.good
        : clampedScore >= 50
            ? OcrQuality.fair
            : OcrQuality.poor;

    return _OcrAttempt(
      recognizedText: recognizedText,
      cleanedText: cleanedText,
      source: source,
      score: clampedScore,
      quality: quality,
      charCount: charCount,
      lineCount: lineCount,
      wordCount: wordCount,
      previewImage: sourceImage,
      imagePath: imagePath,
      script: script,
      textRegions: textRegions,
    );
  }

  List<OcrNotice> _buildNotices({
    required _OcrAttempt best,
    required _SourceImageAnalysis? baseAnalysis,
  }) {
    final notices = <OcrNotice>[];

    if (best.charCount < 40) {
      notices.add(OcrNotice.lowText);
    }
    if (best.wordCount < 8) {
      notices.add(OcrNotice.moveCloser);
    }
    if (best.lineCount <= 1) {
      notices.add(OcrNotice.cropLines);
    }
    if (baseAnalysis != null && baseAnalysis.brightness < 72) {
      notices.add(OcrNotice.darkImage);
    }
    if (baseAnalysis != null && baseAnalysis.brightness > 214) {
      notices.add(OcrNotice.overexposed);
    }
    if (baseAnalysis != null && baseAnalysis.contrast < 34) {
      notices.add(OcrNotice.lowContrast);
    }
    if (best.usedEnhancedPass) {
      notices.add(OcrNotice.enhancedPass);
    }
    if (best.source == OcrSource.handwritingFocus ||
        best.source == OcrSource.handwritingBinary) {
      notices.add(OcrNotice.handwritingFocus);
    }
    if (best.source == OcrSource.documentFocusCrop) {
      notices.add(OcrNotice.autoCrop);
    }

    final deduped = <OcrNotice>{};
    return notices.where(deduped.add).take(4).toList();
  }

  List<OcrBlock> _mapBlocks(RecognizedText recognizedText) {
    final blocks = <OcrBlock>[];
    for (final block in recognizedText.blocks) {
      blocks.add(
        OcrBlock(
          text: block.text,
          type: _determineBlockType(block.text),
          confidence: 1.0,
        ),
      );
    }
    return blocks;
  }

  int _compareAttempts(
    _OcrAttempt left,
    _OcrAttempt right, {
    required bool preferHandwriting,
  }) {
    if (left.score != right.score) {
      return right.score.compareTo(left.score);
    }
    if (preferHandwriting) {
      final leftHandwriting = left.source == OcrSource.handwritingFocus ||
          left.source == OcrSource.handwritingBinary;
      final rightHandwriting = right.source == OcrSource.handwritingFocus ||
          right.source == OcrSource.handwritingBinary;
      if (leftHandwriting != rightHandwriting) {
        return rightHandwriting ? 1 : -1;
      }
    }
    if (left.charCount != right.charCount) {
      return right.charCount.compareTo(left.charCount);
    }
    return left.source.index.compareTo(right.source.index);
  }

  _OcrAttempt _bestAttempt(
    List<_OcrAttempt> attempts, {
    required bool preferHandwriting,
  }) {
    final sorted = [...attempts]..sort(
        (left, right) => _compareAttempts(
          left,
          right,
          preferHandwriting: preferHandwriting,
        ),
      );
    return sorted.first;
  }

  List<DetectedTextRegion> _extractTextRegions(RecognizedText recognizedText) {
    final regions = <DetectedTextRegion>[];

    for (final block in recognizedText.blocks) {
      if (block.lines.isEmpty) {
        regions.add(
          DetectedTextRegion(
            left: block.boundingBox.left,
            top: block.boundingBox.top,
            right: block.boundingBox.right,
            bottom: block.boundingBox.bottom,
          ),
        );
        continue;
      }

      for (final line in block.lines) {
        regions.add(
          DetectedTextRegion(
            left: line.boundingBox.left,
            top: line.boundingBox.top,
            right: line.boundingBox.right,
            bottom: line.boundingBox.bottom,
          ),
        );
      }
    }

    return regions;
  }

  String _normalizeRecognizedText(String text) {
    final lines = text
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return lines.join('\n').trim();
  }

  int _countLines(RecognizedText recognizedText) {
    var count = 0;
    for (final block in recognizedText.blocks) {
      count += block.lines.length;
    }
    return math.max(1, count);
  }

  int _countWords(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .length;
  }

  int _countTextLikeCharacters(String text) {
    return RegExp(
      r'[A-Za-z0-9\u0600-\u06FF\u0750-\u077F\u4E00-\u9FFF\u0900-\u097F]',
    ).allMatches(text).length;
  }

  double _textDensity(String text, int charCount) {
    if (charCount == 0) {
      return 0;
    }
    return _countTextLikeCharacters(text) / charCount;
  }

  static double _averageLuminance(img.Image image) {
    final step = math.max(1, math.min(image.width, image.height) ~/ 90);
    var total = 0.0;
    var samples = 0;

    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        total += img.getLuminance(pixel);
        samples++;
      }
    }

    if (samples == 0) {
      return 0;
    }

    return total / samples;
  }

  static double _contrastEstimate(img.Image image) {
    final step = math.max(1, math.min(image.width, image.height) ~/ 90);
    final luminances = <double>[];

    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        luminances.add(img.getLuminance(pixel).toDouble());
      }
    }

    if (luminances.isEmpty) {
      return 0;
    }

    final mean = luminances.reduce((value, element) => value + element) /
        luminances.length;
    var variance = 0.0;
    for (final value in luminances) {
      final delta = value - mean;
      variance += delta * delta;
    }

    return math.sqrt(variance / luminances.length);
  }

  num _brightnessBoost(_SourceImageAnalysis analysis) {
    if (analysis.brightness < 72) {
      return 0.12;
    }
    if (analysis.brightness > 214) {
      return -0.08;
    }
    return 0.02;
  }

  num _contrastBoost(_SourceImageAnalysis analysis) {
    if (analysis.contrast < 34) {
      return 1.65;
    }
    return 1.25;
  }

  num _gammaBoost(_SourceImageAnalysis analysis) {
    if (analysis.brightness < 72) {
      return 0.85;
    }
    if (analysis.brightness > 214) {
      return 1.1;
    }
    return 0.95;
  }

  num _exposureBoost(_SourceImageAnalysis analysis) {
    if (analysis.brightness < 72) {
      return 0.18;
    }
    if (analysis.brightness > 214) {
      return -0.08;
    }
    return 0.05;
  }

  int _resizeWidth(int currentWidth) {
    if (currentWidth >= 2200) {
      return currentWidth;
    }
    return 2200;
  }

  img.Image _buildHandwritingFocusedImage(img.Image source) {
    final cropped = _cropTowardDocumentCenter(source);
    final resized = img.copyResize(
      cropped,
      width: _resizeWidth(cropped.width),
      interpolation: img.Interpolation.linear,
    );
    final enhanced = img.adjustColor(
      resized,
      contrast: 1.75,
      brightness: 0.08,
      gamma: 0.9,
      exposure: 0.08,
      saturation: 0.0,
    );
    final grayscale = img.grayscale(enhanced);
    return img.histogramStretch(
      img.gaussianBlur(grayscale, radius: 1),
      stretchClipRatio: 0.008,
    );
  }

  img.Image _buildHandwritingBinaryImage(img.Image source) {
    final threshold = _otsuThreshold(source);
    final binary = img.Image.from(source);
    for (var y = 0; y < binary.height; y++) {
      for (var x = 0; x < binary.width; x++) {
        final luminance = img.getLuminance(binary.getPixel(x, y));
        final value = luminance >= threshold ? 255 : 0;
        binary.setPixelRgb(x, y, value, value, value);
      }
    }
    return binary;
  }

  img.Image _cropTowardDocumentCenter(img.Image source) {
    final horizontalInset = (source.width * 0.07).round();
    final topInset = (source.height * 0.08).round();
    final bottomInset = (source.height * 0.06).round();
    final width = math.max(1, source.width - (horizontalInset * 2));
    final height = math.max(1, source.height - topInset - bottomInset);
    return img.copyCrop(
      source,
      x: horizontalInset,
      y: topInset,
      width: width,
      height: height,
    );
  }

  int _otsuThreshold(img.Image source) {
    final histogram = List<int>.filled(256, 0);
    var total = 0;

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final luminance = img.getLuminance(source.getPixel(x, y)).round();
        histogram[luminance.clamp(0, 255)]++;
        total++;
      }
    }

    var sum = 0.0;
    for (var i = 0; i < histogram.length; i++) {
      sum += i * histogram[i];
    }

    var sumBackground = 0.0;
    var weightBackground = 0;
    var maxVariance = -1.0;
    var threshold = 128;

    for (var i = 0; i < histogram.length; i++) {
      weightBackground += histogram[i];
      if (weightBackground == 0) {
        continue;
      }

      final weightForeground = total - weightBackground;
      if (weightForeground == 0) {
        break;
      }

      sumBackground += i * histogram[i];
      final meanBackground = sumBackground / weightBackground;
      final meanForeground = (sum - sumBackground) / weightForeground;
      final meanDelta = meanBackground - meanForeground;
      final betweenClassVariance =
          weightBackground * weightForeground * meanDelta * meanDelta;

      if (betweenClassVariance > maxVariance) {
        maxVariance = betweenClassVariance;
        threshold = i;
      }
    }

    return threshold;
  }

  OcrBlockType _determineBlockType(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('\$') || lowerText.contains('usd')) {
      return OcrBlockType.amount;
    }
    if (lowerText.contains('%') || lowerText.contains('interest')) {
      return OcrBlockType.interest;
    }
    if (lowerText.contains('signature') || lowerText.contains('____')) {
      return OcrBlockType.signatureLine;
    }
    if (lowerText.contains('prison') ||
        lowerText.contains('court') ||
        lowerText.contains('waive')) {
      return OcrBlockType.criticalClause;
    }
    return OcrBlockType.normalText;
  }

  TextRecognizer _recognizerFor(TextRecognitionScript script) {
    return _recognizers.putIfAbsent(
      script,
      () => TextRecognizer(script: script),
    );
  }

  List<TextRecognitionScript> _scriptsForLocale(String localeTag) {
    final normalized = localeTag.toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('zh')) {
      return const [
        TextRecognitionScript.chinese,
        TextRecognitionScript.latin,
      ];
    }
    if (normalized.startsWith('hi') ||
        normalized.startsWith('mr') ||
        normalized.startsWith('ne')) {
      return const [
        TextRecognitionScript.devanagiri,
        TextRecognitionScript.latin,
      ];
    }
    if (normalized.startsWith('ja')) {
      return const [
        TextRecognitionScript.japanese,
        TextRecognitionScript.latin,
      ];
    }
    if (normalized.startsWith('ko')) {
      return const [
        TextRecognitionScript.korean,
        TextRecognitionScript.latin,
      ];
    }
    return const [TextRecognitionScript.latin];
  }

  Future<OcrResult> _processImageWithTesseract(String imagePath) async {
    try {
      final text = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'ara',
        args: {
          "preserve_interword_spaces": "1",
        },
      );

      final cleanedText = text.trim();

      if (cleanedText.isEmpty) {
        throw OcrException(
          'No readable Arabic text was detected in the captured document.',
        );
      }

      final charCount = cleanedText.replaceAll(RegExp(r'\s+'), '').length;
      final lineCount = math.max(1, cleanedText.split('\n').length);
      final wordCount = cleanedText
          .split(RegExp(r'\s+'))
          .where((p) => p.trim().isNotEmpty)
          .length;

      var score = 50; // Base score for tesseract
      score += math.min(30, charCount * 0.1).toInt();
      score += math.min(20, wordCount * 0.5).toInt();
      final clampedScore = score.clamp(0, 100);

      final quality = clampedScore >= 70
          ? OcrQuality.good
          : clampedScore >= 45
              ? OcrQuality.fair
              : OcrQuality.poor;

      return OcrResult(
        fullText: cleanedText,
        blocks: [
          OcrBlock(
            text: cleanedText,
            type: OcrBlockType.normalText,
            confidence: 1.0,
          )
        ],
        quality: quality,
        qualityScore: clampedScore,
        charCount: charCount,
        lineCount: lineCount,
        wordCount: wordCount,
        notices: [], // Simplified for Tesseract
        previewImagePath: imagePath,
        didAutoCrop: false,
        usedEnhancedPass: false,
      );
    } catch (e) {
      throw OcrException(
        'Arabic document text extraction failed. Capture a clearer image or paste the text manually.',
      );
    }
  }

  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.close();
    }
    _recognizers.clear();
  }
}

class OcrResult {
  OcrResult({
    required this.fullText,
    required this.blocks,
    required this.quality,
    required this.qualityScore,
    required this.charCount,
    required this.lineCount,
    required this.wordCount,
    required this.notices,
    required this.previewImagePath,
    required this.didAutoCrop,
    required this.usedEnhancedPass,
  });

  final String fullText;
  final List<OcrBlock> blocks;
  final OcrQuality quality;
  final int qualityScore;
  final int charCount;
  final int lineCount;
  final int wordCount;
  final List<OcrNotice> notices;
  final String previewImagePath;
  final bool didAutoCrop;
  final bool usedEnhancedPass;

  bool get needsRetake => quality == OcrQuality.poor;
}

class OcrBlock {
  OcrBlock({
    required this.text,
    required this.type,
    required this.confidence,
  });

  final String text;
  final OcrBlockType type;
  final double confidence;
}

enum OcrBlockType {
  amount,
  interest,
  date,
  signatureLine,
  blankSpace,
  criticalClause,
  normalText,
}

enum OcrQuality {
  poor,
  fair,
  good,
}

enum OcrNotice {
  lowText,
  moveCloser,
  cropLines,
  darkImage,
  overexposed,
  lowContrast,
  enhancedPass,
  handwritingFocus,
  autoCrop,
}

enum OcrSource {
  original,
  documentFocusCrop,
  enhancedColor,
  highContrastMono,
  handwritingFocus,
  handwritingBinary,
}

class _PreparedInput {
  const _PreparedInput({
    required this.path,
    required this.source,
    required this.previewImage,
  });

  final String path;
  final OcrSource source;
  final img.Image previewImage;
}

class _SourceImageAnalysis {
  const _SourceImageAnalysis({
    required this.imagePath,
    required this.normalizedImage,
    required this.brightness,
    required this.contrast,
  });

  final String imagePath;
  final img.Image normalizedImage;
  final double brightness;
  final double contrast;
}

class _OcrAttempt {
  const _OcrAttempt({
    required this.recognizedText,
    required this.cleanedText,
    required this.source,
    required this.score,
    required this.quality,
    required this.charCount,
    required this.lineCount,
    required this.wordCount,
    required this.previewImage,
    required this.imagePath,
    required this.script,
    required this.textRegions,
  });

  final RecognizedText recognizedText;
  final String cleanedText;
  final OcrSource source;
  final int score;
  final OcrQuality quality;
  final int charCount;
  final int lineCount;
  final int wordCount;
  final img.Image? previewImage;
  final String imagePath;
  final TextRecognitionScript script;
  final List<DetectedTextRegion> textRegions;

  bool get usedEnhancedPass =>
      source == OcrSource.enhancedColor ||
      source == OcrSource.highContrastMono ||
      source == OcrSource.handwritingFocus ||
      source == OcrSource.handwritingBinary;
}
