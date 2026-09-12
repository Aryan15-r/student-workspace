import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ai_assistant/services/ai_service.dart';
import '../models/flashcard.dart';

class FlashcardProvider extends ChangeNotifier {
  static const String _storageKey = 'flashcard_decks';
  List<FlashcardDeck> _decks = [];
  bool _isLoading = false;
  final AiService _aiService = AiService();

  List<FlashcardDeck> get decks => _decks;
  bool get isLoading => _isLoading;

  FlashcardProvider() {
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _decks = jsonList.map((e) => FlashcardDeck.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading flashcard decks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveDecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = json.encode(_decks.map((e) => e.toMap()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving flashcard decks: $e');
    }
  }

  Future<void> createDeck(String title, List<Flashcard> cards) async {
    final newDeck = FlashcardDeck(title: title, cards: cards);
    _decks.add(newDeck);
    await _saveDecks();
    notifyListeners();
  }

  Future<void> deleteDeck(String id) async {
    _decks.removeWhere((deck) => deck.id == id);
    await _saveDecks();
    notifyListeners();
  }

  Future<void> addCardToDeck(String deckId, Flashcard card) async {
    final index = _decks.indexWhere((deck) => deck.id == deckId);
    if (index != -1) {
      _decks[index].cards.add(card);
      await _saveDecks();
      notifyListeners();
    }
  }

  Future<void> deleteCardFromDeck(String deckId, String cardId) async {
    final index = _decks.indexWhere((deck) => deck.id == deckId);
    if (index != -1) {
      _decks[index].cards.removeWhere((card) => card.id == cardId);
      await _saveDecks();
      notifyListeners();
    }
  }

  /// AI Generation
  Future<bool> generateDeckFromTopic(String topic, {int count = 10}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final rawCards = await _aiService.generateFlashcards(topic, count: count);
      if (rawCards.isNotEmpty) {
        final cards = rawCards.map((c) => Flashcard(front: c['front'] ?? '', back: c['back'] ?? '')).toList();
        await createDeck('AI: $topic', cards);
        return true;
      }
    } catch (e) {
      debugPrint('Error generating deck: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
