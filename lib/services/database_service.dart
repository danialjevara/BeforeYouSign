import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';

final databaseProvider =
    Provider((ref) => DatabaseService(ref.watch(secureStorageProvider)));

enum AssessmentStorageResult {
  stored,
  locked,
  unavailable,
  failed,
}

class DatabaseService {
  final SecureStorageService _secureStorage;
  Box? _assessmentsBox;
  Future<void>? _initFuture;

  DatabaseService(this._secureStorage);

  Future<void> init() async {
    if (_assessmentsBox != null) {
      return;
    }
    _initFuture ??= _openEncryptedBox();
    try {
      await _initFuture;
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> _openEncryptedBox() async {
    await _secureStorage.ensureUnlocked();
    await Hive.initFlutter();

    String? keyStr = await _secureStorage.getEncryptionKey();
    List<int> encryptionKey;

    if (keyStr == null) {
      encryptionKey = Hive.generateSecureKey();
      await _secureStorage.saveEncryptionKey(base64UrlEncode(encryptionKey));
    } else {
      encryptionKey = base64Url.decode(keyStr);
    }

    _assessmentsBox ??= await Hive.openBox(
      'risk_assessments',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  Future<Box> _assessments() async {
    await init();
    final box = _assessmentsBox;
    if (box == null) {
      throw StateError('Risk assessments storage is not ready.');
    }
    return box;
  }

  Future<AssessmentStorageResult> saveAssessment(
    Map<String, dynamic> assessment,
  ) async {
    try {
      final box = await _assessments();
      await box.add(assessment);
      return AssessmentStorageResult.stored;
    } on PrivateStorageLockedException {
      return AssessmentStorageResult.locked;
    } on PrivateStorageUnavailableException {
      return AssessmentStorageResult.unavailable;
    } catch (_) {
      return AssessmentStorageResult.failed;
    }
  }

  Future<List<dynamic>> getAssessments() async {
    final box = await _assessments();
    return box.values.toList(growable: false);
  }
}
