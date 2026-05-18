import 'package:beforeyousign/services/gemma_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _RulesBenchmarkCase {
  const _RulesBenchmarkCase({
    required this.label,
    required this.ocrText,
    this.userContext = '',
    this.expectedGuarantor = false,
    this.expectedDebt = false,
    this.expectedWaiver = false,
    this.expectedCollateral = false,
    this.expectedPressure = false,
    this.expectedBlankSpaces = false,
    this.minRiskScore = 2,
    this.maxRiskScore = 10,
    this.evidenceTerm,
  });

  final String label;
  final String ocrText;
  final String userContext;
  final bool expectedGuarantor;
  final bool expectedDebt;
  final bool expectedWaiver;
  final bool expectedCollateral;
  final bool expectedPressure;
  final bool expectedBlankSpaces;
  final int minRiskScore;
  final int maxRiskScore;
  final String? evidenceTerm;
}

void main() {
  const cases = <_RulesBenchmarkCase>[
    _RulesBenchmarkCase(
      label: 'english guarantor debt',
      ocrText:
          'I agree to act as guarantor for this loan and repay all interest.',
      expectedGuarantor: true,
      expectedDebt: true,
      minRiskScore: 6,
      evidenceTerm: 'guarantor',
    ),
    _RulesBenchmarkCase(
      label: 'arabic guarantor debt',
      ocrText: 'أتعهد بصفتي ضامن بسداد القرض مع الفائدة حتى السداد الكامل.',
      userContext: 'هذه ورقة دين.',
      expectedGuarantor: true,
      expectedDebt: true,
      minRiskScore: 6,
      evidenceTerm: 'ضامن',
    ),
    _RulesBenchmarkCase(
      label: 'spanish waiver',
      ocrText: 'Renuncia a cualquier apelación y acepta arbitraje obligatorio.',
      expectedWaiver: true,
      minRiskScore: 4,
      evidenceTerm: 'Renuncia',
    ),
    _RulesBenchmarkCase(
      label: 'portuguese debt collateral',
      ocrText:
          'O fiador responde pela dívida e oferece salário como garantia pessoal.',
      expectedGuarantor: true,
      expectedDebt: true,
      expectedCollateral: true,
      minRiskScore: 7,
      evidenceTerm: 'fiador',
    ),
    _RulesBenchmarkCase(
      label: 'french guarantor debt waiver',
      ocrText: 'Le garant accepte cette dette et renonce à tout appel.',
      expectedGuarantor: true,
      expectedDebt: true,
      expectedWaiver: true,
      minRiskScore: 8,
      evidenceTerm: 'garant',
    ),
    _RulesBenchmarkCase(
      label: 'hindi guarantor debt',
      ocrText: 'मैं जमानतदार बनता हूं और ऋण की किस्त व ब्याज चुकाऊंगा।',
      expectedGuarantor: true,
      expectedDebt: true,
      minRiskScore: 6,
      evidenceTerm: 'जमानतदार',
    ),
    _RulesBenchmarkCase(
      label: 'chinese debt collateral pressure',
      ocrText: '借款人同意用工资和财产作为抵押偿还贷款，直接签吧。',
      expectedDebt: true,
      expectedCollateral: true,
      expectedPressure: true,
      minRiskScore: 6,
      evidenceTerm: '工资',
    ),
    _RulesBenchmarkCase(
      label: 'spanish blank spaces',
      ocrText: 'Monto total: ____ Fecha de pago: ____ Firma: ____',
      expectedBlankSpaces: true,
      minRiskScore: 4,
      maxRiskScore: 4,
    ),
    _RulesBenchmarkCase(
      label: 'portuguese pressure from context',
      ocrText: 'Documento simples de confirmação.',
      userContext: 'É só formalidade, só assina, não acontece nada.',
      expectedPressure: true,
      minRiskScore: 3,
      maxRiskScore: 3,
    ),
    _RulesBenchmarkCase(
      label: 'benign english control',
      ocrText: 'I received a copy of the schedule and will review it later.',
      minRiskScore: 2,
      maxRiskScore: 2,
    ),
  ];

  test('multilingual rules benchmark keeps broad heuristic coverage', () {
    for (final benchmarkCase in cases) {
      final signals = GemmaService.detectRiskSignals(
        ocrText: benchmarkCase.ocrText,
        userContext: benchmarkCase.userContext,
      );

      expect(
        signals.hasGuarantorTerms,
        benchmarkCase.expectedGuarantor,
        reason: '${benchmarkCase.label}: guarantor detection mismatch',
      );
      expect(
        signals.hasDebtTerms,
        benchmarkCase.expectedDebt,
        reason: '${benchmarkCase.label}: debt detection mismatch',
      );
      expect(
        signals.hasWaiverTerms,
        benchmarkCase.expectedWaiver,
        reason: '${benchmarkCase.label}: waiver detection mismatch',
      );
      expect(
        signals.hasCollateralTerms,
        benchmarkCase.expectedCollateral,
        reason: '${benchmarkCase.label}: collateral detection mismatch',
      );
      expect(
        signals.mentionsPressure,
        benchmarkCase.expectedPressure,
        reason: '${benchmarkCase.label}: pressure detection mismatch',
      );
      expect(
        signals.hasBlankSpaces,
        benchmarkCase.expectedBlankSpaces,
        reason: '${benchmarkCase.label}: blank-space detection mismatch',
      );
      expect(
        signals.riskScore,
        inInclusiveRange(
          benchmarkCase.minRiskScore,
          benchmarkCase.maxRiskScore,
        ),
        reason: '${benchmarkCase.label}: risk score out of benchmark range',
      );

      final evidenceTerm = benchmarkCase.evidenceTerm;
      if (evidenceTerm != null) {
        final snippet = GemmaService.extractEvidenceSnippet(
          primaryText: benchmarkCase.ocrText,
          secondaryText: benchmarkCase.userContext,
          terms: [evidenceTerm],
        );
        expect(
          snippet,
          contains(evidenceTerm),
          reason: '${benchmarkCase.label}: evidence snippet not grounded',
        );
      }
    }
  });
}
