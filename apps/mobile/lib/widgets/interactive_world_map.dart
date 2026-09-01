import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/server_model.dart';

class InteractiveWorldMapBackground extends StatefulWidget {
  final List<ServerNode> servers;
  final ServerNode? selectedServer;
  final bool isConnected;
  final bool isConnecting;
  final Function(ServerNode)? onServerTapped;

  const InteractiveWorldMapBackground({
    super.key,
    required this.servers,
    this.selectedServer,
    required this.isConnected,
    required this.isConnecting,
    this.onServerTapped,
  });

  @override
  State<InteractiveWorldMapBackground> createState() => _InteractiveWorldMapBackgroundState();
}

class _InteractiveWorldMapBackgroundState extends State<InteractiveWorldMapBackground> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  Offset _geoToPixel(double lat, double lon, Size size) {
    final x = (lon + 180.0) * (size.width / 360.0);
    final y = (90.0 - lat) * (size.height / 180.0);
    return Offset(x, y);
  }

  void _handleTapDown(TapDownDetails details, Size size) {
    if (widget.servers.isEmpty) return;

    // Convert local screen position through transformation matrix
    final Matrix4 matrix = _transformController.value;
    final Matrix4 inverted = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    final Offset scenePos = MatrixUtils.transformPoint(inverted, details.localPosition);

    for (final server in widget.servers) {
      final lat = server.location.latitude ?? 0.0;
      final lon = server.location.longitude ?? 0.0;
      final pt = _geoToPixel(lat, lon, size);
      final dist = (pt - scenePos).distance;

      if (dist < 26.0) {
        widget.onServerTapped?.call(server);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onTapDown: (details) => _handleTapDown(details, size),
          child: InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(120),
            minScale: 0.85,
            maxScale: 3.5,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _VectorWorldMapPainter(
                    servers: widget.servers,
                    selectedServer: widget.selectedServer,
                    isConnected: widget.isConnected,
                    isConnecting: widget.isConnecting,
                    pulseProgress: _pulseController.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _VectorWorldMapPainter extends CustomPainter {
  final List<ServerNode> servers;
  final ServerNode? selectedServer;
  final bool isConnected;
  final bool isConnecting;
  final double pulseProgress;
  final bool isDark;

  _VectorWorldMapPainter({
    required this.servers,
    this.selectedServer,
    required this.isConnected,
    required this.isConnecting,
    required this.pulseProgress,
    required this.isDark,
  });

  Offset _geoToPixel(double lat, double lon, Size size) {
    final x = (lon + 180.0) * (size.width / 360.0);
    final y = (90.0 - lat) * (size.height / 180.0);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Map Canvas Background
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF090D14) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Subtle Coordinate Lat/Long Grid
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.035) : Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Stylized Continents & Landmass Vector Clusters
    final landPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;

    final continentClusters = [
      // North America
      [45.0, -100.0, 36.0], [55.0, -110.0, 30.0], [35.0, -95.0, 26.0], [30.0, -85.0, 22.0], [58.0, -135.0, 24.0],
      // South America
      [-15.0, -55.0, 30.0], [-25.0, -60.0, 25.0], [5.0, -70.0, 20.0], [-40.0, -65.0, 18.0],
      // Europe
      [50.0, 15.0, 24.0], [58.0, 10.0, 18.0], [45.0, 25.0, 20.0], [40.0, -3.0, 16.0], [62.0, 20.0, 16.0],
      // Africa
      [0.0, 20.0, 32.0], [15.0, 15.0, 26.0], [-20.0, 25.0, 24.0], [-30.0, 22.0, 18.0],
      // Asia & Middle East
      [40.0, 90.0, 46.0], [55.0, 80.0, 38.0], [25.0, 105.0, 32.0], [35.0, 120.0, 28.0], [25.0, 45.0, 22.0], [20.0, 78.0, 24.0],
      // Australia & Oceania
      [-25.0, 135.0, 28.0], [-38.0, 145.0, 16.0], [-42.0, 172.0, 14.0],
    ];

    for (final cluster in continentClusters) {
      final center = _geoToPixel(cluster[0], cluster[1], size);
      final radius = cluster[2] * (size.width / 420.0);
      canvas.drawCircle(center, radius, landPaint);
    }

    // 4. Laser Connection Beam Arc from Client to Selected Server
    if (isConnected && selectedServer != null) {
      final clientPt = _geoToPixel(6.5244, 3.3792, size); // Client Origin
      final destLat = selectedServer!.location.latitude ?? 50.1109;
      final destLon = selectedServer!.location.longitude ?? 8.6821;
      final serverPt = _geoToPixel(destLat, destLon, size);

      final arcPath = Path();
      arcPath.moveTo(clientPt.dx, clientPt.dy);

      final midX = (clientPt.dx + serverPt.dx) / 2;
      final midY = math.min(clientPt.dy, serverPt.dy) - 50.0;
      arcPath.quadraticBezierTo(midX, midY, serverPt.dx, serverPt.dy);

      // Arc Glow
      final arcGlow = Paint()
        ..color = AppColors.primaryEmerald.withValues(alpha: 0.35)
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(arcPath, arcGlow);

      // Arc Core Line
      final arcLine = Paint()
        ..color = AppColors.primaryEmerald
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(arcPath, arcLine);

      // Client Indicator
      final clientPaint = Paint()..color = AppColors.primaryCyan;
      canvas.drawCircle(clientPt, 5.0, clientPaint);
      canvas.drawCircle(clientPt, 2.5, Paint()..color = Colors.white);
    }

    // 5. Server Pins with Pulsing Radar Rings
    final pinPaint = Paint()..style = PaintingStyle.fill;
    final pulsePaint = Paint()..style = PaintingStyle.stroke;

    for (final server in servers) {
      final lat = server.location.latitude ?? 0.0;
      final lon = server.location.longitude ?? 0.0;
      final pt = _geoToPixel(lat, lon, size);
      final isSelected = selectedServer?.id == server.id;

      if (isSelected) {
        // Pulsing radar ring
        final waveRadius = 8.0 + (pulseProgress * 22.0);
        final waveAlpha = (1.0 - pulseProgress).clamp(0.0, 1.0);
        pulsePaint
          ..color = (isConnected ? AppColors.primaryEmerald : AppColors.warningOrange).withValues(alpha: waveAlpha * 0.8)
          ..strokeWidth = 2.2;
        canvas.drawCircle(pt, waveRadius, pulsePaint);

        // Pin Glow & Core
        pinPaint.color = isConnected ? AppColors.primaryEmerald : AppColors.warningOrange;
        canvas.drawCircle(pt, 8.5, pinPaint);
        pinPaint.color = Colors.white;
        canvas.drawCircle(pt, 3.5, pinPaint);
      } else {
        // Inactive Server Pin
        pinPaint.color = isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);
        canvas.drawCircle(pt, 4.0, pinPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VectorWorldMapPainter oldDelegate) => true;
}
