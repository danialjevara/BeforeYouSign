import 'dart:async';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_copy.dart';
import '../models/analysis_data.dart';
import '../services/gemma_service.dart';
import '../services/ocr_service.dart';
import '../services/permission_service.dart';
import '../services/voice_service.dart';

enum _CaptureStep { document, context }

enum _CaptureMode { printed, handwriting }

class CaptureHubScreen extends ConsumerStatefulWidget {
  const CaptureHubScreen({super.key});

  @override
  ConsumerState<CaptureHubScreen> createState() => _CaptureHubScreenState();
}

class _CaptureHubScreenState extends ConsumerState<CaptureHubScreen> {
  bool _isAnalyzing = false;
  bool _isCapturing = false;
  bool _isPreparingCamera = false;
  bool _isFlashOn = false;
  bool _isCameraInitialized = false;
  bool _isListening = false;
  _CaptureStep _step = _CaptureStep.document;
  _CaptureMode _captureMode = _CaptureMode.printed;
  bool _showCaptureIntro = false;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  final _ocrService = OcrService();
  final TextEditingController _documentTextController = TextEditingController();

  // ignore: unused_field
  String? _capturedImagePath;
  OcrResult? _ocrResult;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    unawaited(ref.read(voiceServiceProvider).stopListening());
    _cameraController?.dispose();
    _ocrService.dispose();
    _documentTextController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera({bool force = false}) async {
    if (_isPreparingCamera) {
      return;
    }
    if (!force && _cameraController != null && _isCameraInitialized) {
      return;
    }

    if (mounted) {
      setState(() {
        _isPreparingCamera = true;
      });
    } else {
      _isPreparingCamera = true;
    }

    final hasPermission = await PermissionService.requestCameraPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _isPreparingCamera = false;
        });
      } else {
        _isPreparingCamera = false;
      }
      return;
    }

    try {
      if (force) {
        await _releaseCamera();
      }

      _cameras ??= await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _isPreparingCamera = false;
          });
        } else {
          _isPreparingCamera = false;
        }
        return;
      }

      final selectedCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _isPreparingCamera = false;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isPreparingCamera = false;
          _isFlashOn = false;
        });
      } else {
        _isCameraInitialized = false;
        _isPreparingCamera = false;
        _isFlashOn = false;
      }
    }
  }

  Future<void> _releaseCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;
    _isFlashOn = false;
    await controller?.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startTypedMode() async {
    await _stopVoiceInput();
    await _releaseCamera();
    if (!mounted) {
      return;
    }

    setState(() {
      _step = _CaptureStep.context;
      _capturedImagePath = null;
      _ocrResult = null;
      _isAnalyzing = false;
    });
  }

  Future<void> _beginCameraCapture() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _showCaptureIntro = false;
    });

    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) {
      return;
    }

    try {
      final nextFlashState = !_isFlashOn;
      await _cameraController!.setFlashMode(
        nextFlashState ? FlashMode.torch : FlashMode.off,
      );
      setState(() {
        _isFlashOn = nextFlashState;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
      _showMessage(_flashUnavailableText());
    }
  }

  Future<void> _captureDocument() async {
    final copy = AppCopy.of(context);
    final localeTag = context.localeTag;
    if (_isCapturing) {
      return;
    }
    if (_cameraController == null || !_isCameraInitialized) {
      _showMessage(copy.cameraNotReady);
      if (!_isPreparingCamera) {
        await _initializeCamera(force: true);
      }
      return;
    }

    XFile? capturedFile;
    setState(() {
      _isCapturing = true;
    });

    try {
      capturedFile = await _cameraController!.takePicture();

      if (_isFlashOn) {
        await _toggleFlash();
      }

      await _releaseCamera();

      final ocrResult = await _ocrService
          .processImage(
            capturedFile.path,
            localeTag: localeTag,
            preferHandwriting: _captureMode == _CaptureMode.handwriting,
          )
          .timeout(
            const Duration(seconds: 25),
            onTimeout: () => throw OcrException(
              'Document text extraction took too long. Paste or type the text to continue.',
            ),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _step = _CaptureStep.context;
        _capturedImagePath = ocrResult.previewImagePath;
        _ocrResult = ocrResult;
        _documentTextController.text = ocrResult.fullText.trim();
      });
    } on OcrException catch (e) {
      if (!mounted) {
        return;
      }

      await _releaseCamera();

      setState(() {
        _step = _CaptureStep.context;
        _capturedImagePath = capturedFile?.path;
        _ocrResult = null;
        _documentTextController.clear();
      });
      _showMessage(copy.addTextManually(e.message));
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (!mounted) {
        return;
      }

      _showMessage(copy.captureFailed);
      await _startTypedMode();
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final copy = AppCopy.of(context);
    final localeTag = context.localeTag;
    
    if (_isCapturing) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User canceled
      }

      final imagePath = result.files.single.path;
      if (imagePath == null) return;

      setState(() {
        _isCapturing = true;
      });

      await _releaseCamera();

      final ocrResult = await _ocrService
          .processImage(
            imagePath,
            localeTag: localeTag,
            preferHandwriting: _captureMode == _CaptureMode.handwriting,
          )
          .timeout(
            const Duration(seconds: 25),
            onTimeout: () => throw OcrException(
              'Document text extraction took too long. Paste or type the text to continue.',
            ),
          );

      if (!mounted) return;

      setState(() {
        _step = _CaptureStep.context;
        _capturedImagePath = ocrResult.previewImagePath;
        _ocrResult = ocrResult;
        _documentTextController.text = ocrResult.fullText.trim();
      });
    } on OcrException catch (e) {
      if (!mounted) return;

      setState(() {
        _step = _CaptureStep.context;
        _ocrResult = null;
        _documentTextController.clear();
      });
      _showMessage(copy.addTextManually(e.message));
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (!mounted) return;

      _showMessage(copy.captureFailed);
      await _startTypedMode();
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _retakeDocument() async {
    await _stopVoiceInput();
    await _releaseCamera();
    if (!mounted) {
      return;
    }

    setState(() {
      _step = _CaptureStep.document;
      _showCaptureIntro = false;
      _capturedImagePath = null;
      _documentTextController.clear();
      _isAnalyzing = false;
      _isCapturing = false;
      _ocrResult = null;
    });
    await _initializeCamera(force: true);
  }

  Future<void> _startAnalysis() async {
    final copy = AppCopy.of(context);
    final documentText = _documentTextController.text.trim();
    if (documentText.isEmpty) {
      _showMessage(copy.addDocumentText);
      return;
    }

    await _stopVoiceInput();
    if (!mounted) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    final analysisData = AnalysisData(
      ocrText: documentText,
      userContext: copy.noContextProvided,
      preference: AnalysisPreference.gemmaOnly,
    );

    await context.push('/verdict', extra: analysisData);
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _stopVoiceInput() async {
    final voiceService = ref.read(voiceServiceProvider);
    if (voiceService.isListening) {
      await voiceService.stopListening();
    }

    if (!mounted || !_isListening) {
      return;
    }

    setState(() {
      _isListening = false;
    });
  }

  Future<void> _startVoiceHold() async {
    await _toggleVoiceInput();
  }

  Future<void> _toggleVoiceInput() async {
    final voiceService = ref.read(voiceServiceProvider);
    final copy = AppCopy.of(context);

    if (_isListening) {
      await _stopVoiceInput();
      return;
    }

    final hasPermission = await PermissionService.requestMicrophonePermission();
    if (!hasPermission) {
      _showMessage(copy.microphonePermission);
      return;
    }

    final deviceLocale =
        WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    final speechLocale =
        await voiceService.resolveBestSpeechLocale(deviceLocale);
    if (speechLocale == null) {
      _showMessage(copy.speechNotAvailable);
      return;
    }

    final initialText = _documentTextController.text.trim();

    final started = await voiceService.startListening(
      localeId: speechLocale,
      onStatus: (status) {
        if (!mounted) {
          return;
        }
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isListening = false;
        });
        if (error.errorMsg != 'error_no_match' &&
            error.errorMsg != 'error_speech_timeout') {
          _showMessage(copy.speechCouldNotStart);
        }
      },
      onResult: (text, finalResult) {
        if (!mounted) {
          return;
        }

        final newText = initialText.isEmpty ? text : '$initialText\n$text';
        _documentTextController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );

        if (finalResult) {
          setState(() {
            _isListening = false;
          });
        }
      },
    );

    if (!mounted) {
      return;
    }

    if (!started) {
      _showMessage(copy.speechCouldNotStart);
      return;
    }

    setState(() {
      _isListening = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gemma = ref.watch(gemmaServiceProvider);
    final copy = AppCopy.of(context);

    return PopScope(
      canPop: _step == _CaptureStep.document,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            _step = _CaptureStep.document;
            _showCaptureIntro = true;
          });
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF020617)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(copy, gemma),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _step == _CaptureStep.document
                              ? _buildDocumentStep(copy)
                              : _buildContextStep(copy, gemma.isReady),
                        ),
                      ),
                      if (_isCapturing)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Color(0xFFFFB300),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _captureProcessingText(copy),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveCaptureArea() {
    final copy = AppCopy.of(context);
    if (_isPreparingCamera) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFFB300)),
            const SizedBox(height: 16),
            Text(
              _cameraPreparingText(),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_isCameraInitialized && _cameraController != null) {
      return CameraPreview(_cameraController!);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.document_scanner_outlined,
          size: 72,
          color: Colors.white.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 16),
        Text(
          copy.pointCamera,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            copy.cameraNotReady,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(AppCopy copy, GemmaService gemma) {
    final gemmaReady = gemma.isReady;
    final gemmaBusy = gemma.isDownloading || gemma.isPaused;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFFFB300), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Color(0xFFFFB300), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              copy.privateAnalysis,
              style: const TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (gemmaReady)
            _buildStatusChip(
              icon: Icons.auto_awesome,
              label: copy.gemmaReadyShort,
              color: const Color(0xFF4CAF50),
            )
          else if (gemmaBusy)
            TextButton.icon(
              onPressed: () => context.push('/gemma-setup'),
              icon: Icon(
                gemma.isPaused
                    ? Icons.pause_circle_outline
                    : Icons.downloading_rounded,
                size: 18,
                color: const Color(0xFF64B5F6),
              ),
              label: Text(
                copy.gemmaDownloadStatusChip(
                  (gemma.downloadProgress * 100).round().clamp(0, 100),
                ),
                style: const TextStyle(
                  color: Color(0xFF64B5F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => context.push('/gemma-setup'),
              child: Text(
                copy.enableGemmaShort,
                style: const TextStyle(
                  color: Color(0xFF64B5F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentStep(AppCopy copy) {
    if (_showCaptureIntro) {
      return _buildCaptureIntro(copy);
    }

    return _buildLiveDocumentCapture(copy);
  }

  Widget _buildCaptureIntro(AppCopy copy) {
    return SingleChildScrollView(
      key: const ValueKey('capture-intro'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusChip(
                icon: Icons.looks_one_rounded,
                label: _stepLabel(1),
                color: const Color(0xFF64B5F6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _captureStageTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _captureStageBody(),
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildCaptureGuidance(),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _beginCameraCapture,
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(
                _startCameraLabel(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.image_outlined),
              label: Text(copy.selectFromGallery),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _startTypedMode,
              icon: const Icon(Icons.keyboard_alt_outlined),
              label: Text(copy.typeDocumentInstead),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDocumentCapture(AppCopy copy) {
    return Stack(
      key: const ValueKey('document-live'),
      fit: StackFit.expand,
      children: [
        _buildLiveCaptureArea(),
        Positioned(top: 80, left: 24, child: _buildCorner(0)),
        Positioned(top: 80, right: 24, child: _buildCorner(1)),
        Positioned(bottom: 140, left: 24, child: _buildCorner(2)),
        Positioned(bottom: 140, right: 24, child: _buildCorner(3)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () async {
                      setState(() {
                        _showCaptureIntro = true;
                      });
                      await _releaseCamera();
                    },
                    tooltip: _captureTipsTitle(),
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Opacity(
                        opacity: 0.85,
                        child: _buildCaptureModeSelector(copy),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: !_isCameraInitialized || _isPreparingCamera
                        ? null
                        : _toggleFlash,
                    tooltip: _flashButtonLabel(),
                    icon: Icon(
                      _isFlashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color:
                          _isFlashOn ? const Color(0xFFFFB300) : Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildLiveCameraControls(copy),
        ),
      ],
    );
  }

  Widget _buildLiveCameraControls(AppCopy copy) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _isCapturing ? null : _pickImageFromGallery,
                  icon: const Icon(Icons.image_outlined, color: Colors.white, size: 32),
                  tooltip: copy.selectFromGallery,
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap:
                      _isPreparingCamera || _isCapturing ? null : _captureDocument,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _isCapturing ? Colors.grey : const Color(0xFFFFB300),
                        shape: BoxShape.circle,
                      ),
                      child: _isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 64), // Balance the flex
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _isCapturing ? null : _startTypedMode,
              icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
              label: Text(copy.typeDocumentInstead),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextStep(AppCopy copy, bool gemmaReady) {
    return SingleChildScrollView(
      key: const ValueKey('context-step'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusChip(
                icon: Icons.looks_two_rounded,
                label: _stepLabel(2),
                color: const Color(0xFF64B5F6),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _retakeDocument,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(copy.retake),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64B5F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _reviewStageTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (_ocrResult != null &&
              (_ocrResult!.quality != OcrQuality.good ||
                  _ocrResult!.notices.isNotEmpty)) ...[
            _buildOcrQualityCard(_ocrResult!),
            const SizedBox(height: 12),
          ],
          _buildSectionCard(
            title: copy.documentText,
            trailing: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _startVoiceHold(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? const Color(0xFFFFB300)
                      : const Color(0xFF64B5F6).withValues(alpha: 0.15),
                  border: Border.all(
                    color: _isListening
                        ? const Color(0xFFFFB300)
                        : const Color(0xFF64B5F6).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.black : const Color(0xFF64B5F6),
                  size: 20,
                ),
              ),
            ),
            child: TextField(
              controller: _documentTextController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: copy.typeOrTapSpeak,
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 8,
              minLines: 4,
            ),
          ),
          const SizedBox(height: 14),
          if (gemmaReady) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _startAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isAnalyzing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        copy.analyzeWithGemma,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    String? helper,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (helper != null && helper.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              helper,
              style: const TextStyle(
                color: Colors.white54,
                height: 1.35,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _stepLabel(int currentStep) {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => 'الخطوة $currentStep من 2',
      'hi' => 'चरण $currentStep / 2',
      'zh' => '第 $currentStep / 2 步',
      _ => 'Step $currentStep of 2',
    };
  }

  String _captureStageTitle() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => 'التقط المستند أولًا',
      'hi' => 'पहले दस्तावेज़ कैप्चर करें',
      'zh' => '先拍摄文件',
      _ => 'Capture the document first',
    };
  }

  String _captureStageBody() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => 'التقط الصورة أولاً، ثم أضف السياق.',
      'hi' =>
        'फोटो लेने के बाद कैमरा बंद हो जाएगा, फिर आप टेक्स्ट की समीक्षा करके संदर्भ बोल या लिख सकेंगे।',
      'zh' => '拍照后相机会自动释放，然后你可以检查文本并通过语音或文字补充上下文。',
      _ => 'Capture the photo, then add context.',
    };
  }

  String _startCameraLabel() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => 'ابدأ الكاميرا',
      'hi' => 'कैमरा शुरू करें',
      'zh' => '启动相机',
      _ => 'Start camera',
    };
  }

  String _reviewStageTitle() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => 'راجع النص ثم أضف السياق',
      'hi' => 'टेक्स्ट जाँचें, फिर संदर्भ जोड़ें',
      'zh' => '检查文本，然后补充上下文',
      _ => 'Review the text, then add context',
    };
  }

  String _flashButtonLabel() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => _isFlashOn ? 'إطفاء الفلاش' : 'تشغيل الفلاش',
      'hi' => _isFlashOn ? 'फ्लैश बंद' : 'फ्लैश चालू',
      'zh' => _isFlashOn ? '关闭闪光灯' : '打开闪光灯',
      _ => _isFlashOn ? 'Flash off' : 'Flash on',
    };
  }

  String _flashUnavailableText() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => 'الفلاش غير متاح على هذا الجهاز أو في وضع التصوير الحالي.',
      'hi' => 'इस डिवाइस या इस कैमरा मोड में फ्लैश उपलब्ध नहीं है।',
      'zh' => '当前设备或当前拍摄模式不支持闪光灯。',
      _ =>
        'Flash is not available on this device or in the current capture mode.',
    };
  }

  String _cameraPreparingText() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => 'جارٍ تجهيز الكاميرا...',
      'hi' => 'कैमरा तैयार किया जा रहा है...',
      'zh' => '正在准备相机...',
      _ => 'Preparing the camera...',
    };
  }



  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureGuidance() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _captureTipsTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ..._captureTips().map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureModeSelector(AppCopy copy) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCaptureModeChip(
              icon: Icons.description_outlined,
              label: copy.printedModeLabel,
              selected: _captureMode == _CaptureMode.printed,
              onTap: () {
                setState(() {
                  _captureMode = _CaptureMode.printed;
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildCaptureModeChip(
              icon: Icons.draw_outlined,
              label: copy.handwritingModeLabel,
              selected: _captureMode == _CaptureMode.handwriting,
              onTap: () {
                setState(() {
                  _captureMode = _CaptureMode.handwriting;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureModeChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFB300).withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFFB300) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? const Color(0xFFFFB300) : Colors.white70,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? const Color(0xFFFFB300) : Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrQualityCard(OcrResult result) {
    final color = _ocrQualityColor(result.quality);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _ocrQualityHeadline(result.quality),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildStatusChip(
                icon: Icons.analytics_outlined,
                label: '${result.qualityScore}/100',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _ocrQualitySummary(result),
            style: const TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          if (result.notices.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...result.notices.map(
              (notice) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chevron_right, color: color, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _noticeText(notice),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (result.needsRetake) ...[
            const SizedBox(height: 10),
            Text(
              _retakeRecommendation(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _captureProcessingText(AppCopy copy) {
    return switch (copy.languageCode) {
      'ar' => 'جارٍ تحسين الصورة وقراءة النص...',
      'hi' => 'छवि सुधारी जा रही है और टेक्स्ट पढ़ा जा रहा है...',
      'zh' => '正在增强图像并读取文本...',
      _ => 'Improving the image and reading text...',
    };
  }

  String _captureTipsTitle() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => 'لأفضل قراءة للنص',
      'hi' => 'बेहतर OCR के लिए',
      'zh' => '为了更好的 OCR',
      _ => 'For better OCR',
    };
  }

  List<String> _captureTips() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => const [
          'اجعل الورقة تملأ أغلب الإطار مع ظهور الزوايا الأربع.',
          'تجنب اللمعان والظلال، واستخدم الفلاش فقط عند الحاجة.',
          'اقترب بما يكفي حتى تكون السطور واضحة قبل الالتقاط.',
          'للنص المكتوب باليد، قرّب منطقة الكتابة أكثر وحاول أن يكون الحبر داكنًا وواضحًا.',
        ],
      'hi' => const [
          'दस्तावेज़ को फ्रेम का अधिकांश भाग भरने दें और चारों कोने दिखाएँ।',
          'चमक और छाया से बचें, और फ्लैश केवल ज़रूरत पर ही उपयोग करें।',
          'इतना पास आएँ कि लाइनें साफ दिखें, फिर फोटो लें।',
          'हाथ से लिखे टेक्स्ट के लिए लिखावट वाले हिस्से को और पास रखें और गहरी स्याही बेहतर होती है।',
        ],
      'zh' => const [
          '让文件尽量填满画面，并确保四个角都可见。',
          '避免反光和阴影，只在必要时打开闪光灯。',
          '靠近一些，确保文字行清晰后再拍摄。',
          '如果是手写文字，请让书写区域更靠近镜头，并尽量保证笔迹更深更清晰。',
        ],
      _ => const [
          'Fill most of the frame with the page and keep all four corners visible.',
          'Avoid glare and shadows, and use flash only when needed.',
          'Move close enough that the text lines look sharp before capture.',
          'For handwriting, keep the written area larger in frame and use darker, clearer ink when possible.',
        ],
    };
  }

  Color _ocrQualityColor(OcrQuality quality) {
    return switch (quality) {
      OcrQuality.good => const Color(0xFF4CAF50),
      OcrQuality.fair => const Color(0xFFFFB300),
      OcrQuality.poor => const Color(0xFFFF7043),
    };
  }

  String _ocrQualityHeadline(OcrQuality quality) {
    final languageCode = AppCopy.of(context).languageCode;
    return switch ((languageCode, quality)) {
      ('ar', OcrQuality.good) => 'استخراج النص قوي',
      ('ar', OcrQuality.fair) => 'استخراج النص متوسط',
      ('ar', OcrQuality.poor) => 'استخراج النص ضعيف',
      ('hi', OcrQuality.good) => 'टेक्स्ट कैप्चर मजबूत है',
      ('hi', OcrQuality.fair) => 'टेक्स्ट कैप्चर ठीक है',
      ('hi', OcrQuality.poor) => 'टेक्स्ट कैप्चर कमजोर है',
      ('zh', OcrQuality.good) => '文本提取效果较强',
      ('zh', OcrQuality.fair) => '文本提取效果一般',
      ('zh', OcrQuality.poor) => '文本提取效果较弱',
      (_, OcrQuality.good) => 'Text extraction looks strong',
      (_, OcrQuality.fair) => 'Text extraction looks usable',
      (_, OcrQuality.poor) => 'Text extraction looks weak',
    };
  }

  String _ocrQualitySummary(OcrResult result) {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' =>
        'تم التقاط ${result.charCount} حرفًا عبر ${result.lineCount} سطر. عدّل النص إذا لاحظت أي أخطاء قبل التحليل.',
      'hi' =>
        '${result.lineCount} पंक्तियों में ${result.charCount} अक्षर मिले। विश्लेषण से पहले यदि ज़रूरत हो तो टेक्स्ट ठीक करें।',
      'zh' =>
        '共提取 ${result.charCount} 个字符、${result.lineCount} 行。分析前如有需要请先修正文档文本。',
      _ =>
        'Captured ${result.charCount} characters across ${result.lineCount} lines. Edit the text if anything looks wrong before analysis.',
    };
  }

  String _noticeText(OcrNotice notice) {
    final copy = AppCopy.of(context);
    if (notice == OcrNotice.autoCrop) {
      return copy.autoCropNotice;
    }

    final languageCode = copy.languageCode;
    return switch ((languageCode, notice)) {
      ('ar', OcrNotice.lowText) => 'تم التقاط جزء صغير فقط من النص.',
      ('ar', OcrNotice.moveCloser) => 'اقترب أكثر حتى تملأ الورقة معظم الإطار.',
      ('ar', OcrNotice.cropLines) =>
        'حافظ على كل السطور داخل الإطار واجعل الصفحة أكثر استواءً.',
      ('ar', OcrNotice.darkImage) =>
        'الصورة داكنة. أضف إضاءة أكثر أو استخدم الفلاش.',
      ('ar', OcrNotice.overexposed) =>
        'قد تكون الصورة شديدة السطوع. قلل اللمعان والضوء المباشر.',
      ('ar', OcrNotice.lowContrast) =>
        'التباين منخفض. ضع الورقة على خلفية أغمق.',
      ('ar', OcrNotice.enhancedPass) =>
        'استخدم التطبيق نسخة محسّنة من الصورة لرفع جودة القراءة.',
      ('ar', OcrNotice.handwritingFocus) =>
        'تم تشغيل معالجة إضافية للنص اليدوي، لكن مراجعة النص يدويًا ما زالت مهمة قبل التحليل.',
      ('hi', OcrNotice.lowText) => 'बहुत कम टेक्स्ट कैप्चर हुआ है।',
      ('hi', OcrNotice.moveCloser) =>
        'थोड़ा और पास आएँ ताकि दस्तावेज़ फ्रेम भर सके।',
      ('hi', OcrNotice.cropLines) =>
        'सभी पंक्तियाँ फ्रेम में रखें और पेज को सपाट रखें।',
      ('hi', OcrNotice.darkImage) =>
        'छवि अंधेरी है। और रोशनी जोड़ें या फ्लैश उपयोग करें।',
      ('hi', OcrNotice.overexposed) =>
        'छवि बहुत तेज़ रोशनी में हो सकती है। ग्लेयर कम करें।',
      ('hi', OcrNotice.lowContrast) =>
        'कॉन्ट्रास्ट कम है। पेज को गहरे बैकग्राउंड पर रखें।',
      ('hi', OcrNotice.enhancedPass) =>
        'ऐप ने OCR सुधारने के लिए उन्नत इमेज पास इस्तेमाल किया।',
      ('hi', OcrNotice.handwritingFocus) =>
        'हस्तलिखित टेक्स्ट के लिए अतिरिक्त प्रोसेसिंग की गई, फिर भी विश्लेषण से पहले मैन्युअल जाँच ज़रूरी है।',
      ('zh', OcrNotice.lowText) => '只识别到少量文字。',
      ('zh', OcrNotice.moveCloser) => '请再靠近一些，让文件填满更多画面。',
      ('zh', OcrNotice.cropLines) => '请确保所有文字行都在画面内，并让页面更平整。',
      ('zh', OcrNotice.darkImage) => '图像偏暗，请增加光线或打开闪光灯。',
      ('zh', OcrNotice.overexposed) => '图像可能过亮，请减少反光和强光。',
      ('zh', OcrNotice.lowContrast) => '对比度较低，请把纸张放在更深色的背景上。',
      ('zh', OcrNotice.enhancedPass) => '应用已使用增强图像再次尝试 OCR。',
      ('zh', OcrNotice.handwritingFocus) => '已为手写文字启用更强的处理，但分析前仍建议手动检查文本。',
      (_, OcrNotice.lowText) => 'Only a small amount of text was captured.',
      (_, OcrNotice.moveCloser) =>
        'Move closer so the document fills more of the frame.',
      (_, OcrNotice.cropLines) =>
        'Keep all lines inside the frame and hold the page flatter.',
      (_, OcrNotice.darkImage) =>
        'The capture looks dark. Add more light or use the flash.',
      (_, OcrNotice.overexposed) =>
        'The page may be washed out. Reduce glare and strong light.',
      (_, OcrNotice.lowContrast) =>
        'Low contrast was detected. Place the page on a darker background.',
      (_, OcrNotice.enhancedPass) =>
        'The app used an enhanced image pass to improve OCR.',
      (_, OcrNotice.handwritingFocus) =>
        'An extra handwriting-focused pass was used, but manual review is still recommended before analysis.',
      (_, OcrNotice.autoCrop) => copy.autoCropNotice,
    };
  }

  String _retakeRecommendation() {
    final languageCode = AppCopy.of(context).languageCode;
    return switch (languageCode) {
      'ar' => 'يفضل إعادة الالتقاط أو مراجعة النص يدويًا قبل التحليل.',
      'hi' =>
        'विश्लेषण से पहले दोबारा फोटो लें या टेक्स्ट को मैन्युअली जाँचें।',
      'zh' => '建议先重拍，或在分析前手动检查文本。',
      _ =>
        'A retake is recommended, or manually review the text before analysis.',
    };
  }

  Widget _buildCorner(int position) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: CornerPainter(position: position),
      ),
    );
  }
}

class CornerPainter extends CustomPainter {
  const CornerPainter({required this.position});

  final int position;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    switch (position) {
      case 0:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
        break;
      case 1:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case 2:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case 3:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
