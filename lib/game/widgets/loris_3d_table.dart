import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

/// A real-time Three.js scene used as the LORIS table surface.
///
/// Flutter continues to render the interactive cards, seats and HUD above this
/// scene, while the table itself is rendered with perspective 3D geometry.
class Loris3DTable extends StatefulWidget {
  const Loris3DTable({super.key});

  @override
  State<Loris3DTable> createState() => _Loris3DTableState();
}

class _Loris3DTableState extends State<Loris3DTable> {
  late final three.ThreeJS _three;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _three = three.ThreeJS(
      setup: _setup,
      onSetupComplete: () {
        if (mounted) setState(() => _ready = true);
      },
    );
  }

  Future<void> _setup() async {
    final width = math.max(1.0, _three.width);
    final height = math.max(1.0, _three.height);

    _three.scene = three.Scene();
    _three.scene.background = three.Color(0x120D12);

    final camera = three.PerspectiveCamera(38, width / height, 0.1, 120);
    camera.position.setValues(0, 11.5, 13.8);
    camera.lookAt(_three.scene.position);
    _three.camera = camera;

    _three.scene.add(three.AmbientLight(0xFFF0D4, 0.82));

    final keyLight = three.DirectionalLight(0xFFF0D4, 1.45);
    keyLight.position.setValues(-5, 12, 7);
    _three.scene.add(keyLight);

    final redFill = three.PointLight(0x8D2437, 0.72);
    redFill.position.setValues(5, 4, -5);
    _three.scene.add(redFill);

    final floor = three.Mesh(
      three.PlaneGeometry(90, 90),
      three.MeshPhongMaterial.fromMap({
        'color': 0x170F16,
        'shininess': 18,
      }),
    );
    floor.rotation.x = -math.pi / 2;
    floor.position.y = -0.08;
    _three.scene.add(floor);

    // Sculpted dark-walnut table body, rendered as actual 3D geometry.
    final pedestal = three.Mesh(
      three.CylinderGeometry(2.5, 3.2, 0.82, 64),
      three.MeshPhongMaterial.fromMap({
        'color': 0x32151D,
        'shininess': 65,
      }),
    );
    pedestal.position.y = 0.43;
    pedestal.scale.setValues(1.5, 1, 0.92);
    _three.scene.add(pedestal);

    final goldUnderRim = three.Mesh(
      three.CylinderGeometry(5.82, 5.82, 0.18, 72),
      three.MeshPhongMaterial.fromMap({
        'color': 0xC58A36,
        'shininess': 105,
      }),
    );
    goldUnderRim.position.y = 0.88;
    goldUnderRim.scale.setValues(1.48, 1, 0.9);
    _three.scene.add(goldUnderRim);

    final tabletop = three.Mesh(
      three.CylinderGeometry(5.72, 5.72, 0.22, 96),
      three.MeshPhongMaterial.fromMap({
        'color': 0x07513B,
        'shininess': 92,
      }),
    );
    tabletop.position.y = 1.04;
    tabletop.scale.setValues(1.48, 1, 0.9);
    _three.scene.add(tabletop);

    final outerGoldRing = three.Mesh(
      three.TorusGeometry(5.58, 0.055, 12, 96),
      three.MeshPhongMaterial.fromMap({
        'color': 0xF4CC78,
        'shininess': 120,
      }),
    );
    outerGoldRing.rotation.x = math.pi / 2;
    outerGoldRing.position.y = 1.17;
    outerGoldRing.scale.setValues(1.48, 0.9, 1);
    _three.scene.add(outerGoldRing);

    final innerGoldRing = three.Mesh(
      three.TorusGeometry(5.18, 0.018, 8, 96),
      three.MeshPhongMaterial.fromMap({
        'color': 0xB98A45,
        'shininess': 100,
      }),
    );
    innerGoldRing.rotation.x = math.pi / 2;
    innerGoldRing.position.y = 1.17;
    innerGoldRing.scale.setValues(1.48, 0.9, 1);
    _three.scene.add(innerGoldRing);

    // Keep the camera fixed in the requested elevated Far View.
    camera.lookAt(three.Vector3(0, 0.9, 0));
  }

  @override
  void dispose() {
    _three.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(140),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF120D12)),
          _three.build(),
          if (!_ready)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFE7BD69),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
