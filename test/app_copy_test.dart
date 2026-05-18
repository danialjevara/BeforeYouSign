import 'package:beforeyousign/localization/app_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supported locales share the same translation keys', () {
    final referenceKeys =
        AppCopy.debugStrings[AppCopy.fallbackLanguageCode]!.keys.toSet();

    for (final languageCode in AppCopy.supportedLanguageCodes) {
      expect(
        AppCopy.debugStrings[languageCode]?.keys.toSet(),
        referenceKeys,
        reason: '$languageCode should keep full translation coverage',
      );
    }
  });

  test('Gemma messaging keeps full analysis primary and fallback limited', () {
    final en = AppCopy.forLocale('en');
    final es = AppCopy.forLocale('es-MX');

    expect(
      en.gemmaSetupBody,
      contains('accurate on-device analysis'),
    );
    expect(en.useAppNow, 'Continue with limited scan');
    expect(en.analyzeDocument, 'RUN LIMITED SAFETY SCAN');
    expect(
      en
          .gemmaSetupChecklist(
            freeSpace: '4 GB',
            ram: '6 GB',
            modelSize: '2.8 GB',
          )
          .first,
      contains('designed around Gemma 4'),
    );

    expect(
      es.gemmaSetupBody,
      contains('diseñado alrededor de Gemma 4'),
    );
    expect(es.useAppNow, 'Continuar con escaneo limitado');
    expect(es.refreshStatus, 'Actualizar estado');
    expect(en.documentClauseLabel, 'Clause from the document');
    expect(en.whyDangerousLabel, 'Why this is dangerous');
    expect(en.printedModeLabel, 'Printed');
    expect(en.handwritingModeLabel, 'Handwriting');
    expect(en.captureModePrintedHint, contains('Fill the frame'));
    expect(en.captureModeHandwritingHint, contains('handwriting'));
    expect(en.autoCropBadge, 'Auto-cropped');
    expect(en.autoCropNotice, contains('auto-cropped'));
  });

  test(
      'locale resolution prefers supported device languages and falls back cleanly',
      () {
    expect(AppCopy.resolveLanguageCode('es-MX'), 'es');
    expect(AppCopy.resolveLanguageCode('pt-BR'), 'pt');
    expect(AppCopy.resolveLanguageCode('fr-CA'), 'fr');
    expect(AppCopy.resolveLanguageCode('ar-EG'), 'ar');
    expect(AppCopy.resolveLanguageCode('zh-Hant-TW'), 'zh');
    expect(AppCopy.resolveLanguageCode('de-DE'), 'en');

    expect(AppCopy.resolveLocale(const Locale('es', 'MX')).languageCode, 'es');
    expect(AppCopy.resolveLocale(const Locale('pt', 'BR')).languageCode, 'pt');
    expect(AppCopy.resolveLocale(const Locale('fr', 'CA')).languageCode, 'fr');
    expect(AppCopy.resolveLocale(const Locale('hi', 'IN')).languageCode, 'hi');
    expect(AppCopy.resolveLocale(const Locale('de', 'DE')).languageCode, 'en');
  });

  test('Arabic legal help copy stays readable', () {
    final copy = AppCopy.forLocale('ar');

    expect(copy.nearbyFallbackTitle, 'نتائج الخريطة ضعيفة الآن');
    expect(
      copy.nearbyFallbackHint,
      'راجع المصادر الرسمية أدناه كخطوة أكثر موثوقية.',
    );
    expect(copy.officialSourcesTitle('مصر'), 'مصادر رسمية في مصر');
    expect(
      copy.officialSourcesBody(true),
      'عندما تكون نتائج الخريطة ضعيفة، تظهر هنا مصادر رسمية موثوقة كخطوة تالية.',
    );
    expect(copy.officialSourceHeader, 'مصدر رسمي');
    expect(copy.officialSourceBadge, 'رسمي');
    expect(copy.openOfficialSite, 'افتح الموقع الرسمي');
    expect(copy.callOfficialLine, 'اتصل بالجهة الرسمية');
    expect(copy.matchedTextLabel, 'النص المطابق');
    expect(
      copy.legalUncertaintyWarning,
      'تنبيه: التطبيق قد يخطئ في التحليل أو يفوت بنودًا مهمة. ليس بديلًا عن محامٍ مرخص.',
    );
  });

  test('Spanish legal help copy stays readable', () {
    final copy = AppCopy.forLocale('es-MX');

    expect(copy.languageCode, 'es');
    expect(copy.countryChip('México'), 'País: México');
    expect(copy.officialSourcesTitle('México'), 'Fuentes oficiales en México');
    expect(copy.officialSourceHeader, 'Fuente oficial');
    expect(copy.openOfficialSite, 'Abrir sitio oficial');
    expect(copy.callOfficialLine, 'Llamar a la línea oficial');
    expect(
        copy.nearbyFallbackTitle, 'Los resultados del mapa son débiles ahora');
    expect(copy.matchedTextLabel, 'Texto coincidente');
    expect(
      copy.legalUncertaintyWarning,
      'Advertencia: la app puede equivocarse o pasar por alto detalles legales importantes. No sustituye a un abogado autorizado.',
    );
  });

  test('Portuguese and French legal help copy stays readable', () {
    final pt = AppCopy.forLocale('pt-BR');
    final fr = AppCopy.forLocale('fr-FR');

    expect(pt.languageCode, 'pt');
    expect(pt.countryChip('Brasil'), 'País: Brasil');
    expect(pt.officialSourcesTitle('Brasil'), 'Fontes oficiais em Brasil');
    expect(pt.officialSourceHeader, 'Fonte oficial');
    expect(pt.callOfficialLine, 'Ligar para a linha oficial');
    expect(pt.matchedTextLabel, 'Trecho correspondente');
    expect(
      pt.legalUncertaintyWarning,
      'Aviso: o aplicativo pode errar ou ignorar detalhes jurídicos importantes. Ele não substitui um advogado habilitado.',
    );

    expect(fr.languageCode, 'fr');
    expect(fr.countryChip('France'), 'Pays : France');
    expect(fr.officialSourcesTitle('France'), 'Sources officielles à France');
    expect(fr.officialSourceHeader, 'Source officielle');
    expect(fr.openOfficialSite, 'Ouvrir le site officiel');
    expect(fr.matchedTextLabel, 'Texte correspondant');
    expect(
      fr.legalUncertaintyWarning,
      'Avertissement : l’application peut se tromper ou manquer des détails juridiques importants. Elle ne remplace pas un avocat habilité.',
    );
  });

  test('Hindi and Chinese legal help copy stays readable', () {
    final hi = AppCopy.forLocale('hi');
    final zh = AppCopy.forLocale('zh');

    expect(hi.officialSourcesTitle('भारत'), 'भारत में आधिकारिक कानूनी स्रोत');
    expect(hi.officialSourceHeader, 'आधिकारिक स्रोत');
    expect(hi.matchedTextLabel, 'मिला हुआ पाठ');
    expect(
      hi.legalUncertaintyWarning,
      'चेतावनी: यह ऐप गलत हो सकता है या कोई महत्वपूर्ण कानूनी बात छोड़ सकता है। यह लाइसेंस प्राप्त वकील का विकल्प नहीं है।',
    );

    expect(zh.officialSourcesTitle('中国'), '中国 的官方法律资源');
    expect(zh.officialSourceHeader, '官方来源');
    expect(zh.matchedTextLabel, '匹配文本');
    expect(
      zh.legalUncertaintyWarning,
      '警告：这个应用可能出错，也可能漏掉重要法律细节。它不能代替执业律师。',
    );
  });
}
