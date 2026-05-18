import 'package:beforeyousign/services/gemma_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rules fallback detects Arabic guarantor and debt signals', () {
    final signals = GemmaService.detectRiskSignals(
      ocrText: 'أتعهد بصفتي ضامن بسداد القرض مع الفائدة.',
      userContext: 'هذه ورقة دين.',
    );

    expect(signals.hasGuarantorTerms, isTrue);
    expect(signals.hasDebtTerms, isTrue);
    expect(signals.hasBlankSpaces, isFalse);
    expect(signals.riskScore, greaterThanOrEqualTo(6));
  });

  test('rules fallback detects waiver, collateral, pressure, and blanks', () {
    final signals = GemmaService.detectRiskSignals(
      ocrText:
          'I waive my right to appeal and pledge my salary as collateral ____',
      userContext: 'They told me just sign because it is just a formality.',
    );

    expect(signals.hasBlankSpaces, isTrue);
    expect(signals.hasWaiverTerms, isTrue);
    expect(signals.hasCollateralTerms, isTrue);
    expect(signals.mentionsPressure, isTrue);
    expect(signals.riskScore, 8);
  });

  test('evidence extraction returns a grounded Arabic snippet', () {
    final snippet = GemmaService.extractEvidenceSnippet(
      primaryText: 'أتعهد بصفتي ضامن بسداد القرض مع الفائدة حتى السداد الكامل.',
      secondaryText: '',
      terms: const ['ضامن', 'قرض', 'فائدة'],
    );

    expect(snippet, contains('ضامن'));
    expect(snippet, contains('القرض'));
  });

  test('jurisdiction hints become more specific for supported locales', () {
    expect(
      GemmaService.jurisdictionHintFor('ar-EG'),
      contains('Arabic financial terms'),
    );
    expect(
      GemmaService.jurisdictionHintFor('en-US'),
      contains('personal guarantees'),
    );
  });

  test('long documents are excerpted around risk terms before prompting', () {
    final longPrefix = List.filled(
      600,
      'Ordinary scheduling clause with no signature risk.',
    ).join(' ');
    final longSuffix = List.filled(
      600,
      'Standard notice text for routine document handling.',
    ).join(' ');
    final longDocument = [
      longPrefix,
      'The signer agrees to act as guarantor for the loan.',
      'The signer waives appeal rights and pledges salary as collateral.',
      longSuffix,
    ].join('\n');

    final prepared = GemmaService.prepareDocumentTextForPrompt(longDocument);

    expect(prepared.length, lessThan(longDocument.length));
    expect(prepared, contains('Document excerpted'));
    expect(prepared, contains('guarantor'));
    expect(prepared, contains('collateral'));
  });

  test('compact document prompt stays below the mobile context budget', () {
    final longDocument = List.filled(
      300,
      'The signer agrees to act as guarantor for a loan and pledges salary as collateral.',
    ).join('\n');

    final standard = GemmaService.prepareDocumentTextForPrompt(longDocument);
    final compact = GemmaService.prepareDocumentTextForPrompt(
      longDocument,
      compact: true,
    );

    expect(compact.length, lessThan(standard.length));
    expect(compact.length, lessThanOrEqualTo(2300));
    expect(compact, contains('guarantor'));
  });

  test(
      'recommended actions prioritize help, review, and questions for risky text',
      () {
    final signals = GemmaService.detectRiskSignals(
      ocrText:
          'I waive my right to appeal and pledge my salary as collateral ____',
      userContext: 'They told me just sign because it is just a formality.',
    );

    final actionIds = GemmaService.recommendActionIds(
      signals: signals,
      riskScore: signals.riskScore,
      groundedScenarioCount: 1,
      gemmaReady: true,
    );

    expect(actionIds.first, 'open_legal_help');
    expect(actionIds, contains('review_document_again'));
    expect(actionIds, contains('copy_questions'));
  });

  test('trust level distinguishes grounded, mixed, and caution states', () {
    expect(
      GemmaService.trustLevelForSources(
          const ['document', 'document', 'model']),
      'grounded',
    );
    expect(
      GemmaService.trustLevelForSources(const ['document', 'context', 'model']),
      'mixed',
    );
    expect(
      GemmaService.trustLevelForSources(const ['model', 'none', 'none']),
      'caution',
    );
  });
}
