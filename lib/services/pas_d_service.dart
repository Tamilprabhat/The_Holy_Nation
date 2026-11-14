import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PasDService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const List _models = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
  ];

  static const String _systemInstruction = '''
நீங்கள் "Pas D" — "The Holy Nation" (பரிசுத்த ஜாதி - 1 பேதுரு 2:9) செயலியின் அன்பான, வேதாகம அறிவு நிறைந்த AI டிஜிட்டல் போதகர் (AI Digital Pastor).
உங்கள் வழிகாட்டுதல் விதிகள்:
1. பயனர் தமிழில் கேட்டால் தெளிவான, இனிமையான தமிழிலும், ஆங்கிலத்தில் கேட்டால் ஆங்கிலத்திலும் பதிலளிக்கவும்.
2. ஒவ்வொரு ஆலோசனைக்கும் பொருத்தமான பரிசுத்த வேதாகம வசனங்களை (புத்தகம், அதிகாரம், வசனம் குறிப்பிட்டு — எ.கா: பிலிப்பியர் 4:6-7, சங்கீதம் 23:1) ஆதாரமாகக் கொடுக்கவும்.
3. பதில்கள் ஆறுதலாகவும், நம்பிக்கையூட்டுவதாகவும், கிறிஸ்தவ அன்போடும் சுருக்கமாகவும் தெளிவாகவும் இருக்க வேண்டும்.
4. கடைசியில் பயனருக்காக ஒரு சிறிய, ஊக்கமளிக்கும் ஜெபக் குறிப்பைச் சேர்க்கவும்.
''';

  static Future<String> askPasD(
    String userMessage, {
    List history = const [],
  }) async {
    final cleanedKey = _apiKey.trim();
    if (cleanedKey.isEmpty) {
      return 'API Key கட்டமைக்கப்படவில்லை. GitHub Secrets-ல் GEMINI_API_KEY சேர்க்கப்பட்டுள்ளதா எனச் சரிபார்க்கவும்.';
    }

    final List contents = [];

    for (final msg in history) {
      if (msg is Map) {
        final role = msg['role'] == 'user' ? 'user' : 'model';
        final text = (msg['text'] ?? msg['content'] ?? '').toString();
        if (text.trim().isNotEmpty) {
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

    final requestBody = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemInstruction}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    });

    int lastStatusCode = 0;

    try {
      for (final model in _models) {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$cleanedKey',
        );

        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
              },
              body: requestBody,
            )
            .timeout(const Duration(seconds: 30));

        lastStatusCode = response.statusCode;

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final candidates = data['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content != null ? content['parts'] : null;
            if (parts is List && parts.isNotEmpty) {
              final reply = parts[0]['text']?.toString().trim();
              if (reply != null && reply.isNotEmpty) {
                return reply;
              }
            }
          }
          return 'மன்னிக்கவும், இப்போதைக்கு பதில் உருவாக்க முடியவில்லை. சற்று நேரம் கழித்து மீண்டும் கேளுங்கள்.';
        } else if (response.statusCode == 404) {
          continue;
        } else if (response.statusCode == 400 || response.statusCode == 403) {
          return 'API Key அனுமதிப் பிழை (${response.statusCode}). Google AI Studio-வில் உங்கள் API Key சரியாக உள்ளதா எனச் சரிபார்க்கவும்.';
        } else if (response.statusCode == 429) {
          return 'அதிகப்படியான கேள்விகள் கேட்கப்பட்டுள்ளன (429). ஒரு நிமிடம் கழித்து மீண்டும் முயற்சிக்கவும்.';
        }
      }

      return 'தொடர்புப் பிழை ($lastStatusCode). சற்று நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.';
    } on SocketException {
      return 'இணையத் தொடர்பு துண்டிக்கப்பட்டுள்ளது. உங்கள் நெட்வொர்க்கைச் சரிபார்க்கவும்.';
    } catch (e) {
      return 'தொடர்புப் பிழை ஏற்பட்டுள்ளது. இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';
    }
  }

  Future<String> sendMessage(
    String userMessage, {
    List history = const [],
  }) {
    return askPasD(userMessage, history: history);
  }

  static Future<String> getResponse(String userMessage) {
    return askPasD(userMessage);
  }
}
