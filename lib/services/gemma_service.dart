import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../localization/app_copy.dart';

final gemmaServiceProvider = ChangeNotifierProvider((ref) => GemmaService());

enum GemmaModelStatus {
  notDownloaded,
  downloading,
  paused,
  installing,
  ready,
  error,
}

class GemmaRequirementException implements Exception {
  const GemmaRequirementException({
    required this.message,
    required this.canUseLimitedFallback,
  });

  final String message;
  final bool canUseLimitedFallback;

  @override
  String toString() => message;
}

class GemmaService extends ChangeNotifier {
  GemmaService() {
    unawaited(initialize());
  }

  static const String _modelUrl = String.fromEnvironment(
    'GEMMA_MODEL_URL',
    defaultValue:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm?download=true',
  );
  static const String _expectedModelSha256 = String.fromEnvironment(
    'GEMMA_MODEL_SHA256',
    defaultValue:
        '181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c',
  );
  static const String _modelName = 'Gemma 4 E2B-it';
  static const String _modelSource = 'Official Hugging Face LiteRT-LM download';
  static const double _modelSizeGb = 2.6;
  static const double _recommendedFreeSpaceGb = 4.0;
  static const int _recommendedRamGb = 4;
  static const int _fallbackModelSizeBytes = 2791728742;
  static const int _primaryGemmaContextTokens = 2048;
  static const int _fallbackGemmaContextTokens = 1024;
  static const int _maxDocumentPromptChars = 2000;
  static const int _maxCompactDocumentPromptChars = 1000;
  static const int _maxContextPromptChars = 400;
  static const int _maxCompactContextPromptChars = 200;
  static const int _promptEdgeChars = 400;
  static const int _compactPromptEdgeChars = 200;
  static const int _riskExcerptRadiusChars = 120;
  static const int _compactRiskExcerptRadiusChars = 80;
  static const int _maxRiskExcerptChars = 600;
  static const int _maxCompactRiskExcerptChars = 300;
  static const Duration _modelStartupTimeout = Duration(seconds: 35);
  static const Duration _sessionStartupTimeout = Duration(seconds: 20);
  static const Duration _queryAddTimeout = Duration(seconds: 10);
  static const Duration _responseIdleTimeout = Duration(seconds: 45);
  static const Duration _responseTotalTimeout = Duration(seconds: 90);
  static const Duration _sessionCloseTimeout = Duration(seconds: 5);
  static const Duration _overallInferenceTimeout = Duration(seconds: 100);
  static const String _downloadGroup = 'gemma-model-download';
  static const String _downloadTaskId = 'gemma-4-e2b-model';
  static const String _downloadDirectory = 'models';
  static const String _downloadFilename = 'gemma-4-E2B-it.litertlm';
  static const String _verifiedHashFilename = 'gemma-4-E2B-it.sha256-ok.json';
  static const String _downloadStateFilename =
      'gemma-4-E2B-it.download-state.json';
  static const int _downloadRetryCount = 10;
  static const int _foregroundDownloadThresholdMb = 64;
  static const List<({PreferredBackend backend, String label})>
      _gemmaBackendAttempts = [
    (backend: PreferredBackend.gpu, label: 'GPU'),
    (backend: PreferredBackend.cpu, label: 'CPU'),
  ];

  Future<String> get _logFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/gemma_download_log.txt';
  }

  Future<void> _logToFile(String message) async {
    try {
      final path = await _logFilePath;
      final file = File(path);
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
      );
      debugPrint(message);
    } catch (e) {
      debugPrint('Failed to log to file: $e\nOriginal message: $message');
    }
  }

  static const List<String> _guarantorTerms = [
    'guarantor',
    'guarantee',
    'surety',
    'co-signer',
    'cosigner',
    'kafala',
    'garante',
    'aval',
    'avalista',
    'fiador',
    'fiança',
    'fianca',
    'caution',
    'caution solidaire',
    'garant',
    'garantidor',
    'जमानतदार',
    'गारंटर',
    'गारंटी',
    '担保人',
    '保证人',
    '连带保证',
    'ضامن',
    'كفيل',
  ];
  static const List<String> _debtTerms = [
    'loan',
    'debt',
    'interest',
    'promissory',
    'installment',
    'repay',
    'principal',
    'préstamo',
    'prestamo',
    'deuda',
    'interés',
    'interes',
    'pagaré',
    'pagare',
    'cuota',
    'empréstimo',
    'emprestimo',
    'dívida',
    'divida',
    'juros',
    'parcela',
    'parcelas',
    'promissória',
    'promissoria',
    'prêt',
    'pret',
    'dette',
    'intérêt',
    'interet',
    'échéance',
    'echeance',
    'ऋण',
    'कर्ज',
    'ब्याज',
    'किस्त',
    '贷款',
    '债务',
    '利息',
    '分期',
    '欠款',
    'دين',
    'قرض',
    'فائدة',
  ];
  static const List<String> _waiverTerms = [
    'waive',
    'arbitration',
    'no appeal',
    'indemnify',
    'exclusive jurisdiction',
    'renuncia',
    'renuncia a',
    'arbitraje',
    'sin apelación',
    'sin apelacion',
    'renúncia',
    'renuncia',
    'arbitragem',
    'sem recurso',
    'renonciation',
    'renonce à',
    'renonce a',
    'renonce',
    'arbitrage',
    'sans appel',
    'त्याग',
    'मध्यस्थता',
    'अपील नहीं',
    '放弃',
    '仲裁',
    '不得上诉',
    'تنازل',
    'تحكيم',
  ];
  static const List<String> _collateralTerms = [
    'collateral',
    'all assets',
    'salary',
    'wage',
    'wages',
    'security interest',
    'lien',
    'garantía',
    'garantia',
    'salario',
    'bienes',
    'embargo',
    'garantia real',
    'garantia pessoal',
    'salário',
    'salario',
    'bens',
    'penhor',
    'garantie',
    'salaire',
    'biens',
    'nantissement',
    'gage',
    'गिरवी',
    'वेतन',
    'संपत्ति',
    'जमानत',
    '抵押',
    '工资',
    '财产',
    '资产',
    '担保物',
    'راتب',
    'أصل',
    'ضمان',
  ];
  static const List<String> _assetRiskTerms = [
    ..._debtTerms,
    ..._collateralTerms,
  ];
  static const List<String> _pressureTerms = [
    'just a formality',
    'just sign',
    'my friend asked me',
    'nothing will happen',
    'sign now',
    'today only',
    'solo firma',
    'solo es una formalidad',
    'es un trámite',
    'es un tramite',
    'no pasa nada',
    'só assina',
    'so assina',
    'é só formalidade',
    'e so formalidade',
    'não acontece nada',
    'nao acontece nada',
    'signez seulement',
    'simple formalité',
    'simple formalite',
    'il n\'arrivera rien',
    'बस साइन कर दो',
    'सिर्फ औपचारिकता है',
    'कुछ नहीं होगा',
    '直接签吧',
    '只是走个流程',
    '不会有事',
    'امضي بس',
    'مجرد إجراء',
    'مجرد ورقة',
  ];

  final FileDownloader _downloader = FileDownloader();

  GemmaModelStatus _status = GemmaModelStatus.notDownloaded;
  double _downloadProgress = 0.0;
  bool _isInitialized = false;
  bool _downloadManagerReady = false;
  String? _lastError;
  DownloadTask? _downloadTask;
  StreamSubscription<TaskUpdate>? _downloadUpdatesSubscription;
  int _expectedFileSizeBytes = _fallbackModelSizeBytes;
  double? _networkSpeedMbps;
  Duration? _timeRemaining;
  bool _sideloadInstallFailed = false;

  static const int _maxAutoResumeAttempts = 10;
  int _autoResumeAttemptsRemaining = _maxAutoResumeAttempts;

  GemmaModelStatus get status => _status;
  double get downloadProgress => _downloadProgress;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  String get modelName => _modelName;
  String get modelSource => _modelSource;
  String get modelSizeLabel => '${_modelSizeGb.toStringAsFixed(1)} GB';
  String get recommendedFreeSpaceLabel =>
      '${_recommendedFreeSpaceGb.toStringAsFixed(1)} GB';
  String get recommendedRamLabel => '$_recommendedRamGb GB RAM';
  bool get isReady => _status == GemmaModelStatus.ready;
  bool get isDownloading =>
      _status == GemmaModelStatus.downloading ||
      _status == GemmaModelStatus.installing;
  bool get isPaused => _status == GemmaModelStatus.paused;
  bool get canPause => _status == GemmaModelStatus.downloading;
  bool get canResume => _status == GemmaModelStatus.paused;
  bool get isAutoResuming =>
      _autoResumeAttemptsRemaining < _maxAutoResumeAttempts &&
      _autoResumeAttemptsRemaining > 0 &&
      _status == GemmaModelStatus.downloading;
  int get totalBytes => _expectedFileSizeBytes > 0
      ? _expectedFileSizeBytes
      : _fallbackModelSizeBytes;
  int get downloadedBytes => (totalBytes * _downloadProgress).round();
  String get downloadedMegabytesLabel => _formatMegabytes(downloadedBytes);
  String get totalMegabytesLabel => _formatMegabytes(totalBytes);
  String? get speedMegabytesLabel {
    final speed = _networkSpeedMbps;
    if (speed == null || speed <= 0) {
      return null;
    }
    return speed >= 10 ? speed.toStringAsFixed(0) : speed.toStringAsFixed(1);
  }

  String? get timeRemainingLabel {
    final remaining = _timeRemaining;
    if (remaining == null || remaining.inSeconds <= 0) {
      return null;
    }
    final hours = remaining.inHours;
    final minutes =
        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '${remaining.inMinutes}:$seconds';
  }

  static const String masterSystemPrompt = '''
You are an expert, objective on-device paperwork risk analyst.
Identify critical signing risks. Be extremely concise. Do not give legal advice.
Return ONLY valid JSON matching this exact structure:
{
  "risk_score": <int 1-10>,
  "risk_title": "<very short title>",
  "verdict_summary": "<1 concise sentence>",
  "top_risks": [
    {
      "title": "<title>",
      "description": "<concise risk explanation>",
      "why_dangerous": "<consequence>",
      "evidence": "<exact short quote from text>",
      "question_to_ask": "<question for the other party>"
    }
  ],
  "safer_next_step": "<one clear next step>",
  "language_detected": "<language code>"
}
RULES:
1. "top_risks" array must contain ONLY the 1 or 2 most severe risks. If there are no major risks, return an empty array []. Do NOT hallucinate risks.
2. "evidence" MUST be an exact quote under 100 chars.
3. NEVER return markdown formatting outside the JSON block.
''';

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _ensureDownloadManager();
    await refreshStatus(markInitialized: true);
  }

  Future<void> refreshStatus({bool markInitialized = false}) async {
    await _ensureDownloadManager();

    try {
      final internalPath = await _internalModelPath;

      if (await _isVerifiedModelFile(internalPath)) {
        await _linkGemmaModel(internalPath, logPrefix: 'GEMMA INTERNAL');
        await _markModelReady();
      } else {
        final installedFromLocalFile = await _tryInstallFromLocalFile();
        if (!installedFromLocalFile && !_sideloadInstallFailed) {
          await _restoreDownloadState();
        }
      }
    } catch (e) {
      _status = GemmaModelStatus.error;
      _lastError = 'Gemma initialization failed: $e';
    }

    if (markInitialized) {
      _isInitialized = true;
    }
    notifyListeners();
  }

  Future<String> get _internalModelPath async {
    final docsDir = await getApplicationDocumentsDirectory();
    return '${docsDir.path}/models/$_downloadFilename';
  }

  Future<String> get _verifiedHashPath async {
    final docsDir = await getApplicationDocumentsDirectory();
    return '${docsDir.path}/models/$_verifiedHashFilename';
  }

  Future<bool> _isVerifiedModelFile(String path) async {
    try {
      await _verifyModelFileIntegrity(path, useCachedVerification: true);
      return true;
    } catch (e) {
      debugPrint('GEMMA: Model file is not verified: $e');
      return false;
    }
  }

  Future<void> _verifyModelFileIntegrity(
    String path, {
    bool useCachedVerification = false,
    bool deleteOnFailure = false,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Gemma model file was not found at $path.');
    }

    final stat = await file.stat();
    final fileLength = stat.size;
    if (fileLength < _minimumValidModelSizeBytes) {
      if (deleteOnFailure) {
        await file.delete().catchError((_) => file);
      }
      throw Exception(
        'Gemma model file is too small '
        '(${(fileLength / 1024 / 1024).toStringAsFixed(0)} MB).',
      );
    }

    if (_expectedModelSha256.trim().isEmpty) {
      return;
    }

    final expectedHash = _expectedModelSha256.toLowerCase();
    final verifiedHashFile = File(await _verifiedHashPath);
    if (useCachedVerification && await verifiedHashFile.exists()) {
      try {
        final cached = jsonDecode(await verifiedHashFile.readAsString())
            as Map<String, dynamic>;
        final cachedHash = cached['sha256']?.toString().toLowerCase();
        final cachedSize = cached['size_bytes'];
        final cachedModified = cached['modified_milliseconds_since_epoch'];
        if (cachedHash == expectedHash &&
            cachedSize == fileLength &&
            cachedModified == stat.modified.millisecondsSinceEpoch) {
          return;
        }
      } catch (_) {}
    }

    final actualHash = (await sha256.bind(file.openRead()).first).toString();
    if (actualHash.toLowerCase() != expectedHash) {
      if (deleteOnFailure) {
        await file.delete().catchError((_) => file);
      }
      throw Exception(
        'Gemma SHA256 mismatch. Expected $expectedHash but found $actualHash.',
      );
    }

    if (!await verifiedHashFile.parent.exists()) {
      await verifiedHashFile.parent.create(recursive: true);
    }
    await verifiedHashFile.writeAsString(
      jsonEncode({
        'filename': _downloadFilename,
        'sha256': actualHash.toLowerCase(),
        'size_bytes': fileLength,
        'modified_milliseconds_since_epoch':
            stat.modified.millisecondsSinceEpoch,
        'verified_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<void> _linkGemmaModel(
    String filePath, {
    required String logPrefix,
  }) async {
    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    ).fromFile(filePath).install();
    debugPrint('$logPrefix: Model at $filePath linked to engine.');
  }

  Future<void> _deleteGemmaEngineCaches(String modelPath) async {
    try {
      final modelDir = File(modelPath).parent;
      if (!await modelDir.exists()) {
        return;
      }

      await for (final entity in modelDir.list()) {
        if (entity is! File) {
          continue;
        }
        final lowerPath = entity.path.toLowerCase();
        final isEngineCache = lowerPath.contains('mldrift_program_cache') ||
            lowerPath.contains('xnnpack_cache');
        if (!isEngineCache) {
          continue;
        }
        debugPrint('GEMMA: Deleting engine cache: ${entity.path}');
        await entity.delete();
      }
    } catch (cacheError) {
      debugPrint(
        'GEMMA: Could not clean engine cache (non-fatal): $cacheError',
      );
    }
  }

  Future<String> _runInstalledModelHealthCheck() async {
    Object? lastError;
    String? lastAttemptLabel;
    final errorLog = StringBuffer();

    for (final (backend: backend, label: backendLabel)
        in _gemmaBackendAttempts) {
      final attemptLabel = '$backendLabel engine startup';
      try {
        debugPrint('GEMMA: Health check trying $attemptLabel...');
        final model = await FlutterGemma.getActiveModel(
          maxTokens: 32,
          preferredBackend: backend,
          enableSpeculativeDecoding: false,
        );
        await model.close();
        debugPrint('GEMMA: Health check passed on $backendLabel.');
        return backendLabel;
      } catch (error) {
        lastAttemptLabel = attemptLabel;
        lastError = error;
        errorLog.writeln('  - $attemptLabel: $error');
        debugPrint('GEMMA: Health check failed on $backendLabel: $error');
      }
    }

    throw Exception(
      'All Gemma engine health checks failed:\n$errorLog'
      'Last: $lastAttemptLabel: $lastError',
    );
  }

  Future<void> _markModelReady() async {
    _sideloadInstallFailed = false;
    _status = GemmaModelStatus.ready;
    _downloadProgress = 1.0;
    _lastError = null;
    notifyListeners();
  }

  /// Sideload paths: if the model file is found at one of these locations
  /// (e.g. pushed via ADB), it will be copied into app storage and linked.
  static const List<String> _sideloadPaths = [
    '/storage/emulated/0/Download/gemma-4-E2B-it.litertlm',
    '/sdcard/Download/gemma-4-E2B-it.litertlm',
  ];

  /// Try to install the model from a local sideloaded file.
  /// Returns true if the model was found and installed successfully.
  Future<bool> _tryInstallFromLocalFile() async {
    _sideloadInstallFailed = false;
    Object? lastInstallError;
    String? lastCandidatePath;

    for (final path in _sideloadPaths) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;

        final fileLength = await file.length();
        debugPrint('GEMMA SIDELOAD: Found model at $path ($fileLength bytes)');

        if (fileLength < _minimumValidModelSizeBytes) {
          debugPrint('GEMMA SIDELOAD: File too small, skipping.');
          continue;
        }

        lastCandidatePath = path;
        _expectedFileSizeBytes = fileLength;
        _status = GemmaModelStatus.installing;
        _downloadProgress = 0.9;
        _lastError = null;
        notifyListeners();

        // GEMMA FIX: On Android 15, the native engine (C++) often cannot access
        // files in the Download folder directly even with MANAGE_EXTERNAL_STORAGE.
        // We MUST copy it to internal storage once for stable engine initialization.
        final destPath = await _internalModelPath;
        final modelsDir = File(destPath).parent;
        if (!await modelsDir.exists()) {
          await modelsDir.create(recursive: true);
        }

        if (!await _isVerifiedModelFile(destPath)) {
          debugPrint(
            'GEMMA SIDELOAD: Copying to internal storage for native access...',
          );
          await file.copy(destPath);
          debugPrint('GEMMA SIDELOAD: Copy complete.');
        }

        await _verifyModelFileIntegrity(
          destPath,
          useCachedVerification: true,
          deleteOnFailure: true,
        );

        _downloadProgress = 0.95;
        notifyListeners();

        await _deleteGemmaEngineCaches(destPath);
        await _linkGemmaModel(destPath, logPrefix: 'GEMMA SIDELOAD');
        final backendLabel = await _runInstalledModelHealthCheck();

        debugPrint(
          'GEMMA SIDELOAD: Model passed health check on $backendLabel.',
        );

        await _markModelReady();

        debugPrint('GEMMA SIDELOAD: Installation complete!');
        return true;
      } catch (e) {
        lastInstallError = e;
        debugPrint('GEMMA SIDELOAD: Failed from $path: $e');
      }
    }

    if (lastCandidatePath != null && lastInstallError != null) {
      _sideloadInstallFailed = true;
      _status = GemmaModelStatus.error;
      _lastError =
          'Found the local Gemma model on this phone at $lastCandidatePath, '
          'but it could not be prepared. $lastInstallError';
      notifyListeners();
    }

    return false;
  }

  Future<bool> importModelFromPicker() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) {
        return false;
      }
      final pickedPath = result.files.single.path;
      if (pickedPath == null) {
        return false;
      }

      final file = File(pickedPath);
      final fileLength = await file.length();
      if (fileLength < _minimumValidModelSizeBytes) {
        _lastError =
            'الملف المختار صغير جداً ولا يمكن أن يكون نموذج Gemma صالح.';
        _status = GemmaModelStatus.error;
        notifyListeners();
        return false;
      }

      _expectedFileSizeBytes = fileLength;
      _status = GemmaModelStatus.installing;
      _downloadProgress = 0.9;
      _lastError = null;
      notifyListeners();

      final destPath = await _internalModelPath;
      final modelsDir = File(destPath).parent;
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      if (!await _isVerifiedModelFile(destPath)) {
        await file.copy(destPath);
      }

      await _verifyModelFileIntegrity(
        destPath,
        useCachedVerification: true,
        deleteOnFailure: true,
      );

      _downloadProgress = 0.95;
      notifyListeners();

      await _deleteGemmaEngineCaches(destPath);
      await _linkGemmaModel(destPath, logPrefix: 'GEMMA IMPORT');
      await _runInstalledModelHealthCheck();

      await _markModelReady();
      return true;
    } catch (e) {
      _status = GemmaModelStatus.error;
      _lastError = 'فشل في استيراد النموذج: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> downloadModel() async {
    await _ensureDownloadManager();
    if (!_isInitialized) {
      _isInitialized = true;
    }

    await refreshStatus();

    if (_status == GemmaModelStatus.ready ||
        _status == GemmaModelStatus.installing ||
        _status == GemmaModelStatus.downloading) {
      return;
    }

    // Try sideloading from local file first (e.g. pushed via ADB)
    try {
      if (await _tryInstallFromLocalFile() || _sideloadInstallFailed) {
        return;
      }
    } catch (e) {
      debugPrint(
        'GEMMA: Sideload attempt failed, falling back to download: $e',
      );
    }

    if (_status == GemmaModelStatus.paused) {
      await resumeDownload();
      return;
    }

    if (_status == GemmaModelStatus.error &&
        _downloadProgress > 0.01 &&
        _downloadProgress < 0.999 &&
        _downloadTask != null) {
      await resumeDownload();
      return;
    }

    _status = GemmaModelStatus.downloading;
    _lastError = null;
    _networkSpeedMbps = null;
    _timeRemaining = null;
    _autoResumeAttemptsRemaining = _maxAutoResumeAttempts;
    _downloadTask = _createDownloadTask();
    notifyListeners();

    try {
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.status;
        if (!notificationStatus.isGranted) {
          await Permission.notification.request();
        }

        final status = await Permission.ignoreBatteryOptimizations.status;
        if (!status.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      }
    } catch (_) {}

    unawaited(
      _logToFile(
        'GEMMA DOWNLOAD: Starting manual download. Task: ${_downloadTask?.taskId}',
      ),
    );
    try {
      final enqueued = await _downloader.enqueue(_downloadTask!);
      if (!enqueued) {
        throw Exception('The model download could not be enqueued.');
      }
      unawaited(_logToFile('GEMMA DOWNLOAD: Task enqueued successfully.'));
    } catch (e) {
      unawaited(_logToFile('GEMMA DOWNLOAD ERROR: Failed to enqueue task. $e'));
      _status = GemmaModelStatus.error;
      _lastError = _mapDownloadError(e);
      notifyListeners();
    }
  }

  Future<void> pauseDownload() async {
    await _ensureDownloadManager();
    final task = _downloadTask;
    if (task == null || !canPause) {
      return;
    }

    try {
      final paused = await _downloader.pause(task);
      if (!paused) {
        throw Exception('The device could not pause this download right now.');
      }
      _status = GemmaModelStatus.paused;
      notifyListeners();
    } catch (e) {
      _status = GemmaModelStatus.error;
      _lastError = _mapDownloadError(e);
      notifyListeners();
    }
  }

  Future<void> resumeDownload() async {
    await _ensureDownloadManager();

    // Try sideloading from local file first (e.g. pushed via ADB)
    try {
      if (await _tryInstallFromLocalFile() || _sideloadInstallFailed) {
        return;
      }
    } catch (e) {
      debugPrint(
        'GEMMA: Sideload attempt failed in resume, falling back to network resume: $e',
      );
    }

    final task = _downloadTask ?? _createDownloadTask();
    _downloadTask = task;

    if (_downloadProgress >= 0.999) {
      _status = GemmaModelStatus.installing;
      _lastError = null;
      notifyListeners();
      await _installDownloadedModelFromTask(task);
      return;
    }

    unawaited(_logToFile('GEMMA DOWNLOAD: User requested manual resume.'));
    try {
      final canResume = await _downloader.taskCanResume(task);
      unawaited(_logToFile('GEMMA DOWNLOAD: taskCanResume=$canResume'));
      if (canResume) {
        final resumed = await _downloader.resume(task);
        if (resumed) {
          _status = GemmaModelStatus.downloading;
          _lastError = null;
          _autoResumeAttemptsRemaining = _maxAutoResumeAttempts;
          notifyListeners();
          return;
        }
      }
      throw Exception(
        'The download could not resume from saved progress. '
        'You can try again, or restart the download.',
      );
    } catch (e) {
      _status = GemmaModelStatus.error;
      _lastError = _mapDownloadError(e);
      notifyListeners();
    }
  }

  Future<void> restartDownload() async {
    await _ensureDownloadManager();

    if (_downloadTask != null) {
      try {
        await _downloader.cancelTaskWithId(_downloadTaskId);
      } catch (_) {}
    }

    await _clearSavedDownloadProgress();

    // Try sideloading from local file first (e.g. pushed via ADB)
    try {
      if (await _tryInstallFromLocalFile() || _sideloadInstallFailed) {
        return;
      }
    } catch (e) {
      debugPrint(
        'GEMMA: Sideload attempt failed in restart, falling back to network restart: $e',
      );
    }

    _status = GemmaModelStatus.downloading;
    _lastError = null;
    _downloadProgress = 0.0;
    _networkSpeedMbps = null;
    _timeRemaining = null;
    _autoResumeAttemptsRemaining = _maxAutoResumeAttempts;
    _downloadTask = _createDownloadTask();
    notifyListeners();

    try {
      final enqueued = await _downloader.enqueue(_downloadTask!);
      if (!enqueued) {
        throw Exception('The model download could not be enqueued.');
      }
    } catch (e) {
      _status = GemmaModelStatus.error;
      _lastError = _mapDownloadError(e);
      notifyListeners();
    }
  }

  String _localeToLanguageName(String localeTag) {
    final code = localeTag.split('_').first.toLowerCase();
    switch (code) {
      case 'ar':
        return 'Arabic';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'pt':
        return 'Portuguese';
      case 'hi':
        return 'Hindi';
      case 'zh':
        return 'Chinese';
      default:
        return 'English';
    }
  }

  String buildAnalysisPrompt({
    required String ocrText,
    required String userContext,
    required String locationContext,
    bool compact = false,
  }) {
    final jurisdictionHint = jurisdictionHintFor(locationContext);
    final countryHint = _countryCodeHintFromLocale(locationContext);
    final languageName = _localeToLanguageName(locationContext);

    final preparedDocumentText = prepareDocumentTextForPrompt(
      ocrText,
      compact: compact,
    );
    final preparedUserContext = prepareUserContextForPrompt(
      userContext,
      compact: compact,
    );

    final languageDirective =
        'CRITICAL: ALL JSON string values MUST be written in $languageName.';

    if (compact) {
      return '''
$masterSystemPrompt

$languageDirective

DOCUMENT EXCERPT:
$preparedDocumentText

USER CONTEXT:
${preparedUserContext.isEmpty ? 'None provided.' : preparedUserContext}

LOCALE: $locationContext
HINT: $jurisdictionHint

Return JSON only.
''';
    }

    return '''
$masterSystemPrompt

$languageDirective

DOCUMENT TEXT:
$preparedDocumentText

USER CONTEXT:
${preparedUserContext.isEmpty ? 'None provided.' : preparedUserContext}

DEVICE LOCALE:
$locationContext

COUNTRY / LEGAL CONTEXT HINT:
$countryHint
$jurisdictionHint

Respond with JSON only.
''';
  }

  Future<Map<String, dynamic>> analyze({
    required String ocrText,
    required String audioTranscript,
    required String locationContext,
  }) async {
    final copy = AppCopy.forLocale(locationContext);

    if (_status != GemmaModelStatus.ready) {
      throw GemmaRequirementException(
        message: copy.gemmaNotInstalled,
        canUseLimitedFallback: false,
      );
    }

    try {
      final prompt = buildAnalysisPrompt(
        ocrText: ocrText,
        userContext: audioTranscript,
        locationContext: locationContext,
      );
      final compactPrompt = buildAnalysisPrompt(
        ocrText: ocrText,
        userContext: audioTranscript,
        locationContext: locationContext,
        compact: true,
      );

      final inference = await _runGemmaInference(
        prompt: prompt,
        compactPrompt: compactPrompt,
      ).timeout(_overallInferenceTimeout);
      final parsedJson = _parseGemmaJson(
        inference.responseText,
        copy,
        ocrText: ocrText,
        userContext: audioTranscript,
      );
      return {
        ...parsedJson,
        'analysis_mode': 'gemma',
        'analysis_source': 'Gemma 4 full analysis (${inference.backendLabel})',
        'analysis_notice': copy.fullAnalysisCompleted,
      };
    } catch (e) {
      _lastError = 'Gemma inference failed. $e';
      debugPrint('GEMMA ERROR: $_lastError');
      notifyListeners();

      if (ocrText.trim().isNotEmpty) {
        return _buildRulesBasedAssessment(
          ocrText: ocrText,
          userContext: audioTranscript,
          notice: copy.gemmaCouldNotFinish,
          copy: copy,
        );
      }

      throw GemmaRequirementException(
        message: copy.gemmaCouldNotFinish,
        canUseLimitedFallback: true,
      );
    }
  }

  Future<_GemmaInferenceResult> _runGemmaInference({
    required String prompt,
    required String compactPrompt,
  }) async {
    Object? lastError;
    String? lastAttemptLabel;
    final errorLog = StringBuffer();
    final promptAttempts = [
      (
        text: compactPrompt,
        label: 'compact prompt',
        maxTokens: _fallbackGemmaContextTokens,
      ),
      (
        text: prompt,
        label: 'standard prompt',
        maxTokens: _primaryGemmaContextTokens,
      ),
    ];

    for (final promptAttempt in promptAttempts) {
      for (final (backend: backend, label: backendLabel)
          in _gemmaBackendAttempts) {
        InferenceModelSession? session;
        try {
          debugPrint(
            'GEMMA: Trying $backendLabel ${promptAttempt.label} '
            'with ${promptAttempt.maxTokens} context tokens...',
          );
          final model = await FlutterGemma.getActiveModel(
            maxTokens: promptAttempt.maxTokens,
            preferredBackend: backend,
            enableSpeculativeDecoding: false,
          ).timeout(_modelStartupTimeout);
          session = await model
              .createSession(
                temperature: 0.2,
                randomSeed: 7,
                topK: 1,
                enableThinking: false,
              )
              .timeout(_sessionStartupTimeout);

          try {
            await session
                .addQueryChunk(
                  Message.text(text: promptAttempt.text, isUser: true),
                )
                .timeout(_queryAddTimeout);
            final responseText = await _collectSessionResponse(
              session,
            ).timeout(_responseTotalTimeout);
            if (responseText.trim().isEmpty) {
              throw const FormatException('Gemma returned an empty response.');
            }
            debugPrint(
              'GEMMA: Success on $backendLabel ${promptAttempt.label} '
              'with ${promptAttempt.maxTokens} context tokens',
            );
            return _GemmaInferenceResult(
              responseText: responseText,
              backendLabel:
                  '$backendLabel, ${promptAttempt.maxTokens} context tokens',
            );
          } finally {
            try {
              await session.close().timeout(_sessionCloseTimeout);
            } catch (e) {
              debugPrint('GEMMA: session.close() error (ignored): $e');
            }
            // DO NOT call model.close() — it causes SIGSEGV crash
            // in native ThreadPool::RunWorker. The model is reused
            // via FlutterGemma.getActiveModel() singleton.
          }
        } catch (error) {
          lastAttemptLabel =
              '$backendLabel ${promptAttempt.label} with ${promptAttempt.maxTokens} context tokens';
          lastError = error;
          errorLog.writeln('  ✗ $lastAttemptLabel: $error');
          debugPrint('GEMMA FAIL: $lastAttemptLabel → $error');
        }
      }
    }

    throw Exception(
      'All inference attempts failed:\n$errorLog\n'
      'Last: $lastAttemptLabel → $lastError',
    );
  }

  Future<String> _collectSessionResponse(InferenceModelSession session) async {
    final buffer = StringBuffer();
    await for (final chunk in session.getResponseAsync().timeout(
      _responseIdleTimeout,
      onTimeout: (sink) {
        sink.addError(
          TimeoutException(
            'Gemma did not emit output for '
            '${_responseIdleTimeout.inSeconds} seconds.',
          ),
        );
        sink.close();
      },
    )) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  Future<void> _ensureDownloadManager() async {
    if (_downloadManagerReady) {
      return;
    }

    _downloadUpdatesSubscription ??= _downloader.updates.listen(
      (update) => unawaited(_handleDownloadUpdate(update)),
    );

    _downloader.configureNotificationForGroup(
      _downloadGroup,
      running: const TaskNotification(
        'Downloading Gemma 4',
        '{progress}% downloaded - {networkSpeed}',
      ),
      complete: const TaskNotification(
        'Gemma 4 download finished',
        'Return to Before You Sign to finish setup.',
      ),
      error: const TaskNotification(
        'Gemma 4 download failed',
        'Open Before You Sign to retry.',
      ),
      paused: const TaskNotification(
        'Gemma 4 download paused',
        'Open Before You Sign to resume.',
      ),
      progressBar: true,
    );

    await _downloader.configure(
      globalConfig: [
        (
          Config.runInForegroundIfFileLargerThan,
          _foregroundDownloadThresholdMb,
        ),
      ],
    );
    await _downloader.start();
    await _downloader.resumeFromBackground();
    _downloadManagerReady = true;
  }

  DownloadTask _createDownloadTask() {
    return DownloadTask(
      taskId: _downloadTaskId,
      url: _modelUrl,
      filename: _downloadFilename,
      directory: _downloadDirectory,
      baseDirectory: BaseDirectory.applicationDocuments,
      group: _downloadGroup,
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: _downloadRetryCount,
      priority: 0,
      displayName: _modelName,
      metaData: _modelName,
    );
  }

  Future<void> _restoreDownloadState() async {
    final records = await _downloader.database.allRecords(
      group: _downloadGroup,
    );
    TaskRecord? record;
    for (final candidate in records) {
      if (candidate.taskId == _downloadTaskId) {
        record = candidate;
        break;
      }
    }

    if (record == null) {
      _status = GemmaModelStatus.notDownloaded;
      _downloadProgress = 0.0;
      _downloadTask = null;
      _expectedFileSizeBytes = _fallbackModelSizeBytes;
      _networkSpeedMbps = null;
      _timeRemaining = null;
      _lastError = null;
      await _clearSavedDownloadProgress();
      return;
    }

    _downloadTask = record.task is DownloadTask
        ? record.task as DownloadTask
        : _createDownloadTask();
    if (record.expectedFileSize > 0) {
      _expectedFileSizeBytes = record.expectedFileSize;
    }
    _setDownloadProgress(record.progress);
    await _restoreSavedDownloadProgress();
    _networkSpeedMbps = null;
    _timeRemaining = null;

    switch (record.status) {
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
        _status = GemmaModelStatus.downloading;
        _lastError = null;
        return;
      case TaskStatus.paused:
        _status = GemmaModelStatus.paused;
        _lastError = null;
        return;
      case TaskStatus.complete:
        final installed = await _installDownloadedModelFromTask(_downloadTask!);
        if (!installed) {
          _status = GemmaModelStatus.error;
        }
        return;
      case TaskStatus.failed:
      case TaskStatus.canceled:
      case TaskStatus.notFound:
        _status = GemmaModelStatus.error;
        _lastError = record.exception?.description ?? 'Model download failed.';
        return;
    }
  }

  Future<void> _handleDownloadUpdate(TaskUpdate update) async {
    if (update.task.taskId != _downloadTaskId) {
      return;
    }

    if (update is TaskProgressUpdate) {
      _downloadTask = update.task is DownloadTask
          ? update.task as DownloadTask
          : _downloadTask;
      if (update.expectedFileSize > 0) {
        _expectedFileSizeBytes = update.expectedFileSize;
      }
      final acceptedProgress = _setDownloadProgress(update.progress);
      if (acceptedProgress == null) {
        return;
      }
      _networkSpeedMbps = update.networkSpeed > 0 ? update.networkSpeed : null;
      _timeRemaining =
          update.timeRemaining.inSeconds > 0 ? update.timeRemaining : null;
      if (_status != GemmaModelStatus.installing &&
          _status != GemmaModelStatus.ready) {
        _status = GemmaModelStatus.downloading;
      }
      _lastError = null;
      unawaited(_saveDownloadProgress());
      notifyListeners();
      return;
    }

    if (update is! TaskStatusUpdate) {
      return;
    }

    _downloadTask = update.task is DownloadTask
        ? update.task as DownloadTask
        : _downloadTask;

    switch (update.status) {
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
        _status = GemmaModelStatus.downloading;
        _lastError = null;
        _autoResumeAttemptsRemaining = _maxAutoResumeAttempts;
        notifyListeners();
        return;
      case TaskStatus.paused:
        _status = GemmaModelStatus.paused;
        notifyListeners();
        return;
      case TaskStatus.complete:
        _downloadProgress = 1.0;
        _status = GemmaModelStatus.installing;
        _lastError = null;
        unawaited(_clearSavedDownloadProgress());
        notifyListeners();
        await _installDownloadedModelFromTask(update.task);
        return;
      case TaskStatus.failed:
      case TaskStatus.notFound:
        unawaited(
          _logToFile(
            'GEMMA DOWNLOAD UPDATE: Status=${update.status}, '
            'Exception=${update.exception}',
          ),
        );
        if (_autoResumeAttemptsRemaining > 0 && _downloadTask != null) {
          _autoResumeAttemptsRemaining--;
          final attempt = _maxAutoResumeAttempts - _autoResumeAttemptsRemaining;
          final backoffSeconds = (3 * (1 << (attempt - 1))).clamp(3, 60);
          unawaited(
            _logToFile(
              'GEMMA DOWNLOAD: Connection lost at '
              '${(_downloadProgress * 100).round()}%. '
              'Auto-resuming in ${backoffSeconds}s '
              '(attempt $attempt/$_maxAutoResumeAttempts)...',
            ),
          );
          _lastError = null;
          notifyListeners();
          await Future<void>.delayed(Duration(seconds: backoffSeconds));
          try {
            final canResume = await _downloader.taskCanResume(_downloadTask!);
            if (canResume) {
              final resumed = await _downloader.resume(_downloadTask!);
              if (resumed) {
                _status = GemmaModelStatus.downloading;
                notifyListeners();
                return;
              }
            }
            // Resume not available — re-enqueue a fresh task.
            // This is better than exhausting attempts because
            // background_downloader can still pick up the partial file.
            unawaited(
              _logToFile(
                'GEMMA DOWNLOAD: resume() not available on attempt $attempt '
                '(taskCanResume=$canResume). Waiting for user action.',
              ),
            );
            _status = GemmaModelStatus.error;
            _lastError =
                'The download connection dropped and could not resume automatically. Tap Resume to continue, or restart only if Resume fails.';
            notifyListeners();
            return;
          } catch (resumeError) {
            unawaited(_logToFile('GEMMA DOWNLOAD: Resume error: $resumeError'));
            if (_autoResumeAttemptsRemaining > 0) {
              unawaited(_retryAutoResume());
              return;
            }
          }
        }
        _status = GemmaModelStatus.error;
        _lastError = _mapDownloadError(update.exception ?? update.status);
        unawaited(
          _logToFile('GEMMA DOWNLOAD: Failed permanently: $_lastError'),
        );
        notifyListeners();
        return;
      case TaskStatus.canceled:
        unawaited(_logToFile('GEMMA DOWNLOAD: Task canceled.'));
        _status = GemmaModelStatus.error;
        _lastError = _mapDownloadError(update.exception ?? update.status);
        notifyListeners();
        return;
    }
  }

  Future<void> _retryAutoResume() async {
    if (_downloadTask == null || _autoResumeAttemptsRemaining <= 0) {
      _status = GemmaModelStatus.error;
      _lastError = 'All resume attempts exhausted. Tap "Resume" to try again.';
      notifyListeners();
      return;
    }

    _autoResumeAttemptsRemaining--;
    final attempt = _maxAutoResumeAttempts - _autoResumeAttemptsRemaining;
    final backoffSeconds = (3 * (1 << (attempt - 1))).clamp(3, 60);
    unawaited(
      _logToFile(
        'GEMMA DOWNLOAD: Retry auto-resume in ${backoffSeconds}s '
        '(attempt $attempt/$_maxAutoResumeAttempts)...',
      ),
    );

    await Future<void>.delayed(Duration(seconds: backoffSeconds));

    try {
      final canResume = await _downloader.taskCanResume(_downloadTask!);
      if (canResume) {
        final resumed = await _downloader.resume(_downloadTask!);
        if (resumed) {
          _status = GemmaModelStatus.downloading;
          notifyListeners();
          return;
        }
      }
      if (_autoResumeAttemptsRemaining > 0) {
        unawaited(_retryAutoResume());
      } else {
        _status = GemmaModelStatus.error;
        _lastError =
            'All resume attempts exhausted. Tap "Resume" to try again.';
        unawaited(_logToFile('GEMMA DOWNLOAD: All retry attempts exhausted.'));
        notifyListeners();
      }
    } catch (e) {
      unawaited(_logToFile('GEMMA DOWNLOAD: Retry error: $e'));
      if (_autoResumeAttemptsRemaining > 0) {
        unawaited(_retryAutoResume());
      } else {
        _status = GemmaModelStatus.error;
        _lastError =
            'All resume attempts exhausted. Tap "Resume" to try again.';
        notifyListeners();
      }
    }
  }

  static const int _minimumValidModelSizeBytes = 2000000000;

  Future<bool> _installDownloadedModelFromTask(Task task) async {
    try {
      final filePath = await task.filePath();
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Downloaded model file was not found on the device.');
      }
      final fileLength = await file.length();
      debugPrint('GEMMA: Downloaded file size: $fileLength bytes');

      if (fileLength < _minimumValidModelSizeBytes) {
        debugPrint(
          'GEMMA: File too small ($fileLength bytes), '
          'expected at least $_minimumValidModelSizeBytes. '
          'Deleting corrupted file.',
        );
        await file.delete();
        throw Exception(
          'Downloaded model file is too small '
          '(${(fileLength / 1024 / 1024).toStringAsFixed(0)} MB). '
          'The download may have been interrupted. '
          'Please try downloading again on a stable connection.',
        );
      }

      if (fileLength > 0) {
        _expectedFileSizeBytes = fileLength;
      }

      _status = GemmaModelStatus.installing;
      notifyListeners();

      await _verifyModelFileIntegrity(
        filePath,
        useCachedVerification: false,
        deleteOnFailure: true,
      );

      await _deleteGemmaEngineCaches(filePath);
      await _linkGemmaModel(filePath, logPrefix: 'GEMMA DOWNLOAD');

      debugPrint('GEMMA: Running post-install health check...');
      try {
        final backendLabel = await _runInstalledModelHealthCheck();
        debugPrint('GEMMA: Health check passed on $backendLabel.');
      } catch (healthError) {
        debugPrint('GEMMA: Health check FAILED: $healthError');
        throw Exception(
          'The model file passed integrity verification, but the Gemma engine '
          'could not start on this device. Do not re-download unless the '
          'SHA256 check fails. Engine error: $healthError',
        );
      }

      _status = GemmaModelStatus.ready;
      _downloadProgress = 1.0;
      _lastError = null;
      unawaited(_clearSavedDownloadProgress());
      notifyListeners();

      return true;
    } catch (e) {
      _status = GemmaModelStatus.error;
      _lastError =
          'Gemma finished downloading, but the model could not be prepared on this device. $e';
      debugPrint('GEMMA INSTALL ERROR: $_lastError');
      notifyListeners();
      return false;
    }
  }

  double? _setDownloadProgress(double value) {
    if (value.isNaN || value.isInfinite) {
      return null;
    }
    if (value < 0.0) {
      return null;
    }

    final normalized = value.clamp(0.0, 1.0).toDouble();

    if (normalized == _downloadProgress ||
        (normalized < _downloadProgress &&
            (_downloadProgress - normalized) < 0.01)) {
      return null;
    }

    if (normalized < _downloadProgress) {
      unawaited(
        _logToFile(
          'GEMMA DOWNLOAD: Progress reversed from '
          '${(_downloadProgress * 100).round()}% to ${(normalized * 100).round()}%. '
          'The server may not have supported resume, causing a restart.',
        ),
      );
    }

    _downloadProgress = normalized;
    return normalized;
  }

  Future<File> _downloadStateFile() async {
    final task = _downloadTask ?? _createDownloadTask();
    final statePath = await task.filePath(withFilename: _downloadStateFilename);
    return File(statePath);
  }

  DateTime? _lastProgressSaveTime;
  bool _isSavingProgress = false;

  Future<void> _saveDownloadProgress() async {
    if (_downloadProgress <= 0.0 || _downloadProgress >= 1.0) {
      return;
    }

    final now = DateTime.now();
    if (_lastProgressSaveTime != null &&
        now.difference(_lastProgressSaveTime!) < const Duration(seconds: 3)) {
      return;
    }

    if (_isSavingProgress) return;
    _isSavingProgress = true;

    try {
      _lastProgressSaveTime = now;
      final file = await _downloadStateFile();
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      await file.writeAsString(
        jsonEncode({
          'progress': _downloadProgress,
          'expectedFileSizeBytes': _expectedFileSizeBytes,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('GEMMA: Could not save download progress: $e');
    } finally {
      _isSavingProgress = false;
    }
  }

  Future<void> _restoreSavedDownloadProgress() async {
    try {
      final file = await _downloadStateFile();
      if (!await file.exists()) {
        return;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final savedProgressValue = decoded['progress'];
      final savedProgress = savedProgressValue is num
          ? savedProgressValue.toDouble().clamp(0.0, 1.0).toDouble()
          : null;
      if (savedProgress != null &&
          savedProgress > 0.0 &&
          savedProgress < 1.0 &&
          savedProgress > _downloadProgress) {
        _downloadProgress = savedProgress;
      }
      final expectedFileSizeValue = decoded['expectedFileSizeBytes'];
      if (expectedFileSizeValue is num && expectedFileSizeValue > 0) {
        _expectedFileSizeBytes = expectedFileSizeValue.toInt();
      }
    } catch (e) {
      debugPrint('GEMMA: Could not restore saved download progress: $e');
    }
  }

  Future<void> _clearSavedDownloadProgress() async {
    try {
      final file = await _downloadStateFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('GEMMA: Could not clear saved download progress: $e');
    }
  }

  String _formatMegabytes(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    if (megabytes >= 1000) {
      return megabytes.toStringAsFixed(0);
    }
    return megabytes.toStringAsFixed(1);
  }

  String _mapDownloadError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('401') || message.contains('authentication')) {
      return 'Model download failed because the source requires authentication.';
    }
    if (message.contains('404') || message.contains('not found')) {
      return 'Model download failed because the model file could not be found.';
    }
    if (message.contains('space') ||
        message.contains('storage') ||
        message.contains('disk') ||
        message.contains('filesystem')) {
      return 'Model download failed because the device may not have enough free storage.';
    }
    if (message.contains('resume')) {
      return 'The saved download could not be resumed. Start it again on a stable network.';
    }
    if (message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return 'Model download failed because the connection was interrupted. Try again on a stable network.';
    }
    return 'Model download failed. $error';
  }

  @visibleForTesting
  static String prepareDocumentTextForPrompt(
    String ocrText, {
    bool compact = false,
  }) {
    final normalized = _normalizePromptText(ocrText);
    final maxDocumentChars =
        compact ? _maxCompactDocumentPromptChars : _maxDocumentPromptChars;
    if (normalized.length <= maxDocumentChars) {
      return normalized;
    }

    final edgeChars = compact ? _compactPromptEdgeChars : _promptEdgeChars;
    final beginning = _clipPromptRange(normalized, 0, edgeChars);
    final ending = _clipPromptRange(
      normalized,
      normalized.length - edgeChars,
      normalized.length,
    );
    final riskExcerpts = _buildRiskFocusedExcerpts(
      normalized,
      compact: compact,
    );

    final sections = <String>[
      'Document excerpted for on-device context budget. Original length: ${normalized.length} characters. This is a risk-screening view, not a full legal reading of every omitted clause.',
      '--- BEGINNING OF DOCUMENT ---\n$beginning',
      if (riskExcerpts.isNotEmpty)
        '--- RISK-FOCUSED EXCERPTS FROM MIDDLE ---\n$riskExcerpts'
      else
        '--- RISK-FOCUSED EXCERPTS FROM MIDDLE ---\nNo known risk keywords were found in the omitted middle. Be explicit that the user may need a fuller review for long documents.',
      '--- END OF DOCUMENT ---\n$ending',
    ];

    return sections.join('\n\n').trim();
  }

  @visibleForTesting
  static String prepareUserContextForPrompt(
    String userContext, {
    bool compact = false,
  }) {
    final normalized = _normalizePromptText(userContext);
    final maxContextChars =
        compact ? _maxCompactContextPromptChars : _maxContextPromptChars;
    if (normalized.length <= maxContextChars) {
      return normalized;
    }

    final beginningChars = compact ? 210 : 500;
    final endingChars = compact ? 90 : 200;
    final beginning = _clipPromptRange(normalized, 0, beginningChars);
    final ending = _clipPromptRange(
      normalized,
      normalized.length - endingChars,
      normalized.length,
    );

    return '''
User context excerpted for on-device context budget. Original length: ${normalized.length} characters.

--- BEGINNING OF USER CONTEXT ---
$beginning

--- END OF USER CONTEXT ---
$ending
'''
        .trim();
  }

  static String _buildRiskFocusedExcerpts(String text, {bool compact = false}) {
    final lowerText = text.toLowerCase();
    final excerptRadius =
        compact ? _compactRiskExcerptRadiusChars : _riskExcerptRadiusChars;
    final maxExcerptChars =
        compact ? _maxCompactRiskExcerptChars : _maxRiskExcerptChars;
    final maxExcerptCount = compact ? 4 : 6;
    final terms = <String>{
      ..._guarantorTerms,
      ..._debtTerms,
      ..._waiverTerms,
      ..._collateralTerms,
      ..._pressureTerms,
      '____',
      '...',
    };
    final ranges = <({int start, int end})>[];

    for (final rawTerm in terms) {
      final term = _compactWhitespace(rawTerm).toLowerCase();
      if (term.isEmpty) {
        continue;
      }

      final index = lowerText.indexOf(term);
      if (index == -1) {
        continue;
      }

      ranges.add((
        start: _clampPromptIndex(index - excerptRadius, text.length),
        end: _clampPromptIndex(
          index + term.length + excerptRadius,
          text.length,
        ),
      ));
    }

    if (ranges.isEmpty) {
      return '';
    }

    ranges.sort((left, right) => left.start.compareTo(right.start));
    final merged = <({int start, int end})>[];
    for (final range in ranges) {
      if (merged.isEmpty || range.start > merged.last.end + 80) {
        merged.add(range);
        continue;
      }

      final last = merged.removeLast();
      merged.add((
        start: last.start,
        end: last.end > range.end ? last.end : range.end,
      ));
    }

    final buffer = StringBuffer();
    var count = 0;
    for (final range in merged) {
      final fragment = _clipPromptRange(text, range.start, range.end);
      if (fragment.isEmpty) {
        continue;
      }

      final nextExcerpt = '[excerpt ${count + 1}]\n$fragment';
      if (buffer.length + nextExcerpt.length > maxExcerptChars) {
        break;
      }
      if (count > 0) {
        buffer.writeln('\n---');
      }
      buffer.writeln(nextExcerpt);
      count += 1;
      if (count == maxExcerptCount) {
        break;
      }
    }

    return buffer.toString().trim();
  }

  static String _clipPromptRange(String text, int start, int end) {
    final safeStart = _clampPromptIndex(start, text.length);
    final safeEnd = _clampPromptIndex(end, text.length);
    if (safeEnd <= safeStart) {
      return '';
    }

    return text.substring(safeStart, safeEnd).trim();
  }

  static int _clampPromptIndex(int value, int length) {
    if (value < 0) {
      return 0;
    }
    if (value > length) {
      return length;
    }
    return value;
  }

  static String _normalizePromptText(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Map<String, dynamic> _parseGemmaJson(
    String rawText,
    AppCopy copy, {
    required String ocrText,
    required String userContext,
  }) {
    final trimmed = rawText.trim();

    try {
      final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
      return _normalizeAssessment(
        decoded,
        copy,
        ocrText: ocrText,
        userContext: userContext,
      );
    } catch (_) {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        throw const FormatException('Gemma did not return valid JSON.');
      }

      final decoded =
          jsonDecode(trimmed.substring(start, end + 1)) as Map<String, dynamic>;
      return _normalizeAssessment(
        decoded,
        copy,
        ocrText: ocrText,
        userContext: userContext,
      );
    }
  }

  Map<String, dynamic> _normalizeAssessment(
    Map<String, dynamic> parsed,
    AppCopy copy, {
    required String ocrText,
    required String userContext,
  }) {
    int riskScore = 5;
    final rawScore = parsed['risk_score'];
    if (rawScore is num) {
      riskScore = rawScore.round().clamp(1, 10);
    }

    List<Map<String, dynamic>> topRisks = [];
    final rawTopRisks = parsed['top_risks'];
    if (rawTopRisks is List) {
      for (final rawRisk in rawTopRisks) {
        if (rawRisk is Map) {
          final riskMap = rawRisk.cast<String, dynamic>();
          final rawQuestion = riskMap['question_to_ask']?.toString().trim();
          final evidence = _groundEvidence(
            rawEvidence: riskMap['evidence']?.toString() ?? '',
            primaryText: ocrText,
            secondaryText: userContext,
          );

          topRisks.add({
            'title': riskMap['title']?.toString() ?? copy.reviewRisk,
            'description':
                riskMap['description']?.toString() ?? copy.reviewRisk,
            'why_dangerous': riskMap['why_dangerous']?.toString().trim() ??
                riskMap['description']?.toString() ??
                copy.reviewRisk,
            'evidence': evidence.text,
            'evidence_source': evidence.source,
            'trust_level': _trustLevelForSource(evidence.source),
            'question_to_ask': rawQuestion != null && rawQuestion.isNotEmpty
                ? rawQuestion
                : copy.reviewRisk,
          });
        }
      }
    }

    final trustSnapshot = _buildTrustSnapshot(topRisks);
    final signals = detectRiskSignals(
      ocrText: ocrText,
      userContext: userContext,
    );
    final rawSaferNextStep = parsed['safer_next_step']?.toString().trim();

    return {
      'risk_score': riskScore,
      'risk_title':
          parsed['risk_title']?.toString() ?? copy.documentRiskAssessment,
      'top_risks': topRisks,
      'verdict_summary':
          parsed['verdict_summary']?.toString() ?? copy.reviewDocument,
      'safer_next_step': rawSaferNextStep != null && rawSaferNextStep.isNotEmpty
          ? rawSaferNextStep
          : copy.defaultSaferNextStep,
      'recommended_actions': _normalizeRecommendedActions(
        rawActions: parsed['recommended_actions'],
        copy: copy,
        signals: signals,
        riskScore: riskScore,
        groundedScenarioCount: trustSnapshot.groundedScenarioCount,
        gemmaReady: true,
      ),
      'language_detected':
          parsed['language_detected']?.toString() ?? copy.languageCode,
      'disclaimer': parsed['disclaimer']?.toString() ?? copy.aiRiskOnly,
      'grounding_count': trustSnapshot.groundedScenarioCount,
      'grounding_total': topRisks.length,
      'trust_level': trustSnapshot.level,
      'document_grounding_count': trustSnapshot.documentCount,
      'context_grounding_count': trustSnapshot.contextCount,
      'inferred_grounding_count': trustSnapshot.inferredCount,
      'unverified_grounding_count': trustSnapshot.unverifiedCount,
    };
  }

  Map<String, dynamic> _buildRulesBasedAssessment({
    required String ocrText,
    required String userContext,
    required String notice,
    required AppCopy copy,
  }) {
    final signals = detectRiskSignals(
      ocrText: ocrText,
      userContext: userContext,
    );
    final riskScore = signals.riskScore;
    final personalLiabilityEvidence = extractEvidenceSnippet(
      primaryText: ocrText,
      secondaryText: userContext,
      terms: _guarantorTerms,
    );
    final termsChangeEvidence = extractEvidenceSnippet(
      primaryText: ocrText,
      secondaryText: userContext,
      terms: _waiverTerms,
      preferBlankSpaces: signals.hasBlankSpaces,
    );
    final assetExposureEvidence = extractEvidenceSnippet(
      primaryText: ocrText,
      secondaryText: userContext,
      terms: _assetRiskTerms,
    );
    final liabilityGrounding = _groundEvidence(
      rawEvidence: personalLiabilityEvidence,
      primaryText: ocrText,
      secondaryText: userContext,
    );
    final termsGrounding = _groundEvidence(
      rawEvidence: termsChangeEvidence,
      primaryText: ocrText,
      secondaryText: userContext,
    );
    final assetGrounding = _groundEvidence(
      rawEvidence: assetExposureEvidence,
      primaryText: ocrText,
      secondaryText: userContext,
    );

    final title = riskScore >= 8
        ? copy.highRisk
        : riskScore >= 5
            ? copy.moderateRisk
            : copy.limitedRisk;
    List<Map<String, dynamic>> topRisks = [];

    if (signals.hasGuarantorTerms || riskScore >= 5) {
      topRisks.add({
        'title': copy.personalLiability,
        'description': signals.hasGuarantorTerms
            ? copy.personalLiabilityGuarantor
            : copy.personalLiabilityGeneric,
        'why_dangerous': signals.hasGuarantorTerms
            ? copy.personalLiabilityGuarantor
            : copy.personalLiabilityGeneric,
        'evidence': liabilityGrounding.text,
        'evidence_source': liabilityGrounding.source,
        'trust_level': _trustLevelForSource(liabilityGrounding.source),
        'question_to_ask': copy.personalLiabilityQuestion,
      });
    }

    if (signals.hasBlankSpaces || riskScore >= 7) {
      topRisks.add({
        'title': copy.termsChange,
        'description':
            signals.hasBlankSpaces ? copy.blankSpaces : copy.broadClauses,
        'why_dangerous':
            signals.hasBlankSpaces ? copy.blankSpaces : copy.broadClauses,
        'evidence': termsGrounding.text,
        'evidence_source': termsGrounding.source,
        'trust_level': _trustLevelForSource(termsGrounding.source),
        'question_to_ask': copy.termsChangeQuestion,
      });
    }

    if (topRisks.isEmpty && riskScore > 3) {
      topRisks.add({
        'title': copy.assetExposure,
        'description': signals.hasCollateralTerms || signals.hasDebtTerms
            ? copy.debtSignals
            : copy.financialDisputes,
        'why_dangerous': signals.hasCollateralTerms || signals.hasDebtTerms
            ? copy.debtSignals
            : copy.financialDisputes,
        'evidence': assetGrounding.text,
        'evidence_source': assetGrounding.source,
        'trust_level': _trustLevelForSource(assetGrounding.source),
        'question_to_ask': copy.assetExposureQuestion,
      });
    }

    final trustSnapshot = _buildTrustSnapshot(topRisks);

    return {
      'risk_score': riskScore,
      'risk_title': title,
      'top_risks': topRisks,
      'verdict_summary': copy.rulesSummary,
      'safer_next_step': copy.defaultSaferNextStep,
      'recommended_actions': _normalizeRecommendedActions(
        rawActions: null,
        copy: copy,
        signals: signals,
        riskScore: riskScore,
        groundedScenarioCount: trustSnapshot.groundedScenarioCount,
        gemmaReady: false,
      ),
      'language_detected': copy.languageCode,
      'disclaimer': copy.limitedOfflineDisclaimer,
      'analysis_mode': 'rules',
      'analysis_source': copy.limitedOffline,
      'analysis_notice': notice,
      'grounding_count': trustSnapshot.groundedScenarioCount,
      'grounding_total': 3,
      'trust_level': trustSnapshot.level,
      'document_grounding_count': trustSnapshot.documentCount,
      'context_grounding_count': trustSnapshot.contextCount,
      'inferred_grounding_count': trustSnapshot.inferredCount,
      'unverified_grounding_count': trustSnapshot.unverifiedCount,
    };
  }

  @override
  void dispose() {
    _downloadUpdatesSubscription?.cancel();
    super.dispose();
  }

  @visibleForTesting
  static RulesSignalSnapshot detectRiskSignals({
    required String ocrText,
    required String userContext,
  }) {
    final combined = '$ocrText\n$userContext'.toLowerCase();

    bool containsAny(List<String> terms) {
      for (final term in terms) {
        if (_containsTerm(combined, term)) {
          return true;
        }
      }
      return false;
    }

    return RulesSignalSnapshot(
      hasBlankSpaces: ocrText.contains('____') || ocrText.contains('...'),
      hasGuarantorTerms: containsAny(_guarantorTerms),
      hasDebtTerms: containsAny(_debtTerms),
      hasWaiverTerms: containsAny(_waiverTerms),
      hasCollateralTerms: containsAny(_collateralTerms),
      mentionsPressure: containsAny(_pressureTerms),
    );
  }

  @visibleForTesting
  static List<String> recommendActionIds({
    required RulesSignalSnapshot signals,
    required int riskScore,
    required int groundedScenarioCount,
    required bool gemmaReady,
  }) {
    final actions = <String>[];

    if (riskScore >= 7 ||
        signals.hasGuarantorTerms ||
        signals.hasCollateralTerms ||
        signals.hasWaiverTerms) {
      actions.add('open_legal_help');
    }

    if (signals.hasBlankSpaces || groundedScenarioCount <= 1) {
      actions.add('review_document_again');
    }

    if (riskScore >= 4 || signals.mentionsPressure || signals.hasDebtTerms) {
      actions.add('copy_questions');
    }

    if (!gemmaReady) {
      actions.add('set_up_gemma');
    }

    if (actions.isEmpty) {
      actions.addAll(['review_document_again', 'copy_questions']);
    }

    return actions.toSet().take(3).toList(growable: false);
  }

  @visibleForTesting
  static String trustLevelForSources(Iterable<String> sources) {
    final values =
        sources.map((source) => source.trim()).toList(growable: false);
    if (values.isEmpty) {
      return 'caution';
    }
    final documentCount = values.where((source) => source == 'document').length;
    final groundedCount = values
        .where((source) => source == 'document' || source == 'context')
        .length;

    if (documentCount >= 2 || groundedCount == values.length) {
      return 'grounded';
    }
    if (groundedCount >= 2) {
      return 'mixed';
    }
    return 'caution';
  }

  @visibleForTesting
  static String jurisdictionHintFor(String locationContext) {
    final normalized = locationContext.trim().toUpperCase();
    if (normalized.endsWith('-EG') || normalized.endsWith('-AE')) {
      return 'Give extra attention to guarantor liability, debt acknowledgements, blank amounts, salary deductions, enforcement wording, and Arabic financial terms.';
    }
    if (normalized.endsWith('-IN')) {
      return 'Give extra attention to guarantor wording, debt promises, blank fields, arbitration, salary recovery, and one-sided undertakings.';
    }
    if (normalized.endsWith('-US') || normalized.endsWith('-GB')) {
      return 'Give extra attention to personal guarantees, arbitration, fee shifting, waiver clauses, broad indemnities, and collateral language.';
    }
    return 'Give extra attention to personal guarantees, blank fields, debt, waivers, collateral, salary deductions, and vague obligations.';
  }

  static String _countryCodeHintFromLocale(String localeTag) {
    final normalized = localeTag.replaceAll('_', '-').trim();
    final parts = normalized.split('-');
    if (parts.length < 2) {
      return 'Country hint unavailable. Be explicit about uncertainty and avoid pretending to know the user\'s jurisdiction.';
    }

    final countryCode = parts[1].toUpperCase();
    return 'Country hint from device locale: $countryCode. Use it only as a weak legal-context hint, not as proof of jurisdiction.';
  }

  @visibleForTesting
  static String extractEvidenceSnippet({
    required String primaryText,
    required String secondaryText,
    required List<String> terms,
    bool preferBlankSpaces = false,
  }) {
    if (preferBlankSpaces) {
      final blankPrimary = _extractBlankSpacesSnippet(primaryText);
      if (blankPrimary.isNotEmpty) {
        return blankPrimary;
      }
      final blankSecondary = _extractBlankSpacesSnippet(secondaryText);
      if (blankSecondary.isNotEmpty) {
        return blankSecondary;
      }
    }

    for (final source in [primaryText, secondaryText]) {
      final snippet = _extractTermSnippet(source, terms);
      if (snippet.isNotEmpty) {
        return snippet;
      }
    }

    return '';
  }

  List<Map<String, String>> _normalizeRecommendedActions({
    required dynamic rawActions,
    required AppCopy copy,
    required RulesSignalSnapshot signals,
    required int riskScore,
    required int groundedScenarioCount,
    required bool gemmaReady,
  }) {
    const allowedIds = {
      'open_legal_help',
      'copy_questions',
      'review_document_again',
      'set_up_gemma',
    };
    final actions = <Map<String, String>>[];

    if (rawActions is List) {
      for (final rawAction in rawActions) {
        if (rawAction is! Map) {
          continue;
        }

        final actionMap = rawAction.cast<String, dynamic>();
        final actionId = actionMap['action_id']?.toString().trim() ?? '';
        if (!allowedIds.contains(actionId) ||
            actions.any((action) => action['action_id'] == actionId)) {
          continue;
        }

        final rawReason = actionMap['reason']?.toString().trim();
        final priority =
            actionMap['priority']?.toString().trim().toLowerCase() == 'primary'
                ? 'primary'
                : 'secondary';
        actions.add({
          'action_id': actionId,
          'reason': rawReason != null && rawReason.isNotEmpty
              ? rawReason
              : _defaultActionReason(copy, actionId),
          'priority': priority,
        });
      }
    }

    for (final actionId in recommendActionIds(
      signals: signals,
      riskScore: riskScore,
      groundedScenarioCount: groundedScenarioCount,
      gemmaReady: gemmaReady,
    )) {
      if (actions.any((action) => action['action_id'] == actionId)) {
        continue;
      }

      actions.add({
        'action_id': actionId,
        'reason': _defaultActionReason(copy, actionId),
        'priority': actions.isEmpty ? 'primary' : 'secondary',
      });

      if (actions.length == 3) {
        break;
      }
    }

    actions.sort((left, right) {
      final leftWeight = left['priority'] == 'primary' ? 0 : 1;
      final rightWeight = right['priority'] == 'primary' ? 0 : 1;
      return leftWeight.compareTo(rightWeight);
    });

    for (var index = 0; index < actions.length; index++) {
      actions[index] = {
        ...actions[index],
        'priority': index == 0 ? 'primary' : 'secondary',
      };
    }

    return actions.take(3).toList(growable: false);
  }

  static String _defaultActionReason(AppCopy copy, String actionId) {
    return switch (actionId) {
      'open_legal_help' => copy.openLegalHelpActionReason,
      'copy_questions' => copy.copyQuestionsActionReason,
      'review_document_again' => copy.reviewDocumentAgainActionReason,
      'set_up_gemma' => copy.setUpGemmaActionReason,
      _ => copy.reviewDocumentAgainActionReason,
    };
  }

  static String _trustLevelForSource(String source) {
    return switch (source) {
      'document' => 'grounded',
      'context' => 'contextual',
      'model' => 'inferred',
      _ => 'unverified',
    };
  }

  static _TrustSnapshot _buildTrustSnapshot(
    List<Map<String, dynamic>> scenarios,
  ) {
    var documentCount = 0;
    var contextCount = 0;
    var inferredCount = 0;
    var unverifiedCount = 0;
    final evidenceSources = <String>[];

    for (final scenario in scenarios) {
      final evidenceSource =
          scenario['evidence_source']?.toString().trim() ?? 'none';
      evidenceSources.add(evidenceSource);

      switch (evidenceSource) {
        case 'document':
          documentCount += 1;
          break;
        case 'context':
          contextCount += 1;
          break;
        case 'model':
          inferredCount += 1;
          break;
        default:
          unverifiedCount += 1;
          break;
      }
    }

    return _TrustSnapshot(
      level: trustLevelForSources(evidenceSources),
      documentCount: documentCount,
      contextCount: contextCount,
      inferredCount: inferredCount,
      unverifiedCount: unverifiedCount,
    );
  }

  static _GroundedEvidence _groundEvidence({
    required String rawEvidence,
    required String primaryText,
    required String secondaryText,
  }) {
    final compactEvidence = _compactWhitespace(
      rawEvidence.replaceAll('"', '').replaceAll("'", ''),
    );
    if (compactEvidence.isEmpty) {
      return const _GroundedEvidence(text: '', source: 'none');
    }

    final candidates = <String>{compactEvidence};
    for (final fragment in compactEvidence.split('...')) {
      final cleaned = _compactWhitespace(fragment);
      if (cleaned.length >= 6) {
        candidates.add(cleaned);
      }
    }
    for (final fragment in compactEvidence.split(RegExp(r'[,:;()\[\]]'))) {
      final cleaned = _compactWhitespace(fragment);
      if (cleaned.length >= 6) {
        candidates.add(cleaned);
      }
    }

    final orderedCandidates = candidates.toList()
      ..sort((left, right) => right.length.compareTo(left.length));
    final sources = [
      ('document', _compactWhitespace(primaryText)),
      ('context', _compactWhitespace(secondaryText)),
    ];

    for (final candidate in orderedCandidates) {
      final candidateLower = candidate.toLowerCase();
      for (final (source, compactText) in sources) {
        if (compactText.isEmpty) {
          continue;
        }

        final matchIndex = compactText.toLowerCase().indexOf(candidateLower);
        if (matchIndex != -1) {
          return _GroundedEvidence(
            text: _limitSnippet(compactText, matchIndex),
            source: source,
          );
        }
      }
    }

    return _GroundedEvidence(text: compactEvidence, source: 'model');
  }

  static String _extractBlankSpacesSnippet(String text) {
    if (text.trim().isEmpty) {
      return '';
    }

    final lines = text.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final compact = _compactWhitespace(line);
      if (compact.contains('____') || compact.contains('...')) {
        final blankIndex = compact.indexOf('____');
        final dotsIndex = compact.indexOf('...');
        final matchIndex = blankIndex != -1 ? blankIndex : dotsIndex;
        if (matchIndex != -1) {
          return _limitSnippet(compact, matchIndex);
        }
      }
    }

    final compact = _compactWhitespace(text);
    final blankIndex = compact.indexOf('____');
    if (blankIndex != -1) {
      return _limitSnippet(compact, blankIndex);
    }
    final dotsIndex = compact.indexOf('...');
    if (dotsIndex != -1) {
      return _limitSnippet(compact, dotsIndex);
    }
    return '';
  }

  static String _extractTermSnippet(String text, List<String> terms) {
    final compact = _compactWhitespace(text);
    if (compact.isEmpty) {
      return '';
    }

    var bestIndex = -1;
    for (final term in terms) {
      final index = _findTermIndex(compact, term);
      if (index != -1 && (bestIndex == -1 || index < bestIndex)) {
        bestIndex = index;
      }
    }

    if (bestIndex == -1) {
      return '';
    }

    return _limitSnippet(compact, bestIndex);
  }

  static bool _containsTerm(String text, String term) {
    return _findTermIndex(text, term) != -1;
  }

  static int _findTermIndex(String text, String term) {
    final compactText = _compactWhitespace(text).toLowerCase();
    final compactTerm = _compactWhitespace(term).toLowerCase();
    if (compactText.isEmpty || compactTerm.isEmpty) {
      return -1;
    }

    if (!_requiresBoundaryCheck(compactTerm)) {
      return compactText.indexOf(compactTerm);
    }

    var searchStart = 0;
    while (true) {
      final index = compactText.indexOf(compactTerm, searchStart);
      if (index == -1) {
        return -1;
      }

      final beforeIsBoundary =
          index == 0 || !_isWordLikeCharacter(compactText[index - 1]);
      final afterIndex = index + compactTerm.length;
      final afterIsBoundary = afterIndex >= compactText.length ||
          !_isWordLikeCharacter(compactText[afterIndex]);

      if (beforeIsBoundary && afterIsBoundary) {
        return index;
      }

      searchStart = index + 1;
    }
  }

  static bool _requiresBoundaryCheck(String term) {
    if (term.contains(' ')) {
      return false;
    }

    return !RegExp(r'[\u4E00-\u9FFF]').hasMatch(term);
  }

  static bool _isWordLikeCharacter(String character) {
    return RegExp(
      r'[A-Za-z0-9\u00C0-\u024F\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\u0900-\u097F]',
    ).hasMatch(character);
  }

  static String _limitSnippet(String text, int matchIndex) {
    if (text.length <= 140) {
      return text;
    }

    var start = matchIndex - 45;
    if (start < 0) {
      start = 0;
    }
    var end = matchIndex + 95;
    if (end > text.length) {
      end = text.length;
    }

    var snippet = text.substring(start, end).trim();
    if (start > 0) {
      snippet = '...$snippet';
    }
    if (end < text.length) {
      snippet = '$snippet...';
    }
    return snippet;
  }

  static String _compactWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _GemmaInferenceResult {
  const _GemmaInferenceResult({
    required this.responseText,
    required this.backendLabel,
  });

  final String responseText;
  final String backendLabel;
}

class _GroundedEvidence {
  const _GroundedEvidence({required this.text, required this.source});

  final String text;
  final String source;
}

class _TrustSnapshot {
  const _TrustSnapshot({
    required this.level,
    required this.documentCount,
    required this.contextCount,
    required this.inferredCount,
    required this.unverifiedCount,
  });

  final String level;
  final int documentCount;
  final int contextCount;
  final int inferredCount;
  final int unverifiedCount;

  int get groundedScenarioCount => documentCount + contextCount;
}

@immutable
class RulesSignalSnapshot {
  const RulesSignalSnapshot({
    required this.hasBlankSpaces,
    required this.hasGuarantorTerms,
    required this.hasDebtTerms,
    required this.hasWaiverTerms,
    required this.hasCollateralTerms,
    required this.mentionsPressure,
  });

  final bool hasBlankSpaces;
  final bool hasGuarantorTerms;
  final bool hasDebtTerms;
  final bool hasWaiverTerms;
  final bool hasCollateralTerms;
  final bool mentionsPressure;

  int get riskScore {
    var value = 2;
    if (hasBlankSpaces) value += 2;
    if (hasGuarantorTerms) value += 2;
    if (hasDebtTerms) value += 2;
    if (hasWaiverTerms) value += 2;
    if (hasCollateralTerms) value += 1;
    if (mentionsPressure) value += 1;
    return value.clamp(1, 10);
  }
}
