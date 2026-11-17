import 'dart:math' as math;

import 'package:flutter/material.dart' hide Material;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Native 3D LORIS table scene. All visible table props in this layer are
/// actual meshes rendered with perspective, PBR materials and real lighting.
class LorisTableSurface extends StatefulWidget {
  const LorisTableSurface({super.key, this.playerCount = 6});

  final int playerCount;

  @override
  State<LorisTableSurface> createState() => _LorisTableSurfaceState();
}

class _LorisTableSurfaceState extends State<LorisTableSurface> {
  final Scene _scene = Scene();
  bool _ready = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _initializeScene();
  }

  Future<void> _initializeScene() async {
    try {
      await Scene.initializeStaticResources();
      _scene.directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.45, -1, -0.65),
        color: vm.Vector3(1, 0.82, 0.62),
        intensity: 3.2,
        castsShadow: true,
        shadowMapResolution: 1536,
        shadowSoftness: 0.12,
      );

      // Dark studio floor and the heavy, lacquered table body.
      _addMesh(
        CuboidGeometry(vm.Vector3(200, 0.12, 200)),
        _pbr(0x160D16, roughness: 0.92),
        vm.Vector3(0, -0.72, 0),
      );
      _addMesh(
        CuboidGeometry(vm.Vector3(4.55, 0.30, 2.92)),
        _pbr(0x4B1821, metallic: 0.42, roughness: 0.28),
        vm.Vector3(0, 0.38, 0),
      );
      _addMesh(
        CuboidGeometry(vm.Vector3(4.42, 0.035, 2.80)),
        _pbr(0x741B2B, roughness: 0.82),
        vm.Vector3(0, 0.55, 0),
      );
      _addMesh(
        CuboidGeometry(vm.Vector3(4.48, 0.045, 2.86)),
        _pbr(0xD5A64A, metallic: 0.94, roughness: 0.2),
        vm.Vector3(0, 0.51, 0),
      );
      _addMesh(
        CuboidGeometry(vm.Vector3(4.36, 0.04, 2.74)),
        _pbr(0x761C2C, roughness: 0.88),
        vm.Vector3(0, 0.575, 0),
      );

      // Pedestal and foot: separate 3D meshes, not a painted border.
      _addMesh(
        CuboidGeometry(vm.Vector3(0.52, 0.88, 0.52)),
        _pbr(0x6C2630, metallic: 0.55, roughness: 0.3),
        vm.Vector3(0, -0.12, 0),
      );
      _addMesh(
        CuboidGeometry(vm.Vector3(1.25, 0.12, 0.92)),
        _pbr(0xB98736, metallic: 0.9, roughness: 0.22),
        vm.Vector3(0, -0.61, 0),
      );

      _addPlayers();
      _addThreeDimensionalCards();

      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  void _addPlayers() {
    final count = widget.playerCount == 4 ? 4 : 6;
    const skinTones = [0xE5B58F, 0xB97854, 0xD69A72, 0x8D563F, 0xF0C7A2, 0xA96B4B];
    const outfits = [0x263F63, 0x7C2636, 0x285C4B, 0x514071, 0x9A672D, 0x354A58];
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / count);
      final x = math.cos(angle) * 2.48;
      final z = math.sin(angle) * 1.78;
      final avatar = Node(name: '3d_player_${i + 1}');
      avatar.position = vm.Vector3(x, -0.02, z);
      avatar.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        angle + math.pi / 2,
      );
      final skin = _pbr(skinTones[i % skinTones.length], roughness: 0.78);
      final outfit = _pbr(outfits[i % outfits.length], roughness: 0.62);
      final hair = _pbr(0x211820, roughness: 0.9);

      avatar.add(_child(
        CapsuleGeometry(radius: 0.27, height: 0.48),
        outfit,
        vm.Vector3(0, 0.42, 0),
      ));
      avatar.add(_child(
        SphereGeometry(radius: 0.245, segments: 24, rings: 16),
        skin,
        vm.Vector3(0, 1.02, 0),
      ));
      avatar.add(_child(
        SphereGeometry(radius: 0.25, segments: 24, rings: 12),
        hair,
        vm.Vector3(0, 1.19, 0.035),
      ));
      final eye = _pbr(0x211820, roughness: 0.3);
      avatar.add(_child(
        SphereGeometry(radius: 0.027, segments: 12, rings: 8),
        eye,
        vm.Vector3(-0.075, 1.035, -0.218),
      ));
      avatar.add(_child(
        SphereGeometry(radius: 0.027, segments: 12, rings: 8),
        eye,
        vm.Vector3(0.075, 1.035, -0.218),
      ));
      avatar.add(_child(
        SphereGeometry(radius: 0.026, segments: 12, rings: 8),
        _pbr(0x8E3F43, roughness: 0.65),
        vm.Vector3(0, 0.94, -0.232),
      ));
      _scene.add(avatar);
    }
  }

  void _addThreeDimensionalCards() {
    final cardFace = _pbr(0xFFF4DF, roughness: 0.48);
    final cardBack = _pbr(0x8B1E30, metallic: 0.28, roughness: 0.38);
    final goldEdge = _pbr(0xD7AE59, metallic: 0.96, roughness: 0.2);

    // A small face-down deck in the middle, each card has physical thickness.
    for (var i = 0; i < 4; i++) {
      final card = Node(name: 'center_deck_card_$i');
      card.position = vm.Vector3(
        (i - 1.5) * 0.045,
        0.64 + i * 0.027,
        (i - 1.5) * -0.035,
      );
      card.rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        (i - 1.5) * 0.045,
      );
      card.add(_child(
        CuboidGeometry(vm.Vector3(0.46, 0.026, 0.66)),
        cardBack,
        vm.Vector3.zero(),
      ));
      card.add(_child(
        CuboidGeometry(vm.Vector3(0.425, 0.004, 0.625)),
        goldEdge,
        vm.Vector3(0, 0.015, 0),
      ));
      card.add(_child(
        CuboidGeometry(vm.Vector3(0.405, 0.003, 0.605)),
        cardFace,
        vm.Vector3(0, 0.018, 0),
      ));
      _scene.add(card);
    }

    // Physical card fans around all seats; the game-state texture/face binding
    // is the next integration step, while the cards themselves are 3D meshes.
    final count = widget.playerCount == 4 ? 4 : 6;
    for (var seat = 0; seat < count; seat++) {
      final angle = -math.pi / 2 + (math.pi * 2 * seat / count);
      final cx = math.cos(angle) * 1.48;
      final cz = math.sin(angle) * 1.04;
      final tangentX = -math.sin(angle);
      final tangentZ = math.cos(angle);
      for (var c = 0; c < 5; c++) {
        final spread = (c - 2) * 0.105;
        final card = Node(name: 'hand_${seat}_$c');
        card.position = vm.Vector3(
          cx + tangentX * spread,
          0.665 + c * 0.001,
          cz + tangentZ * spread,
        );
        card.rotation = vm.Quaternion.axisAngle(
          vm.Vector3(0, 1, 0),
          angle + math.pi,
        );
        card.add(_child(
          CuboidGeometry(vm.Vector3(0.34, 0.025, 0.49)),
          cardBack,
          vm.Vector3.zero(),
        ));
        card.add(_child(
          CuboidGeometry(vm.Vector3(0.315, 0.004, 0.465)),
          cardFace,
          vm.Vector3(0, 0.015, 0),
        ));
        _scene.add(card);
      }
    }
  }

  Node _child(
    Geometry geometry,
    Material material,
    vm.Vector3 position,
  ) {
    final node = Node(mesh: Mesh(geometry, material));
    node.position = position;
    return node;
  }

  void _addMesh(Geometry geometry, Material material, vm.Vector3 position) {
    final node = Node(mesh: Mesh(geometry, material));
    node.position = position;
    _scene.add(node);
  }

  PhysicallyBasedMaterial _pbr(
    int rgb, {
    double metallic = 0.0,
    double roughness = 0.7,
  }) {
    final material = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        ((rgb >> 16) & 0xFF) / 255,
        ((rgb >> 8) & 0xFF) / 255,
        (rgb & 0xFF) / 255,
        1,
      )
      ..metallicFactor = metallic
      ..roughnessFactor = roughness;
    return material;
  }

  @override
  void dispose() {
    _scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return const ColoredBox(color: Color(0xFF260A12));
    }
    if (!_ready) {
      return const ColoredBox(color: Color(0xFF260A12));
    }
    return SceneView(
      _scene,
      camera: PerspectiveCamera(
        position: vm.Vector3(0, 5.7, 8.1),
        target: vm.Vector3(0, 0.38, 0),
        fovRadiansY: 0.72,
        fovNear: 0.05,
        fovFar: 100,
      ),
    );
  }
}
