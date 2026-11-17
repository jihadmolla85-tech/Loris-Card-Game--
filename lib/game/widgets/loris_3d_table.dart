import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' hide Material;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;
import '../models/loris_card.dart' as loris;

/// Native 3D LORIS table scene. All visible table props in this layer are
/// actual meshes rendered with perspective, PBR materials and real lighting.
class LorisTableSurface extends StatefulWidget {
  const LorisTableSurface({super.key, this.playerCount = 6, this.hands, this.playedCards = const [], this.playedBy = const [], this.flyingCard, this.flyingFromPlayer, this.flightStarted = false, this.dealing = false, this.dealerIndex = 0, this.dealerDrawCards, this.dealerDrawVisibleCount = 0, this.dealerDrawStartPlayer = 0, this.dealerDrawActive = false});

  final int playerCount;
  final List<List<loris.Card>>? hands;
  final List<loris.Card> playedCards;
  final List<int> playedBy;
  final loris.Card? flyingCard;
  final int? flyingFromPlayer;
  final bool flightStarted;
  final bool dealing;
  final int dealerIndex;
  final List<loris.Card>? dealerDrawCards;
  final int dealerDrawVisibleCount;
  final int dealerDrawStartPlayer;
  final bool dealerDrawActive;

  @override
  State<LorisTableSurface> createState() => _LorisTableSurfaceState();
}

class _LorisTableSurfaceState extends State<LorisTableSurface> {
  late Scene _scene;
  String? _lastHandsSignature;
  bool _ready = false;
  Node? _flyingNode;
  Duration? _flightStartElapsed;
  Duration? _dealStartElapsed;
  Node? _dealerDrawNode;
  Duration? _dealerDrawStartElapsed;
  vm.Vector3? _dealerDrawStart;
  vm.Vector3? _dealerDrawTarget;
  final List<Node> _dealNodes = [];
  final List<vm.Vector3> _dealStarts = [];
  final List<vm.Vector3> _dealTargets = [];
  final List<Node> _avatarHeadNodes = [];
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _scene = Scene();
    _lastHandsSignature = _handsSignature(widget.hands);
    _initializeScene();
  }

  String _handsSignature(List<List<loris.Card>>? hands) {
    final handSignature = hands == null
        ? 'undealt'
        : hands.map((hand) => hand.map((card) => card.toString()).join(',')).join('|');
    final playedSignature = widget.playedCards.map((card) => card.toString()).join(',');
    final dealerSignature = widget.dealerDrawCards == null
        ? 'no-dealer-draw'
        : '${widget.dealerDrawVisibleCount}:${widget.dealerDrawStartPlayer}:${widget.dealerDrawActive}:${widget.dealerDrawCards!.take(widget.dealerDrawVisibleCount).join(',')}';
    return '$handSignature#played:$playedSignature#by:${widget.playedBy.join(',')}#flight:${widget.flyingCard}:${widget.flyingFromPlayer}:${widget.flightStarted}#deal:${widget.dealing}:${widget.dealerIndex}#$dealerSignature';
  }

  @override
  void didUpdateWidget(covariant LorisTableSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final signature = _handsSignature(widget.hands);
    if (oldWidget.playerCount != widget.playerCount || signature != _lastHandsSignature) {
      _lastHandsSignature = signature;
      _scene.dispose();
      _scene = Scene();
      _ready = false;
      _loadError = null;
      _initializeScene();
    }
  }

  Future<void> _initializeScene() async {
    _dealNodes.clear();
    _dealStarts.clear();
    _dealTargets.clear();
    _avatarHeadNodes.clear();
    _dealStartElapsed = null;
    _dealerDrawNode = null;
    _dealerDrawStartElapsed = null;
    _dealerDrawStart = null;
    _dealerDrawTarget = null;
    _flyingNode = null;
    _flightStartElapsed = null;
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
      _addPlayedCards();
      _addFlyingCard();

      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  void _addPlayers() {
    final count = widget.playerCount == 4 ? 4 : 6;
    const skinTones = [0xE5B58F, 0xB97854, 0xD69A72, 0x8D563F, 0xF0C7A2, 0xA96B4B];
    const outfits = [0x263F63, 0x7C2636, 0x285C4B, 0x514071, 0x9A672D, 0x354A58];
    const hairColors = [0x211820, 0x3A241D, 0x171C2A, 0x5B3325, 0x252525, 0x462A20];

    for (var i = 0; i < count; i++) {
      final angle = math.pi / 2 + (math.pi * 2 * i / count);
      final avatar = Node(name: '3d_seated_player_${i + 1}');
      // Keep players compact so the cards and table remain the visual focus.
      avatar.scale = vm.Vector3.all(0.56);
      avatar.position = vm.Vector3(math.cos(angle) * 2.48, -0.02, math.sin(angle) * 1.78);
      avatar.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), angle + math.pi / 2);

      final skin = _pbr(skinTones[i % skinTones.length], roughness: 0.78);
      final outfit = _pbr(outfits[i % outfits.length], roughness: 0.58);
      final hair = _pbr(hairColors[i % hairColors.length], roughness: 0.88);
      final shirt = _pbr(0xF5EBDD, roughness: 0.7);
      final tie = _pbr([0x9B263A, 0xB88732, 0x274B63, 0x315B49, 0x693C68, 0x9B4C2D][i], roughness: 0.48);
      final eyeWhite = _pbr(0xFFF9EE, roughness: 0.24);
      final iris = _pbr([0x4A2D22, 0x273C55, 0x3B271C, 0x31513D, 0x49352A, 0x30231F][i], roughness: 0.28);
      final dark = _pbr(0x211820, roughness: 0.7);
      final mouth = _pbr(0x873C43, roughness: 0.6);

      // Compact waist-up portrait only: no chair or lower-body geometry.
      // Small half-portrait silhouette: head, shoulders, upper torso and hands.
      avatar.add(_child(CapsuleGeometry(radius: 0.30, height: 0.58), outfit, vm.Vector3(0, 0.39, 0.02)));
      avatar.add(_child(SphereGeometry(radius: 0.245, segments: 24, rings: 14), outfit, vm.Vector3(0, 0.59, 0.015)));
      avatar.add(_child(CapsuleGeometry(radius: 0.078, height: 0.26), skin, vm.Vector3(0, 0.79, -0.005)));
      avatar.add(_child(CuboidGeometry(vm.Vector3(0.23, 0.19, 0.025)), shirt, vm.Vector3(0, 0.60, -0.205)));
      avatar.add(_child(CuboidGeometry(vm.Vector3(0.07, 0.23, 0.035)), tie, vm.Vector3(0, 0.49, -0.23)));
      avatar.add(_child(SphereGeometry(radius: 0.045, segments: 12, rings: 8), tie, vm.Vector3(0, 0.62, -0.245)));

      for (final side in [-1.0, 1.0]) {
        final lapel = _child(CuboidGeometry(vm.Vector3(0.105, 0.30, 0.035)), shirt, vm.Vector3(side * 0.105, 0.55, -0.218));
        lapel.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), side * -0.28);
        avatar.add(lapel);

        // Upper arm, forearm angled toward the felt and a visible hand.
        final upperArm = _child(CapsuleGeometry(radius: 0.092, height: 0.34), outfit, vm.Vector3(side * 0.30, 0.43, -0.015));
        upperArm.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), side * -0.55);
        avatar.add(upperArm);
        final forearm = _child(CapsuleGeometry(radius: 0.067, height: 0.34), outfit, vm.Vector3(side * 0.32, 0.48, -0.22));
        forearm.rotation = vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2);
        avatar.add(forearm);
        avatar.add(_child(CuboidGeometry(vm.Vector3(0.14, 0.09, 0.12)), shirt, vm.Vector3(side * 0.32, 0.49, -0.36)));
        avatar.add(_child(SphereGeometry(radius: 0.078, segments: 18, rings: 12), skin, vm.Vector3(side * 0.32, 0.50, -0.43)));
        for (var finger = 0; finger < 3; finger++) {
          avatar.add(_child(
            CapsuleGeometry(radius: 0.018, height: 0.085),
            skin,
            vm.Vector3(side * 0.32 + (finger - 1) * 0.035, 0.49, -0.49),
          ));
        }
        avatar.add(_child(SphereGeometry(radius: 0.072, segments: 16, rings: 10), skin, vm.Vector3(side * 0.235, 1.02, -0.005)));
      }

      // Head is a separate animated 3D rig pivot, not a flat portrait.
      final head = Node(name: 'player_head_rig_${i + 1}');
      head.position = vm.Vector3(0, 1.02, 0);
      head.add(_child(SphereGeometry(radius: 0.245, segments: 32, rings: 22), skin, vm.Vector3.zero()));
      head.add(_child(SphereGeometry(radius: 0.25, segments: 32, rings: 18), hair, vm.Vector3(0, 0.17, 0.035)));
      head.add(_child(SphereGeometry(radius: 0.095, segments: 20, rings: 12), hair, vm.Vector3(0, 0.205, -0.13)));
      // Side locks and layered fringe make each silhouette distinct.
      for (final side in [-1.0, 1.0]) {
        head.add(_child(SphereGeometry(radius: 0.075, segments: 18, rings: 12), hair, vm.Vector3(side * 0.19, 0.055, -0.015)));
        final brow = _child(CapsuleGeometry(radius: 0.018, height: 0.095), hair, vm.Vector3(side * 0.078, 0.105, -0.218));
        brow.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), side * (i == 4 ? -0.18 : 0.12));
        head.add(brow);
        head.add(_child(SphereGeometry(radius: 0.052, segments: 18, rings: 12), eyeWhite, vm.Vector3(side * 0.078, 0.025, -0.219)));
        head.add(_child(SphereGeometry(radius: 0.028, segments: 16, rings: 10), iris, vm.Vector3(side * 0.078, 0.025, -0.246)));
        head.add(_child(SphereGeometry(radius: 0.014, segments: 12, rings: 8), dark, vm.Vector3(side * 0.078, 0.025, -0.264)));
        head.add(_child(SphereGeometry(radius: 0.012, segments: 10, rings: 8), eyeWhite, vm.Vector3(side * 0.068, 0.038, -0.275)));
      }
      head.add(_child(SphereGeometry(radius: 0.044, segments: 16, rings: 10), skin, vm.Vector3(0, -0.045, -0.247)));
      head.add(_child(SphereGeometry(radius: 0.022, segments: 12, rings: 8), skin, vm.Vector3(-0.018, -0.062, -0.275)));
      head.add(_child(SphereGeometry(radius: 0.022, segments: 12, rings: 8), skin, vm.Vector3(0.018, -0.062, -0.275)));

      // Different mouth geometry gives the six seats distinct expressions.
      final expression = i % 6;
      final mouthNode = _child(
        CapsuleGeometry(radius: 0.017, height: expression == 2 || expression == 5 ? 0.055 : 0.10),
        mouth,
        vm.Vector3(0, -0.125, -0.231),
      );
      mouthNode.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2);
      head.add(mouthNode);
      if (expression == 2 || expression == 5) {
        head.add(_child(SphereGeometry(radius: 0.025, segments: 14, rings: 10), mouth, vm.Vector3(0, -0.125, -0.245)));
      }
      if (expression == 0 || expression == 3) {
        for (final side in [-1.0, 1.0]) {
          head.add(_child(SphereGeometry(radius: 0.018, segments: 12, rings: 8), _pbr(0xD67D70, roughness: 0.8), vm.Vector3(side * 0.15, -0.075, -0.205)));
        }
      }
      if (expression == 4) {
        // Subtle moustache on one avatar for a more varied cast.
        for (final side in [-1.0, 1.0]) {
          head.add(_child(SphereGeometry(radius: 0.035, segments: 14, rings: 10), hair, vm.Vector3(side * 0.045, -0.095, -0.245)));
        }
      }
      avatar.add(head);
      _avatarHeadNodes.add(head);
      _scene.add(avatar);
    }
  }

  void _addThreeDimensionalCards() {
    final cardFace = _pbr(0xFFF7E8, roughness: 0.48);
    final cardBack = _pbr(0x8B1E30, metallic: 0.28, roughness: 0.38);
    final goldEdge = _pbr(0xD7AE59, metallic: 0.96, roughness: 0.2);
    final backPattern = _pbr(0xD5A64A, metallic: 0.82, roughness: 0.25);

    // A physical reserve deck, with a gold inset and embossed centre medallion.
    for (var i = 0; i < 4; i++) {
      final card = Node(name: 'center_deck_card_$i');
      card.position = vm.Vector3((i - 1.5) * 0.025, 0.64 + i * 0.027, (i - 1.5) * -0.02);
      card.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), (i - 1.5) * 0.025);
      card.add(_child(CuboidGeometry(vm.Vector3(0.46, 0.026, 0.66)), cardBack, vm.Vector3.zero()));
      card.add(_child(CuboidGeometry(vm.Vector3(0.405, 0.004, 0.605)), backPattern, vm.Vector3(0, 0.015, 0)));
      card.add(_child(CuboidGeometry(vm.Vector3(0.37, 0.003, 0.57)), cardBack, vm.Vector3(0, 0.018, 0)));
      card.add(_child(SphereGeometry(radius: 0.085, segments: 20, rings: 12), goldEdge, vm.Vector3(0, 0.022, 0)));
      _scene.add(card);
    }

    if (widget.dealerDrawCards != null) {
      _addDealerDrawCards();
      return;
    }

    final count = widget.playerCount == 4 ? 4 : 6;
    final hands = widget.hands;
    if (widget.dealing && hands != null) {
      _addDealingCards();
      return;
    }
    for (var seat = 0; seat < count; seat++) {
      final angle = math.pi / 2 + (math.pi * 2 * seat / count);
      final cx = math.cos(angle) * 1.48;
      final cz = math.sin(angle) * 1.04;
      final tangentX = -math.sin(angle);
      final tangentZ = math.cos(angle);
      final hand = hands != null && seat < hands.length ? hands[seat] : const <loris.Card>[];
      final visibleCount = hand.isEmpty ? 5 : hand.length;

      for (var c = 0; c < visibleCount; c++) {
        final spread = (c - (visibleCount - 1) / 2) * (visibleCount > 6 ? 0.072 : 0.105);
        final card = Node(name: 'hand_${seat}_$c');
        card.position = vm.Vector3(cx + tangentX * spread, 0.665 + c * 0.0015, cz + tangentZ * spread);
        card.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), angle + math.pi);
        card.add(_child(CuboidGeometry(vm.Vector3(0.34, 0.025, 0.49)), cardBack, vm.Vector3.zero()));
        card.add(_child(CuboidGeometry(vm.Vector3(0.324, 0.003, 0.474)), goldEdge, vm.Vector3(0, 0.014, 0)));
        card.add(_child(CuboidGeometry(vm.Vector3(0.312, 0.004, 0.462)), cardFace, vm.Vector3(0, 0.017, 0)));

        // Opponents' cards stay face-down. Only the local player's hand is revealed.
        if (seat == 0 && c < hand.length) {
          _addCardFace(card, hand[c], goldEdge);
        } else {
          card.add(_child(
            CuboidGeometry(vm.Vector3(0.235, 0.002, 0.012)),
            backPattern,
            vm.Vector3(0, 0.020, 0),
          ));
          card.add(_child(
            CuboidGeometry(vm.Vector3(0.012, 0.002, 0.32)),
            backPattern,
            vm.Vector3(0, 0.020, 0),
          ));
        }
        _scene.add(card);
      }
    }
  }

  void _addDealerDrawCards() {
    final cards = widget.dealerDrawCards!;
    final visibleCount = widget.dealerDrawVisibleCount.clamp(0, cards.length);
    final cardBack = _pbr(0x8B1E30, metallic: 0.28, roughness: 0.36);
    final cardFace = _pbr(0xFFF7E8, roughness: 0.48);
    final gold = _pbr(0xD7AE59, metallic: 0.96, roughness: 0.2);
    final start = vm.Vector3(0, 0.84, 0);
    final count = widget.playerCount;

    for (var i = 0; i < visibleCount; i++) {
      final player = (widget.dealerDrawStartPlayer + i) % count;
      final angle = math.pi / 2 + math.pi * 2 * player / count;
      final target = vm.Vector3(
        math.cos(angle) * 1.24,
        0.675 + i * 0.002,
        math.sin(angle) * 0.84,
      );
      final card = Node(name: 'dealer_draw_card_$i');
      final isCurrent = widget.dealerDrawActive && i == visibleCount - 1;
      card.position = isCurrent ? start.clone() : target;
      card.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), angle + math.pi);
      card.add(_child(CuboidGeometry(vm.Vector3(0.36, 0.026, 0.51)), cardBack, vm.Vector3.zero()));
      card.add(_child(CuboidGeometry(vm.Vector3(0.344, 0.004, 0.494)), gold, vm.Vector3(0, 0.015, 0)));
      card.add(_child(CuboidGeometry(vm.Vector3(0.332, 0.004, 0.482)), cardFace, vm.Vector3(0, 0.018, 0)));
      _addCardFace(card, cards[i], gold);
      _scene.add(card);
      if (isCurrent) {
        _dealerDrawNode = card;
        _dealerDrawStart = start;
        _dealerDrawTarget = target;
        _dealerDrawStartElapsed = null;
      }
    }
  }

  void _addDealingCards() {
    final count = widget.playerCount;
    final dealerAngle = math.pi / 2 + math.pi * 2 * widget.dealerIndex / count;
    final start = vm.Vector3(
      math.cos(dealerAngle) * 2.05,
      0.78,
      math.sin(dealerAngle) * 1.48,
    );
    final cardBack = _pbr(0x8B1E30, metallic: 0.28, roughness: 0.36);
    final gold = _pbr(0xD7AE59, metallic: 0.96, roughness: 0.2);
    final pattern = _pbr(0xD5A64A, metallic: 0.82, roughness: 0.25);

    // Eight clockwise rounds: one card per seat, starting to the dealer's right.
    for (var round = 0; round < 8; round++) {
      for (var step = 1; step <= count; step++) {
        final seat = (widget.dealerIndex + step) % count;
        final angle = math.pi / 2 + math.pi * 2 * seat / count;
        final cx = math.cos(angle) * 1.48;
        final cz = math.sin(angle) * 1.04;
        final tangentX = -math.sin(angle);
        final tangentZ = math.cos(angle);
        final spread = (round - 3.5) * 0.105;
        final target = vm.Vector3(
          cx + tangentX * spread,
          0.665 + round * 0.0015,
          cz + tangentZ * spread,
        );
        final node = Node(name: 'dealing_card_${round}_$seat');
        node.position = start.clone();
        node.add(_child(CuboidGeometry(vm.Vector3(0.34, 0.025, 0.49)), cardBack, vm.Vector3.zero()));
        node.add(_child(CuboidGeometry(vm.Vector3(0.324, 0.003, 0.474)), gold, vm.Vector3(0, 0.014, 0)));
        node.add(_child(CuboidGeometry(vm.Vector3(0.312, 0.004, 0.462)), cardBack, vm.Vector3(0, 0.017, 0)));
        node.add(_child(CuboidGeometry(vm.Vector3(0.235, 0.002, 0.012)), pattern, vm.Vector3(0, 0.020, 0)));
        node.add(_child(CuboidGeometry(vm.Vector3(0.012, 0.002, 0.32)), pattern, vm.Vector3(0, 0.020, 0)));
        node.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), dealerAngle + math.pi);
        _scene.add(node);
        _dealNodes.add(node);
        _dealStarts.add(start.clone());
        _dealTargets.add(target);
      }
    }
    _dealStartElapsed = null;
  }

  void _addCardFace(Node card, loris.Card value, Material gold) {
    if (value.isLoris) {
      card.add(_child(
        CuboidGeometry(vm.Vector3(0.19, 0.004, 0.19)),
        gold,
        vm.Vector3(0, 0.023, 0),
      ));
      card.add(_child(
        SphereGeometry(radius: 0.055, segments: 18, rings: 12),
        _pbr(0x7C1D31, roughness: 0.3),
        vm.Vector3(0, 0.028, 0),
      ));
      return;
    }

    final isRed = value.suit == loris.Suit.hearts || value.suit == loris.Suit.diamonds;
    final ink = _pbr(isRed ? 0xB51F35 : 0x20232A, roughness: 0.52);
    final glyph = value.displayName;
    final segments = _segmentsFor(glyph);
    const xLeft = -0.115;
    const zTop = -0.175;
    const horizontal = 0.046;
    const vertical = 0.061;
    const thickness = 0.009;
    final positions = <String, vm.Vector3>{
      'a': vm.Vector3(xLeft + 0.026, 0.023, zTop),
      'g': vm.Vector3(xLeft + 0.026, 0.023, zTop + vertical),
      'd': vm.Vector3(xLeft + 0.026, 0.023, zTop + vertical * 2),
      'f': vm.Vector3(xLeft, 0.023, zTop + vertical / 2),
      'b': vm.Vector3(xLeft + horizontal, 0.023, zTop + vertical / 2),
      'e': vm.Vector3(xLeft, 0.023, zTop + vertical * 1.5),
      'c': vm.Vector3(xLeft + horizontal, 0.023, zTop + vertical * 1.5),
    };
    for (final segment in segments) {
      final horizontalSegment = segment == 'a' || segment == 'g' || segment == 'd';
      card.add(_child(
        CuboidGeometry(horizontalSegment
            ? vm.Vector3(horizontal, 0.004, thickness)
            : vm.Vector3(thickness, 0.004, vertical)),
        ink,
        positions[segment]!,
      ));
    }

    // The suit mark is built from real 3D primitives, not a flat emoji or icon.
    final suitZ = 0.075;
    switch (value.suit!) {
      case loris.Suit.diamonds:
        _addDiamond(card, ink, vm.Vector3(0, 0.025, suitZ));
        break;
      case loris.Suit.hearts:
        card.add(_child(SphereGeometry(radius: 0.043, segments: 14, rings: 10), ink, vm.Vector3(-0.025, 0.026, suitZ)));
        card.add(_child(SphereGeometry(radius: 0.043, segments: 14, rings: 10), ink, vm.Vector3(0.025, 0.026, suitZ)));
        _addDiamond(card, ink, vm.Vector3(0, 0.026, suitZ + 0.035));
        break;
      case loris.Suit.clubs:
        card.add(_child(SphereGeometry(radius: 0.038, segments: 14, rings: 10), ink, vm.Vector3(0, 0.026, suitZ - 0.025)));
        card.add(_child(SphereGeometry(radius: 0.034, segments: 14, rings: 10), ink, vm.Vector3(-0.031, 0.026, suitZ + 0.018)));
        card.add(_child(SphereGeometry(radius: 0.034, segments: 14, rings: 10), ink, vm.Vector3(0.031, 0.026, suitZ + 0.018)));
        card.add(_child(CuboidGeometry(vm.Vector3(0.014, 0.004, 0.06)), ink, vm.Vector3(0, 0.026, suitZ + 0.065)));
        break;
      case loris.Suit.spades:
        _addDiamond(card, ink, vm.Vector3(0, 0.026, suitZ - 0.018));
        card.add(_child(SphereGeometry(radius: 0.034, segments: 14, rings: 10), ink, vm.Vector3(-0.03, 0.026, suitZ + 0.018)));
        card.add(_child(SphereGeometry(radius: 0.034, segments: 14, rings: 10), ink, vm.Vector3(0.03, 0.026, suitZ + 0.018)));
        card.add(_child(CuboidGeometry(vm.Vector3(0.014, 0.004, 0.06)), ink, vm.Vector3(0, 0.026, suitZ + 0.065)));
        break;
    }
  }

  List<String> _segmentsFor(String label) {
    const map = <String, String>{
      'A': 'abcefg',
      'J': 'bcde',
      'Q': 'abcfdeg',
      'K': 'efg',
      '2': 'abged',
      '3': 'abgcd',
      '4': 'fgbc',
      '5': 'afgcd',
      '6': 'afgecd',
      '7': 'abc',
      '8': 'abcdefg',
      '9': 'abfgcd',
      '10': 'abcdefg',
    };
    return (map[label] ?? 'abcefg').split('');
  }

  void _addDiamond(Node card, Material material, vm.Vector3 position) {
    final pip = _child(
      CuboidGeometry(vm.Vector3(0.072, 0.004, 0.072)),
      material,
      position,
    );
    pip.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), math.pi / 4);
    card.add(pip);
  }

  void _addPlayedCards() {
    final cards = widget.playedCards;
    final count = cards.length;
    final back = _pbr(0x8B1E30, metallic: 0.25, roughness: 0.35);
    final face = _pbr(0xFFF7E8, roughness: 0.45);
    final gold = _pbr(0xD7AE59, metallic: 0.96, roughness: 0.2);
    for (var i = 0; i < count; i++) {
      final card = Node(name: 'played_card_$i');
      final offset = i - (count - 1) / 2;
      card.position = vm.Vector3(offset * 0.32, 0.69 + i * 0.002, offset * 0.12);
      card.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), offset * 0.12);
      card.add(_child(CuboidGeometry(vm.Vector3(0.39, 0.025, 0.54)), back, vm.Vector3.zero()));
      card.add(_child(CuboidGeometry(vm.Vector3(0.372, 0.004, 0.522)), gold, vm.Vector3(0, 0.014, 0)));
      card.add(_child(CuboidGeometry(vm.Vector3(0.36, 0.004, 0.51)), face, vm.Vector3(0, 0.017, 0)));
      _addCardFace(card, cards[i], gold);
      _scene.add(card);
    }
  }

  void _addFlyingCard() {
    final value = widget.flyingCard;
    final seat = widget.flyingFromPlayer;
    if (value == null || seat == null || !widget.flightStarted) return;

    final count = widget.playerCount == 4 ? 4 : 6;
    final angle = math.pi / 2 + (math.pi * 2 * seat / count);
    final start = vm.Vector3(math.cos(angle) * 1.48, 0.76, math.sin(angle) * 1.04);
    final playedCount = widget.playedCards.length;
    final offset = playedCount / 2;
    final target = vm.Vector3(offset * 0.32, 0.70, offset * 0.12);

    final card = Node(name: '3d_flying_card');
    card.position = start;
    card.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), angle + math.pi);
    final back = _pbr(0x8B1E30, metallic: 0.25, roughness: 0.35);
    final face = _pbr(0xFFF7E8, roughness: 0.45);
    final gold = _pbr(0xD7AE59, metallic: 0.96, roughness: 0.2);
    card.add(_child(CuboidGeometry(vm.Vector3(0.39, 0.025, 0.54)), back, vm.Vector3.zero()));
    card.add(_child(CuboidGeometry(vm.Vector3(0.372, 0.004, 0.522)), gold, vm.Vector3(0, 0.014, 0)));
    card.add(_child(CuboidGeometry(vm.Vector3(0.36, 0.004, 0.51)), face, vm.Vector3(0, 0.017, 0)));
    _addCardFace(card, value, gold);
    if (value.isLoris) {
      // Gold sparks orbit the special card during its longer 3D flight.
      for (var spark = 0; spark < 12; spark++) {
        final angle = math.pi * 2 * spark / 12;
        card.add(_child(
          SphereGeometry(radius: 0.025, segments: 12, rings: 8),
          gold,
          vm.Vector3(math.cos(angle) * 0.245, 0.032, math.sin(angle) * 0.34),
        ));
      }
    }
    _scene.add(card);

    _flyingNode = card;
    _flightStartElapsed = null;
    _flightStartPosition = start;
    _flightTargetPosition = target;
    _flightStartAngle = angle + math.pi;
  }

  vm.Vector3? _flightStartPosition;
  vm.Vector3? _flightTargetPosition;
  double _flightStartAngle = 0;

  void _tickCardFlight(Duration elapsed, double deltaSeconds) {
    // Gentle idle head motion keeps the 3D opponents alive between turns.
    final idleTime = elapsed.inMicroseconds / 1000000;
    for (var i = 0; i < _avatarHeadNodes.length; i++) {
      final phase = idleTime * 0.72 + i * 1.17;
      final yaw = math.sin(phase) * 0.035;
      final nod = math.sin(phase * 0.63) * 0.018;
      _avatarHeadNodes[i].rotation = vm.Quaternion.axisAngle(
        vm.Vector3(0, 1, 0),
        yaw,
      ) * vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), nod);
    }

    final dealerNode = _dealerDrawNode;
    final dealerStart = _dealerDrawStart;
    final dealerTarget = _dealerDrawTarget;
    if (dealerNode != null && dealerStart != null && dealerTarget != null) {
      _dealerDrawStartElapsed ??= elapsed;
      final seconds = (elapsed - _dealerDrawStartElapsed!).inMicroseconds / 1000000;
      final raw = (seconds / 0.48).clamp(0.0, 1.0);
      final eased = 1 - math.pow(1 - raw, 3).toDouble();
      final arc = math.sin(raw * math.pi) * 0.24;
      dealerNode.position = vm.Vector3(
        dealerStart.x + (dealerTarget.x - dealerStart.x) * eased,
        dealerStart.y + (dealerTarget.y - dealerStart.y) * eased + arc,
        dealerStart.z + (dealerTarget.z - dealerStart.z) * eased,
      );
    }
    if (_dealNodes.isNotEmpty) {
      _dealStartElapsed ??= elapsed;
      final seconds = (elapsed - _dealStartElapsed!).inMicroseconds / 1000000;
      for (var i = 0; i < _dealNodes.length; i++) {
        final local = ((seconds - i * 0.09) / 0.32).clamp(0.0, 1.0);
        if (local <= 0) continue;
        final eased = 1 - math.pow(1 - local, 3).toDouble();
        final start = _dealStarts[i];
        final target = _dealTargets[i];
        final arc = math.sin(local * math.pi) * 0.22;
        _dealNodes[i].position = vm.Vector3(
          start.x + (target.x - start.x) * eased,
          start.y + (target.y - start.y) * eased + arc,
          start.z + (target.z - start.z) * eased,
        );
        final dealerAngle = math.pi / 2 + math.pi * 2 * widget.dealerIndex / widget.playerCount;
        _dealNodes[i].rotation = vm.Quaternion.axisAngle(
          vm.Vector3(0, 1, 0),
          dealerAngle * (1 - eased),
        );
      }
    }
    final node = _flyingNode;
    final start = _flightStartPosition;
    final target = _flightTargetPosition;
    if (node == null || start == null || target == null) return;

    _flightStartElapsed ??= elapsed;
    final seconds = (elapsed - _flightStartElapsed!).inMicroseconds / 1000000;
    final raw = (seconds / 0.62).clamp(0.0, 1.0);
    final eased = 1 - math.pow(1 - raw, 3).toDouble();
    final arc = math.sin(raw * math.pi) * (widget.flyingCard?.isLoris == true ? 0.68 : 0.42);
    node.position = vm.Vector3(
      start.x + (target.x - start.x) * eased,
      start.y + (target.y - start.y) * eased + arc,
      start.z + (target.z - start.z) * eased,
    );
    final rotation = _flightStartAngle * (1 - eased) +
        (widget.flyingCard?.isLoris == true ? raw * math.pi * 2 : 0);
    node.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), rotation);
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
      onTick: _tickCardFlight,
    );
  }
}
