import 'package:flutter/material.dart';

class HealthGauge extends StatelessWidget {
  final int score;
  final double size;

  const HealthGauge({super.key, required this.score, this.size = 160});

  Color get _color {
    if (score >= 85) return const Color(0xFF2D6A4F);
    if (score >= 65) return const Color(0xFF6B9B4F);
    if (score >= 40) return const Color(0xFFC9772E);
    return const Color(0xFFC0392B);
  }

  String get _label {
    if (score >= 85) return 'ممتازة';
    if (score >= 65) return 'جيدة';
    if (score >= 40) return 'تحتاج انتباه';
    return 'تحتاج صيانة عاجلة';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              progress: score / 100,
              color: _color,
              trackColor: _color.withValues(alpha: 0.12),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: size * 0.19,
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _label,
                style: TextStyle(fontSize: size * 0.07, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _GaugePainter({required this.progress, required this.color, required this.trackColor});

  static const double _startAngle = 2.35619; // 135 degrees
  static const double _sweepAngle = 4.71239; // 270 degrees

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.09;
    final arcRect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, _startAngle, _sweepAngle, false, trackPaint);
    canvas.drawArc(arcRect, _startAngle, _sweepAngle * progress.clamp(0, 1), false, progressPaint);
    canvas.clipRect(rect);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
