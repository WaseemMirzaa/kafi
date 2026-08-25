import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/geo_location.dart';
import 'package:kafi_app/services/location_service.dart';
import 'package:kafi_app/services/places_service.dart';
import 'package:kafi_app/utils/constants/app_constants.dart';
import 'package:kafi_app/utils/constants/location_constants.dart';
import 'package:kafi_app/utils/kafi_text_context_menu.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// A selected location value. Carries the structured pieces the DB persists:
/// coordinates, a human-readable address, and (when reverse-geocoded) city and
/// country.
class KafiLocation {
  final String displayName;
  final String fullAddress;
  final double? lat;
  final double? lng;
  final String? city;
  final String? country;

  const KafiLocation({
    required this.displayName,
    required this.fullAddress,
    this.lat,
    this.lng,
    this.city,
    this.country,
  });

  @override
  String toString() => displayName;
}

/// Convert a picked [KafiLocation] into the persisted [GeoLocation] shape.
extension KafiLocationGeo on KafiLocation {
  GeoLocation toGeoLocation() => GeoLocation(
        lat: lat,
        lng: lng,
        address: fullAddress,
        city: city ?? '',
        country: country ?? '',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Public trigger widget
// ─────────────────────────────────────────────────────────────────────────────

/// Tappable field that opens the Uber-style Google Maps picker when a valid
/// Maps/Places API key is configured. Falls back to a curated UAE list only
/// when the key is still the placeholder (independent of Firebase mock mode).
class KafiLocationPicker extends StatefulWidget {
  const KafiLocationPicker({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.onLocationPicked,
    this.label,
  });

  final String? initialValue;
  final ValueChanged<String> onChanged;

  /// Optional richer callback with the full [KafiLocation] (coords + city +
  /// country + address) so callers can persist the structured location, not
  /// just the display string.
  final ValueChanged<KafiLocation>? onLocationPicked;
  final String? label;

  @override
  State<KafiLocationPicker> createState() => _KafiLocationPickerState();
}

class _KafiLocationPickerState extends State<KafiLocationPicker> {
  String _displayValue = '';

  /// Fallback sheet only when Maps/Places cannot run — not tied to Firebase mock.
  static bool get _useFallbackPicker =>
      AppConstants.googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY' ||
      AppConstants.googleMapsApiKey.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.initialValue ?? '';
  }

  @override
  void didUpdateWidget(covariant KafiLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect externally-driven changes (e.g. GPS auto-detect updating the
    // bound controller value), since this widget keeps its own display state.
    final incoming = widget.initialValue ?? '';
    if (incoming != oldWidget.initialValue && incoming != _displayValue) {
      setState(() => _displayValue = incoming);
    }
  }

  void _open(BuildContext context) async {
    final result = await showModalBottomSheet<KafiLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _useFallbackPicker
          ? _FallbackLocationSheet(initial: _displayValue)
          : const _LocationPickerSheet(),
    );
    if (result != null && result.displayName.trim().isNotEmpty) {
      setState(() => _displayValue = result.displayName.trim());
      widget.onChanged(result.displayName.trim());
      widget.onLocationPicked?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final empty = _displayValue.isEmpty;
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: KafiColors.cardBorder),
          borderRadius: BorderRadius.circular(12),
          color: KafiColors.inputBg,
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: KafiColors.roseD, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                empty ? (widget.label ?? AppStrings.locationPickerHint.tr) : _displayValue,
                style: KafiTheme.nunito(14,
                    color: empty ? KafiColors.ts : KafiColors.td),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            empty
                ? const Icon(Icons.keyboard_arrow_down_rounded, color: KafiColors.ts, size: 20)
                : Text(AppStrings.locationChange.tr,
                    style: KafiTheme.nunito(12, color: KafiColors.roseD, w: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback Uber-style sheet — searchable UAE areas + real-GPS nearest-area
// (used only when no Google Maps API key is configured)
// ─────────────────────────────────────────────────────────────────────────────

class _FallbackLocationSheet extends StatefulWidget {
  const _FallbackLocationSheet({this.initial = ''});
  final String initial;

  @override
  State<_FallbackLocationSheet> createState() => _FallbackLocationSheetState();
}

class _FallbackLocationSheetState extends State<_FallbackLocationSheet> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String? _selectedName;
  String? _selectedSubtitle;
  bool _locating = false;
  List<UaeArea> _filtered = LocationConstants.uaeAreas;

  @override
  void initState() {
    super.initState();
    if (widget.initial.trim().isNotEmpty) {
      _searchCtrl.text = widget.initial.trim();
      _selectedName = widget.initial.trim();
      _filter(widget.initial.trim());
    }
    // Do not autofocus — iOS SystemContextMenu races with sheet mount.
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = LocationConstants.uaeAreas;
      } else {
        _filtered = LocationConstants.uaeAreas
            .where((a) =>
                a.name.toLowerCase().contains(q) ||
                a.emirate.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  void _select(String name, String subtitle) {
    _focusNode.unfocus();
    setState(() {
      _selectedName = name;
      _selectedSubtitle = subtitle;
      _searchCtrl.text = name;
      _filtered = [];
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      String? name;
      String? subtitle;

      // 1) Full reverse-geocode when a Maps/Geocoding key is configured.
      if (Get.isRegistered<LocationService>()) {
        final detected = await Get.find<LocationService>().detectCurrentCity();
        if (detected != null && detected.trim().isNotEmpty) {
          name = detected.trim();
        }
      }

      // 2) Otherwise resolve REAL device GPS to the nearest known area. This
      // needs no API key, so "use my current location" is never a hardcoded
      // guess.
      if (name == null) {
        final pos = await _currentPosition();
        if (pos != null) {
          final nearest =
              LocationConstants.nearestArea(pos.latitude, pos.longitude);
          if (nearest != null) {
            name = nearest.name;
            subtitle = nearest.emirate;
          }
        }
      }

      if (name == null || name.isEmpty) {
        if (mounted) {
          Get.snackbar(
            AppStrings.errorTitle.tr,
            AppStrings.locationPermissionDenied.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return;
      }

      // Fill in the emirate subtitle from the curated list when only a name is
      // known (Google reverse-geocode path).
      subtitle ??= LocationConstants.emirateFor(name) ?? 'UAE';
      _select(name, subtitle);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Real device position via geolocator, requesting permission once. Returns
  /// null when location services are off or permission is denied.
  Future<Position?> _currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  void _confirm() {
    final name = (_selectedName ?? _searchCtrl.text).trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      KafiLocation(
        displayName: name,
        fullAddress: _selectedSubtitle != null ? '$name, ${_selectedSubtitle!}' : name,
        city: name,
        country: AppStrings.countryUae.tr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final hasSelection =
        (_selectedName ?? _searchCtrl.text).trim().isNotEmpty;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _handle(),
            _header(),
            _searchBar(),
            _currentLocationTile(),
            const Divider(height: 1),
            Expanded(child: _body(scrollCtrl)),
            if (hasSelection) _confirmBar(bottomPad),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: KafiColors.ts.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(AppStrings.locationPickerTitle.tr,
                  style: KafiTheme.fredoka(18, color: KafiColors.td)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: KafiColors.ts),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          decoration: BoxDecoration(
            color: KafiColors.inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: KafiColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: KafiColors.roseD.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.search, color: KafiColors.roseD, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _focusNode,
                  contextMenuBuilder: kafiNoTextContextMenu,
                  enableInteractiveSelection: false,
                  onChanged: (v) {
                    _selectedName = null;
                    _selectedSubtitle = null;
                    _filter(v);
                  },
                  style: KafiTheme.nunito(14, color: KafiColors.td),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppStrings.locationSearchHint.tr,
                    hintStyle: KafiTheme.nunito(14, color: KafiColors.ts),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: KafiColors.ts, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _selectedName = null;
                      _selectedSubtitle = null;
                      _filtered = LocationConstants.uaeAreas;
                    });
                  },
                ),
            ],
          ),
        ),
      );

  Widget _currentLocationTile() => ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: KafiColors.roseP,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _locating
              ? const Padding(
                  padding: EdgeInsets.all(9),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: KafiColors.roseD),
                )
              : const Icon(Icons.my_location_rounded,
                  color: KafiColors.roseD, size: 20),
        ),
        title: Text(AppStrings.locationUseCurrentLocation.tr,
            style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w600)),
        subtitle: Text(AppStrings.locationGPSSubtitle.tr,
            style: KafiTheme.nunito(11, color: KafiColors.ts)),
        onTap: _locating ? null : _useCurrentLocation,
      );

  Widget _body(ScrollController ctrl) {
    if (_selectedName != null && _filtered.isEmpty) {
      return _selectedPreview();
    }
    if (_filtered.isEmpty) {
      return ListView(
        controller: ctrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Center(
            child: Text(AppStrings.locationSearchPrompt.tr,
                style: KafiTheme.fredoka(16, color: KafiColors.td),
                textAlign: TextAlign.center),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: ctrl,
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (_, i) {
        final a = _filtered[i];
        final selected = _selectedName == a.name;
        return ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? KafiColors.roseP : KafiColors.navyS,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on_outlined,
                color: selected ? KafiColors.roseD : KafiColors.navy, size: 20),
          ),
          title: Text(a.name,
              style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w600)),
          subtitle: Text(a.emirate, style: KafiTheme.nunito(11, color: KafiColors.ts)),
          onTap: () => _select(a.name, a.emirate),
        );
      },
    );
  }

  Widget _selectedPreview() {
    final name = _selectedName!;
    final sub = _selectedSubtitle ?? '';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    KafiColors.roseP,
                    KafiColors.purL.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KafiColors.cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [KafiColors.roseD, KafiColors.pur],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.place_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(name,
                      style: KafiTheme.fredoka(18, color: KafiColors.td),
                      textAlign: TextAlign.center),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(sub,
                        style: KafiTheme.nunito(13, color: KafiColors.ts),
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmBar(double bottomPad) => Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPad),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: KafiColors.roseD,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(AppStrings.locationConfirm.tr,
                style: KafiTheme.nunito(15,
                    color: Colors.white, w: FontWeight.w700)),
            onPressed: _confirm,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Google Maps sheet — requires a valid Maps/Places API key
// ─────────────────────────────────────────────────────────────────────────────

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  static final _uaeCenter = LatLng(
    AppConstants.placesBiasLat,
    AppConstants.placesBiasLng,
  );

  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _placesService = PlacesService();

  List<PlacePrediction> _predictions = [];
  PlaceDetails? _selectedPlace;
  bool _searching = false;
  bool _locating = false;
  bool _resolvingPin = false;
  bool _programmaticMove = false;
  Timer? _debounce;
  Timer? _cameraDebounce;
  GoogleMapController? _mapCtrl;
  LatLng _cameraTarget = _uaeCenter;

  @override
  void initState() {
    super.initState();
    // Real GPS + reverse geocode as soon as the sheet opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cameraDebounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      final results = await _placesService.autocomplete(value);
      if (mounted) setState(() { _predictions = results; _searching = false; });
    });
  }

  Future<void> _selectPrediction(PlacePrediction p) async {
    _focusNode.unfocus();
    setState(() { _searching = true; _predictions = []; });
    final details = await _placesService.getDetails(p.placeId);
    if (!mounted) return;
    if (details != null) {
      _applyPlace(details, displayOverride: p.mainText);
      await _animateTo(details.lat, details.lng);
      setState(() => _searching = false);
    } else {
      setState(() => _searching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(AppStrings.locationServiceDisabled.tr);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError(AppStrings.locationPermissionDenied.tr);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final details =
          await _placesService.reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (details != null) {
        _applyPlace(details);
        await _animateTo(details.lat, details.lng);
      } else {
        _showError(AppStrings.locationPermissionDenied.tr);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _applyPlace(PlaceDetails details, {String? displayOverride}) {
    final label = displayOverride?.trim().isNotEmpty == true
        ? displayOverride!.trim()
        : details.shortLabel;
    _searchCtrl.text = label;
    setState(() {
      _selectedPlace = details;
      _cameraTarget = LatLng(details.lat, details.lng);
    });
  }

  Future<void> _animateTo(double lat, double lng) async {
    _programmaticMove = true;
    _cameraTarget = LatLng(lat, lng);
    await _mapCtrl?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _cameraTarget, zoom: 16),
      ),
    );
    // Allow camera-idle reverse-geocode again after the animation settles.
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      _programmaticMove = false;
    });
  }

  void _onCameraMove(CameraPosition position) {
    _cameraTarget = position.target;
  }

  void _onCameraIdle() {
    if (_programmaticMove || _predictions.isNotEmpty) return;
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() => _resolvingPin = true);
      try {
        final details = await _placesService.reverseGeocode(
          _cameraTarget.latitude,
          _cameraTarget.longitude,
        );
        if (!mounted || details == null) return;
        _applyPlace(details);
      } finally {
        if (mounted) setState(() => _resolvingPin = false);
      }
    });
  }

  void _showError(String msg) {
    if (mounted) {
      Get.snackbar(AppStrings.errorTitle.tr, msg, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _confirm() {
    final place = _selectedPlace;
    if (place == null) return;
    Navigator.pop(
      context,
      KafiLocation(
        displayName: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : place.shortLabel,
        fullAddress: place.formattedAddress,
        lat: place.lat,
        lng: place.lng,
        city: place.city ?? place.emirate,
        country: place.country,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _handle(),
            _header(),
            _searchBar(),
            _currentLocationTile(),
            const Divider(height: 1),
            Expanded(
              child: _predictions.isNotEmpty
                  ? _predictionsList(scrollCtrl)
                  : _mapWithPin(),
            ),
            if (_selectedPlace != null) _confirmBar(bottomPad),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: KafiColors.ts.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(AppStrings.locationPickerTitle.tr,
                  style: KafiTheme.fredoka(18, color: KafiColors.td)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: KafiColors.ts),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          decoration: BoxDecoration(
            color: KafiColors.inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: KafiColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: KafiColors.roseD.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.search, color: KafiColors.roseD, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _focusNode,
                  contextMenuBuilder: kafiNoTextContextMenu,
                  enableInteractiveSelection: false,
                  onChanged: _onSearchChanged,
                  style: KafiTheme.nunito(14, color: KafiColors.td),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppStrings.locationSearchHint.tr,
                    hintStyle: KafiTheme.nunito(14, color: KafiColors.ts),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_searching || _resolvingPin)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KafiColors.roseD,
                    ),
                  ),
                )
              else if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: KafiColors.ts, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _predictions = [];
                      _selectedPlace = null;
                    });
                  },
                ),
            ],
          ),
        ),
      );

  Widget _currentLocationTile() => ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: KafiColors.roseP,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _locating
              ? const Padding(
                  padding: EdgeInsets.all(9),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: KafiColors.roseD),
                )
              : const Icon(Icons.my_location_rounded,
                  color: KafiColors.roseD, size: 20),
        ),
        title: Text(AppStrings.locationUseCurrentLocation.tr,
            style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w600)),
        subtitle: Text(AppStrings.locationGPSSubtitle.tr,
            style: KafiTheme.nunito(11, color: KafiColors.ts)),
        onTap: _locating ? null : _useCurrentLocation,
      );

  Widget _predictionsList(ScrollController ctrl) => ListView.separated(
        controller: ctrl,
        itemCount: _predictions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
        itemBuilder: (_, i) {
          final p = _predictions[i];
          return ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: KafiColors.navyS,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: KafiColors.navy, size: 20),
            ),
            title: Text(p.mainText,
                style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w600)),
            subtitle: p.secondaryText.isNotEmpty
                ? Text(p.secondaryText,
                    style: KafiTheme.nunito(11, color: KafiColors.ts),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)
                : null,
            onTap: () => _selectPrediction(p),
          );
        },
      );

  /// Always-on Google Map with a fixed center pin (Uber-style). Drag the map
  /// to pick; camera-idle reverse-geocodes the pin into the search field.
  Widget _mapWithPin() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _cameraTarget, zoom: 14),
          onMapCreated: (c) => _mapCtrl = c,
          onCameraMove: _onCameraMove,
          onCameraIdle: _onCameraIdle,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          mapType: MapType.normal,
        ),
        // Fixed pin — the map moves under it.
        const IgnorePointer(
          child: Padding(
            padding: EdgeInsets.only(bottom: 36),
            child: Icon(Icons.location_on, color: KafiColors.roseD, size: 48),
          ),
        ),
        if (_selectedPlace != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _addressCard(_selectedPlace!),
          ),
        Positioned(
          right: 12,
          bottom: _selectedPlace != null ? 96 : 12,
          child: FloatingActionButton.small(
            heroTag: 'loc_gps',
            backgroundColor: Colors.white,
            onPressed: _locating ? null : _useCurrentLocation,
            child: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: KafiColors.roseD),
                  )
                : const Icon(Icons.my_location, color: KafiColors.roseD),
          ),
        ),
      ],
    );
  }

  Widget _addressCard(PlaceDetails place) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KafiColors.roseD, KafiColors.pur],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.place_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_searchCtrl.text.isNotEmpty ? _searchCtrl.text : place.shortLabel,
                      style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(place.formattedAddress,
                      style: KafiTheme.nunito(11, color: KafiColors.ts),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _confirmBar(double bottomPad) => Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPad),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: KafiColors.roseD,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(AppStrings.locationConfirm.tr,
                style: KafiTheme.nunito(15, color: Colors.white, w: FontWeight.w700)),
            onPressed: _confirm,
          ),
        ),
      );
}
