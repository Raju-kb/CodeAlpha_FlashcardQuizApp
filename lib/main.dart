import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

/// CodeAlpha App Development Internship — Task 1: Flashcard Quiz App.
///
/// A flashcard study app: each card has a question on the front and the
/// answer on the back. Users can flip cards, move between them, and add,
/// edit, delete, shuffle and reset cards. Cards are saved on the device
/// with shared_preferences, so the deck survives closing the app.
void main() {
  runApp(const FlashcardQuizApp());
}

class FlashcardQuizApp extends StatelessWidget {
  const FlashcardQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard Quiz App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const FlashcardHomePage(),
    );
  }
}

class FlashcardHomePage extends StatefulWidget {
  const FlashcardHomePage({super.key});

  @override
  State<FlashcardHomePage> createState() => _FlashcardHomePageState();
}

class _FlashcardHomePageState extends State<FlashcardHomePage>
    with SingleTickerProviderStateMixin {
  static const String _storageKey = 'codealpha_flashcards_v1';

  List<Flashcard> _cards = List<Flashcard>.from(defaultCards);
  int _currentIndex = 0;
  bool _flipped = false;
  int _editingIndex = -1; // -1 means the form is adding a new card.
  bool _loaded = false;

  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _loadCards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  // ---------- Persistence ----------

  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final loaded = decoded
            .whereType<Map<String, dynamic>>()
            .map(Flashcard.fromJson)
            .where((card) => card.isValid)
            .toList();
        if (loaded.isNotEmpty) {
          _cards = loaded;
        }
      } catch (_) {
        // Corrupt saved data: fall back to the default deck.
        _cards = List<Flashcard>.from(defaultCards);
      }
    }
    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _cards.map((card) => card.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  // ---------- Actions ----------

  void _flip() {
    if (_cards.isEmpty) return;
    setState(() => _flipped = !_flipped);
    if (_flipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _goTo(int index) {
    if (_cards.isEmpty) return;
    setState(() {
      _currentIndex =
          ((index % _cards.length) + _cards.length) % _cards.length;
      _flipped = false;
    });
    _flipController.reset();
  }

  void _shuffle() {
    if (_cards.length < 2) return;
    setState(() {
      _cards.shuffle(Random());
      _currentIndex = 0;
      _flipped = false;
    });
    _flipController.reset();
    _saveCards();
    _showMessage('Deck shuffled!');
  }

  Future<void> _deleteCard(int index) async {
    if (index < 0 || index >= _cards.length) return;
    final removed = _cards[index];
    setState(() {
      _cards.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = -1;
        _questionController.clear();
        _answerController.clear();
      } else if (_editingIndex > index) {
        _editingIndex--;
      }
      if (_currentIndex >= _cards.length) {
        _currentIndex = _cards.isEmpty ? 0 : _cards.length - 1;
      }
      _flipped = false;
    });
    _flipController.reset();
    await _saveCards();
    _showMessage('Deleted: "${removed.question}"');
  }

  Future<void> _confirmDeleteCurrent() async {
    if (_cards.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this card?'),
        content: Text('“${_cards[_currentIndex].question}”'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteCard(_currentIndex);
    }
  }

  void _startEdit(int index) {
    if (index < 0 || index >= _cards.length) return;
    setState(() {
      _editingIndex = index;
      _questionController.text = _cards[index].question;
      _answerController.text = _cards[index].answer;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = -1;
      _questionController.clear();
      _answerController.clear();
    });
  }

  Future<void> _submitForm() async {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();
    if (question.isEmpty || answer.isEmpty) {
      _showMessage('Please fill in both the question and the answer.');
      return;
    }
    if (_editingIndex >= 0) {
      setState(() {
        _cards[_editingIndex] =
            Flashcard(question: question, answer: answer);
        _currentIndex = _editingIndex;
        _flipped = false;
      });
      _flipController.reset();
      await _saveCards();
      _showMessage('Card updated!');
      _cancelEdit();
    } else {
      setState(() {
        _cards.add(Flashcard(question: question, answer: answer));
        _currentIndex = _cards.length - 1;
        _flipped = false;
      });
      _flipController.reset();
      await _saveCards();
      _questionController.clear();
      _answerController.clear();
      _showMessage('Card added! It is now the last card in the deck.');
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to defaults?'),
        content: const Text(
          'Reset the deck to the 10 default cards? '
          'Your added / edited cards will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _cards = List<Flashcard>.from(defaultCards);
      _currentIndex = 0;
      _flipped = false;
      _editingIndex = -1;
      _questionController.clear();
      _answerController.clear();
    });
    _flipController.reset();
    await _saveCards();
    _showMessage('Deck reset to the 10 default cards.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final total = _cards.length;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Quiz App'),
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Chip(
                      label: Text('CodeAlpha · Task 1 · App Development'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Study smarter — flip a card, test yourself, '
                    'and build your own deck.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        total == 0
                            ? 'Card 0 of 0'
                            : 'Card ${_currentIndex + 1} of $total',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$total ${total == 1 ? 'card' : 'cards'} in deck',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : (_currentIndex + 1) / total,
                    borderRadius: BorderRadius.circular(99),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  if (total == 0)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Your deck is empty.\n'
                          'Add a flashcard below, or reset to the '
                          '10 default cards.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else ...[
                    GestureDetector(
                      onTap: _flip,
                      child: _buildFlippingCard(colorScheme),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _goTo(_currentIndex - 1),
                            child: const Text('← Previous'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _flip,
                            child: Text(
                              _flipped ? 'Hide Answer' : 'Show Answer',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _goTo(_currentIndex + 1),
                            child: const Text('Next →'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tip: tap the card to flip it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _shuffle,
                          icon: const Icon(Icons.shuffle),
                          label: const Text('Shuffle'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _startEdit(_currentIndex),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit This Card'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _confirmDeleteCurrent,
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete This Card'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _resetToDefaults,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Reset to Defaults'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildFormCard(),
                  const SizedBox(height: 16),
                  _buildManageCard(),
                  const SizedBox(height: 16),
                  const Text(
                    'CodeAlpha App Development Internship — Task 1. '
                    'Cards are saved on your device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFlippingCard(ColorScheme colorScheme) {
    final card = _cards[_currentIndex];
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * 3.141592653589793;
        final isBack = angle > 3.141592653589793 / 2;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: SizedBox(
            height: 260,
            width: double.infinity,
            child: isBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(3.141592653589793),
                    alignment: Alignment.center,
                    child: _buildCardFace(
                      tag: 'Answer',
                      text: card.answer,
                      isAnswer: true,
                      colorScheme: colorScheme,
                    ),
                  )
                : _buildCardFace(
                    tag: 'Question',
                    text: card.question,
                    isAnswer: false,
                    colorScheme: colorScheme,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCardFace({
    required String tag,
    required String text,
    required bool isAnswer,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 6,
      color: isAnswer ? colorScheme.primary : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              label: Text(tag),
              backgroundColor: isAnswer
                  ? colorScheme.onPrimary.withOpacity(0.2)
                  : colorScheme.primaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isAnswer
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAnswer
                  ? 'Tap the card again to go back to the question.'
                  : 'Tap the card or “Show Answer” to reveal the answer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isAnswer
                    ? colorScheme.onPrimary.withOpacity(0.8)
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final isEditing = _editingIndex >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing
                  ? 'Edit Flashcard ${_editingIndex + 1}'
                  : 'Add a Flashcard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Write a question for the front and its answer for the back.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'e.g. What is the capital of France?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: 'Answer',
                hintText: 'e.g. Paris',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _submitForm,
                    child: Text(isEditing ? 'Save Changes' : 'Add Card'),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _cancelEdit,
                    child: const Text('Cancel Edit'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage Cards',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Edit or delete any card in your deck.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (_cards.isEmpty)
              const Text(
                'No cards yet — add one above.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cards.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${index + 1}. ${card.question}'),
                    subtitle: Text(card.answer),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit',
                          onPressed: () => _startEdit(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete',
                          onPressed: () => _deleteCard(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
