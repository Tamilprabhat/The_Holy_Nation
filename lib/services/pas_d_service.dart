import 'dart:convert';
import 'package:http/http.dart' as http;

class PasDService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String _systemPrompt = '''
நீங்கள் "Pas D" (AI Digital Pastor) — "The Holy Nation" செயலியின் வேதாகம வழிகாட்டி.
விதிகள்:
1. பயனர் தமிழ் அல்லது ஆங்கிலத்தில் கேட்கும் கேள்விகளுக்கு அதே மொழியில் அன்பாகவும், ஆறுதலாகவும், தெளிவாகவும் பதிலளிக்கவும்.
2. ஒவ்வொரு பதிலிலும் பொருத்தமான பரிசுத்த வேதாகம வசனங்களை (புத்தகம், அதிகாரம், வசனம் குறிப்பிட்டு) மேற்கோள் காட்டவும்.
3. வேதாகம சத்தியங்களுக்கு உட்பட்டு, ஜெபக் குறிப்புகள் மற்றும் ஆவிக்குரிய ஆலோசனைகளை வழங்கவும்.
4. பதில்களைச் சுருக்கமாகவும், வாசிக்க எளிதாகவும் பத்திகளாகப் பிரித்துத் தரவும்.
''';

  static Future<String> askPasD(
    String userMessage, {
    List<dynamic> history = const [],
  }) async {
    if (_apiKey.isEmpty) {
      return "API Key அமைக்கப்படவில்லை. GitHub Secrets-இல் GEMINI_API_KEY உள்ளதா எனச் சரிபார்க்கவும்.";
    }

    final models = ['gemini-2.5-flash', 'gemini-2.0-flash'];

    for (final model in models) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
        );

        final List> contents = [];

        for (final item in history) {
          if (item is Map) {
            final role = item['role']?.toString() ?? 'user';
            final text = item['text']?.toString() ?? '';
            if (text.isNotEmpty) {
              contents.add({
                'role': role,
                'parts': [
                  {'text': text}
                ],
              });
            }
          }
        }

        contents.add({
          'role': 'user',
          'parts': [
            {'text': userMessage}
          ],
        });

        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'systemInstruction': {
                  'parts': [
                    {'text': _systemPrompt}
                  ],
                },
                'contents': contents,
                'generationConfig': {
                  'temperature': 0.7,
                  'maxOutputTokens': 1024,
                },
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final replyText = parts[0]['text']?.toString().trim();
              if (replyText != null && replyText.isNotEmpty) {
                return replyText;
              }
            }
          }
          return "பதில் பெற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.";
        } else if (response.statusCode == 404) {
          // அடுத்த மாடலுக்குத் தானாக மாறும்
          continue;
        } else if (response.statusCode == 400 || response.statusCode == 403) {
          return "API Key பிழை (${response.statusCode}). உங்கள் GEMINI_API_KEY சரியானதா எனச் சரிபார்க்கவும்.";
        } else {
          return "தொடர்புப் பிழை (${response.statusCode}). சற்று நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.";
        }
      } catch (e) {
        return "இணையத் தொடர்பு துண்டிக்கப்பட்டுள்ளது. உங்கள் இன்டர்நெட் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.";
      }
    }

    return "AI சேவையைத் தொடர்பு கொள்ள முடியவில்லை (404). சற்று நேரம் கழித்து முயற்சிக்கவும்.";
  }
}
