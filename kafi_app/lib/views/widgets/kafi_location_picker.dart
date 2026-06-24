import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/services/places_service.dart';
import 'package:kafi_app/utils/constants/app_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// A selected location value.
class KafiLocation {
  final String displayName;
  final String fullAddress;
  final double? lat;
  final double? lng;

  const KafiLocation({
    required this.displayName,
    required this.fullAddress,
    this.lat,
    this.lng,
  });

  @override
  String toString() => displayName;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public trigger widget
// ─────────────────────────────────────────────────────────────────────────────

/// Tappable field that opens either a plain text sheet (mock / no API key) or
/// the full Uber-style Google Maps picker (live mode with a valid API key).
class KafiLocationPicker extends StatefulWidget {
  const KafiLocationPicker({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.label,
  });

  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? label;

  @override
  State<KafiLocationPicker> createState() => _KafiLocationPickerState();
}

class _KafiLocationPickerState extends State<KafiLocationPicker> {
  String _displayValue = '';

  /// Use plain text input when in mock mode or when no valid API key is set.
  static bool get _usePlainInput =>
      AppConfig.useMock ||
      AppConstants.googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY';

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
    if (_usePlainInput) {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PlainLocationSheet(initial: _displayValue),
      );
      if (result != null && result.trim().isNotEmpty) {
        setState(() => _displayValue = result.trim());
        widget.onChanged(result.trim());
      }
      return;
    }

    final result = await showModalBottomSheet<KafiLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LocationPickerSheet(),
    );
    if (result != null) {
      setState(() => _displayValue = result.displayName);
      widget.onChanged(result.displayName);
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
// Plain text sheet — used in mock mode / no API key
// ─────────────────────────────────────────────────────────────────────────────

class _PlainLocationSheet extends StatefulWidget {
  const _PlainLocationSheet({this.initial = ''});
  final String initial;

  @override
  State<_PlainLocationSheet> createState() => _PlainLocationSheetState();
}

class _PlainLocationSheetState extends State<_PlainLocationSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KafiColors.ts.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.locationPickerTitle.tr,
            style: KafiTheme.fredoka(18, color: KafiColors.td),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.locationManualHint.tr,
            style: KafiTheme.nunito(11, color: KafiColors.ts),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: KafiTheme.nunito(14, color: KafiColors.td),
            decoration: InputDecoration(
              hintText: AppStrings.locationSearchHint.tr,
              hintStyle: KafiTheme.nunito(14, color: KafiColors.ts),
              prefixIcon: const Icon(Icons.location_on_outlined, color: KafiColors.roseD, size: 20),
              filled: true,
              fillColor: KafiColors.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: KafiColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: KafiColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: KafiColors.roseD, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
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
              label: Text(
                AppStrings.locationConfirm.tr,
                style: KafiTheme.nunito(15, color: Colors.white, w: FontWeight.w700),
              ),
              onPressed: () {
                final v = _ctrl.text.trim();
                if (v.isNotEmpty) Navigator.pop(context, v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Google Maps sheet — live mode only
// ─────────────────────────────────────────────────────────────────────────────

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _placesService = PlacesService();

  List<PlacePrediction> _predictions = [];
  PlaceDetails? _selectedPlace;
  bool _searching = false;
  bool _locating = false;
  bool _mapReady = false;
  Timer? _debounce;
  GoogleMapController? _mapCtrl;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
      _searchCtrl.text = p.mainText;
      setState(() { _selectedPlace = details; _searching = false; _mapReady = false; });
      _animateTo(details.lat, details.lng);
    } else {
      setState(() => _searching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(AppStrings.locationServiceDisabled.tr);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
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
      final details = await _placesService.reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (details != null) {
        _searchCtrl.text = details.formattedAddress;
        setState(() { _selectedPlace = details; _mapReady = false; });
        _animateTo(details.lat, details.lng);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _animateTo(double lat, double lng) {
    _mapCtrl?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 15),
      ),
    );
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
        displayName: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : place.name,
        fullAddress: place.formattedAddress,
        lat: place.lat,
        lng: place.lng,
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
                  : _selectedPlace != null
                      ? _mapView()
                      : _emptyState(scrollCtrl),
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
              if (_searching)
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
                    setState(() { _predictions = []; _selectedPlace = null; });
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: KafiColors.roseD),
                )
              : const Icon(Icons.my_location_rounded, color: KafiColors.roseD, size: 20),
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

  Widget _mapView() {
    final place = _selectedPlace!;
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(place.lat, place.lng),
            zoom: 15,
          ),
          onMapCreated: (c) {
            _mapCtrl = c;
            setState(() => _mapReady = true);
          },
          markers: {
            Marker(
              markerId: const MarkerId('selected'),
              position: LatLng(place.lat, place.lng),
              infoWindow: InfoWindow(title: _searchCtrl.text),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: AnimatedSlide(
            offset: _mapReady ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _mapReady ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: _addressCard(place),
            ),
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
                  Text(_searchCtrl.text,
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

  Widget _emptyState(ScrollController ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: KafiColors.roseP,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.search_rounded, color: KafiColors.roseD, size: 36),
                ),
                const SizedBox(height: 14),
                Text(AppStrings.locationSearchPrompt.tr,
                    style: KafiTheme.fredoka(16, color: KafiColors.td),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(AppStrings.locationSearchSubPrompt.tr,
                    style: KafiTheme.nunito(12, color: KafiColors.ts),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
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
