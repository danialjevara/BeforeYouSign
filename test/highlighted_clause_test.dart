import 'package:beforeyousign/models/highlighted_clause.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildHighlightedClause highlights an exact clause match', () {
    final clause = buildHighlightedClause(
      documentText:
          'I agree to serve as guarantor for the loan and repay any unpaid balance if the borrower defaults.',
      evidence: 'guarantor for the loan',
    );

    expect(clause.hasHighlight, isTrue);
    expect(clause.excerpt, contains('guarantor for the loan'));
    expect(
      clause.excerpt.substring(clause.highlightStart, clause.highlightEnd),
      'guarantor for the loan',
    );
  });

  test('buildHighlightedClause can recover from ellipsis-heavy evidence', () {
    final clause = buildHighlightedClause(
      documentText:
          'The borrower agrees that salary deductions and collateral may be used to recover any missed payment.',
      evidence: '...salary deductions and collateral...',
    );

    expect(clause.hasHighlight, isTrue);
    expect(
      clause.excerpt.substring(clause.highlightStart, clause.highlightEnd),
      'salary deductions and collateral',
    );
  });

  test('buildHighlightedClause falls back to the evidence text when no match exists', () {
    final clause = buildHighlightedClause(
      documentText: 'This page does not contain the target phrase.',
      evidence: 'waive the right to appeal',
    );

    expect(clause.excerpt, 'waive the right to appeal');
    expect(clause.highlightStart, 0);
    expect(clause.highlightEnd, clause.excerpt.length);
  });
}
