import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sixth_sense_app/screens/geofence.dart';


/// Full-screen "Safe Zone" map for the caregiver.
///
/// Draw an area on the map, save it, and the pulsing dot representing the
/// blind person turns from mint to coral — with a banner — the moment
/// their location falls outside it.
///
/// This build keeps things intentionally simple: one shape, one signal
/// color pair, tap-to-simulate movement. Swap in a real location stream
/// later (see README) without touching the visual layer.
class SafeZoneMapScreen extends StatefulWidget {
  const SafeZoneMapScreen({
    super.key,
    this.personName = 'Meera',
    this.initialCenter = const LatLng(12.9716, 77.5946), // Bengaluru default
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

enum _Mode { draw, live }

// ---- Palette ---------------------------------------------------------
// One calm ink background, one mint "safe" signal, one coral "alert"
// signal. Everything else in the UI is a shade of white on top of glass.
const _ink = Color(0xFF0E1420);
const _mint = Color(0xFF6EE7D6);
const _coral = Color(0xFFFF6F6B);
const _glass = Color(0xFF1A2233);

class _SafeZoneMapScreenState extends State<SafeZoneMapScreen> {
  final MapController _mapController = MapController();

  _Mode _mode = _Mode.live;
  List<LatLng> _zone = [];
  List<LatLng> _draft = [];

  late LatLng _person;
  bool _outside = false;
  double? _distance;

  @override
  void initState() {
    super.initState();
    _person = widget.initialCenter;
    _zone = List.of(widget.initialZone);
    _evaluate();
  }

  bool get _hasZone => _zone.length >= 3;

  void _onTap(TapPosition _, LatLng point) {
    if (_mode == _Mode.draw) {
      setState(() => _draft.add(point));
    } else {
      setState(() => _person = point);
      _evaluate();
    }
  }

  void _evaluate() {
    if (!_hasZone) {
      setState(() {
        _outside = false;
        _distance = null;
      });
      return;
    }
    final inside = isPointInPolygon(_person, _zone);
    final dist = distanceToPolygonBoundaryMeters(_person, _zone);
    final wasOutside = _outside;
    setState(() {
      _outside = !inside;
      _distance = dist;
    });
    if (_outside && !wasOutside) {
      HapticFeedback.vibrate();
      widget.onZoneBreach?.call();
      // Hook a real push notification (FCM/APNs) here so the caregiver is
      // reached even when this screen isn't open — see README.
    }
  }

  void _startDrawing() => setState(() {
        _draft = List.of(_zone);
        _mode = _Mode.draw;
      });

  void _save() {
    if (_draft.length < 3) return;
    setState(() {
      _zone = List.of(_draft);
      _draft = [];
      _mode = _Mode.live;
    });
    widget.onZoneSaved?.call(_zone);
    _evaluate();
  }

  void _cancelDrawing() => setState(() {
        _draft = [];
        _mode = _Mode.live;
      });

  @override
  Widget build(BuildContext context) {
    final signal = _outside ? _coral : _mint;

    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _person,
              initialZoom: 16,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.safezone',
              ),
              if (_hasZone)
                PolygonLayer(polygons: [
                  Polygon(
                    points: _zone,
                    color: signal.withOpacity(0.10),
                    borderColor: signal.withOpacity(0.85),
                    borderStrokeWidth: 2.5,
                  ),
                ]),
              if (_mode == _Mode.draw && _draft.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(points: _draft, color: _mint, strokeWidth: 2.5),
                ]),
              if (_mode == _Mode.draw)
                MarkerLayer(
                  markers: _draft
                      .map((p) => Marker(
                            point: p,
                            width: 12,
                            height: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _mint,
                                border: Border.all(color: _ink, width: 2),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              MarkerLayer(markers: [
                Marker(
                  point: _person,
                  width: 56,
                  height: 56,
                  child: _Pulse(color: signal),
                ),
              ]),
            ],
          ),

          _Header(
            mode: _mode,
            onBack: () => Navigator.of(context).maybePop(),
            onMode: (m) => m == _Mode.draw ? _startDrawing() : _cancelDrawing(),
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _outside
                ? _AlertBar(key: const ValueKey('alert'), name: widget.personName, meters: _distance)
                : const SizedBox.shrink(key: ValueKey('none')),
          ),

          _BottomSheet(
            mode: _mode,
            hasZone: _hasZone,
            outside: _outside,
            distance: _distance,
            draftCount: _draft.length,
            personName: widget.personName,
            onStartDrawing: _startDrawing,
            onSave: _save,
            onCancel: _cancelDrawing,
            onUndo: _draft.isEmpty ? null : () => setState(() => _draft.removeLast()),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Presentation
// ============================================================================

class _Pulse extends StatefulWidget {
  const _Pulse({required this.color});
  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1 + _c.value * 1.4,
            child: Opacity(
              opacity: (1 - _c.value).clamp(0.0, 1.0) * 0.5,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
              ),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent floating glass surface used for every piece of chrome.
class _Glass extends StatelessWidget {
  const _Glass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 20});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _glass.withOpacity(0.86),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mode, required this.onBack, required this.onMode});
  final _Mode mode;
  final VoidCallback onBack;
  final ValueChanged<_Mode> onMode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            _Glass(
              radius: 16,
              padding: const EdgeInsets.all(10),
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(12),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
            const Spacer(),
            _Glass(
              radius: 16,
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Tab(label: 'Live', selected: mode == _Mode.live, onTap: () => onMode(_Mode.live)),
                  _Tab(label: 'Draw', selected: mode == _Mode.draw, onTap: () => onMode(_Mode.draw)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _mint : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: selected ? _ink : Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AlertBar extends StatelessWidget {
  const _AlertBar({super.key, required this.name, required this.meters});
  final String name;
  final double? meters;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 74,
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
        bottom: false,
        child: _Glass(
          radius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: _coral)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meters == null
                      ? '$name has left the safe zone'
                      : '$name is ${meters!.round()}m outside the safe zone',
                  style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  const _BottomSheet({
    required this.mode,
    required this.hasZone,
    required this.outside,
    required this.distance,
    required this.draftCount,
    required this.personName,
    required this.onStartDrawing,
    required this.onSave,
    required this.onCancel,
    required this.onUndo,
  });

  final _Mode mode;
  final bool hasZone;
  final bool outside;
  final double? distance;
  final int draftCount;
  final String personName;
  final VoidCallback onStartDrawing;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: mode == _Mode.draw ? _drawCard() : _liveCard(),
        ),
      ),
    );
  }

  Widget _drawCard() {
    return _Glass(
      key: const ValueKey('draw'),
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draftCount < 3 ? 'Tap the map to trace where they can go' : 'Keep tracing, or save this area',
            style: GoogleFonts.manrope(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: onUndo,
                icon: const Icon(Icons.undo_rounded, color: Colors.white54, size: 20),
                tooltip: 'Undo point',
              ),
              TextButton(
                onPressed: onCancel,
                child: Text('Cancel', style: GoogleFonts.manrope(color: Colors.white54, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: draftCount < 3 ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mint,
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'Save area',
                  style: GoogleFonts.manrope(
                    color: draftCount < 3 ? Colors.white38 : _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _liveCard() {
    if (!hasZone) {
      return _Glass(
        key: const ValueKey('empty'),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'No safe zone set yet',
                style: GoogleFonts.manrope(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: onStartDrawing,
              style: ElevatedButton.styleFrom(
                backgroundColor: _mint,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Draw zone', style: GoogleFonts.manrope(color: _ink, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    final signal = outside ? _coral : _mint;
    final status = outside ? 'Outside safe zone' : 'Inside safe zone';
    final sub = distance == null ? 'Tap the map to move $personName' : '${distance!.round()}m from the boundary';

    return _Glass(
      key: const ValueKey('status'),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: signal)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(personName, style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                Text(sub, style: GoogleFonts.manrope(color: Colors.white38, fontSize: 11.5)),
              ],
            ),
          ),
          Text(status, style: GoogleFonts.manrope(color: signal, fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onStartDrawing,
            icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 18),
            tooltip: 'Edit zone',
          ),
        ],
      ),
    );
  }
}