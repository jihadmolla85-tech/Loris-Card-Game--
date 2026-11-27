import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loris_card_game/game/models/loris_card.dart';
import 'package:loris_card_game/game/widgets/loris_card_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('card-face paths match the supplied four-suit artwork', () {
    for (final suit in Suit.values) {
      expect(
        lorisCardFaceAssetPath(Card.normal(suit: suit, rank: 14)),
        'assets/${_suitName(suit)}_A.png',
      );
      expect(
        lorisTrumpPreviewCardAssetPath(suit),
        'assets/${_suitName(suit)}_2.png',
      );
    }

    expect(
      lorisCardFaceAssetPath(const Card.loris(replacesRank: 7)),
      'assets/Spades_Joker_Red.png',
    );
  });

  test('all card faces and both portrait collections are bundled', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();

    for (final suit in Suit.values) {
      for (var rank = 3; rank <= 14; rank++) {
        expect(
          assets,
          contains(lorisCardFaceAssetPath(Card.normal(suit: suit, rank: rank))),
        );
      }
      expect(assets, contains(lorisTrumpPreviewCardAssetPath(suit)));
    }

    final men = assets.where(
      (path) => path.startsWith('assets/portraits/men/') && path.endsWith('.jpg'),
    );
    final women = assets.where(
      (path) => path.startsWith('assets/portraits/women/') && path.endsWith('.jpg'),
    );
    expect(men.length, 40);
    expect(women.length, 40);
  });

  test('original splash, logo, and source art archives remain bundled', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();

    for (final path in [
      'assets/Splash Screen and back page of card.jpg',
      'assets/Player Portrait.zip',
      'assets/all_playing_cards.zip',
      'assets/images/loris_icon.jpg',
      'assets/images/loris_logo.jpg',
      'assets/images/loris_portrait_atlas.jpg',
      'assets/images/file_00000000f9f882119c70821c3044291b.png',
    ]) {
      expect(assets, contains(path), reason: 'Missing restored artwork: $path');
    }
  });
}

String _suitName(Suit suit) => switch (suit) {
  Suit.clubs => 'Clubs',
  Suit.diamonds => 'Diamonds',
  Suit.hearts => 'Hearts',
  Suit.spades => 'Spades',
};
