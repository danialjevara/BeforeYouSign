import 'package:beforeyousign/data/legal_official_sources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('official legal sources cover key launch countries', () {
    const expectedCountries = [
      'US',
      'GB',
      'IN',
      'AE',
      'EG',
      'BD',
      'JP',
      'KR',
      'ID',
      'TH',
      'TR',
      'MX',
      'PE',
      'AR',
      'CL',
      'CO',
      'BR',
    ];

    for (final countryCode in expectedCountries) {
      final entries = legalOfficialResourcesByCountryCode[countryCode];
      expect(entries, isNotNull, reason: '$countryCode should have sources');
      expect(entries, isNotEmpty, reason: '$countryCode should not be empty');
    }
  });

  test('official legal sources use https links when a website is present', () {
    for (final entryList in legalOfficialResourcesByCountryCode.values) {
      for (final entry in entryList) {
        expect(entry.name.trim(), isNotEmpty);
        expect(entry.description.trim(), isNotEmpty);
        expect(entry.website.trim(), startsWith('https://'));
      }
    }
  });
}
