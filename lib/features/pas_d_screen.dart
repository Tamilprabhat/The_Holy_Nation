import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../services/pas_d_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? userQuestion;
  String? feedbackType;
  String? feedbackNote;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.userQuestion,
    this.feedbackType,
    this.feedbackNote,
  });
}

class PasDScreen extends StatefulWidget {
  const PasDScreen({super.key});

  @override
  State createState() => _PasDScreenState();
}

class _PasDScreenState extends State {
  final List _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  Database? _feedbackDb;

  final List _quickPrompts = [
    "மன அமைதிக்கான வேத வசனம்",
    "பயத்தை நீக்கும் ஜெபம்",
    "மன்னிப்பைப் பற்றி வேதம் என்ன சொல்கிறது?",
    "Biblical guidance for difficult times",
  ];

  final List _improvementReasons = [
    "தமிழ் எழுத்து / இலக்கணப் பிழை உள்ளது",
    "இன்னும் ஆழமான வேத வசனங்கள் தேவை",
    "கேள்விக்குப் பொருத்தமான பதில் இல்லை",
    "இன்னும் எளிமையாகவும் தெளிவாகவும் வேண்டும்",
  ];

  @override
  void initState() {
    super.initState();
    _initFeedbackDb();
    _addWelcomeMessage();
  }

  Future _initFeedbackDb() async {
    try {
      final dbDir = await getDatabasesPath();
      final dbPath = p.join(dbDir, 'pas_d_feedback.db');
      _feedbackDb = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS feedback_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              question TEXT,
              ai_reply TEXT,
              feedback_type TEXT,
              user_comment TEXT,
              created_at TEXT
            )
          ''');
        },
      );
    } catch (_) {}
  }

  Future _saveFeedbackLog({
    required String question,
    required String aiReply,
    required String feedbackType,
    String userComment = '',
  }) async {
    try {
      if (_feedbackDb == null) {
        await _initFeedbackDb();
      }
      await _feedbackDb?.insert('feedback_logs', {
        'question': question,
        'ai_reply': aiReply,
        'feedback_type': feedbackType,
        'user_comment': userComment,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text:
            "வணக்கம்! நான் Pas D (AI Digital Pastor). வேதாகம அடிப்படையிலான ஆலோசனைகள், ஜெபக் குறிப்புகள் மற்றும் சந்தேகங்களுக்கு தமிழ் அல்லது ஆங்கிலத்தில் கேளுங்கள்.",
        isUser: false,
      ),
    );
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _addWelcomeMessage();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future _sendMessage([String? customText]) async {
    final text = (customText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    final history = _messages
        .skip(1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      if (customText == null) {
        _controller.clear();
      }
    });
    _scrollToBottom();

    final reply = await PasDService.askPasD(text, history: history);

    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: reply.toString(),
          isUser: false,
          userQuestion: text,
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future _regenerateWithFeedback(
      ChatMessage targetMsg, String combinedFeedback) async {
    if (_isLoading) return;
    final originalQuestion =
        targetMsg.userQuestion ?? "வேதாகம அடிப்படையிலான ஆலோசனை";

    final history = _messages
        .skip(1)
        .where((m) => m != targetMsg)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    final improvedReply = await PasDService.askPasD(
      originalQuestion,
      history: history,
      feedbackCorrection: combinedFeedback,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: improvedReply.toString(),
          isUser: false,
          userQuestion: originalQuestion,
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _onAmenPressed(ChatMessage message) async {
    setState(() {
      message.feedbackType = 'amen';
      message.feedbackNote = 'ஆமென், நன்றி இயேசுவே';
    });

    await _saveFeedbackLog(
      question: message.userQuestion ?? '',
      aiReply: message.text,
      feedbackType: 'amen',
      userComment: 'ஆமென், நன்றி இயேசுவே',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🙏 ஆமென்! உங்கள் நன்றி பதியப்பட்டது. தேவனுக்கே மகிமை!"),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF1B4332),
      ),
    );
  }

  void _openFeedbackSheet(ChatMessage message) {
    final TextEditingController noteController = TextEditingController();
    final Set selectedReasons = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1D26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 18 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.rate_review_outlined,
                            color: Color(0xFFE4AF37), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "நான் எதிர்பார்த்த பதில் இதுவல்ல",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "எதை மேம்படுத்த வேண்டும் எனத் தேர்ந்தெடுக்கவும் அல்லது உங்கள் கருத்தை எழுதவும்:",
                      style: TextStyle(color: Colors.white60, fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _improvementReasons.map((reason) {
                        final isSelected = selectedReasons.contains(reason);
                        return FilterChip(
                          selected: isSelected,
                          backgroundColor: const Color(0xFF0F1115),
                          selectedColor:
                              const Color(0xFFE4AF37).withValues(alpha: 0.25),
                          checkmarkColor: const Color(0xFFE4AF37),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFE4AF37)
                                : Colors.white12,
                          ),
                          label: Text(
                            reason,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.amberAccent
                                  : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () {
                            setSheetState(() {
                              if (isSelected) {
                                selectedReasons.remove(reason);
                              } else {
                                selectedReasons.add(reason);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            "உங்கள் கருத்தை இங்கே பதிவிடுங்கள் (உதா: எந்த வசனம் தேவை, என்ன பிழை உள்ளது)...",
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 12.5),
                        filled: true,
                        fillColor: const Color(0xFF0F1115),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final parts = [];
                              if (selectedReasons.isNotEmpty) {
                                parts.add(selectedReasons.join(', '));
                              }
                              if (noteController.text.trim().isNotEmpty) {
                                parts.add(noteController.text.trim());
                              }
                              final fullNote = parts.isEmpty
                                  ? 'நான் எதிர்பார்த்த பதில் இதுவல்ல'
                                  : parts.join(' • ');

                              setState(() {
                                message.feedbackType = 'improve';
                                message.feedbackNote = fullNote;
                              });

                              await _saveFeedbackLog(
                                question: message.userQuestion ?? '',
                                aiReply: message.text,
                                feedbackType: 'improve',
                                userComment: fullNote,
                              );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "உங்கள் கருத்து பதியப்பட்டது. மிக்க நன்றி!"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text(
                              "கருத்தைப் பதிவு செய்",
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final parts = [];
                              if (selectedReasons.isNotEmpty) {
                                parts.add(selectedReasons.join(', '));
                              }
                              if (noteController.text.trim().isNotEmpty) {
                                parts.add(noteController.text.trim());
                              }
                              final fullNote = parts.isEmpty
                                  ? 'எழுத்துப் பிழையின்றி இன்னும் தெளிவான வேதாகம பதில் தேவை'
                                  : parts.join(' • ');

                              setState(() {
                                message.feedbackType = 'improve';
                                message.feedbackNote = fullNote;
                              });

                              await _saveFeedbackLog(
                                question: message.userQuestion ?? '',
                                aiReply: message.text,
                                feedbackType: 'improve_regenerate',
                                userComment: fullNote,
                              );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              _regenerateWithFeedback(message, fullNote);
                            },
                            child: const Text(
                              "திருத்திப் புதிய பதில் பெறு",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _feedbackDb?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF0F1115);
    const Color cardDark = Color(0xFF1A1D26);
    const Color goldAccent = Color(0xFFE4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: goldAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pas D",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "AI Digital Pastor • Biblical Guide",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'புதிய உரையாடல்',
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: goldAccent,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "உங்களுக்கான வேதாகம பதிலை பெற சற்று நேரம் ஜெபத்தோடு காத்திருங்கள்...",
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final message = _messages[index];
                final isUser = message.isUser;
                final bool showFeedbackBar = !isUser && index > 0;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.86,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? goldAccent.withValues(alpha: 0.18)
                          : cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUser
                            ? goldAccent.withValues(alpha: 0.5)
                            : Colors.white10,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            height: 1.55,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(height: 10),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 8),
                          if (showFeedbackBar) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _onAmenPressed(message),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: message.feedbackType == 'amen'
                                          ? const Color(0xFF1B4332)
                                          : const Color(0xFF0F1115),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: message.feedbackType == 'amen'
                                            ? Colors.tealAccent
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: Text(
                                      "🙏 ஆமென், நன்றி இயேசுவே",
                                      style: TextStyle(
                                        color: message.feedbackType == 'amen'
                                            ? Colors.tealAccent
                                            : Colors.white70,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _openFeedbackSheet(message),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: message.feedbackType == 'improve'
                                          ? Colors.amber.withValues(alpha: 0.2)
                                          : const Color(0xFF0F1115),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: message.feedbackType == 'improve'
                                            ? Colors.amberAccent
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: Text(
                                      "✍️ எதிர்பார்த்த பதில் இதுவல்ல",
                                      style: TextStyle(
                                        color: message.feedbackType == 'improve'
                                            ? Colors.amberAccent
                                            : Colors.white70,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (message.feedbackType == 'improve' &&
                                message.feedbackNote != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                "உங்கள் கருத்து: ${message.feedbackNote}",
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                          ],
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: message.text),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("பதில் நகலெடுக்கப்பட்டது"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: goldAccent,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Copy",
                                    style: TextStyle(
                                      color: goldAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_messages.length == 1)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    backgroundColor: cardDark,
                    side: BorderSide(color: goldAccent.withValues(alpha: 0.4)),
                    label: Text(
                      _quickPrompts[index],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () => _sendMessage(_quickPrompts[index]),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: cardDark,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "உங்கள் கேள்வியை இங்கே கேளுங்கள்...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: bgDark,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: goldAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black, size: 20),
                      onPressed: _isLoading ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
