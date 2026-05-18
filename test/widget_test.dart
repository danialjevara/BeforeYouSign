import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beforeyousign/screens/verdict_dashboard_screen.dart';
import 'package:beforeyousign/localization/app_copy.dart';

void main() {
  test('onboarding screen CTA labels are correctly defined', () {
    final copy = AppCopy.forLocale('en');

    // The primary CTA should encourage Gemma setup
    expect(copy.primaryGemmaCta, isNotEmpty);
    expect(copy.primaryGemmaCta.toLowerCase(), contains('gemma'));

    // The secondary CTA should offer continuing without Gemma
    expect(copy.useAppNow, isNotEmpty);

    // Both CTAs should be distinct
    expect(copy.primaryGemmaCta, isNot(equals(copy.useAppNow)));
  });

  testWidgets('verdict screen asks for document text when opened without input',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: VerdictDashboardScreen(),
        ),
      ),
    );

    expect(
      find.text(AppCopy.forLocale('en').addDocumentText),
      findsOneWidget,
    );
    expect(
      find.text(AppCopy.forLocale('en').typeOrPasteContinue),
      findsOneWidget,
    );
    expect(
      find.text(AppCopy.forLocale('en').analyzeDocument),
      findsOneWidget,
    );
  });
}
