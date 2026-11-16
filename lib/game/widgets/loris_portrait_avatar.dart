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
    // Six distinct expressions make the table feel like a live match.
    final expression = variant % 6;
    final eyeWhite = Paint()..color = const Color(0xFFFFF8E9);
    final iris = Paint()..color = const Color(0xFF493126);
    final pupil = Paint()..color = const Color(0xFF17131A);
    final shine = Paint()..color = Colors.white;
    final eyeY = expression == 2 ? .485 : .49;
    final eyeHeight = expression == 2 ? .075 : .052;

    // A wink for one portrait; the others have expressive, detailed eyes.
    if (expression == 5) {
      canvas.drawOval(Rect.fromCenter(
        center: Offset(w * .40, h * eyeY),
        width: w * .13,
        height: h * eyeHeight,
      ), eyeWhite);
      canvas.drawCircle(Offset(w * .405, h * eyeY), w * .025, iris);
      canvas.drawCircle(Offset(w * .412, h * (eyeY - .012)), w * .009, shine);
      final wink = Paint()
        ..color = const Color(0xFF30201B)
        ..strokeWidth = w * .045
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * .55, h * .49), Offset(w * .66, h * .49), wink);
    } else {
      for (final x in [.40, .60]) {
        canvas.drawOval(Rect.fromCenter(
          center: Offset(w * x, h * eyeY),
          width: w * .13,
          height: h * eyeHeight,
        ), eyeWhite);
        final lookY = expression == 1 ? eyeY + .008 : eyeY;
        canvas.drawCircle(Offset(w * x, h * lookY), w * .032, iris);
        canvas.drawCircle(Offset(w * x, h * lookY), w * .018, pupil);
        canvas.drawCircle(Offset(w * (x - .009), h * (lookY - .012)), w * .008, shine);
      }
    }

    final brow = Paint()
      ..color = hair.color
      ..strokeWidth = w * .038
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leftBrow = Path();
    final rightBrow = Path();
    switch (expression) {
      case 0: // Warm, cheerful smile.
        leftBrow.moveTo(w * .34, h * .435);
        leftBrow.quadraticBezierTo(w * .40, h * .415, w * .46, h * .44);
        rightBrow.moveTo(w * .54, h * .44);
        rightBrow.quadraticBezierTo(w * .60, h * .415, w * .66, h * .435);
        break;
      case 1: // Focused competitor.
        leftBrow.moveTo(w * .34, h * .435);
        leftBrow.lineTo(w * .46, h * .465);
        rightBrow.moveTo(w * .54, h * .465);
        rightBrow.lineTo(w * .66, h * .435);
        break;
      case 2: // Surprised.
        leftBrow.moveTo(w * .34, h * .405);
        leftBrow.quadraticBezierTo(w * .40, h * .37, w * .46, h * .405);
        rightBrow.moveTo(w * .54, h * .405);
        rightBrow.quadraticBezierTo(w * .60, h * .37, w * .66, h * .405);
        break;
      case 3: // Confident.
        leftBrow.moveTo(w * .34, h * .445);
        leftBrow.lineTo(w * .46, h * .425);
        rightBrow.moveTo(w * .54, h * .425);
        rightBrow.lineTo(w * .66, h * .445);
        break;
      case 4: // Worried.
        leftBrow.moveTo(w * .34, h * .425);
        leftBrow.quadraticBezierTo(w * .40, h * .46, w * .46, h * .45);
        rightBrow.moveTo(w * .54, h * .45);
        rightBrow.quadraticBezierTo(w * .60, h * .46, w * .66, h * .425);
        break;
      default: // Playful wink.
        leftBrow.moveTo(w * .34, h * .43);
        leftBrow.quadraticBezierTo(w * .40, h * .405, w * .46, h * .43);
        rightBrow.moveTo(w * .55, h * .435);
        rightBrow.lineTo(w * .66, h * .435);
    }
    canvas.drawPath(leftBrow, brow);
    canvas.drawPath(rightBrow, brow);

    final nose = Paint()
      ..color = const Color(0xFF9C5D49)
      ..strokeWidth = w * .022
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .5, h * .51), Offset(w * .48, h * .57), nose);

    final mouthPaint = Paint()
      ..color = const Color(0xFF793B39)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .032
      ..strokeCap = StrokeCap.round;
    if (expression == 2) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * .5, h * .635), width: w * .105, height: h * .10),
        mouthPaint..style = PaintingStyle.fill,
      );
    } else {
      final mouth = Path()..moveTo(w * .42, h * .63);
      switch (expression) {
        case 0:
          mouth.quadraticBezierTo(w * .5, h * .715, w * .58, h * .63);
          break;
        case 1:
          mouth.lineTo(w * .58, h * .63);
          break;
        case 3:
          mouth.quadraticBezierTo(w * .53, h * .675, w * .59, h * .62);
          break;
        case 4:
          mouth.quadraticBezierTo(w * .5, h * .59, w * .58, h * .63);
          break;
        default:
          mouth.quadraticBezierTo(w * .5, h * .69, w * .58, h * .63);
      }
      canvas.drawPath(mouth, mouthPaint);
    }

    // Subtle cheek highlights help the small portraits read more clearly.
    final blush = Paint()..color = const Color(0x55D66B63);
    if (expression == 0 || expression == 5) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .34, h * .59), width: w * .09, height: h * .035), blush);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .66, h * .59), width: w * .09, height: h * .035), blush);
    }
  }

  @override
  bool shouldRepaint(covariant _LorisPortraitPainter oldDelegate) =>
      oldDelegate.variant != variant;

}
