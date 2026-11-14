import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pas_d_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class PasDScreen extends StatefulWidget {
  const PasDScreen({super.key});

  @override
  State<PasDScreen> createState() => _PasDScreenState();
}

class _PasDScreenState extends State<PasDScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text:
            'கிறிஸ்துவுக்குள் அன்பானவரே, வாழ்த்துக்கள்! நான் Pas D.\n\nவேதாகம சந்தேகங்கள், ஆவிக்குரிய வளர்ச்சி அல்லது ஜெபக் குறிப்புகள் குறித்து என்னிடம் கேளுங்கள். வேத வசனங்களின் அடிப்படையில் உங்களுக்கு வழிகாட்ட நான் தயாராக உள்ளேன்.',
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final List history = _messages
        .skip(1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _controller.clear();
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
    const Color cardDark = Color(0xFF1A1E26);
    const Color goldAccent = Color(0xFFD4AF37);

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
              child: const Icon(
                Icons.auto_awesome,
                color: goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
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
                  
