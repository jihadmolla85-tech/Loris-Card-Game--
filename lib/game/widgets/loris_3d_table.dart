import 'package:material_ui/material_ui.dart';

/// Full-screen virtual LORIS table surface.
/// The screen itself becomes the playing felt; there is no separate table model.
class LorisTableSurface extends StatelessWidget {
  const LorisTableSurface({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(140),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9A2938),
                  Color(0xFF741A2A),
                  Color(0xFF4A0D1B),
                  Color(0xFF2B0712),
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 1.15,
                colors: [Color(0x33FFD88A), Color(0x00FFD88A), Color(0x5530000B)],
                stops: [0, 0.58, 1],
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(132),
                  border: Border.all(color: const Color(0x99FFE1A0), width: 1.4),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(124),
                  border: Border.all(color: const Color(0x33FFE7B2), width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
