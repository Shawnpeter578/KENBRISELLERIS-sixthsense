import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:sixth_sense_app/screens/geofence.dart';

/// A phone-first live location and safe-boundary screen.
///
/// The widget keeps boundary storage outside the UI: use [onZoneSaved] to
/// persist the returned polygon in your backend/local database.
class SafeZoneMapScreen extends StatefulWidget {
  const SafeZoneMapScreen({
    super.key,
    this.personName = 'My location',
    this.initialCenter = const LatLng(12.9716, 77.5946),
    this.initialZone = const [],
    this.onZoneSaved,
    this.onZoneBreach,
  });

  final String personName;
  final LatLng initialCenter;
  final List<LatLng> initialZone;
  final ValueChanged<List<LatLng>>? onZoneSaved;
  final VoidCallback? onZoneBreach;

  @override
  State<SafeZoneMapScreen> createState() => _SafeZoneMapScreenState();
}

enum _Mode { live, draw }
enum _LocationState { loading, ready, serviceOff, denied, error }

const _navy = Color(0xFF10233D);
const _blue = Color(0xFF2F80ED);
const _safe = Color(0xFF13B887);
const _danger = Color(0xFFE85858);
const _surface = Color(0xFFF9FBFF);

class _SafeZoneMapScreenState extends State<SafeZoneMapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;

  _Mode _mode = _Mode.live;
  _LocationState _locationState = _LocationState.loading;
  List<LatLng> _zone = [];
  List<LatLng> _draft = [];
  late LatLng _person;
  DateTime? _lastUpdated;
  double? _accuracy;
  double? _distance;
  bool _outside = false;
  String? _locationError;

  bool get _hasZone => _zone.length >= 3;
  bool get _isDrawing => _mode == _Mode.draw;

  @override
  void initState() {
    super.initState();
    _person = widget.initialCenter;
    _zone = List.of(widget.initialZone);
    _evaluate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLiveLocation());
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLiveLocation() async {
    await _positionSubscription?.cancel();
    if (mounted) setState(() => _locationState = _LocationState.loading);

    if (!await Geolocator.isLocationServiceEnabled()) {
      _setLocationProblem(_LocationState.serviceOff, 'Turn on Location Services to show your live position.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _setLocationProblem(
        _LocationState.denied,
        permission == LocationPermission.deniedForever
            ? 'Location permission is blocked. Enable it in your phone settings.'
            : 'Allow location permission to show your live position.',
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5),
      );
      _updatePosition(position, recenter: true);
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5),
      ).listen(
        _updatePosition,
        onError: (_) => _setLocationProblem(_LocationState.error, 'Unable to update your live location.'),
      );
    } catch (_) {
      _setLocationProblem(_LocationState.error, 'Unable to get your live location. Try again.');
    }
  }

  void _setLocationProblem(_LocationState state, String message) {
    if (!mounted) return;
    setState(() {
      _locationState = state;
      _locationError = message;
    });
  }

  void _updatePosition(Position position, {bool recenter = false}) {
    if (!mounted) return;
    final point = LatLng(position.latitude, position.longitude);
    final wasOutside = _outside;
    final result = _evaluateAt(point);
    setState(() {
      _person = point;
      _accuracy = position.accuracy;
      _lastUpdated = DateTime.now();
      _locationState = _LocationState.ready;
      _locationError = null;
      _outside = result.$1;
      _distance = result.$2;
    });
    if (_outside && !wasOutside) {
      HapticFeedback.heavyImpact();
      widget.onZoneBreach?.call();
    }
    if (recenter) _mapController.move(point, 16);
  }

  (bool, double?) _evaluateAt(LatLng point) {
    if (!_hasZone) return (false, null);
    return (!isPointInPolygon(point, _zone), distanceToPolygonBoundaryMeters(point, _zone));
  }

  void _evaluate() {
    final result = _evaluateAt(_person);
    _outside = result.$1;
    _distance = result.$2;
  }

  void _onTap(TapPosition _, LatLng point) {
    if (_isDrawing) setState(() => _draft.add(point));
  }

  void _beginDrawing() => setState(() {
        _mode = _Mode.draw;
        _draft = List.of(_zone);
      });

  void _cancelDrawing() => setState(() {
        _mode = _Mode.live;
        _draft = [];
      });

  void _saveBoundary() {
    if (_draft.length < 3) return;
    final wasOutside = _outside;
    final result = (
      !isPointInPolygon(_person, _draft),
      distanceToPolygonBoundaryMeters(_person, _draft),
    );
    setState(() {
      _zone = List.of(_draft);
      _draft = [];
      _mode = _Mode.live;
      _outside = result.$1;
      _distance = result.$2;
    });
    widget.onZoneSaved?.call(List.unmodifiable(_zone));
    if (_outside && !wasOutside) {
      HapticFeedback.heavyImpact();
      widget.onZoneBreach?.call();
    }
  }

  void _removeBoundary() {
    setState(() {
      _zone = [];
      _draft = [];
      _mode = _Mode.live;
      _outside = false;
      _distance = null;
    });
    widget.onZoneSaved?.call(const []);
  }

  void _recenter() => _mapController.move(_person, 16);

  @override
  Widget build(BuildContext context) {
    final signal = _outside ? _danger : _safe;
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _person, initialZoom: 16, onTap: _onTap),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.sixth_sense_app',
              ),
              if (_hasZone)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _zone,
                      color: signal.withOpacity(.16),
                      borderColor: signal,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
              if (_isDrawing && _draft.length >= 2)
                PolylineLayer(polylines: [Polyline(points: _draft, color: _blue, strokeWidth: 3)]),
              if (_isDrawing)
                MarkerLayer(
                  markers: _draft.map((point) => Marker(point: point, width: 22, height: 22, child: const _Vertex())).toList(),
                ),
              MarkerLayer(markers: [Marker(point: _person, width: 64, height: 64, child: _LiveMarker(color: signal))]),
            ],
          ),
          _TopBar(mode: _mode, onClose: () => Navigator.of(context).maybePop(), onDraw: _beginDrawing, onCancel: _cancelDrawing),
          Positioned(
            right: 16,
            top: MediaQuery.paddingOf(context).top + 78,
            child: _MapButton(icon: Icons.my_location_rounded, tooltip: 'Center on my location', onPressed: _recenter),
          ),
          if (_locationState != _LocationState.ready)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 74,
              left: 16,
              right: 72,
              child: _LocationNotice(state: _locationState, message: _locationError, onRetry: _startLiveLocation),
            ),
          if (_outside)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 136,
              left: 16,
              right: 16,
              child: _BreachBanner(name: widget.personName, distance: _distance),
            ),
          _BottomPanel(
            drawing: _isDrawing,
            hasZone: _hasZone,
            outside: _outside,
            personName: widget.personName,
            accuracy: _accuracy,
            updatedAt: _lastUpdated,
            distance: _distance,
            draftCount: _draft.length,
            onStart: _beginDrawing,
            onUndo: _draft.isEmpty ? null : () => setState(() => _draft.removeLast()),
            onSave: _saveBoundary,
            onCancel: _cancelDrawing,
            onRemove: _removeBoundary,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.mode, required this.onClose, required this.onDraw, required this.onCancel});
  final _Mode mode;
  final VoidCallback onClose;
  final VoidCallback onDraw;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            _RoundSurface(icon: Icons.arrow_back_rounded, onTap: onClose),
            const SizedBox(width: 10),
            Expanded(
              child: _Surface(
                child: Text(
                  mode == _Mode.draw ? 'Draw safe boundary' : 'Live location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(color: _navy, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _Surface(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: TextButton.icon(
                onPressed: mode == _Mode.draw ? onCancel : onDraw,
                icon: Icon(mode == _Mode.draw ? Icons.close_rounded : Icons.draw_rounded, size: 18),
                label: Text(mode == _Mode.draw ? 'Cancel' : 'Draw'),
                style: TextButton.styleFrom(foregroundColor: _blue, textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ]),
        ),
      );
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.drawing, required this.hasZone, required this.outside, required this.personName, required this.accuracy, required this.updatedAt, required this.distance, required this.draftCount, required this.onStart, required this.onUndo, required this.onSave, required this.onCancel, required this.onRemove});
  final bool drawing, hasZone, outside;
  final String personName;
  final double? accuracy, distance;
  final DateTime? updatedAt;
  final int draftCount;
  final VoidCallback onStart, onSave, onCancel, onRemove;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) => Positioned(
        left: 12,
        right: 12,
        bottom: 12,
        child: SafeArea(
          top: false,
          child: _Surface(
            radius: 26,
            padding: const EdgeInsets.all(18),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: drawing ? _drawingCard() : _statusCard(),
            ),
          ),
        ),
      );

  Widget _drawingCard() => Column(key: const ValueKey('drawing'), mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Create your boundary', style: GoogleFonts.manrope(color: _navy, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 4),
        Text(draftCount < 3 ? 'Tap at least 3 points on the map. $draftCount added.' : '$draftCount points added. Save when the area looks right.', style: GoogleFonts.manrope(color: const Color(0xFF64748B), fontSize: 12.5, height: 1.35)),
        const SizedBox(height: 16),
        // Wrap actions so compact phones never receive a horizontal overflow.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(onPressed: onUndo, icon: const Icon(Icons.undo_rounded, size: 18), label: const Text('Undo')),
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
            FilledButton.icon(onPressed: draftCount >= 3 ? onSave : null, icon: const Icon(Icons.check_rounded, size: 18), label: const Text('Save boundary')),
          ],
        ),
      ]);

  Widget _statusCard() {
    final color = outside ? _danger : _safe;
    final status = outside ? 'Outside boundary' : hasZone ? 'Inside boundary' : 'No boundary yet';
    final detail = accuracy == null ? 'Finding your phone…' : 'Live • accurate to ${accuracy!.round()} m';
    return Column(key: const ValueKey('status'), mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(.12), shape: BoxShape.circle), child: Icon(Icons.location_on_rounded, color: color)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(personName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: _navy, fontWeight: FontWeight.w800, fontSize: 16)), Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(color: const Color(0xFF64748B), fontSize: 12))])),
      ]),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(99)), child: Text(status, style: GoogleFonts.manrope(color: color, fontWeight: FontWeight.w800, fontSize: 11))),
      if (hasZone) ...[
        const SizedBox(height: 12),
        Text(distance == null ? 'Boundary monitoring is active.' : '${distance!.round()} m from the nearest boundary', style: GoogleFonts.manrope(color: const Color(0xFF64748B), fontSize: 12.5)),
      ],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: onStart, icon: const Icon(Icons.draw_rounded, size: 18), label: Text(hasZone ? 'Edit boundary' : 'Draw boundary'))),
        if (hasZone) ...[const SizedBox(width: 10), IconButton.filledTonal(onPressed: onRemove, tooltip: 'Remove boundary', icon: const Icon(Icons.delete_outline_rounded, color: _danger))],
      ]),
    ]);
  }
}

class _LocationNotice extends StatelessWidget {
  const _LocationNotice({required this.state, required this.message, required this.onRetry});
  final _LocationState state;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loading = state == _LocationState.loading;
    final opensSettings = state == _LocationState.denied || state == _LocationState.serviceOff;
    return _Surface(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        if (loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2)) else const Icon(Icons.location_off_rounded, color: _danger, size: 20),
        const SizedBox(width: 9),
        Expanded(child: Text(loading ? 'Getting your live location…' : message ?? 'Location unavailable', style: GoogleFonts.manrope(color: _navy, fontWeight: FontWeight.w600, fontSize: 12))),
        if (!loading)
          TextButton(
            onPressed: opensSettings
                ? () {
                    if (state == _LocationState.serviceOff) {
                      Geolocator.openLocationSettings();
                    } else {
                      Geolocator.openAppSettings();
                    }
                  }
                : onRetry,
            child: Text(opensSettings ? 'Settings' : 'Retry'),
          ),
      ]),
    );
  }
}

class _BreachBanner extends StatelessWidget {
  const _BreachBanner({required this.name, required this.distance});
  final String name;
  final double? distance;
  @override
  Widget build(BuildContext context) => _Surface(radius: 16, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), child: Row(children: [const Icon(Icons.warning_amber_rounded, color: _danger), const SizedBox(width: 8), Expanded(child: Text(distance == null ? '$name has left the boundary' : '$name is ${distance!.round()} m from the boundary', style: GoogleFonts.manrope(color: _danger, fontWeight: FontWeight.w800, fontSize: 12.5)))]));
}

class _LiveMarker extends StatefulWidget {
  const _LiveMarker({required this.color});
  final Color color;
  @override
  State<_LiveMarker> createState() => _LiveMarkerState();
}

class _LiveMarkerState extends State<_LiveMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _controller, builder: (_, __) => Stack(alignment: Alignment.center, children: [Container(width: 30 + 24 * _controller.value, height: 30 + 24 * _controller.value, decoration: BoxDecoration(color: widget.color.withOpacity((.28 * (1 - _controller.value)).clamp(0.0, 1.0).toDouble()), shape: BoxShape.circle)), Container(width: 20, height: 20, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: widget.color.withOpacity(.45), blurRadius: 10)]))]));
}

class _Vertex extends StatelessWidget { const _Vertex(); @override Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _blue, width: 4), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)])); }
class _MapButton extends StatelessWidget { const _MapButton({required this.icon, required this.tooltip, required this.onPressed}); final IconData icon; final String tooltip; final VoidCallback onPressed; @override Widget build(BuildContext context) => _Surface(radius: 16, padding: EdgeInsets.zero, child: IconButton(onPressed: onPressed, tooltip: tooltip, icon: Icon(icon, color: _blue))); }
class _RoundSurface extends StatelessWidget { const _RoundSurface({required this.icon, required this.onTap}); final IconData icon; final VoidCallback onTap; @override Widget build(BuildContext context) => _Surface(radius: 16, padding: EdgeInsets.zero, child: IconButton(onPressed: onTap, icon: Icon(icon, color: _navy))); }
class _Surface extends StatelessWidget { const _Surface({required this.child, this.padding = const EdgeInsets.all(12), this.radius = 18}); final Widget child; final EdgeInsets padding; final double radius; @override Widget build(BuildContext context) => Container(padding: padding, decoration: BoxDecoration(color: Colors.white.withOpacity(.96), borderRadius: BorderRadius.circular(radius), border: Border.all(color: const Color(0xFFE5ECF6)), boxShadow: const [BoxShadow(color: Color(0x2410233D), blurRadius: 18, offset: Offset(0, 8))]), child: child); }
