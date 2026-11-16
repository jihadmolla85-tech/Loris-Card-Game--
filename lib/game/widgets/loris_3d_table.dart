import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

/// Real GPU-rendered 3D table foundation for the LORIS play surface.
/// Flutter continues to draw interactive HUD and player labels above it.
class Loris3DTable extends StatefulWidget {
  const Loris3DTable({super.key, this.playerCount = 4});

  final int playerCount;

  @override
  State<Loris3DTable> createState() => _Loris3DTableState();
}

class _Loris3DTableState extends State<Loris3DTable> {
  late final three.ThreeJS _three;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _three = three.ThreeJS(
      onSetupComplete: () {
        if (mounted) setState(() {});
      },
      setup: _setupScene,
    );
  }

  Future<void> _setupScene() async {
    try {
      _three.scene = three.Scene();
      _three.scene.background = three.Color.fromHex32(0xFF08090D);
      _three.camera = three.PerspectiveCamera(
        37,
        _three.width / math.max(1, _three.height),
        0.1,
        100,
      );
      _three.camera.position.setValues(0, 3.35, 5.7);
      _three.camera.lookAt(three.Vector3(0, 0, 0));

      _three.scene.add(three.AmbientLight(0xffffff, 1.15));

      final keyLight = three.DirectionalLight(0xffe2ad, 2.2);
      keyLight.position.setValues(-3, 6, 4);
      _three.scene.add(keyLight);

      final fillLight = three.PointLight(0xb44b55, 1.1);
      fillLight.position.setValues(2, 2.5, -2);
      _three.scene.add(fillLight);

      final rimMaterial = three.MeshStandardMaterial.fromMap({
        'color': 0xc89a43,
        'metalness': 0.88,
        'roughness': 0.24,
      });
      final darkMetal = three.MeshStandardMaterial.fromMap({
        'color': 0x32151d,
        'metalness': 0.72,
        'roughness': 0.3,
      });
      final feltMaterial = three.MeshStandardMaterial.fromMap({
        'color': 0x501923,
        'metalness': 0.08,
        'roughness': 0.92,
      });
      final cardMaterial = three.MeshStandardMaterial.fromMap({
        'color': 0xf7f0df,
        'metalness': 0.02,
        'roughness': 0.62,
      });
      final cardBackMaterial = three.MeshStandardMaterial.fromMap({
        'color': 0x7e1f2c,
        'metalness': 0.18,
        'roughness': 0.42,
      });

      // Solid elliptical pedestal and layered metallic tabletop.
      final pedestal = three.Mesh(
        three.CylinderGeometry(1.0, 1.12, 0.34, 64),
        darkMetal,
      )..scale.setValues(1.62, 1, 0.88);
      pedestal.position.y = -0.42;
      _three.scene.add(pedestal);

      final goldRim = three.Mesh(
        three.CylinderGeometry(1.0, 1.0, 0.17, 64),
        rimMaterial,
      )..scale.setValues(1.78, 1, 1.0);
      goldRim.position.y = -0.12;
      _three.scene.add(goldRim);

      final tableTop = three.Mesh(
        three.CylinderGeometry(1.0, 1.0, 0.14, 64),
        feltMaterial,
      )..scale.setValues(1.72, 1, 0.94);
      tableTop.position.y = -0.015;
      _three.scene.add(tableTop);

      final innerInlay = three.Mesh(
        three.CylinderGeometry(1.0, 1.0, 0.012, 64),
        three.MeshStandardMaterial.fromMap({
          'color': 0x681d2b,
          'metalness': 0.12,
          'roughness': 0.88,
        }),
      )..scale.setValues(1.55, 1, 0.79);
      innerInlay.position.y = 0.06;
      _three.scene.add(innerInlay);

      // Gold table legs, visible from the low cinematic camera.
      for (final x in [-1.15, 1.15]) {
        for (final z in [-0.58, 0.58]) {
          final leg = three.Mesh(
            three.CylinderGeometry(0.075, 0.11, 0.72, 20),
            darkMetal,
          );
          leg.position.setValues(x, -0.82, z);
          _three.scene.add(leg);
          final foot = three.Mesh(
            three.CylinderGeometry(0.13, 0.13, 0.055, 24),
            rimMaterial,
          );
          foot.position.setValues(x, -1.18, z);
          _three.scene.add(foot);
        }
      }

      // Physical card geometry on the felt: a small face-up trick and deck.
      final cardGroup = three.Group();
      for (var i = 0; i < 4; i++) {
        final card = three.Mesh(
          three.BoxGeometry(0.34, 0.018, 0.48),
          cardMaterial,
        );
        card.position.setValues((i - 1.5) * 0.17, 0.09 + i * 0.004, (i.isEven ? -0.03 : 0.03));
        card.rotation.y = (i - 1.5) * 0.13;
        card.rotation.x = -0.035;
        cardGroup.add(card);
      }
      _three.scene.add(cardGroup);

      final deck = three.Mesh(
        three.BoxGeometry(0.38, 0.075, 0.52),
        cardBackMaterial,
      );
      deck.position.setValues(-1.05, 0.11, 0.05);
      deck.rotation.y = -0.22;
      _three.scene.add(deck);

      final deckEdge = three.Mesh(
        three.BoxGeometry(0.385, 0.012, 0.525),
        rimMaterial,
      );
      deckEdge.position.setValues(-1.05, 0.15, 0.05);
      deckEdge.rotation.y = -0.22;
      _three.scene.add(deckEdge);

      // Sculpted seat plinths around the oval; Flutter avatars remain layered
      // above these anchors until full character models are supplied.
      final count = widget.playerCount == 6 ? 6 : 4;
      for (var i = 0; i < count; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * i / count);
        final x = math.cos(angle) * 2.12;
        final z = math.sin(angle) * 1.12;
        final seat = three.Mesh(
          three.CylinderGeometry(0.25, 0.29, 0.12, 32),
          darkMetal,
        );
        seat.position.setValues(x, -0.03, z);
        _three.scene.add(seat);

        final seatTrim = three.Mesh(
          three.CylinderGeometry(0.255, 0.255, 0.025, 32),
          rimMaterial,
        );
        seatTrim.position.setValues(x, 0.045, z);
        _three.scene.add(seatTrim);
      }

      _three.addAnimationEvent((dt) {
        // Very subtle idle motion keeps the rendered scene alive without
        // moving the board underneath interactive Flutter controls.
        cardGroup.rotation.y += dt * 0.018;
      });
    } catch (_) {
      _failed = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _three.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xff681d2b), Color(0xff160d12)],
          ),
        ),
      );
    }
    return RepaintBoundary(child: _three.build());
  }
}
