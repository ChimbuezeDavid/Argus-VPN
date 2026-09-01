import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/server_model.dart';

class Globe3DBackground extends StatefulWidget {
  final List<ServerNode> servers;
  final ServerNode? selectedServer;
  final bool isConnected;
  final bool isConnecting;

  const Globe3DBackground({
    super.key,
    required this.servers,
    this.selectedServer,
    this.isConnected = false,
    this.isConnecting = false,
  });

  @override
  State<Globe3DBackground> createState() => _Globe3DBackgroundState();
}

class _Globe3DBackgroundState extends State<Globe3DBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _targetRotationY = 0.0;
  double _targetPitchX = 0.2; // Slight downward tilt for 3D perspective

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _updateTargetOrientation();
  }

  @override
  void didUpdateWidget(covariant Globe3DBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedServer?.id != widget.selectedServer?.id) {
      _updateTargetOrientation();
    }
  }

  void _updateTargetOrientation() {
    if (widget.selectedServer != null) {
      // Focus on the selected server longitude
      final lon = widget.selectedServer!.location.longitude ?? 8.6821;
      final lat = widget.selectedServer!.location.latitude ?? 50.1109;
      final lonRad = lon * math.pi / 180.0;
      final latRad = lat * math.pi / 180.0;
      _targetRotationY = lonRad;
      _targetPitchX = (latRad * 0.4).clamp(-0.4, 0.4);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, _) {
          // Ambient slow continuous auto-spin when disconnected, or smooth target orientation when selected
          final autoSpin = _rotationController.value * 2 * math.pi;
          final rotY = widget.selectedServer != null
              ? (_targetRotationY + (math.sin(autoSpin * 0.5) * 0.15))
              : autoSpin;

          return CustomPaint(
            size: Size.infinite,
            painter: _Globe3DPainter(
              rotationY: rotY,
              pitchX: _targetPitchX,
              servers: widget.servers,
              selectedServer: widget.selectedServer,
              isConnected: widget.isConnected,
              isConnecting: widget.isConnecting,
              animProgress: _rotationController.value,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class _Globe3DPainter extends CustomPainter {
  final double rotationY;
  final double pitchX;
  final List<ServerNode> servers;
  final ServerNode? selectedServer;
  final bool isConnected;
  final bool isConnecting;
  final double animProgress;
  final bool isDark;

  _Globe3DPainter({
    required this.rotationY,
    required this.pitchX,
    required this.servers,
    required this.selectedServer,
    required this.isConnected,
    required this.isConnecting,
    required this.animProgress,
    required this.isDark,
  });

  // Continental landmass point cloud (latitude, longitude)
  static final List<List<double>> _landmassPoints = [
    // North America
    [45.0, -100.0], [50.0, -110.0], [55.0, -120.0], [40.0, -80.0], [35.0, -90.0],
    [30.0, -100.0], [38.0, -120.0], [48.0, -95.0], [52.0, -85.0], [32.0, -85.0],
    [42.0, -73.0], [45.0, -75.0], [60.0, -110.0], [64.0, -150.0], [58.0, -135.0],
    [25.0, -102.0], [20.0, -100.0], [18.0, -95.0], [32.0, -115.0], [37.0, -105.0],

    // South America
    [-5.0, -60.0], [-10.0, -55.0], [-15.0, -48.0], [-23.0, -46.0], [-30.0, -60.0],
    [-35.0, -65.0], [-20.0, -65.0], [5.0, -70.0], [0.0, -75.0], [-12.0, -77.0],
    [-40.0, -68.0], [-50.0, -70.0], [-5.0, -40.0], [-8.0, -35.0],

    // Europe
    [51.0, 10.0], [48.0, 2.0], [52.0, 5.0], [55.0, -3.0], [40.0, -3.0],
    [41.0, 14.0], [47.0, 8.0], [59.0, 18.0], [60.0, 10.0], [50.0, 20.0],
    [45.0, 15.0], [44.0, 26.0], [38.0, 23.0], [53.0, 27.0], [56.0, 37.0],

    // Africa
    [30.0, 31.0], [25.0, 15.0], [15.0, 0.0], [10.0, -10.0], [5.0, 20.0],
    [0.0, 25.0], [-5.0, 15.0], [-15.0, 30.0], [-25.0, 28.0], [-33.0, 20.0],
    [5.0, 40.0], [10.0, 45.0], [20.0, 38.0], [12.0, 15.0], [6.5, 3.4],

    // Asia
    [35.0, 105.0], [40.0, 116.0], [31.0, 121.0], [35.0, 139.0], [37.0, 127.0],
    [22.0, 114.0], [1.3, 103.8], [13.0, 100.0], [28.0, 77.0], [19.0, 72.8],
    [55.0, 80.0], [60.0, 100.0], [50.0, 120.0], [25.0, 55.0], [30.0, 45.0],
    [43.0, 132.0], [48.0, 107.0], [23.0, 90.0], [15.0, 121.0],

    // Australia & Oceania
    [-33.0, 151.0], [-37.0, 145.0], [-27.0, 153.0], [-31.0, 115.0], [-23.0, 133.0],
    [-20.0, 140.0], [-35.0, 138.0], [-41.0, 174.0], [-36.0, 175.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Situate globe in the upper-mid area behind the power button
    final cy = size.height * 0.40;
    final radius = math.min(size.width, size.height) * 0.44;

    final primaryGlow = isDark ? AppColors.primaryEmerald : const Color(0xFF0D9488);
    final wireframeColor = isDark
        ? AppColors.primaryEmerald.withValues(alpha: 0.12)
        : const Color(0xFF0F172A).withValues(alpha: 0.08);

    // 1. Atmosphere Radial Backlight Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryGlow.withValues(alpha: isDark ? 0.22 : 0.12),
          primaryGlow.withValues(alpha: isDark ? 0.08 : 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.35));

    canvas.drawCircle(Offset(cx, cy), radius * 1.35, glowPaint);

    // 2. Globe Sphere Perimeter Ring
    final sphereOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = primaryGlow.withValues(alpha: isDark ? 0.35 : 0.20);
    canvas.drawCircle(Offset(cx, cy), radius, sphereOutline);

    // 3. 3D Latitude Rings
    final latPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = wireframeColor;

    for (double lat = -60.0; lat <= 60.0; lat += 30.0) {
      final latRad = lat * math.pi / 180.0;
      final ringRadius = radius * math.cos(latRad);
      final ringY = cy - (radius * math.sin(latRad) * math.cos(pitchX));
      final ringHeight = ringRadius * math.sin(pitchX).abs() * 0.8;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, ringY),
          width: ringRadius * 2,
          height: math.max(ringHeight * 2, 4.0),
        ),
        latPaint,
      );
    }

    // 4. 3D Longitude Meridian Curves
    for (double lon = 0; lon < 360; lon += 45) {
      final path = Path();
      bool firstPoint = true;

      for (double lat = -90; lat <= 90; lat += 10) {
        final pt = _project3D(lat, lon, cx, cy, radius);
        if (pt != null) {
          if (firstPoint) {
            path.moveTo(pt.dx, pt.dy);
            firstPoint = false;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
      }
      canvas.drawPath(path, latPaint);
    }

    // 5. 3D Landmass Mesh Points
    final landDotPaint = Paint()..style = PaintingStyle.fill;
    for (final point in _landmassPoints) {
      final pt = _project3D(point[0], point[1], cx, cy, radius);
      if (pt != null) {
        // Point is on visible hemisphere
        final depth = _getDepthZ(point[0], point[1]);
        final normalizedDepth = (depth / radius).clamp(0.1, 1.0);
        final dotSize = 2.0 + (normalizedDepth * 1.8);

        landDotPaint.color = isDark
            ? AppColors.primaryEmerald.withValues(alpha: 0.25 + (normalizedDepth * 0.45))
            : const Color(0xFF334155).withValues(alpha: 0.15 + (normalizedDepth * 0.35));

        canvas.drawCircle(pt, dotSize, landDotPaint);
      }
    }

    // 6. 3D Server Node Pins
    final nodePaint = Paint()..style = PaintingStyle.fill;
    final pulsePaint = Paint()..style = PaintingStyle.stroke;

    Offset? targetNodeOffset;

    for (final server in servers) {
      final lat = server.location.latitude ?? 50.1109;
      final lon = server.location.longitude ?? 8.6821;
      final pt = _project3D(lat, lon, cx, cy, radius);

      if (pt != null) {
        final depth = _getDepthZ(lat, lon);
        final normalizedDepth = (depth / radius).clamp(0.2, 1.0);
        final isSelected = selectedServer?.id == server.id;

        if (isSelected) {
          targetNodeOffset = pt;

          // Expanding 3D Radar Wave
          final waveRadius = 6.0 + (animProgress * 22.0 * normalizedDepth);
          final waveAlpha = (1.0 - animProgress).clamp(0.0, 1.0) * normalizedDepth;

          pulsePaint
            ..strokeWidth = 2.0
            ..color = AppColors.primaryEmerald.withValues(alpha: waveAlpha);

          canvas.drawCircle(pt, waveRadius, pulsePaint);

          // Center glowing pin
          nodePaint.color = AppColors.primaryEmerald;
          canvas.drawCircle(pt, 5.5 * normalizedDepth, nodePaint);

          nodePaint.color = Colors.white;
          canvas.drawCircle(pt, 2.5 * normalizedDepth, nodePaint);
        } else {
          // Ambient server pin
          nodePaint.color = AppColors.primaryCyan.withValues(alpha: 0.5 * normalizedDepth);
          canvas.drawCircle(pt, 3.0 * normalizedDepth, nodePaint);
        }
      }
    }

    // 7. 3D Laser Connection Stream Curve (Client Origin -> Target Server)
    if (isConnected || isConnecting) {
      final clientPt = _project3D(6.5244, 3.3792, cx, cy, radius); // Client local pos
      if (clientPt != null && targetNodeOffset != null) {
        final beamPath = Path();
        beamPath.moveTo(clientPt.dx, clientPt.dy);

        final midX = (clientPt.dx + targetNodeOffset.dx) / 2;
        final midY = ((clientPt.dy + targetNodeOffset.dy) / 2) - (35 * (radius / 150));

        beamPath.quadraticBezierTo(midX, midY, targetNodeOffset.dx, targetNodeOffset.dy);

        // Glowing 3D Laser Arc
        final arcGlowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..color = AppColors.primaryEmerald.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

        canvas.drawPath(beamPath, arcGlowPaint);

        final arcCorePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = Colors.white;

        canvas.drawPath(beamPath, arcCorePaint);

        // Traveling Laser Packet Particle
        final t = (animProgress * 2.0) % 1.0;
        final px = (1 - t) * (1 - t) * clientPt.dx + 2 * (1 - t) * t * midX + t * t * targetNodeOffset.dx;
        final py = (1 - t) * (1 - t) * clientPt.dy + 2 * (1 - t) * t * midY + t * t * targetNodeOffset.dy;

        final particlePaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white;
        canvas.drawCircle(Offset(px, py), 4.0, particlePaint);

        final particleGlow = Paint()
          ..style = PaintingStyle.fill
          ..color = AppColors.primaryEmerald.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        canvas.drawCircle(Offset(px, py), 8.0, particleGlow);
      }
    }
  }

  /// Calculates depth Z from viewer (positive = front hemisphere, negative = back)
  double _getDepthZ(double lat, double lon) {
    final latRad = lat * math.pi / 180.0;
    final lonRad = lon * math.pi / 180.0;

    final cosLat = math.cos(latRad);
    final sinLat = math.sin(latRad);
    final deltaLon = lonRad - rotationY;

    // 3D coordinates on unit sphere
    final yUnit = -sinLat;
    final zUnit = cosLat * math.cos(deltaLon);

    // Apply pitch rotation around X axis
    final zPitched = (zUnit * math.cos(pitchX)) - (yUnit * math.sin(pitchX));
    return zPitched;
  }

  /// Projects 3D (lat, lon) coordinates onto 2D Canvas space
  Offset? _project3D(double lat, double lon, double cx, double cy, double radius) {
    final latRad = lat * math.pi / 180.0;
    final lonRad = lon * math.pi / 180.0;

    final cosLat = math.cos(latRad);
    final sinLat = math.sin(latRad);
    final deltaLon = lonRad - rotationY;

    // 3D unit sphere
    final xUnit = cosLat * math.sin(deltaLon);
    final yUnit = -sinLat;
    final zUnit = cosLat * math.cos(deltaLon);

    // Apply pitch X rotation
    final yPitched = (yUnit * math.cos(pitchX)) + (zUnit * math.sin(pitchX));
    final zPitched = (zUnit * math.cos(pitchX)) - (yUnit * math.sin(pitchX));

    // Visible hemisphere check (z > 0 faces the camera)
    if (zPitched <= 0.05) return null;

    final screenX = cx + (xUnit * radius);
    final screenY = cy + (yPitched * radius);

    return Offset(screenX, screenY);
  }

  @override
  bool shouldRepaint(covariant _Globe3DPainter oldDelegate) => true;
}
