import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_copy.dart';
import '../services/gemma_service.dart';

class ModelDownloadScreen extends ConsumerStatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  ConsumerState<ModelDownloadScreen> createState() =>
      _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends ConsumerState<ModelDownloadScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_checkModelStatus);
  }

  Future<void> _checkModelStatus() async {
    await ref.read(gemmaServiceProvider).initialize();
  }

  Future<void> _startDownload() async {
    await ref.read(gemmaServiceProvider).downloadModel();
  }

  Future<void> _pauseDownload() async {
    await ref.read(gemmaServiceProvider).pauseDownload();
  }

  Future<void> _resumeDownload() async {
    await ref.read(gemmaServiceProvider).resumeDownload();
  }

  Future<void> _restartDownload() async {
    await ref.read(gemmaServiceProvider).restartDownload();
  }

  void _confirmRestart(AppCopy copy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          copy.restartDownloadTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          copy.restartDownloadBody,
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(copy.cancelLabel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _restartDownload();
            },
            child: Text(
              copy.restartDownloadConfirm,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gemmaService = ref.watch(gemmaServiceProvider);
    final copy = AppCopy.of(context);
    final status = gemmaService.status;
    final progress = gemmaService.downloadProgress;
    final progressPercent = (progress * 100).round().clamp(0, 100);
    final downloadedLine = copy.downloadProgressDetail(
      gemmaService.downloadedMegabytesLabel,
      gemmaService.totalMegabytesLabel,
    );

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                const Icon(
                  Icons.download_rounded,
                  size: 56,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  copy.gemmaSetupTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  copy.gemmaSetupBody,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '${gemmaService.modelName} · ${gemmaService.modelSizeLabel}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildChecklist(copy, gemmaService),
                const SizedBox(height: 16),
                _buildStatusSection(
                  copy,
                  status: status,
                  gemmaService: gemmaService,
                  progressPercent: progressPercent,
                  downloadedLine: downloadedLine,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklist(AppCopy copy, GemmaService gemmaService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.gemmaSetupChecklistTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...copy
              .gemmaSetupChecklist(
                freeSpace: gemmaService.recommendedFreeSpaceLabel,
                ram: gemmaService.recommendedRamLabel,
                modelSize: gemmaService.modelSizeLabel,
              )
              .map(
                (item) => Padding(
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
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.3,
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

  Widget _buildStatusSection(
    AppCopy copy, {
    required GemmaModelStatus status,
    required GemmaService gemmaService,
    required int progressPercent,
    required String downloadedLine,
  }) {
    if (status == GemmaModelStatus.ready) {
      return Column(
        children: [
          const Icon(Icons.verified_rounded,
              color: Color(0xFF4CAF50), size: 56),
          const SizedBox(height: 10),
          Text(
            copy.gemmaReady,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: Text(copy.backToApp),
          ),
        ],
      );
    }

    if (status == GemmaModelStatus.installing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 12),
            Text(
              copy.gemmaInstallingNow,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              copy.modelPreparing,
              style: const TextStyle(color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final hasPartialProgress = gemmaService.downloadProgress > 0.01;
    final hasCompletedDownload = gemmaService.downloadProgress >= 0.999;
    return Column(
      children: [
        if (status == GemmaModelStatus.error)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              gemmaService.lastError ?? copy.downloadFailed,
              style: const TextStyle(
                  color: Colors.redAccent, height: 1.4, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        _buildDownloadCard(
          copy,
          progressPercent: progressPercent,
          downloadedLine: downloadedLine,
          backgroundHint:
              hasCompletedDownload && status == GemmaModelStatus.error
                  ? null
                  : gemmaService.isAutoResuming
                      ? copy.downloadReconnecting
                      : status == GemmaModelStatus.paused
                          ? copy.downloadPaused
                          : copy.backgroundDownloadReady,
          speedLine: gemmaService.speedMegabytesLabel == null
              ? null
              : copy.downloadSpeedDetail(gemmaService.speedMegabytesLabel!),
          remainingLine: gemmaService.timeRemainingLabel == null
              ? null
              : copy.downloadRemainingDetail(gemmaService.timeRemainingLabel!),
        ),
        const SizedBox(height: 14),
        if (status == GemmaModelStatus.downloading &&
            gemmaService.canPause) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pauseDownload,
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              label: Text(copy.pauseDownload),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ] else if (status == GemmaModelStatus.paused) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resumeDownload,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(copy.resumeDownload),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ] else if (status == GemmaModelStatus.error &&
            hasCompletedDownload) ...[
          TextButton.icon(
            onPressed: _checkModelStatus,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(copy.refreshStatus),
          ),
        ] else if (status == GemmaModelStatus.error && hasPartialProgress) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resumeDownload,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(copy.resumeDownload),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmRestart(copy),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(copy.restartDownloadButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white12),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.download_for_offline_rounded, size: 18),
              label: Text(copy.downloadGemma),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _checkModelStatus,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(copy.refreshStatus),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadCard(
    AppCopy copy, {
    required int progressPercent,
    required String downloadedLine,
    required String? backgroundHint,
    required String? speedLine,
    required String? remainingLine,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progressPercent == 0 ? null : progressPercent / 100,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 10),
          Text(
            '$progressPercent%',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            downloadedLine,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (speedLine != null) ...[
            const SizedBox(height: 4),
            Text(
              speedLine,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (remainingLine != null) ...[
            const SizedBox(height: 2),
            Text(
              remainingLine,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (backgroundHint != null) ...[
            const SizedBox(height: 8),
            Text(
              backgroundHint,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12, height: 1.3),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
