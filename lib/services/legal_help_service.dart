import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../data/legal_official_sources.dart';

final legalHelpServiceProvider = Provider((ref) => LegalHelpService());

class LegalHelpService {
  static final Uri _overpassUri =
      Uri.parse('https://overpass-api.de/api/interpreter');
  static final Uri _nominatimReverseUri =
      Uri.parse('https://nominatim.openstreetmap.org/reverse');
  static const Duration _snapshotCacheDuration = Duration(minutes: 5);
  static const Duration _reverseLookupTimeout = Duration(seconds: 4);
  static const Duration _overpassTimeout = Duration(seconds: 8);
  static LegalHelpSnapshot? _cachedSnapshot;
  static DateTime? _cachedSnapshotAt;
  static String? _cachedLocaleTag;

  static const Map<String, int> _defaultCategoryScores = {
    'Lawyer': 0,
    'Legal aid': 1,
    'Notary': 2,
    'Court': 3,
    'Bar association': 4,
    'Legal help': 5,
  };

  Future<LegalHelpSnapshot> loadNearbyHelp({
    String localeTag = 'en',
    bool forceRefresh = false,
  }) async {
    Position? userPosition;
    String? nearbyLookupMessage;
    final localeCountryCode = _countryCodeFromLocale(localeTag);

    try {
      userPosition = await _determinePosition();
    } on LegalHelpException catch (error) {
      nearbyLookupMessage = error.message;
    } catch (_) {
      nearbyLookupMessage = 'Nearby legal help could not be loaded right now.';
    }

    if (!forceRefresh &&
        _cachedSnapshot != null &&
        _cachedSnapshotAt != null &&
        _cachedLocaleTag == localeTag) {
      final cacheAge = DateTime.now().difference(_cachedSnapshotAt!);
      if (cacheAge <= _snapshotCacheDuration) {
        if (userPosition != null) {
          final distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            _cachedSnapshot!.userLatitude,
            _cachedSnapshot!.userLongitude,
          );
          if (distance < 5000) {
            return _cachedSnapshot!;
          }
        } else if (_cachedSnapshot!.places.isEmpty) {
          return _cachedSnapshot!;
        }
      }
    }


    List<LegalHelpPlace> places = const [];
    LegalHelpRegion resolvedRegion = const LegalHelpRegion();

    if (userPosition != null) {
      final quickProfile = _countryProfileFor(localeCountryCode);
      final regionFuture = _resolveRegion(
        userPosition,
        localeTag: localeTag,
      );
      final placesFuture = _fetchNearbyPlaces(
        userPosition,
        region: LegalHelpRegion(
          countryCode: localeCountryCode,
          countryName: localeCountryCode,
        ),
        profile: quickProfile,
      );

      try {
        resolvedRegion = await regionFuture;
      } on LegalHelpException catch (error) {
        nearbyLookupMessage ??= error.message;
      } catch (_) {
        nearbyLookupMessage ??=
            'Nearby legal help could not be loaded right now.';
      }

      try {
        places = await placesFuture;
      } on LegalHelpException catch (error) {
        nearbyLookupMessage ??= error.message;
      } catch (_) {
        nearbyLookupMessage ??=
            'Nearby legal help could not be loaded right now.';
      }

      final resolvedCountryCode =
          resolvedRegion.countryCode ?? localeCountryCode;
      if (places.length < 3 && resolvedCountryCode != localeCountryCode) {
        try {
          final refinedPlaces = await _fetchNearbyPlaces(
            userPosition,
            region: LegalHelpRegion(
              countryCode: resolvedCountryCode,
              countryName: resolvedRegion.countryName ?? resolvedCountryCode,
            ),
            profile: _countryProfileFor(resolvedCountryCode),
          );
          if (refinedPlaces.length > places.length) {
            places = refinedPlaces;
          }
        } catch (_) {}
      }
    }

    final effectiveCountryCode =
        resolvedRegion.countryCode ?? localeCountryCode;
    final effectiveRegion = LegalHelpRegion(
      countryCode: effectiveCountryCode,
      countryName: resolvedRegion.countryName ?? effectiveCountryCode,
    );
    final profile = _countryProfileFor(effectiveCountryCode);

    final snapshot = LegalHelpSnapshot(
      userLatitude: userPosition?.latitude ?? 0,
      userLongitude: userPosition?.longitude ?? 0,
      places: places,
      countryCode: effectiveRegion.countryCode,
      countryName: effectiveRegion.countryName,
      focusCategories: profile.focusCategories,
      officialResources: _officialResourcesFor(effectiveRegion.countryCode),
      nearbyLookupMessage: nearbyLookupMessage,
    );

    _cachedSnapshot = snapshot;
    _cachedSnapshotAt = DateTime.now();
    _cachedLocaleTag = localeTag;
    return snapshot;
  }

  String? _countryCodeFromLocale(String localeTag) {
    final parts = localeTag.replaceAll('_', '-').split('-');
    if (parts.length < 2) {
      return null;
    }

    final candidate = parts[1].trim().toUpperCase();
    if (candidate.length != 2) {
      return null;
    }
    return candidate;
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LegalHelpException(
        'Location services are turned off on this device.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LegalHelpException(
        'Location permission is required to find nearby legal help.',
      );
    }

    final lastKnownPosition = await Geolocator.getLastKnownPosition();
    final lastKnownTimestamp = lastKnownPosition?.timestamp;
    final lastKnownFresh = lastKnownTimestamp != null &&
        DateTime.now().difference(lastKnownTimestamp) <
            const Duration(minutes: 5);
    if (lastKnownFresh) {
      return lastKnownPosition!;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } on TimeoutException {
      if (lastKnownPosition != null) {
        return lastKnownPosition;
      }
      rethrow;
    } catch (_) {
      if (lastKnownPosition != null) {
        return lastKnownPosition;
      }
      rethrow;
    }
  }

  Future<LegalHelpRegion> _resolveRegion(
    Position userPosition, {
    required String localeTag,
  }) async {
    final uri = _nominatimReverseUri.replace(
      queryParameters: {
        'format': 'jsonv2',
        'lat': '${userPosition.latitude}',
        'lon': '${userPosition.longitude}',
        'zoom': '5',
        'addressdetails': '1',
        'accept-language': localeTag,
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'BeforeYouSign/1.0 (country-aware legal help lookup)',
      },
    ).timeout(_reverseLookupTimeout);

    if (response.statusCode != 200) {
      return const LegalHelpRegion();
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final address = decoded['address'] as Map<String, dynamic>? ?? const {};
    final countryCode =
        address['country_code']?.toString().trim().toUpperCase();
    final countryName = address['country']?.toString().trim();

    return LegalHelpRegion(
      countryCode: (countryCode?.isEmpty ?? true) ? null : countryCode,
      countryName: (countryName?.isEmpty ?? true) ? null : countryName,
    );
  }

  Future<List<LegalHelpPlace>> _fetchNearbyPlaces(
    Position userPosition, {
    required LegalHelpRegion region,
    required CountryLegalHelpProfile profile,
  }) async {
    final fastQuery = _buildFastQuery(
      latitude: userPosition.latitude,
      longitude: userPosition.longitude,
      radiusMeters: profile.radiusMeters.clamp(3500, 6500).toInt(),
    );
    var places = await _fetchPlacesForQuery(
      fastQuery,
      userPosition: userPosition,
      region: region,
      profile: profile,
    );

    if (places.length < 4) {
      final expandedQuery = _buildExpandedQuery(
        latitude: userPosition.latitude,
        longitude: userPosition.longitude,
        radiusMeters: profile.radiusMeters,
        profile: profile,
      );
      final expandedPlaces = await _fetchPlacesForQuery(
        expandedQuery,
        userPosition: userPosition,
        region: region,
        profile: profile,
      );
      places = _mergePlaces(places, expandedPlaces);
    }

    places.sort(
      (left, right) => _comparePlaces(
        left,
        right,
        profile: profile,
        countryCode: region.countryCode,
      ),
    );
    return places.take(12).toList();
  }

  Future<List<LegalHelpPlace>> _fetchPlacesForQuery(
    String query, {
    required Position userPosition,
    required LegalHelpRegion region,
    required CountryLegalHelpProfile profile,
  }) async {
    final response = await http
        .post(
          _overpassUri,
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
            'User-Agent': 'BeforeYouSign/1.0 (country-aware legal help lookup)',
          },
          body: 'data=${Uri.encodeQueryComponent(query)}',
        )
        .timeout(_overpassTimeout);

    if (response.statusCode != 200) {
      throw LegalHelpException(
        'Nearby legal help could not be loaded right now (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = decoded['elements'] as List<dynamic>? ?? const [];
    return _parsePlaces(
      elements,
      userPosition: userPosition,
      region: region,
      profile: profile,
    );
  }

  List<LegalHelpPlace> _parsePlaces(
    List<dynamic> elements, {
    required Position userPosition,
    required LegalHelpRegion region,
    required CountryLegalHelpProfile profile,
  }) {
    final seen = <String>{};
    final places = <LegalHelpPlace>[];

    for (final rawElement in elements) {
      if (rawElement is! Map<String, dynamic>) {
        continue;
      }

      final tags = rawElement['tags'] as Map<String, dynamic>? ?? const {};
      final latitude =
          (rawElement['lat'] ?? (rawElement['center'] as Map?)?['lat']) as num?;
      final longitude =
          (rawElement['lon'] ?? (rawElement['center'] as Map?)?['lon']) as num?;
      if (latitude == null || longitude == null) {
        continue;
      }

      final category = _category(tags);
      final name = (tags['name']?.toString().trim().isNotEmpty ?? false)
          ? tags['name'].toString().trim()
          : _fallbackName(category);
      final uniqueKey =
          '$name-${latitude.toStringAsFixed(5)}-${longitude.toStringAsFixed(5)}';
      if (!seen.add(uniqueKey)) {
        continue;
      }

      final distanceMeters = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        latitude.toDouble(),
        longitude.toDouble(),
      );

      places.add(
        LegalHelpPlace(
          name: name,
          category: category,
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
          address: _address(tags),
          phone: _firstPresent(tags, const ['contact:phone', 'phone']),
          website: _normalizeWebsite(
            _firstPresent(tags, const ['contact:website', 'website']),
          ),
          distanceMeters: distanceMeters,
        ),
      );
    }

    places.sort(
      (left, right) => _comparePlaces(
        left,
        right,
        profile: profile,
        countryCode: region.countryCode,
      ),
    );
    return places;
  }

  List<LegalHelpPlace> _mergePlaces(
    List<LegalHelpPlace> primary,
    List<LegalHelpPlace> secondary,
  ) {
    final seen = <String>{};
    final merged = <LegalHelpPlace>[];
    for (final place in [...primary, ...secondary]) {
      final key =
          '${place.name}-${place.latitude.toStringAsFixed(5)}-${place.longitude.toStringAsFixed(5)}';
      if (seen.add(key)) {
        merged.add(place);
      }
    }
    return merged;
  }

  String _buildFastQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    final selectors = <String>[
      _tagSelector(
        key: 'office',
        value: 'lawyer',
        radiusMeters: radiusMeters,
        latitude: latitude,
        longitude: longitude,
      ),
      _tagSelector(
        key: 'office',
        value: 'notary',
        radiusMeters: radiusMeters,
        latitude: latitude,
        longitude: longitude,
      ),
      _tagSelector(
        key: 'lawyer',
        value: 'notary',
        radiusMeters: radiusMeters,
        latitude: latitude,
        longitude: longitude,
      ),
      _tagSelector(
        key: 'amenity',
        value: 'courthouse',
        radiusMeters: radiusMeters,
        latitude: latitude,
        longitude: longitude,
      ),
      ..._nameSelectors(
        regexPattern:
            r'legal aid|public defender|law society|bar association|citizens advice|defensor[ií]a|defensoria|مساعدة قانونية|نقابة المحامين|法律援助|विधिक सेवा',
        radiusMeters: radiusMeters,
        latitude: latitude,
        longitude: longitude,
      ),
    ];

    return '''
[out:json][timeout:12];
(
${selectors.join('\n')}
);
out center tags;
''';
  }

  String _buildExpandedQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required CountryLegalHelpProfile profile,
  }) {
    final selectors = <String>[
      _tagSelector(
        key: 'office',
        value: 'lawyer',
        radiusMeters: radiusMeters,
        latitude: latitude,
        longitude: longitude,
      ),
      _tagSelector(
        key: 'office',
        value: 'notary',
        radiusMeters: radiusMeters,
        latitude: latitude,
        longitude: longitude,
      ),
      _tagSelector(
        key: 'lawyer',
        value: 'notary',
        radiusMeters: radiusMeters,
        latitude: latitude,
        longitude: longitude,
      ),
      _tagSelector(
        key: 'amenity',
        value: 'courthouse',
        radiusMeters: radiusMeters,
        latitude: latitude,
        longitude: longitude,
      ),
    ];

    for (final entry in profile.keywordsByCategory.entries) {
      for (final regexPattern in entry.value) {
        selectors.addAll(
          _nameSelectors(
            regexPattern: regexPattern,
            radiusMeters: radiusMeters,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      }
    }

    return '''
[out:json][timeout:18];
(
${selectors.join('\n')}
);
out center tags;
''';
  }

  String _tagSelector({
    required String key,
    required String value,
    required int radiusMeters,
    required double latitude,
    required double longitude,
  }) {
    return '''
  node["$key"="$value"](around:$radiusMeters,$latitude,$longitude);
  way["$key"="$value"](around:$radiusMeters,$latitude,$longitude);
  relation["$key"="$value"](around:$radiusMeters,$latitude,$longitude);
''';
  }

  List<String> _nameSelectors({
    required String regexPattern,
    required int radiusMeters,
    required double latitude,
    required double longitude,
  }) {
    return [
      '  node["name"~"$regexPattern",i](around:$radiusMeters,$latitude,$longitude);',
      '  way["name"~"$regexPattern",i](around:$radiusMeters,$latitude,$longitude);',
      '  relation["name"~"$regexPattern",i](around:$radiusMeters,$latitude,$longitude);',
      '  node["official_name"~"$regexPattern",i](around:$radiusMeters,$latitude,$longitude);',
      '  way["official_name"~"$regexPattern",i](around:$radiusMeters,$latitude,$longitude);',
      '  relation["official_name"~"$regexPattern",i](around:$radiusMeters,$latitude,$longitude);',
      '  node["operator"~"$regexPattern",i](around:$radiusMeters,$latitude,$longitude);',
      '  way["operator"~"$regexPattern",i](around:$radiusMeters,$latitude,$longitude);',
      '  relation["operator"~"$regexPattern",i](around:$radiusMeters,$latitude,$longitude);',
    ];
  }

  int _comparePlaces(
    LegalHelpPlace left,
    LegalHelpPlace right, {
    required CountryLegalHelpProfile profile,
    required String? countryCode,
  }) {
    final leftCategoryScore = profile.categoryScore(left.category);
    final rightCategoryScore = profile.categoryScore(right.category);
    if (leftCategoryScore != rightCategoryScore) {
      return leftCategoryScore.compareTo(rightCategoryScore);
    }

    final leftOfficialScore = _isOfficialAid(left, countryCode) ? 0 : 1;
    final rightOfficialScore = _isOfficialAid(right, countryCode) ? 0 : 1;
    if (leftOfficialScore != rightOfficialScore) {
      return leftOfficialScore.compareTo(rightOfficialScore);
    }

    return left.distanceMeters.compareTo(right.distanceMeters);
  }

  bool _isOfficialAid(LegalHelpPlace place, String? countryCode) {
    final haystack = '${place.name} ${place.address ?? ''}'.toLowerCase();
    if (countryCode == 'IN') {
      return haystack.contains('district legal services authority') ||
          haystack.contains('state legal services authority') ||
          haystack.contains('legal services authority');
    }
    if (countryCode == 'EG') {
      return haystack.contains('نقابة') ||
          haystack.contains('محكمة') ||
          haystack.contains('توثيق');
    }
    return haystack.contains('legal aid') ||
        haystack.contains('defensoria') ||
        haystack.contains('defensoría') ||
        haystack.contains('asistencia juridica') ||
        haystack.contains('asistencia jurídica') ||
        haystack.contains('bantuan hukum') ||
        haystack.contains('tro giup phap ly') ||
        haystack.contains('trợ giúp pháp lý') ||
        haystack.contains('adli yardim') ||
        haystack.contains('bar association') ||
        haystack.contains('law society') ||
        haystack.contains('public defender') ||
        haystack.contains('lawyers council');
  }

  String _fallbackName(String category) {
    return switch (category) {
      'Lawyer' => 'Nearby lawyer office',
      'Legal aid' => 'Nearby legal aid office',
      'Bar association' => 'Nearby bar association',
      'Notary' => 'Nearby notary office',
      'Court' => 'Nearby courthouse',
      _ => 'Nearby legal help',
    };
  }

  String _category(Map<String, dynamic> tags) {
    final nameFields = [
      tags['name'],
      tags['official_name'],
      tags['operator'],
    ].whereType<String>().join(' ').toLowerCase();

    if (_matchesAny(nameFields, const [
      r'legal aid',
      r'legal services',
      r'public defender',
      r'law centre',
      r'law center',
      r'citizens advice',
      r'community law',
      r'pro bono',
      r'legal services authority',
      r'defensor[ií]a',
      r'defensoria',
      r'asistencia jur[ií]dica',
      r'patrocinio jur[ií]dico',
      r'bantuan hukum',
      r'posbakum',
      r'adli yard[ıi]m',
      r'法テラス',
      r'법률구조',
      r'법률상담',
      r'trợ giúp pháp lý',
      r'tro giup phap ly',
      r'مساعدة قانونية',
      r'الخدمات القانونية',
      r'法律援助',
      r'कानूनी सहायता',
      r'विधिक सेवा',
    ])) {
      return 'Legal aid';
    }

    if (_matchesAny(nameFields, const [
      r'bar association',
      r'bar council',
      r'law society',
      r'state bar',
      r'colegio de abogados',
      r'ordem dos advogados',
      r'lawyers council',
      r'barosu',
      r'변호사회',
      r'đoàn luật sư',
      r'doan luat su',
      r'نقابة المحامين',
      r'律师协会',
      r'बार एसोसिएशन',
      r'बार काउंसिल',
    ])) {
      return 'Bar association';
    }

    if (tags['lawyer'] == 'notary' ||
        tags['office'] == 'notary' ||
        _matchesAny(nameFields, const [
          r'notary',
          r'notarial',
          r'notar[ií]a',
          r'cart[óo]rio',
          r'notaris',
          r'공증',
          r'公証',
          r'công chứng',
          r'cong chung',
          r'كاتب عدل',
          r'توثيق',
          r'公证',
          r'नोटरी',
        ])) {
      return 'Notary';
    }

    if (tags['amenity'] == 'courthouse' ||
        _matchesAny(nameFields, const [
          r'court',
          r'courthouse',
          r'tribunal',
          r'pengadilan',
          r'mahkeme',
          r'법원',
          r'裁判所',
          r'tòa án',
          r'toa an',
          r'محكمة',
          r'法院',
          r'法庭',
          r'न्यायालय',
          r'अदालत',
        ])) {
      return 'Court';
    }

    if (tags['office'] == 'lawyer' ||
        _matchesAny(nameFields, const [
          r'lawyer',
          r'attorney',
          r'advocate',
          r'solicitor',
          r'avocat',
          r'abogado',
          r'advogado',
          r'avukat',
          r'advokat',
          r'변호사',
          r'弁護士',
          r'luật sư',
          r'luat su',
          r'محام',
          r'律师',
          r'वकील',
        ])) {
      return 'Lawyer';
    }

    return 'Legal help';
  }

  bool _matchesAny(String haystack, List<String> patterns) {
    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(haystack)) {
        return true;
      }
    }
    return false;
  }

  String? _address(Map<String, dynamic> tags) {
    final parts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:city'],
      tags['addr:state'],
    ]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(', ');
  }

  String? _firstPresent(Map<String, dynamic> tags, List<String> keys) {
    for (final key in keys) {
      final value = tags[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _normalizeWebsite(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    return 'https://$value';
  }

  List<OfficialLegalResource> _officialResourcesFor(String? countryCode) {
    final entries =
        legalOfficialResourcesByCountryCode[countryCode?.toUpperCase()];
    if (entries == null || entries.isEmpty) {
      return const [];
    }

    return entries
        .map(
          (entry) => OfficialLegalResource(
            name: entry.name,
            description: entry.description,
            website: entry.website,
            phone: entry.phone,
          ),
        )
        .toList(growable: false);
  }

  CountryLegalHelpProfile _countryProfileFor(String? countryCode) {
    final normalized = countryCode?.toUpperCase();

    if (normalized == null) {
      return const CountryLegalHelpProfile(
        radiusMeters: 7000,
        focusCategories: ['Lawyer', 'Legal aid', 'Notary', 'Court'],
        categoryScores: {
          'Lawyer': 0,
          'Legal aid': 1,
          'Notary': 2,
          'Court': 3,
          'Bar association': 4,
        },
        keywordsByCategory: {
          'Legal aid': [
            r'legal aid',
            r'legal services',
            r'public defender',
            r'law centre',
            r'law center',
            r'community law',
            r'pro bono',
          ],
          'Bar association': [
            r'bar association',
            r'bar council',
            r'law society',
          ],
        },
      );
    }

    if (const {'US', 'CA', 'AU', 'NZ'}.contains(normalized)) {
      return const CountryLegalHelpProfile(
        radiusMeters: 9000,
        focusCategories: [
          'Legal aid',
          'Lawyer',
          'Bar association',
          'Notary',
          'Court',
        ],
        categoryScores: {
          'Legal aid': 0,
          'Lawyer': 1,
          'Bar association': 2,
          'Notary': 3,
          'Court': 4,
        },
        keywordsByCategory: {
          'Legal aid': [
            r'legal aid',
            r'legal services',
            r'public defender',
            r'community law',
            r'pro bono',
          ],
          'Bar association': [
            r'bar association',
            r'state bar',
            r'law society',
          ],
        },
      );
    }

    if (const {'GB', 'IE'}.contains(normalized)) {
      return const CountryLegalHelpProfile(
        radiusMeters: 9000,
        focusCategories: [
          'Legal aid',
          'Lawyer',
          'Bar association',
          'Court',
          'Notary',
        ],
        categoryScores: {
          'Legal aid': 0,
          'Lawyer': 1,
          'Bar association': 2,
          'Court': 3,
          'Notary': 4,
        },
        keywordsByCategory: {
          'Legal aid': [
            r'legal aid',
            r'law centre',
            r'law center',
            r'citizens advice',
            r'community law',
          ],
          'Bar association': [
            r'law society',
            r'bar council',
          ],
        },
      );
    }

    if (normalized == 'IN') {
      return const CountryLegalHelpProfile(
        radiusMeters: 10000,
        focusCategories: [
          'Legal aid',
          'Bar association',
          'Lawyer',
          'Notary',
          'Court',
        ],
        categoryScores: {
          'Legal aid': 0,
          'Bar association': 1,
          'Lawyer': 2,
          'Notary': 3,
          'Court': 4,
        },
        keywordsByCategory: {
          'Legal aid': [
            r'legal services authority',
            r'legal aid',
            r'विधिक सेवा',
            r'कानूनी सहायता',
          ],
          'Bar association': [
            r'bar association',
            r'bar council',
            r'बार एसोसिएशन',
            r'बार काउंसिल',
          ],
        },
      );
    }

    if (const {'BD', 'LK', 'PK'}.contains(normalized)) {
      return const CountryLegalHelpProfile(
        radiusMeters: 9000,
        focusCategories: [
          'Legal aid',
          'Lawyer',
          'Bar association',
          'Court',
          'Notary',
        ],
        categoryScores: {
          'Legal aid': 0,
          'Lawyer': 1,
          'Bar association': 2,
          'Court': 3,
          'Notary': 4,
        },
        keywordsByCategory: {
          'Legal aid': [
            r'legal aid',
            r'legal services',
            r'national legal aid',
            r'legal aid office',
          ],
          'Bar association': [
            r'bar association',
            r'bar council',
            r'lawyers association',
          ],
        },
      );
    }

    if (const {
      'EG',
      'SA',
      'AE',
      'QA',
      'KW',
      'BH',
      'OM',
      'JO',
      'LB',
      'IQ',
      'MA',
      'TN',
      'DZ',
    }.contains(normalized)) {
      return const CountryLegalHelpProfile(
        radiusMeters: 9000,
        focusCategories: [
          'Lawyer',
          'Notary',
          'Bar association',
          'Court',
          'Legal aid',
        ],
        categoryScores: {
          'Lawyer': 0,
          'Notary': 1,
          'Bar association': 2,
          'Court': 3,
          'Legal aid': 4,
        },
        keywordsByCategory: {
          'Lawyer': [
            r'محام',
            r'مكتب محام',
            r'مكتب محاماة',
          ],
          'Notary': [
            r'كاتب عدل',
            r'توثيق',
            r'مكتب توثيق',
          ],
          'Bar association': [
            r'نقابة المحامين',
          ],
          'Legal aid': [
            r'مساعدة قانونية',
            r'الخدمات القانونية',
          ],
        },
      );
    }

    if (const {'JP', 'KR'}.contains(normalized)) {
      return const CountryLegalHelpProfile(
        radiusMeters: 9000,
        focusCategories: [
          'Lawyer',
          'Legal aid',
          'Notary',
          'Court',
          'Bar association',
        ],
        categoryScores: {
          'Lawyer': 0,
          'Legal aid': 1,
          'Notary': 2,
          'Court': 3,
          'Bar association': 4,
        },
        keywordsByCategory: {
          'Lawyer': [
            r'弁護士',
            r'변호사',
          ],
          'Legal aid': [
            r'法テラス',
            r'司法支援',
            r'법률구조',
            r'법률상담',
          ],
          'Notary': [
            r'公証',
            r'공증',
          ],
          'Bar association': [
            r'변호사회',
          ],
        },
      );
    }

    if (const {'ID', 'TH', 'VN', 'MY', 'PH'}.contains(normalized)) {
      return const CountryLegalHelpProfile(
        radiusMeters: 9000,
        focusCategories: [
          'Legal aid',
          'Lawyer',
          'Notary',
          'Court',
          'Bar association',
        ],
        categoryScores: {
          'Legal aid': 0,
          'Lawyer': 1,
          'Notary': 2,
          'Court': 3,
          'Bar association': 4,
        },
        keywordsByCategory: {
          'Legal aid': [
            r'legal aid',
            r'bantuan hukum',
            r'posbakum',
            r'trợ giúp pháp lý',
            r'tro giup phap ly',
          ],
          'Lawyer': [
            r'lawyer',
            r'advokat',
            r'luật sư',
            r'luat su',
          ],
          'Notary': [
            r'notary',
            r'notaris',
            r'công chứng',
            r'cong chung',
          ],
          'Bar association': [
            r'bar association',
            r'lawyers council',
            r'đoàn luật sư',
            r'doan luat su',
          ],
        },
      );
    }

    if (const {'BR', 'MX', 'AR', 'CL', 'CO', 'PE'}.contains(normalized)) {
      return const CountryLegalHelpProfile(
        radiusMeters: 9000,
        focusCategories: [
          'Legal aid',
          'Lawyer',
          'Notary',
          'Court',
          'Bar association',
        ],
        categoryScores: {
          'Legal aid': 0,
          'Lawyer': 1,
          'Notary': 2,
          'Court': 3,
          'Bar association': 4,
        },
        keywordsByCategory: {
          'Legal aid': [
            r'defensor[ií]a',
            r'defensoria',
            r'asistencia jur[ií]dica',
            r'patrocinio jur[ií]dico',
            r'ayuda legal',
          ],
          'Lawyer': [
            r'abogado',
            r'abogada',
            r'advogado',
            r'bufete',
            r'estudio jur[ií]dico',
          ],
          'Notary': [
            r'notar[ií]a',
            r'notario',
            r'cart[óo]rio',
          ],
          'Bar association': [
            r'colegio de abogados',
            r'ordem dos advogados',
          ],
        },
      );
    }

    if (const {'CN', 'HK', 'TW', 'SG'}.contains(normalized)) {
      return const CountryLegalHelpProfile(
        radiusMeters: 9000,
        focusCategories: [
          'Lawyer',
          'Legal aid',
          'Notary',
          'Court',
          'Bar association',
        ],
        categoryScores: {
          'Lawyer': 0,
          'Legal aid': 1,
          'Notary': 2,
          'Court': 3,
          'Bar association': 4,
        },
        keywordsByCategory: {
          'Lawyer': [
            r'律师',
            r'律师事务所',
          ],
          'Legal aid': [
            r'法律援助',
            r'法律服务',
          ],
          'Notary': [
            r'公证',
            r'公证处',
          ],
          'Bar association': [
            r'律师协会',
          ],
        },
      );
    }

    return const CountryLegalHelpProfile(
      radiusMeters: 8000,
      focusCategories: ['Lawyer', 'Legal aid', 'Notary', 'Court'],
      categoryScores: {
        'Lawyer': 0,
        'Legal aid': 1,
        'Notary': 2,
        'Court': 3,
        'Bar association': 4,
      },
      keywordsByCategory: {
        'Legal aid': [
          r'legal aid',
          r'legal services',
          r'defensor[ií]a',
          r'defensoria',
          r'bantuan hukum',
          r'tro giup phap ly',
          r'adli yard[ıi]m',
          r'법률구조',
          r'法テラス',
          r'法律援助',
          r'कानूनी सहायता',
          r'مساعدة قانونية',
        ],
        'Bar association': [
          r'bar association',
          r'law society',
          r'colegio de abogados',
          r'ordem dos advogados',
          r'lawyers council',
          r'barosu',
          r'نقابة المحامين',
          r'律师协会',
        ],
      },
    );
  }
}

class LegalHelpSnapshot {
  const LegalHelpSnapshot({
    required this.userLatitude,
    required this.userLongitude,
    required this.places,
    required this.countryCode,
    required this.countryName,
    required this.focusCategories,
    required this.officialResources,
    required this.nearbyLookupMessage,
  });

  final double userLatitude;
  final double userLongitude;
  final List<LegalHelpPlace> places;
  final String? countryCode;
  final String? countryName;
  final List<String> focusCategories;
  final List<OfficialLegalResource> officialResources;
  final String? nearbyLookupMessage;
}

class LegalHelpPlace {
  const LegalHelpPlace({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.website,
    required this.distanceMeters,
  });

  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final String? website;
  final double distanceMeters;
}

class LegalHelpRegion {
  const LegalHelpRegion({
    this.countryCode,
    this.countryName,
  });

  final String? countryCode;
  final String? countryName;
}

class CountryLegalHelpProfile {
  const CountryLegalHelpProfile({
    required this.radiusMeters,
    required this.focusCategories,
    required this.categoryScores,
    required this.keywordsByCategory,
  });

  final int radiusMeters;
  final List<String> focusCategories;
  final Map<String, int> categoryScores;
  final Map<String, List<String>> keywordsByCategory;

  int categoryScore(String category) {
    return categoryScores[category] ??
        LegalHelpService._defaultCategoryScores[category] ??
        100;
  }
}

class OfficialLegalResource {
  const OfficialLegalResource({
    required this.name,
    required this.description,
    this.website,
    this.phone,
  });

  final String name;
  final String description;
  final String? website;
  final String? phone;
}

class LegalHelpException implements Exception {
  const LegalHelpException(this.message);

  final String message;

  @override
  String toString() => message;
}
