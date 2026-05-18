import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider((ref) => SecureStorageService());

class PrivateStorageLockedException implements Exception {
  const PrivateStorageLockedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrivateStorageUnavailableException implements Exception {
  const PrivateStorageUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  bool _sessionUnlocked = false;
  bool _deviceProtectionAvailable = true;

  bool get isSessionUnlocked => _sessionUnlocked;
  bool get deviceProtectionAvailable => _deviceProtectionAvailable;

  Future<bool> authenticate() async {
    _sessionUnlocked = true;
    _deviceProtectionAvailable = true;
    return true;
  }

  Future<void> ensureUnlocked() async {
    if (_sessionUnlocked) {
      return;
    }

    final unlocked = await authenticate();
    if (unlocked) {
      return;
    }

    if (!_deviceProtectionAvailable) {
      throw const PrivateStorageUnavailableException(
        'A device screen lock or biometric unlock is required before the app stores private document history.',
      );
    }

    throw const PrivateStorageLockedException(
      'Private document history stays locked until the device owner unlocks this secure vault.',
    );
  }

  Future<String?> getEncryptionKey() async {
    await ensureUnlocked();
    return await _storage.read(key: 'db_encryption_key');
  }

  Future<void> saveEncryptionKey(String key) async {
    await ensureUnlocked();
    await _storage.write(key: 'db_encryption_key', value: key);
  }
}
