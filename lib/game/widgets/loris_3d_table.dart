import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' hide Material;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;
import '../models/loris_card.dart' as loris;

/// Full-screen 3D LORIS play surface with compact player portraits and cards.
/// The phone display itself is the table; no separate table prop is rendered.
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
  bool _ready = false;
  Duration? _dealStartElapsed;
  Node? _dealerDrawNode;
  Duration? _dealerDrawStartElapsed;
  vm.Vector3? _dealerDrawStart;
  vm.Vector3? _dealerDrawTarget;
  final List<Node> _dealNodes = [];
  final List<vm.Vector3> _dealStarts = [];
  final List<vm.Vector3> _dealTargets = [];
  final List<Node> _avatarHeadNodes = [];
  final List<List<Node>> _avatarEyeNodes = [];
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _scene = Scene();
    _initializeScene();
  }

  @override
  void didUpdateWidget(covariant LorisTableSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Preserve the expensive 3D scene while cards are played; recreating
    // SceneView for every state update caused a black flash on every turn.
    final structureChanged =
        oldWidget.playerCount != widget.playerCount ||
        (oldWidget.hands == null && widget.hands != null) ||
        oldWidget.dealing != widget.dealing ||
        (oldWidget.dealerDrawCards == null) != (widget.dealerDrawCards == null);
    if (structureChanged) {
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
    _avatarEyeNodes.clear();
    _dealStartElapsed = null;
    _dealerDrawNode = null;
    _dealerDrawStartElapsed = null;
    _dealerDrawStart = null;
    _dealerDrawTarget = null;
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

      // Infinite burgundy play plane: the phone display is the table.
      // No raised tabletop, rim, legs, pedestal or surrounding studio floor.
      _addMesh(
        CuboidGeometry(vm.Vector3(200, 0.06, 200)),
        _pbr(0x681727, roughness: 0.84),
        vm.Vector3(0, 0.55, 0),
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

      // Six clearly different expressions: calm, friendly, surprised,
      // determined, confident and cheerful.
      final expression = i % 6;
      final eyeNodes = <Node>[];
      const browAngles = [0.08, -0.20, 0.02, 0.28, -0.12, -0.24];
      const browHeights = [0.105, 0.112, 0.12, 0.085, 0.11, 0.115];
      for (final side in [-1.0, 1.0]) {
        final brow = _child(
          CapsuleGeometry(radius: 0.021, height: 0.105),
          hair,
          vm.Vector3(side * 0.078, browHeights[expression], -0.218),
        );
        brow.rotation = vm.Quaternion.axisAngle(
          vm.Vector3(0, 0, 1),
          side * browAngles[expression],
        );
        head.add(brow);

        final eye = _child(
          SphereGeometry(radius: expression == 2 ? 0.057 : 0.052, segments: 20, rings: 14),
          eyeWhite,
          vm.Vector3(side * 0.078, 0.025, -0.219),
        );
        final irisNode = _child(
          SphereGeometry(radius: 0.028, segments: 16, rings: 10),
          iris,
          vm.Vector3(side * 0.078, 0.025, -0.246),
        );
        final pupilNode = _child(
          SphereGeometry(radius: 0.014, segments: 12, rings: 8),
          dark,
          vm.Vector3(side * 0.078, 0.025, -0.264),
        );
        final glintNode = _child(
          SphereGeometry(radius: 0.012, segments: 10, rings: 8),
          eyeWhite,
          vm.Vector3(side * 0.068, 0.038, -0.275),
        );
        head.add(eye);
        head.add(irisNode);
        head.add(pupilNode);
        head.add(glintNode);
        eyeNodes.addAll([eye, irisNode, pupilNode, glintNode]);
      }
      head.add(_child(SphereGeometry(radius: 0.044, segments: 16, rings: 10), skin, vm.Vector3(0, -0.045, -0.247)));
      head.add(_child(SphereGeometry(radius: 0.022, segments: 12, rings: 8), skin, vm.Vector3(-0.018, -0.062, -0.275)));
      head.add(_child(SphereGeometry(radius: 0.022, segments: 12, rings: 8), skin, vm.Vector3(0.018, -0.062, -0.275)));

      final mouthHeight = expression == 2 || expression == 5 ? 0.052 : 0.105;
      final mouthNode = _child(
        CapsuleGeometry(radius: expression == 2 || expression == 5 ? 0.022 : 0.016, height: mouthHeight),
        mouth,
        vm.Vector3(0, expression == 3 ? -0.137 : -0.125, -0.231),
      );
      mouthNode.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2);
      if (expression == 3) {
        // A slightly downturned mouth for the determined player.
        mouthNode.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), math.pi / 2 + 0.16);
      }
      head.add(mouthNode);
      if (expression == 2 || expression == 5) {
        head.add(_child(
          SphereGeometry(radius: expression == 2 ? 0.028 : 0.034, segments: 16, rings: 10),
          mouth,
          vm.Vector3(0, -0.125, -0.245),
        ));
      }
      if (expression == 1 || expression == 5) {
        // Raised smile corners and warm cheek highlights.
        for (final side in [-1.0, 1.0]) {
          head.add(_child(
            SphereGeometry(radius: 0.018, segments: 12, rings: 8),
            mouth,
            vm.Vector3(side * 0.075, -0.108, -0.229),
          ));
          head.add(_child(
            SphereGeometry(radius: 0.022, segments: 12, rings: 8),
            _pbr(0xD67D70, roughness: 0.8),
            vm.Vector3(side * 0.15, -0.075, -0.205),
          ));
        }
      }
      if (expression == 4) {
        // A neat moustache differentiates the confident avatar.
        for (final side in [-1.0, 1.0]) {
          head.add(_child(SphereGeometry(radius: 0.035, segments: 14, rings: 10), hair, vm.Vector3(side * 0.045, -0.095, -0.245)));
        }
      }
      avatar.add(head);
      _avatarHeadNodes.add(head);
      _avatarEyeNodes.add(eyeNodes);
      _scene.add(avatar);
    }
  }

  List<loris.Card> _sortedHandCards(List<loris.Card> cards) {
    const suitOrder = {
      loris.Suit.clubs: 0,
      loris.Suit.diamonds: 1,
      loris.Suit.hearts: 2,
      loris.Suit.spades: 3,
    };
    final sorted = List<loris.Card>.from(cards);
    sorted.sort((a, b) {
      if (a.isLoris != b.isLoris) return a.isLoris ? 1 : -1;
      if (a.isLoris) return 0;
      final suitCompare = suitOrder[a.suit]!.compareTo(suitOrder[b.suit]!);
      if (suitCompare != 0) return suitCompare;
      return b.rank!.compareTo(a.rank!);
    });
    return sorted;
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
      final unsortedHand = hands != null && seat < hands.length
          ? hands[seat]
          : const <loris.Card>[];
      // Keep the 3D fan in the exact same suit/rank order as the player's
      // interactive hand strip so the two views never contradict each other.
      final hand = seat == 0 ? _sortedHandCards(unsortedHand) : unsortedHand;
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

      // Brief synchronized eyelid squash creates a natural blink every few seconds.
      final blinkPhase = (idleTime + i * 0.83) % 4.8;
      final eyeOpen = blinkPhase > 4.54 ? 0.10 : 1.0;
      for (final eyePart in _avatarEyeNodes[i]) {
        eyePart.scale = vm.Vector3(1, eyeOpen, 1);
      }
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
        position: vm.Vector3(0, 4.9, 8.9),
        target: vm.Vector3(0, 0.62, 0),
        fovRadiansY: 0.84,
        fovNear: 0.05,
        fovFar: 100,
      ),
      onTick: _tickCardFlight,
    );
  }
}
