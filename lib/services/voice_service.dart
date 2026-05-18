import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

final voiceServiceProvider = Provider((ref) => VoiceService());

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechReady = false;
  void Function(String status)? _statusListener;
  void Function(SpeechRecognitionError error)? _errorListener;

  Future<bool> initializeSpeech() async {
    if (_speechReady) {
      return true;
    }

    _speechReady = await _speechToText.initialize(
      onError: _handleSpeechError,
      onStatus: _handleSpeechStatus,
    );
    return _speechReady;
  }

  Future<List<LocaleName>> speechLocales() async {
    final isReady = await initializeSpeech();
    if (!isReady) {
      return const [];
    }

    return _speechToText.locales();
  }

  Future<bool> startListening({
    required String localeId,
    required void Function(String text, bool finalResult) onResult,
    void Function(String status)? onStatus,
    void Function(SpeechRecognitionError error)? onError,
  }) async {
    _statusListener = onStatus;
    _errorListener = onError;

    final isReady = await initializeSpeech();
    if (!isReady) {
      return false;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    await _speechToText.listen(
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 6),
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        autoPunctuation: true,
      ),
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
    return true;
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;

  Future<void> speak({
    required String text,
    required String localeTag,
  }) async {
    await _flutterTts.stop();
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setSpeechRate(0.46);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    final language = await _resolveBestTtsLanguage(localeTag);
    if (language != null) {
      await _flutterTts.setLanguage(language);
    }

    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<String?> resolveBestSpeechLocale(String localeTag) async {
    final locales = await speechLocales();
    if (locales.isEmpty) {
      return null;
    }

    final normalized = _normalizeLocaleTag(localeTag);
    for (final locale in locales) {
      if (_normalizeLocaleTag(locale.localeId) == normalized) {
        return locale.localeId;
      }
    }

    final languageCode = normalized.split('-').first;
    for (final locale in locales) {
      if (_normalizeLocaleTag(locale.localeId).startsWith(languageCode)) {
        return locale.localeId;
      }
    }

    return locales.first.localeId;
  }

  Future<String?> _resolveBestTtsLanguage(String localeTag) async {
    final languages = await _flutterTts.getLanguages;
    if (languages is! List) {
      return null;
    }

    final normalized = _normalizeLocaleTag(localeTag);
    for (final language in languages.whereType<String>()) {
      if (_normalizeLocaleTag(language) == normalized) {
        return language;
      }
    }

    final languageCode = normalized.split('-').first;
    for (final language in languages.whereType<String>()) {
      if (_normalizeLocaleTag(language).startsWith(languageCode)) {
        return language;
      }
    }

    return languages.whereType<String>().firstOrNull;
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (error.permanent) {
      _speechReady = false;
    }
    _errorListener?.call(error);
  }

  void _handleSpeechStatus(String status) {
    _statusListener?.call(status);
  }

  String _normalizeLocaleTag(String value) {
    return value.replaceAll('_', '-').toLowerCase();
  }
}
