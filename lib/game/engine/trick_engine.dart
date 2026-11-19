import '../models/loris_card.dart';
class TrickPlay { final int playerIndex; final Card card; const TrickPlay({required this.playerIndex,required this.card}); }
class TrickEngine {
 final List<List<Card>> hands; final int playerCount; final int dealerIndex; final Suit? trumpSuit; final List<TrickPlay> plays=[]; int completedTricks; late int _firstPlayerIndex;
 TrickEngine({required this.hands,required this.dealerIndex,required this.trumpSuit,this.completedTricks=0,List<TrickPlay> initialPlays=const [],int? restoredFirstPlayerIndex}) : playerCount=hands.length {
 if(playerCount!=4&&playerCount!=6)throw ArgumentError('Player count must be 4 or 6.');
 if(dealerIndex<0||dealerIndex>=playerCount)throw ArgumentError('Invalid dealer index.');
 if(completedTricks<0||completedTricks>8)throw ArgumentError('Invalid completed trick count.');
 _firstPlayerIndex=restoredFirstPlayerIndex??(dealerIndex-1+playerCount)%playerCount;
 if(_firstPlayerIndex<0||_firstPlayerIndex>=playerCount)throw ArgumentError('Invalid first player index.');
 if(initialPlays.length>=playerCount)throw ArgumentError('Invalid initial trick plays.');
 final played=<int>{};
 for(var i=0;i<initialPlays.length;i++){final play=initialPlays[i];if(play.playerIndex!=(_firstPlayerIndex-i+playerCount)%playerCount)throw ArgumentError('Invalid restored trick play order.');if(!played.add(play.playerIndex))throw ArgumentError('A player cannot play twice in one trick.');}
 for(var i=0;i<playerCount;i++){if(hands[i].length!=8-completedTricks-(played.contains(i)?1:0))throw ArgumentError('Invalid hand size for player $i.');}
 plays.addAll(initialPlays);
 }
 int get firstPlayerIndex=>_firstPlayerIndex; int get currentPlayerIndex=>(_firstPlayerIndex-plays.length+playerCount)%playerCount; bool get isComplete=>plays.length==playerCount;
 Suit? get ledSuit {if(plays.isEmpty)return null;final c=plays.first.card;return c.isLoris?Suit.spades:c.suit;}
 List<Card> legalCardsFor(int playerIndex){if(isComplete)throw StateError('Trick is already complete.');if(playerIndex!=currentPlayerIndex)throw StateError('It is not this player’s turn.');final hand=hands[playerIndex];final led=ledSuit;if(led==null)return List.unmodifiable(hand);final following=hand.where((c)=>c.isLoris?led==Suit.spades:c.suit==led).toList();return List.unmodifiable(following.isNotEmpty?[...following,...hand.where((card)=>card.isLoris&&!following.contains(card))]:hand);}
 void playCard(int playerIndex,Card card){if(!legalCardsFor(playerIndex).contains(card))throw ArgumentError('This card cannot be played under LORIS rules.');hands[playerIndex].remove(card);plays.add(TrickPlay(playerIndex:playerIndex,card:card));}
 Suit? _suit(Card c)=>c.isLoris?Suit.spades:c.suit; int _rank(Card c)=>c.isLoris?(c.replacesRank??0):(c.rank??0);
 int get winnerIndex {if(!isComplete)throw StateError('Trick is not complete.');final led=ledSuit;if(led==null)throw StateError('The trick has no led suit.');final trumps=trumpSuit==null?<TrickPlay>[]:plays.where((p)=>_suit(p.card)==trumpSuit).toList();final pool=trumps.isNotEmpty?trumps:plays.where((p)=>_suit(p.card)==led).toList();return pool.reduce((a,b)=>_rank(b.card)>_rank(a.card)?b:a).playerIndex;}
 void resetTrick({int? nextLeaderIndex}){if(!isComplete)throw StateError('Cannot reset an incomplete trick.');final leader=nextLeaderIndex??winnerIndex;if(leader<0||leader>=playerCount)throw ArgumentError('Invalid next leader index.');completedTricks++;_firstPlayerIndex=leader;plays.clear();}
}