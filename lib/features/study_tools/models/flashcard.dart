import 'dart:convert';
import 'package:uuid/uuid.dart';

class Flashcard {
  final String id;
  final String front;
  final String back;
  
  Flashcard({
    String? id,
    required this.front,
    required this.back,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'back': back,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      front: map['front'],
      back: map['back'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Flashcard.fromJson(String source) => Flashcard.fromMap(json.decode(source));
}

class FlashcardDeck {
  final String id;
  final String title;
  final List<Flashcard> cards;

  FlashcardDeck({
    String? id,
    required this.title,
    required this.cards,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'cards': cards.map((x) => x.toMap()).toList(),
    };
  }

  factory FlashcardDeck.fromMap(Map<String, dynamic> map) {
    return FlashcardDeck(
      id: map['id'],
      title: map['title'],
      cards: List<Flashcard>.from(map['cards']?.map((x) => Flashcard.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory FlashcardDeck.fromJson(String source) => FlashcardDeck.fromMap(json.decode(source));
}
