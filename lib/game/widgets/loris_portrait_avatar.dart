import 'package:material_ui/material_ui.dart';

// Stylised human portrait used for every player seat (no animal emoji).
class LorisPortraitAvatar extends StatelessWidget {
  const LorisPortraitAvatar({
    super.key,
    required this.variant,
    this.size = 54,
    this.highlighted = false,
  });

  final int variant;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0A8), Color(0xFFD18B32), Color(0xFFFFD978)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: highlighted ? 12 : 6,
            spreadRadius: highlighted ? 1 : 0,
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _LorisPortraitPainter(variant: variant),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _LorisPortraitPainter extends CustomPainter {
  const _LorisPortraitPainter({required this.variant});
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final skinTones = [
      const Color(0xFFF2C6A0), const Color(0xFFD99A70),
      const Color(0xFFB87550), const Color(0xFF8D563F),
      const Color(0xFFE7B18B), const Color(0xFFC98A68),
    ];
    final hairColors = [
      const Color(0xFF211A20), const Color(0xFF3C241D),
      const Color(0xFF171C2A), const Color(0xFF5B3325),
    ];
    final clothes = [
      const Color(0xFF315B83), const Color(0xFF8D3542),
      const Color(0xFF356B5B), const Color(0xFF5B4388),
      const Color(0xFFB07832), const Color(0xFF34445B),
    ];
    final skin = Paint()..color = skinTones[variant % skinTones.length];
    final hair = Paint()..color = hairColors[variant % hairColors.length];
    final outfit = Paint()..color = clothes[variant % clothes.length];
    final bg = Paint()..shader = const LinearGradient(
      colors: [Color(0xFF8FC4D4), Color(0xFF294A69)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawCircle(Offset(w * .5, h * 1.08), w * .43, outfit);
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * .5, h * .47),
      width: w * .48,
      height: h * .59,
    ), skin);
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * .5, h * .29),
      width: w * .55,
      height: h * .39,
    ), hair);
    // Face is painted over the hair cap to keep a clear human portrait.
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * .5, h * .51),
      width: w * .43,
      height: h * .52,
    ), skin);
    final eye = Paint()..color = const Color(0xFF30201B);
    canvas.drawCircle(Offset(w * .40, h * .49), w * .025, eye);
    canvas.drawCircle(Offset(w * .60, h * .49), w * .025, eye);
    final brow = Paint()
      ..color = hair.color
      ..strokeWidth = w * .035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .35, h * .445), Offset(w * .44, h * .44), brow);
    canvas.drawLine(Offset(w * .56, h * .44), Offset(w * .65, h * .445), brow);
    final nose = Paint()
      ..color = const Color(0xFF9C5D49)
      ..strokeWidth = w * .022
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .5, h * .50), Offset(w * .48, h * .57), nose);
    final smile = Paint()
      ..color = const Color(0xFF793B39)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .025;
    final mouth = Path()
      ..moveTo(w * .43, h * .63)
      ..quadraticBezierTo(w * .5, h * .68, w * .57, h * .63);
    canvas.drawPath(mouth, smile);
  }

  @override
  bool shouldRepaint(covariant _LorisPortraitPainter oldDelegate) =>
      oldDelegate.variant != variant;

}
