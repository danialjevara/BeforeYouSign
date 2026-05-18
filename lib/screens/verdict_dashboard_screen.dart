import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_copy.dart';
import '../models/analysis_data.dart';
import '../models/highlighted_clause.dart';
import '../services/database_service.dart';
import '../services/gemma_service.dart';
import '../services/voice_service.dart';

class VerdictDashboardScreen extends ConsumerStatefulWidget {
  final AnalysisData? analysisData;

  const VerdictDashboardScreen({super.key, this.analysisData});

  @override
  ConsumerState<VerdictDashboardScreen> createState() =>
      _VerdictDashboardScreenState();
}

class _VerdictDashboardScreenState extends ConsumerState<VerdictDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _cardsController;
  late Animation<double> _gaugeAnimation;
  late final VoiceService _voiceService;
  late AnalysisData _analysisRequest;

  int _riskScore = 0;
  Map<String, dynamic>? _analysisResult;
  bool _isSpeaking = false;
  bool _isRetrying = false;
  String? _analysisBlockedMessage;
  bool get _hasAnalysisInput => _analysisRequest.ocrText.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _voiceService = ref.read(voiceServiceProvider);
    _analysisRequest = widget.analysisData ??
        const AnalysisData(
          ocrText: '',
          userContext: '',
        );
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _gaugeAnimation = CurvedAnimation(
      parent: _gaugeController,
      curve: Curves.easeOutCubic,
    );
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (_hasAnalysisInput) {
      _runAnalysis();
    }
  }

  Future<void> _runAnalysis({AnalysisData? request}) async {
    final activeRequest = request ?? _analysisRequest;
    _analysisRequest = activeRequest;
    final gemma = ref.read(gemmaServiceProvider);
    final locationContext =
        WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    try {
      await gemma.initialize();

      final result = await gemma
          .analyze(
            ocrText: activeRequest.ocrText,
            audioTranscript: activeRequest.userContext,
            locationContext: locationContext,
          )
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () => throw const GemmaRequirementException(
              message: 'Analysis timed out. The device may not have enough '
                  'resources for full Gemma analysis right now.',
              canUseLimitedFallback: false,
            ),
          );

      if (!mounted) {
        return;
      }

      await ref.read(databaseProvider).saveAssessment({
        'created_at': DateTime.now().toIso8601String(),
        'ocr_text': activeRequest.ocrText,
        'user_context': activeRequest.userContext,
        'result': result,
      });

      setState(() {
        _analysisBlockedMessage = null;
        _analysisResult = result;
        _riskScore = result['risk_score'] as int? ?? 0;
        _gaugeController.forward(from: 0);
        _cardsController.value = 0;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _cardsController.forward(from: 0);
          }
        });
      });
    } on GemmaRequirementException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _analysisResult = null;
        _analysisBlockedMessage = error.message;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _analysisResult = null;
        _analysisBlockedMessage =
            'Analysis failed to initialize: ${e.toString()}';
      });
    }
  }

  Future<void> _retryFullAnalysis() async {
    setState(() {
      _isRetrying = true;
    });

    final gemma = ref.read(gemmaServiceProvider);
    await gemma.refreshStatus();

    if (!mounted) {
      return;
    }

    if (!gemma.isReady) {
      setState(() {
        _isRetrying = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppCopy.of(context).gemmaNotInstalled,
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push('/gemma-setup');
      }
      return;
    }

    setState(() {
      _analysisBlockedMessage = null;
    });

    try {
      await _runAnalysis(
        request: _analysisRequest.copyWith(
          preference: AnalysisPreference.gemmaOnly,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _voiceService.stopSpeaking();
    _gaugeController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  Future<void> _toggleVerdictAudio() async {
    final voiceService = ref.read(voiceServiceProvider);

    if (_isSpeaking) {
      await voiceService.stopSpeaking();
      if (!mounted) {
        return;
      }
      setState(() {
        _isSpeaking = false;
      });
      return;
    }

    final localeTag = _preferredSpeechLocale();
    final speechText = _buildSpeechText();

    setState(() {
      _isSpeaking = true;
    });

    try {
      await voiceService.speak(
        text: speechText,
        localeTag: localeTag,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  String _preferredSpeechLocale() {
    final deviceLocale = Localizations.localeOf(context).toLanguageTag();
    final detected =
        _analysisResult?['language_detected']?.toString().trim().toLowerCase();
    if (detected == null || detected.isEmpty || detected == 'unknown') {
      return deviceLocale;
    }

    final deviceLanguage = deviceLocale.split('-').first.toLowerCase();
    if (deviceLanguage == detected) {
      return deviceLocale;
    }

    return detected;
  }

  String _buildSpeechText() {
    final copy = AppCopy.of(context);
    final risks = _analysisResult?['top_risks'];
    final riskList = risks is List ? risks : const [];

    final parts = [
      _analysisResult!['risk_title']?.toString() ?? copy.analysisComplete,
      _analysisResult!['verdict_summary']?.toString() ?? '',
    ];

    for (int i = 0; i < riskList.length; i++) {
      final risk = riskList[i];
      if (risk is Map) {
        parts.add(
          copy.scenarioSpoken(
            i + 1,
            risk['title'].toString(),
            _spokenScenarioDetail(risk),
          ),
        );
      }
    }

    parts.addAll([
      _analysisResult!['safer_next_step']?.toString() ?? '',
      _analysisResult!['disclaimer']?.toString() ?? '',
    ]);

    return parts.where((part) => part.trim().isNotEmpty).join(' ');
  }

  String _spokenScenarioDetail(dynamic scenario) {
    if (scenario is! Map) {
      return '';
    }

    final description = scenario['description']?.toString().trim() ?? '';
    final whyDangerous = scenario['why_dangerous']?.toString().trim() ?? '';
    if (whyDangerous.isEmpty || whyDangerous == description) {
      return description;
    }
    return '$description $whyDangerous'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);

    if (!_hasAnalysisInput) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: Color(0xFFFFB300),
                    size: 56,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    copy.addDocumentText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    copy.typeOrPasteContinue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/capture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(copy.analyzeDocument),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_analysisBlockedMessage != null) {
      final gemmaReadyForRetry = ref.watch(gemmaServiceProvider).isReady;
      final isGemmaRuntimeFallback =
          _analysisBlockedMessage == copy.gemmaCouldNotFinish;
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF152033),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF64B5F6).withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF64B5F6),
                      size: 52,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isGemmaRuntimeFallback
                          ? copy.limitedOffline
                          : copy.fullAnalysisRequiredTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _analysisBlockedMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!isGemmaRuntimeFallback)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isRetrying
                              ? null
                              : () async {
                                  if (gemmaReadyForRetry) {
                                    await _retryFullAnalysis();
                                    return;
                                  }
                                  if (context.mounted) {
                                    context.push('/gemma-setup');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor:
                                const Color(0xFFFFB300).withValues(alpha: 0.5),
                            disabledForegroundColor:
                                Colors.black.withValues(alpha: 0.5),
                          ),
                          child: _isRetrying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black54,
                                  ),
                                )
                              : Text(
                                  gemmaReadyForRetry
                                      ? copy.analyzeWithGemma
                                      : copy.primaryGemmaCta,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_analysisResult == null) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF020617)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        color: const Color(0xFF64B5F6),
                        strokeWidth: 3,
                        backgroundColor:
                            const Color(0xFF64B5F6).withValues(alpha: 0.1),
                      ),
                    ),
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF64B5F6),
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  copy.analysisLoading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF64B5F6).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.memory,
                          color: Color(0xFF64B5F6), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        copy.analysisProcessing,
                        style: const TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        context.pop();
                      } else {
                        context.go('/capture');
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  width: 250,
                  child: AnimatedBuilder(
                    animation: _gaugeAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: RiskGaugePainter(
                          riskScore: _riskScore,
                          progress: _gaugeAnimation.value,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _gaugeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _gaugeAnimation.value.clamp(0.0, 1.0),
                      child: child,
                    );
                  },
                  child: Text(
                    _analysisResult!['risk_title']?.toString() ??
                        copy.analysisComplete,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _riskScore >= 8
                          ? const Color(0xFFFF4444)
                          : const Color(0xFFFFB300),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnalysisModeBanner(),
                const SizedBox(height: 16),
                _buildActionPlanCard(),
                const SizedBox(height: 16),
                Text(
                  copy.darkScenarios,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildDynamicScenarios(copy),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1A2E),
                        _riskScore >= 8
                            ? const Color(0xFF2E1616)
                            : const Color(0xFF16213E),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _riskScore >= 8
                          ? const Color(0xFFFF4444).withValues(alpha: 0.4)
                          : const Color(0xFFFFB300).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _riskScore >= 8
                                ? Icons.dangerous
                                : Icons.info_outline,
                            color: _riskScore >= 8
                                ? const Color(0xFFFF4444)
                                : const Color(0xFFFFB300),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            copy.verdictSummary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _analysisResult!['verdict_summary']?.toString() ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildVerdictAndQuestionsCard(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _toggleVerdictAudio,
                    icon: Icon(
                      _isSpeaking
                          ? Icons.stop_circle_outlined
                          : Icons.play_arrow,
                      size: 24,
                    ),
                    label: Text(
                      _isSpeaking ? copy.stopAudio : copy.playAudioVerdict,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                      shadowColor: const Color(0xFFFFB300).withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      context.push('/connect', extra: _analysisRequest),
                  child: Text(
                    copy.connectLegalHelp,
                    style: const TextStyle(
                      color: Color(0xFF64B5F6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                  child: Text(
                    _buildFooterDisclaimer(copy),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildFooterDisclaimer(AppCopy copy) {
    return [
      _analysisResult!['disclaimer']?.toString() ?? copy.aiRiskOnly,
      copy.legalUncertaintyWarning,
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

  Widget _buildAnalysisModeBanner() {
    final copy = AppCopy.of(context);
    final mode = _analysisResult!['analysis_mode']?.toString() ?? 'unknown';
    final source =
        _analysisResult!['analysis_source']?.toString() ?? copy.unknownSource;
    final isRulesMode = mode == 'rules';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isRulesMode
            ? const Color(0xFFFFB300).withValues(alpha: 0.08)
            : const Color(0xFF4CAF50).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRulesMode
              ? const Color(0xFFFFB300).withValues(alpha: 0.35)
              : const Color(0xFF4CAF50).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              source,
              style: TextStyle(
                color: isRulesMode
                    ? const Color(0xFFFFB300)
                    : const Color(0xFF4CAF50),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isRulesMode)
            TextButton(
              onPressed: () => context.push('/gemma-setup'),
              child: Text(
                copy.primaryGemmaCta,
                style: const TextStyle(
                  color: Color(0xFF64B5F6),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getRiskAtIndex(int index) {
    final risks = _analysisResult?['top_risks'];
    if (risks is List && index < risks.length) {
      final risk = risks[index];
      if (risk is Map) {
        return risk.cast<String, dynamic>();
      }
    }
    return null;
  }

  String _scenarioEvidence(int index) {
    final risk = _getRiskAtIndex(index);
    return risk?['evidence']?.toString().trim() ?? '';
  }

  String _scenarioEvidenceSource(int index) {
    final risk = _getRiskAtIndex(index);
    return risk?['evidence_source']?.toString().trim() ?? 'none';
  }

  String _scenarioWhyDangerous(int index) {
    final risk = _getRiskAtIndex(index);
    if (risk == null) return '';
    final whyDangerous = risk['why_dangerous']?.toString().trim() ?? '';
    if (whyDangerous.isNotEmpty) {
      return whyDangerous;
    }
    return risk['description']?.toString().trim() ?? '';
  }

  String _scenarioQuestion(int index) {
    final risk = _getRiskAtIndex(index);
    return risk?['question_to_ask']?.toString().trim() ?? '';
  }

  String _scenarioTrustLevel(int index) {
    final risk = _getRiskAtIndex(index);
    return risk?['trust_level']?.toString().trim() ?? 'unverified';
  }

  List<Widget> _buildDynamicScenarios(AppCopy copy) {
    final risks = _analysisResult?['top_risks'];
    if (risks is! List || risks.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            copy.reviewRisk,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
          ),
        ),
      ];
    }

    final list = <Widget>[];
    for (int i = 0; i < risks.length; i++) {
      final risk = risks[i];
      if (risk is Map) {
        final icon = i == 0
            ? Icons.gavel
            : i == 1
                ? Icons.description_outlined
                : Icons.savings_outlined;
        list.add(
          _buildScenarioCard(
            index: i,
            icon: icon,
            title: '${i + 1}. ${risk['title']}',
            description: risk['description'].toString(),
            whyDangerous: _scenarioWhyDangerous(i),
            evidence: _scenarioEvidence(i),
            evidenceSource: _scenarioEvidenceSource(i),
            trustLevel: _scenarioTrustLevel(i),
            questionToAsk: _scenarioQuestion(i),
          ),
        );
      }
    }
    return list;
  }

  List<_RecommendedAction> _recommendedActions() {
    final rawActions = _analysisResult?['recommended_actions'];
    if (rawActions is! List) {
      return const [];
    }

    final actions = <_RecommendedAction>[];
    for (final rawAction in rawActions) {
      if (rawAction is! Map) {
        continue;
      }

      final actionMap = rawAction.cast<String, dynamic>();
      final actionId = actionMap['action_id']?.toString().trim() ?? '';
      if (actionId.isEmpty) {
        continue;
      }

      actions.add(
        _RecommendedAction(
          id: actionId,
          reason: actionMap['reason']?.toString().trim() ?? '',
          priority: actionMap['priority']?.toString().trim() ?? 'secondary',
        ),
      );
    }

    return actions;
  }

  Widget _buildActionPlanCard() {
    final copy = AppCopy.of(context);
    final actions = _recommendedActions();
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.22),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) {
          final isPrimary = action.priority == 'primary';
          return OutlinedButton.icon(
            onPressed: () => _handleRecommendedAction(action),
            icon: Icon(_actionIcon(action.id), size: 16),
            label: Text(
              copy.actionLabel(action.id),
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isPrimary ? Colors.black : const Color(0xFF64B5F6),
              backgroundColor:
                  isPrimary ? const Color(0xFFFFB300) : Colors.transparent,
              side: BorderSide(
                color: isPrimary
                    ? const Color(0xFFFFB300)
                    : const Color(0xFF64B5F6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _handleRecommendedAction(_RecommendedAction action) async {
    switch (action.id) {
      case 'open_legal_help':
        context.push('/connect', extra: _analysisRequest);
        return;
      case 'copy_questions':
        await _copyQuestionsToClipboard();
        return;
      case 'set_up_gemma':
        context.push('/gemma-setup');
        return;
      case 'review_document_again':
      default:
        context.go('/capture');
        return;
    }
  }

  Future<void> _copyQuestionsToClipboard() async {
    final copy = AppCopy.of(context);
    final risks = _analysisResult?['top_risks'];
    final riskList = risks is List ? risks : const [];
    
    final questions = <String>[];
    for (int i = 0; i < riskList.length; i++) {
      final q = _scenarioQuestion(i);
      if (q.trim().isNotEmpty) {
        questions.add(q);
      }
    }

    final saferNextStep =
        _analysisResult!['safer_next_step']?.toString().trim() ?? '';
    final clipboardText = [
      _analysisResult!['risk_title']?.toString() ?? copy.documentRiskAssessment,
      '',
      _analysisResult!['verdict_summary']?.toString() ?? '',
      '',
      copy.askBeforeSigningTitle,
      ...questions.map((question) => '- $question'),
      '',
      copy.saferNextStepTitle,
      saferNextStep,
    ].where((part) => part.trim().isNotEmpty).join('\n');

    await Clipboard.setData(ClipboardData(text: clipboardText));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(copy.copiedQuestionsMessage)),
    );
  }

  IconData _actionIcon(String actionId) {
    return switch (actionId) {
      'open_legal_help' => Icons.gavel_outlined,
      'copy_questions' => Icons.copy_all_outlined,
      'set_up_gemma' => Icons.auto_awesome,
      _ => Icons.find_in_page_outlined,
    };
  }

  Color _trustLevelColor(String trustLevel) {
    return switch (trustLevel) {
      'grounded' => const Color(0xFF4CAF50),
      'mixed' => const Color(0xFF64B5F6),
      _ => const Color(0xFFFFB300),
    };
  }

  Widget _buildPill({
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildVerdictAndQuestionsCard() {
    final copy = AppCopy.of(context);
    final saferNextStep =
        _analysisResult!['safer_next_step']?.toString().trim() ?? '';
        
    final risks = _analysisResult?['top_risks'];
    final riskList = risks is List ? risks : const [];
    final questions = <String>[];
    for (int i = 0; i < riskList.length; i++) {
      final q = _scenarioQuestion(i);
      if (q.trim().isNotEmpty) {
        questions.add(q);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11192A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF64B5F6).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (saferNextStep.isNotEmpty) ...[
            Text(
              saferNextStep,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.45,
                fontSize: 13,
              ),
            ),
            if (questions.isNotEmpty) const SizedBox(height: 12),
          ],
          if (questions.isNotEmpty) ...[
            Text(
              copy.askBeforeSigningTitle,
              style: const TextStyle(
                color: Color(0xFF64B5F6),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ...questions.map(
              (question) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.help_outline,
                        size: 14,
                        color: Color(0xFFFFB300),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        question,
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
        ],
      ),
    );
  }

  Widget _buildScenarioCard({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required String whyDangerous,
    String evidence = '',
    String evidenceSource = 'none',
    String trustLevel = 'unverified',
    String questionToAsk = '',
  }) {
    final copy = AppCopy.of(context);
    final compactDescription = description.trim();
    final compactWhy = whyDangerous.trim();
    final showSeparateWhy =
        compactWhy.isNotEmpty && compactWhy != compactDescription;
    final showSummary = compactDescription.isNotEmpty &&
        (showSeparateWhy || compactWhy.isEmpty);
    final whyText = showSeparateWhy
        ? compactWhy
        : (compactWhy.isNotEmpty ? compactWhy : compactDescription);
    final evidenceBadge = copy.translateEvidenceSource(evidenceSource);
    final trustBadge = copy.translateTrustLevel(trustLevel);
    final highlightedClause = buildHighlightedClause(
      documentText: _analysisRequest.ocrText,
      evidence: evidence,
    );

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFB300).withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, color: const Color(0xFFFFB300), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPill(
                      label: trustBadge,
                      foreground: _trustLevelColor(
                        trustLevel == 'contextual' ? 'mixed' : trustLevel,
                      ),
                      background: _trustLevelColor(
                        trustLevel == 'contextual' ? 'mixed' : trustLevel,
                      ).withValues(alpha: 0.12),
                    ),
                    if (showSummary) ...[
                      const SizedBox(height: 8),
                      Text(
                        compactDescription,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (evidence.isNotEmpty &&
                        highlightedClause.excerpt.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  copy.documentClauseLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF64B5F6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF64B5F6,
                                    ).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    evidenceBadge,
                                    style: const TextStyle(
                                      color: Color(0xFF64B5F6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                                children: _buildClauseTextSpans(
                                  highlightedClause,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (questionToAsk.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        copy.questionToAskLabel,
                        style: const TextStyle(
                          color: Color(0xFF64B5F6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        questionToAsk.trim(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (whyText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        copy.whyDangerousLabel,
                        style: const TextStyle(
                          color: Color(0xFFFFB300),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        whyText,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildClauseTextSpans(HighlightedClause clause) {
    if (!clause.hasHighlight) {
      return [TextSpan(text: clause.excerpt)];
    }

    return [
      if (clause.highlightStart > 0)
        TextSpan(text: clause.excerpt.substring(0, clause.highlightStart)),
      TextSpan(
        text: clause.excerpt.substring(
          clause.highlightStart,
          clause.highlightEnd,
        ),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          backgroundColor: Color(0x665DADE2),
        ),
      ),
      if (clause.highlightEnd < clause.excerpt.length)
        TextSpan(text: clause.excerpt.substring(clause.highlightEnd)),
    ];
  }
}

class _RecommendedAction {
  const _RecommendedAction({
    required this.id,
    required this.reason,
    required this.priority,
  });

  final String id;
  final String reason;
  final String priority;
}

class RiskGaugePainter extends CustomPainter {
  final int riskScore;
  final double progress;

  RiskGaugePainter({
    required this.riskScore,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);
    final radius = size.width * 0.42;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.8,
      pi * 1.4,
      false,
      bgPaint,
    );

    final segments = [
      (const Color(0xFF4CAF50), 0.0, 0.3),
      (const Color(0xFFFFB300), 0.3, 0.3),
      (const Color(0xFFFF5722), 0.6, 0.2),
      (const Color(0xFFD32F2F), 0.8, 0.2),
    ];

    for (final segment in segments) {
      final segPaint = Paint()
        ..color = segment.$1
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.butt;

      final sweepAngle = pi * 1.4 * segment.$3 * progress;
      final startAngle = pi * 0.8 + (pi * 1.4 * segment.$2);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        segPaint,
      );
    }

    final needleAngle = pi * 0.8 + (pi * 1.4 * (riskScore / 10.0) * progress);
    final needleLength = radius - 10;
    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(
      center,
      8,
      Paint()..color = const Color(0xFFFFB300),
    );
    canvas.drawCircle(
      center,
      4,
      Paint()..color = Colors.white,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(riskScore * progress).round()}/10',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 12),
    );
  }

  @override
  bool shouldRepaint(covariant RiskGaugePainter oldDelegate) {
    return progress != oldDelegate.progress ||
        riskScore != oldDelegate.riskScore;
  }
}
