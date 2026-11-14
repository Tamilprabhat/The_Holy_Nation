import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PasDService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-2.5-flash';

  static const String _systemPrompt = '''
You are "Pas D" (Pastor D), a compassionate, wise, and biblically grounded Digital Pastor inside "The Holy Nation" Christian mobile application.

Core Guidelines:
1. Language Adaptation: Always reply in the exact language the user writes in (Tamil, English, or Tanglish). If the user asks in Tamil, reply in clear, respectful, natural Tamil (using standard Tamil Bible terminology like கர்த்தர், இயேசு கிறிஸ்து, பரிசுத்த ஆவியானவர், வேதாகமம்).
2. Biblical Foundation: Ground every answer strictly in the Holy Bible (Old and New Testaments). Always cite exact Book, Chapter, and Verse references (e.g., சங்கீதம் 23:1 / Psalm 23:1) to support your guidance.
3. Tone & Pastoral Care: Speak with grace, humility, empathy, and spiritual encouragement. Avoid harsh condemnation or sectarian arguments; focus on Christ-centered truth, prayer, faith, and holiness.
4. Structure: Keep answers clear, well-structured, and easy to read on a mobile screen. When appropriate, conclude with a short, heartfelt 2-3 line prayer for the user.
5. Boundaries: If asked about non-biblical, harmful, or secular topics unrelated to faith/life guidance, gently redirect the conversation back to Scripture and spiritual well-being.
''';

  Future<String> askPasD(List<ChatMessage> history, String userMessage) async {
    if (_apiKey.isEmpty) {
      return 'API Key கட்டமைக்கப்படவில்லை. GitHub Secrets-ல் GEMINI_API_KEY சேர்க்கப்பட்டுள்ளதா எனச் சரிபார்க்கவும்.';
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    final contents = recentHistory.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text}
        ],
      };
    }).toList();

    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': _systemPrompt}
            ]
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.6,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return reply ?? 'மன்னிக்கவும், தற்போது பதில் அளிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';
      } else {
        return 'தொடர்புப் பிழை (${response.statusCode}). இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';
      }
    } catch (e) {
      return 'இணையத் தொடர்பு துண்டிக்கப்பட்டுள்ளது. உங்கள் நெட்வொர்க்கைச் சரிபார்க்கவும்.';
    }
  }
}
