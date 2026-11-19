import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pas_d_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class PasDScreen extends StatefulWidget {
  const PasDScreen({super.key});

  @override
  State<PasDScreen> createState() => _PasDScreenState();
}

class _PasDScreenState extends State<PasDScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    "மன அமைதிக்கான வேத வசனம்",
    "பயத்தை நீக்கும் ஜெபம்",
    "மன்னிப்பைப் பற்றி வேதம் என்ன சொல்கிறது?",
    "Biblical guidance for difficult times",
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
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

  Future<void> _sendMessage([String? customText]) async {
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
      _messages.add(ChatMessage(text: reply, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
                color: goldAccent.withOpacity(0.15),
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
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: goldAccent,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "வேதாகம பதிலைத் தயாரிக்கிறது...",
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                final message = _messages[index];
                final isUser = message.isUser;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? goldAccent.withOpacity(0.18)
                          : cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUser
                            ? goldAccent.withOpacity(0.5)
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
                            height: 1.5,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(height: 8),
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
                    side: BorderSide(color: goldAccent.withOpacity(0.4)),
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
