import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_copy.dart';
import '../models/analysis_data.dart';
import '../services/legal_help_service.dart';

class LegalConnectScreen extends ConsumerStatefulWidget {
  const LegalConnectScreen({
    super.key,
    this.analysisData,
  });

  final AnalysisData? analysisData;

  @override
  ConsumerState<LegalConnectScreen> createState() => _LegalConnectScreenState();
}

class _LegalConnectScreenState extends ConsumerState<LegalConnectScreen> {
  Future<LegalHelpSnapshot>? _snapshotFuture;

  @override
  void initState() {
    super.initState();
    final initialLocale =
        WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
    _snapshotFuture = ref.read(legalHelpServiceProvider).loadNearbyHelp(
          localeTag: initialLocale,
        );
  }

  void _reload({bool forceRefresh = false}) {
    setState(() {
      _snapshotFuture = ref.read(legalHelpServiceProvider).loadNearbyHelp(
            localeTag: context.localeTag,
            forceRefresh: forceRefresh,
          );
    });
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }

    context.go('/capture');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: FutureBuilder<LegalHelpSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _buildLoading();
            }

            if (snapshot.hasError) {
              return _buildError(snapshot.error);
            }

            final data = snapshot.data;
            if (data == null) {
              return _buildError(null);
            }

            return _buildContent(data);
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    final copy = AppCopy.of(context);
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFFFFB300)),
                const SizedBox(height: 16),
                Text(
                  copy.loadingNearbyHelp,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  copy.usingGpsLiveData,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(Object? error) {
    final copy = AppCopy.of(context);
    final message =
        error is LegalHelpException ? error.message : copy.nearbyHelpFailed;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      color: Color(0xFFFFB300),
                      size: 42,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _reload(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: Text(copy.tryAgain),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(LegalHelpSnapshot snapshot) {
    final copy = AppCopy.of(context);
    final places = snapshot.places;
    final nearest = places.isNotEmpty ? places.first : null;
    final translatedFocus =
        snapshot.focusCategories.map(copy.translateCategory).toList();
    final officialResources = snapshot.officialResources;
    final nearbyLookupMessage = snapshot.nearbyLookupMessage;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.public, color: Color(0xFF64B5F6), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        snapshot.countryName ?? copy.nearbyLegalHelp,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...translatedFocus.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _infoChip(Icons.filter_alt_outlined, category),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (nearbyLookupMessage != null) ...[
                _buildNearbyFallbackCard(
                  showOfficialFallbackHint: officialResources.isNotEmpty,
                ),
                const SizedBox(height: 16),
              ],
              if (places.isNotEmpty) ...[
                SizedBox(
                  height: 280,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          snapshot.userLatitude,
                          snapshot.userLongitude,
                        ),
                        initialZoom: 13.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.beforeyousign.beforeyousign',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                snapshot.userLatitude,
                                snapshot.userLongitude,
                              ),
                              width: 54,
                              height: 54,
                              child: const _MapMarker(
                                icon: Icons.my_location,
                                color: Color(0xFF64B5F6),
                              ),
                            ),
                            ...places.map(
                              (place) => Marker(
                                point: LatLng(place.latitude, place.longitude),
                                width: 52,
                                height: 52,
                                child: const _MapMarker(
                                  icon: Icons.gavel,
                                  color: Color(0xFFFFB300),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (nearest != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _openNavigation(nearest),
                    icon: const Icon(Icons.navigation),
                    label: Text(copy.navigateToNearest(nearest.category)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (nearest.phone != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _call(nearest.phone!),
                      icon: const Icon(Icons.call),
                      label: Text(copy.callNearestOffice),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
              ],
              Text(
                places.isEmpty
                    ? copy.noNearbyResults
                    : copy.countryAwareResultsTitle(snapshot.countryName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (places.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    copy.noLegalResultsForCountry(snapshot.countryName),
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                )
              else
                ...places.map(_buildPlaceCard),
              if (officialResources.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  copy.officialSourcesTitle(snapshot.countryName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  copy.officialSourcesBody(places.isEmpty),
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                ...officialResources.map(_buildOfficialResourceCard),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyFallbackCard({
    required bool showOfficialFallbackHint,
  }) {
    final copy = AppCopy.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF152033),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF64B5F6).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF64B5F6), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              showOfficialFallbackHint
                  ? '${copy.nearbyFallbackTitle}. ${copy.nearbyFallbackHint}'
                  : copy.nearbyFallbackTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(LegalHelpPlace place) {
    final copy = AppCopy.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _pill(copy.translateCategory(place.category)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            copy.kmAway(place.distanceMeters / 1000),
            style: const TextStyle(
              color: Color(0xFFFFB300),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (place.address != null) ...[
            const SizedBox(height: 8),
            Text(
              place.address!,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionButton(
                icon: Icons.navigation,
                label: copy.navigate,
                onPressed: () => _openNavigation(place),
              ),
              if (place.phone != null)
                _actionButton(
                  icon: Icons.call,
                  label: copy.call,
                  onPressed: () => _call(place.phone!),
                ),
              if (place.website != null)
                _actionButton(
                  icon: Icons.language,
                  label: copy.website,
                  onPressed: () => _openWebsite(place.website!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final copy = AppCopy.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFFFB300), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _handleBack,
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white54,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.location_on, color: Color(0xFFFFB300), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              copy.nearbyLegalHelp,
              style: const TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _reload(forceRefresh: true),
            child: Text(
              copy.refresh,
              style: const TextStyle(color: Color(0xFF64B5F6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFB300),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF64B5F6), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialResourceCard(OfficialLegalResource resource) {
    final copy = AppCopy.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11192A),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF64B5F6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: Color(0xFF64B5F6),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                copy.officialSourceHeader,
                style: const TextStyle(
                  color: Color(0xFF64B5F6),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _pill(copy.officialSourceBadge),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            resource.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resource.description,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (resource.website != null)
                _actionButton(
                  icon: Icons.open_in_new,
                  label: copy.openOfficialSite,
                  onPressed: () => _openWebsite(resource.website!),
                ),
              if (resource.phone != null)
                _actionButton(
                  icon: Icons.call,
                  label: copy.callOfficialLine,
                  onPressed: () => _call(resource.phone!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _safeLaunchUrl(Uri uri, String fallbackMessage) async {
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackMessage),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackMessage),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openNavigation(LegalHelpPlace place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
    );
    await _safeLaunchUrl(uri, AppCopy.of(context).tryAgain);
  }

  Future<void> _call(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    await _safeLaunchUrl(uri, AppCopy.of(context).tryAgain);
  }

  Future<void> _openWebsite(String website) async {
    await _safeLaunchUrl(Uri.parse(website), AppCopy.of(context).tryAgain);
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black, size: 24),
    );
  }
}
