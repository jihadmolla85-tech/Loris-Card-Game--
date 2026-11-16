import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Detailed illustrated player portrait with a varied global character roster.
/// Expression is supplied by the live match state; variant controls appearance.
class LorisPortraitAvatar extends StatelessWidget {
  const LorisPortraitAvatar({
    super.key,
    required this.variant,
    this.size = 54,
    this.highlighted = false,
    this.expression,
  });

  final int variant;
  final double size;
  final bool highlighted;
  final int? expression;

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
            color: Colors.black.withValues(alpha: .4),
            blurRadius: highlighted ? 14 : 7,
            spreadRadius: highlighted ? 1.5 : 0,
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _LorisPortraitPainter(
            variant: variant,
            expression: expression ?? variant % 6,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _LorisPortraitPainter extends CustomPainter {
  const _LorisPortraitPainter({
    required this.variant,
    required this.expression,
  });

  final int variant;
  final int expression;

  static const _skinTones = [
    Color(0xFFF5D0B1), Color(0xFFE9B994), Color(0xFFDCA27C),
    Color(0xFFC88963), Color(0xFFB87550), Color(0xFF985D43),
    Color(0xFF754832), Color(0xFF583728), Color(0xFFE8C0A0),
    Color(0xFFD7A17F), Color(0xFFAC755A), Color(0xFF8B5945),
  ];
  static const _hairColors = [
    Color(0xFF211A20), Color(0xFF3C241D), Color(0xFF171C2A),
    Color(0xFF5B3325), Color(0xFF302B28), Color(0xFF6A4936),
  ];
  static const _outfits = [
    Color(0xFF315B83), Color(0xFF8D3542), Color(0xFF356B5B),
    Color(0xFF5B4388), Color(0xFFB07832), Color(0xFF34445B),
    Color(0xFF176C75), Color(0xFF783E2C), Color(0xFF3D536D),
    Color(0xFF8B6B37), Color(0xFF5C3C54), Color(0xFF2D6650),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final style = variant % 12;
    final skinColor = _skinTones[style];
    final hairColor = _hairColors[variant % _hairColors.length];
    final outfitColor = _outfits[style];
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(const Color(0xFF9CCAD2), const Color(0xFFB38C75), style / 12)!,
          const Color(0xFF182E49),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Soft studio rim light and shoulders.
    canvas.drawCircle(Offset(w * .5, h * .38), w * .47,
        Paint()..color = const Color(0x22FFFFFF));
    final jacket = Paint()..color = outfitColor;
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * .5, h * 1.08),
      width: w * 1.02,
      height: h * .72,
    ), jacket);
    final collar = Paint()..color = Color.lerp(outfitColor, Colors.white, .34)!;
    final collarPath = Path()
      ..moveTo(w * .35, h * .78)
      ..lineTo(w * .5, h * .93)
      ..lineTo(w * .65, h * .78)
      ..lineTo(w * .58, h * .72)
      ..lineTo(w * .42, h * .72)
      ..close();
    canvas.drawPath(collarPath, collar);
    // Outfit trim gives the roster varied shirts, jackets and traditional looks.
    final trim = Paint()
      ..color = const Color(0x66F6D58B)
      ..strokeWidth = w * .025
      ..style = PaintingStyle.stroke;
    if (style % 3 == 0) {
      canvas.drawLine(Offset(w * .23, h * .83), Offset(w * .77, h * .83), trim);
    } else if (style % 3 == 1) {
      canvas.drawLine(Offset(w * .5, h * .86), Offset(w * .5, h), trim);
      canvas.drawCircle(Offset(w * .5, h * .84), w * .035, collar);
    } else {
      canvas.drawLine(Offset(w * .2, h * .91), Offset(w * .8, h * .91), trim);
    }

    // Neck and ears.
    final skin = Paint()..color = skinColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .42, h * .62, w * .16, h * .2),
        Radius.circular(w * .045),
      ),
      skin,
    );
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * .29, h * .49), width: w * .12, height: h * .19,
    ), skin);
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * .71, h * .49), width: w * .12, height: h * .19,
    ), skin);

    // Face shape and subtle cheek/jaw shading.
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * .5, h * .49), width: w * .48, height: h * .62,
    ), Paint()..color = Color.lerp(skinColor, Colors.black, .10)!);
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * .5, h * .47), width: w * .46, height: h * .60,
    ), skin);

    // Hair silhouettes vary between close-cut, curls, waves and long styles.
    final hair = Paint()..color = hairColor;
    switch (style % 4) {
      case 0: // Short neat hair.
        canvas.drawOval(Rect.fromCenter(
          center: Offset(w * .5, h * .245), width: w * .53, height: h * .30,
        ), hair);
        canvas.drawRect(Rect.fromLTWH(w * .235, h * .24, w * .10, h * .28), hair);
        canvas.drawRect(Rect.fromLTWH(w * .665, h * .24, w * .10, h * .28), hair);
        break;
      case 1: // Textured curls.
        canvas.drawOval(Rect.fromCenter(
          center: Offset(w * .5, h * .24), width: w * .61, height: h * .35,
        ), hair);
        for (var i = 0; i < 7; i++) {
          canvas.drawCircle(Offset(w * (.25 + i * .083), h * (.17 + (i.isEven ? .015 : -.015))),
              w * .075, hair);
        }
        break;
      case 2: // Long hair framing the face.
        canvas.drawOval(Rect.fromCenter(
          center: Offset(w * .5, h * .27), width: w * .62, height: h * .39,
        ), hair);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .22, h * .28, w * .13, h * .48), Radius.circular(w * .06),
        ), hair);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .65, h * .28, w * .13, h * .48), Radius.circular(w * .06),
        ), hair);
        break;
      default: // Curly / coiled hair.
        for (var i = 0; i < 9; i++) {
          canvas.drawCircle(Offset(w * (.22 + (i % 5) * .14), h * (.17 + (i ~/ 5) * .075)),
              w * .095, hair);
        }
        break;
    }

    // A few profiles wear a headwrap or a simple cap; no caricature props.
    if (style == 3 || style == 8) {
      final wrap = Paint()..color = style == 3
          ? const Color(0xFF9D3E46) : const Color(0xFF315A75);
      final wrapPaint = Paint()
        ..color = wrap.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .12;
      canvas.drawArc(
        Rect.fromLTWH(w * .24, h * .08, w * .52, h * .30),
        math.pi,
        math.pi,
        false,
        wrapPaint,
      );
      canvas.drawLine(Offset(w * .31, h * .20), Offset(w * .69, h * .20),
          Paint()..color = const Color(0x88F6D58B)..strokeWidth = w * .025);
    }

    // Eyebrows, eyes and expression.
    final brow = Paint()
      ..color = hairColor
      ..strokeWidth = w * .035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final eyeWhite = Paint()..color = const Color(0xFFFFF8EA);
    final iris = Paint()..color = const Color(0xFF493126);
    final pupil = Paint()..color = const Color(0xFF17131A);
    final shine = Paint()..color = Colors.white;
    final eyeY = expression == 2 ? .485 : .49;
    final eyeHeight = expression == 2 ? .075 : .052;
    if (expression == 5) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .40, h * eyeY),
          width: w * .13, height: h * eyeHeight), eyeWhite);
      canvas.drawCircle(Offset(w * .405, h * eyeY), w * .025, iris);
      canvas.drawCircle(Offset(w * .412, h * (eyeY - .012)), w * .009, shine);
      canvas.drawLine(Offset(w * .55, h * .49), Offset(w * .66, h * .49),
          brow..strokeWidth = w * .045);
    } else {
      for (final x in [.40, .60]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(w * x, h * eyeY),
            width: w * .13, height: h * eyeHeight), eyeWhite);
        canvas.drawCircle(Offset(w * x, h * eyeY), w * .032, iris);
        canvas.drawCircle(Offset(w * x, h * eyeY), w * .018, pupil);
        canvas.drawCircle(Offset(w * (x - .009), h * (eyeY - .012)), w * .008, shine);
      }
    }
    final leftBrow = Path();
    final rightBrow = Path();
    switch (expression) {
      case 0: // Happy.
        leftBrow.moveTo(w * .34, h * .435);
        leftBrow.quadraticBezierTo(w * .4, h * .415, w * .46, h * .44);
        rightBrow.moveTo(w * .54, h * .44);
        rightBrow.quadraticBezierTo(w * .6, h * .415, w * .66, h * .435);
        break;
      case 1: // Focused.
        leftBrow.moveTo(w * .34, h * .435); leftBrow.lineTo(w * .46, h * .465);
        rightBrow.moveTo(w * .54, h * .465); rightBrow.lineTo(w * .66, h * .435);
        break;
      case 2: // Surprised.
        leftBrow.moveTo(w * .34, h * .405);
        leftBrow.quadraticBezierTo(w * .4, h * .37, w * .46, h * .405);
        rightBrow.moveTo(w * .54, h * .405);
        rightBrow.quadraticBezierTo(w * .6, h * .37, w * .66, h * .405);
        break;
      case 3: // Confident.
        leftBrow.moveTo(w * .34, h * .445); leftBrow.lineTo(w * .46, h * .425);
        rightBrow.moveTo(w * .54, h * .425); rightBrow.lineTo(w * .66, h * .445);
        break;
      default: // Worried / disappointed.
        leftBrow.moveTo(w * .34, h * .425);
        leftBrow.quadraticBezierTo(w * .4, h * .46, w * .46, h * .45);
        rightBrow.moveTo(w * .54, h * .45);
        rightBrow.quadraticBezierTo(w * .6, h * .46, w * .66, h * .425);
    }
    canvas.drawPath(leftBrow, brow);
    canvas.drawPath(rightBrow, brow);

    // Nose, mouth and expression-specific cheek shading.
    final nose = Paint()..color = Color.lerp(skinColor, Colors.black, .30)!
      ..strokeWidth = w * .022..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .5, h * .51), Offset(w * .48, h * .57), nose);
    final mouthPaint = Paint()
      ..color = const Color(0xFF793B39)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .032
      ..strokeCap = StrokeCap.round;
    if (expression == 2) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .5, h * .635),
          width: w * .105, height: h * .10), mouthPaint..style = PaintingStyle.fill);
    } else {
      final mouth = Path()..moveTo(w * .42, h * .63);
      switch (expression) {
        case 0: mouth.quadraticBezierTo(w * .5, h * .715, w * .58, h * .63); break;
        case 1: mouth.lineTo(w * .58, h * .63); break;
        case 3: mouth.quadraticBezierTo(w * .53, h * .675, w * .59, h * .62); break;
        case 4: mouth.quadraticBezierTo(w * .5, h * .59, w * .58, h * .63); break;
        default: mouth.quadraticBezierTo(w * .5, h * .69, w * .58, h * .63);
      }
      canvas.drawPath(mouth, mouthPaint);
    }
    if (expression == 0 || expression == 5) {
      final blush = Paint()..color = const Color(0x44D66B63);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .34, h * .59),
          width: w * .09, height: h * .035), blush);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * .66, h * .59),
          width: w * .09, height: h * .035), blush);
    }
  }

  @override
  bool shouldRepaint(covariant _LorisPortraitPainter oldDelegate) =>
      oldDelegate.variant != variant || oldDelegate.expression != expression;
}
