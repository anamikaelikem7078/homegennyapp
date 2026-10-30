import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';

/// Where a staff member is during today's shift: home + "at home" circle,
/// the staff member's last point and today's trail. Refreshes every
/// `next_refresh_sec` (60 s) while open. Outside the shift the server sends
/// no location — by design.
class ClientStaffLiveMapScreen extends ConsumerStatefulWidget {
  const ClientStaffLiveMapScreen({super.key, required this.staffId});

  final String staffId;

  @override
  ConsumerState<ClientStaffLiveMapScreen> createState() => _ClientStaffLiveMapScreenState();
}

/// A round marker with the staff member's initials — green at home, red
/// away — so the staff pin can't be mistaken for the home pin.
Future<BitmapDescriptor> _initialsMarker(String name, Color color) async {
  const size = 96.0;
  final initials = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(size / 2, size / 2);
  canvas.drawCircle(center, size / 2, Paint()..color = Colors.white);
  canvas.drawCircle(center, size / 2 - 7, Paint()..color = color);
  final text = TextPainter(
    text: TextSpan(
      text: initials.isEmpty ? '?' : initials,
      style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: 44, height: 44);
}

class _ClientStaffLiveMapScreenState extends ConsumerState<ClientStaffLiveMapScreen> {
  GoogleMapController? _map;
  Timer? _refresh;

  /// Drawn markers keyed by "name|atHome"; the default pin shows until ready.
  final _markerIcons = <String, BitmapDescriptor>{};

  BitmapDescriptor _staffIcon(String name, bool away) {
    final key = '$name|$away';
    final cached = _markerIcons[key];
    if (cached != null) return cached;
    _initialsMarker(name, away ? AppColors.error : AppColors.success).then((icon) {
      if (mounted) setState(() => _markerIcons[key] = icon);
    });
    // Placeholder while the bitmap is drawn; also blocks re-entry.
    return _markerIcons[key] = BitmapDescriptor.defaultMarkerWithHue(
      away ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
    );
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _map?.dispose();
    super.dispose();
  }

  void _scheduleRefresh(ClientStaffLocation data) {
    _refresh?.cancel();
    final seconds = data.nextRefreshSec;
    if (seconds == null || seconds <= 0) return;
    _refresh = Timer(Duration(seconds: seconds), () {
      if (mounted) ref.invalidate(clientStaffLocationProvider(widget.staffId));
    });
  }

  List<LatLng> _points(ClientStaffLocation d) => [
        if (d.home != null) LatLng(d.home!.lat, d.home!.lng),
        if (d.last != null) LatLng(d.last!.lat, d.last!.lng),
        for (final p in d.trail) LatLng(p.lat, p.lng),
      ];

  Future<void> _fit(ClientStaffLocation d) async {
    final map = _map;
    final points = _points(d);
    if (map == null || points.isEmpty) return;
    if (points.length == 1) {
      await map.animateCamera(CameraUpdate.newLatLngZoom(points.first, 16));
      return;
    }
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    // Keep at least the "at home" circle in view.
    const pad = 0.003;
    await map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south - pad, west - pad),
          northeast: LatLng(north + pad, east + pad),
        ),
        48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(clientStaffLocationProvider(widget.staffId));
    ref.listen(clientStaffLocationProvider(widget.staffId), (_, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      _scheduleRefresh(data);
      _fit(data);
    });
    // If the first load came from an already-resolved provider, the listener
    // above won't fire for it.
    final first = location.valueOrNull;
    if (first != null && _refresh == null) _scheduleRefresh(first);

    ClientStaffToday? staff;
    for (final s in ref.watch(clientTodayAttendanceProvider).valueOrNull?.staff ?? const <ClientStaffToday>[]) {
      if (s.staffId == widget.staffId) staff = s;
    }
    final name = staff?.name.split(' ').first ?? 'Staff';

    return DsPage(
      title: name,
      subtitle: 'Live location',
      onBack: () => context.canPop() ? context.pop() : context.go(ClientRoutes.attendanceToday),
      onRefresh: () async => ref.invalidate(clientStaffLocationProvider(widget.staffId)),
      body: dsAsyncBody(
        location,
        onRetry: () => ref.invalidate(clientStaffLocationProvider(widget.staffId)),
        builder: (d) => [
          _Header(name: name, data: d),
          const SizedBox(height: 14),
          if (_points(d).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 380,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _points(d).first, zoom: 15),
                  onMapCreated: (c) {
                    _map = c;
                    _fit(d);
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  // Lets the map pan inside the scrolling page.
                  gestureRecognizers: {Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)},
                  markers: {
                    if (d.home != null)
                      Marker(
                        markerId: const MarkerId('home'),
                        position: LatLng(d.home!.lat, d.home!.lng),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                        infoWindow: const InfoWindow(title: 'Home'),
                      ),
                    if (d.last != null)
                      Marker(
                        markerId: const MarkerId('staff'),
                        position: LatLng(d.last!.lat, d.last!.lng),
                        icon: _staffIcon(staff?.name ?? name, d.last!.atHome == false),
                        anchor: const Offset(0.5, 0.5),
                        infoWindow: InfoWindow(title: name, snippet: d.last!.label),
                      ),
                  },
                  circles: {
                    if (d.home != null)
                      Circle(
                        circleId: const CircleId('home-radius'),
                        center: LatLng(d.home!.lat, d.home!.lng),
                        radius: d.farMeters.toDouble(),
                        strokeWidth: 1,
                        strokeColor: AppColors.primary.withValues(alpha: 0.6),
                        fillColor: AppColors.primary.withValues(alpha: 0.08),
                      ),
                  },
                  polylines: {
                    if (d.trail.length > 1)
                      Polyline(
                        polylineId: const PolylineId('trail'),
                        points: [for (final p in d.trail) LatLng(p.lat, p.lng)],
                        width: 3,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                  },
                ),
              ),
            ),
          if (d.home == null) ...[
            const SizedBox(height: 14),
            DsListCard(
              icon: Icons.add_home_rounded,
              iconColor: AppColors.warning,
              title: 'Set your home on the map',
              subtitle: 'Needed to show whether staff are at your home',
              onTap: () => context.push(ClientRoutes.address),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.data});

  final String name;
  final ClientStaffLocation data;

  static String _ago(String iso) {
    final at = DateTime.tryParse(iso);
    if (at == null) return '';
    final minutes = DateTime.now().toUtc().difference(at.toUtc()).inMinutes;
    if (minutes < 1) return 'Updated just now';
    if (minutes < 60) return 'Updated $minutes min ago';
    return 'Updated at ${DateFormatter.time(iso)}';
  }

  @override
  Widget build(BuildContext context) {
    final last = data.last;
    final String title;
    String? label;
    Color? labelColor;
    final String sub;

    switch (data.status) {
      case 'PRESENT':
        final since = data.checkIn?.at;
        title = since == null ? '$name · Present' : '$name · Present since ${DateFormatter.since(since)}';
        if (last != null) {
          label = last.label;
          labelColor = last.atHome == false ? AppColors.error : AppColors.success;
          sub = last.stale ? 'Location not updated since ${DateFormatter.time(last.at)}' : _ago(last.at);
        } else {
          sub = 'Waiting for the first location update';
        }
      case 'CHECKED_OUT':
        title = data.checkOutAt == null ? 'Checked out' : 'Checked out at ${DateFormatter.time(data.checkOutAt)}';
        sub = 'Location is shared only during the shift.';
      default:
        title = 'Not checked in yet';
        sub = 'Location is shared only during the shift.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.lightTextPrimary,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: labelColor),
            ),
          ],
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: last?.stale == true ? AppColors.warning : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
