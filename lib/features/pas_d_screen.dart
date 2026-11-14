import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pas_d_service.dart';

class PasDScreen extends StatefulWidget {
  const PasDScreen({super.key});

  @override
  State<PasDScreen> createState() => _PasDScreenState();
}

class _PasDScreenState extends State<PasDScreen> {
  final PasDService _pasDService = PasDService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'கிறிஸ்துவுக்குள் அன்பானவரே, வாழ்த்துக்கள்! நான் Pas D.\n\nவேதாகம சந்தேகங்கள், ஆவிக்குரிய வளர்ச்சி அல்லது ஜெபக் குறிப்புகள் குறித்து என்னிடம் கேளுங்கள். வேத வசனங்களின் அடிப்படையில் உங்களுக்கு வழிகாட்ட நான் தயாராக உள்ளேன்.',
      isUser: false,
    ),
  ];

  bool _isLoading = false;

  final List<String> _quickPrompts = [
    'மன அமைதிக்கு வேத வசனம்',
    'விசுவாசத்தில் வளர்வது எப்படி?',
    'பரிசுத்த ஆவியானவரின் கனிகள்',
    'How to overcome fear biblically?',
  ];

  void _sendMessage([String? presetText]) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await _pasDService.askPasD(
      _messages.sublist(0, _messages.length - 1),
      text,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
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

  void _clearChat() {
    setState(() {
      _messages.removeRange(1, _messages.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F1115);
    const cardDark = Color(0xFF1A1D24);
    const goldAccent = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: cardDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: goldAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: goldAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pas D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'AI Digital Pastor • Biblical Guide',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'உரையாடலை அழி (Clear Chat)',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _clearChat,
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
                if (_isLoading && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: goldAccent,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Pas D வேத வசனங்களை ஆராய்கிறார்...',
                            style: TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                return _buildMessageBubble(msg, cardDark, goldAccent);
              },
            ),
          ),
          if (_messages.length <= 2)
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    backgroundColor: cardDark,
                    side: BorderSide(color: goldAccent.withOpacity(0.4)),
                    label: Text(
                      _quickPrompts[index],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    onPressed: () => _sendMessage(_quickPrompts[index]),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: cardDark,
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'உங்கள் வேதாகமக் கேள்வியைக் கேளுங்கள்...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        filled: true,
                        fillColor: bgDark,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
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
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                      onPressed: () => _sendMessage(),
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

  Widget _buildMessageBubble(ChatMessage msg, Color cardDark, Color goldAccent) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? goldAccent.withOpacity(0.2) : cardDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser ? goldAccent.withOpacity(0.5) : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            if (!msg.isUser) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('பதில் நகலெடுக்கப்பட்டது (Copied)'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 14, color: Colors.white54),
                      SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
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
  }
}
