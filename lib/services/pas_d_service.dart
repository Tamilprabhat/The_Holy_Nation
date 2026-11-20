import 'dart:convert';
import 'package:http/http.dart' as http;

class PasDService {
  static String get _apiKey =>
      const String.fromEnvironment('GEMINI_API_KEY').trim();

  static String? _cachedWorkingModel;

  static const String _systemPrompt = '''
நீங்கள் "Pas D" (AI Digital Pastor) — "The Holy Nation" செயலியின் வேதாகம வழிகாட்டி.
விதிகள்:
1. பயனர் தமிழ் அல்லது ஆங்கிலத்தில் கேட்கும் கேள்விகளுக்கு அதே மொழியில் அன்பாகவும், ஆறுதலாகவும், தெளிவாகவும் பதிலளிக்கவும்.
2. ஒவ்வொரு பதிலிலும் பொருத்தமான பரிசுத்த வேதாகம வசனங்களை (புத்தகம், அதிகாரம், வசனம் குறிப்பிட்டு) மேற்கோள் காட்டவும்.
3. வேதாகம சத்தியங்களுக்கு உட்பட்டு, ஜெபக் குறிப்புகள் மற்றும் ஆவிக்குரிய ஆலோசனைகளை வழங்கவும்.
4. பதில்களைச் சுருக்கமாகவும், வாசிக்க எளிதாகவும் பத்திகளாகப் பிரித்துத் தரவும்.
''';

  static Future _discoverActiveModels() async {
    final List discovered = [];
    final client = http.Client();
    try {
      final listUri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
      );
      final res = await client
          .get(listUri, headers: {'Connection': 'close'})
          .timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final models = data['models'];
        if (models is List) {
          final List flashModels = [];
          final List otherModels = [];

          for (final m in models) {
            if (m is Map) {
              final rawName = m['name']?.toString() ?? '';
              final methods = m['supportedGenerationMethods'];
              if (methods is List && methods.contains('generateContent')) {
                final cleanName = rawName.replaceFirst('models/', '');
                if (cleanName.contains('embedding') ||
                    cleanName.contains('imagen') ||
                    cleanName.contains('veo')) {
                  continue;
                }
                if (cleanName.contains('flash')) {
                  flashModels.add(cleanName);
                } else if (cleanName.contains('gemini')) {
                  otherModels.add(cleanName);
                }
              }
            }
          }

          flashModels.sort((a, b) => b.toString().compareTo(a.toString()));
          otherModels.sort((a, b) => b.toString().compareTo(a.toString()));

          discovered.addAll(flashModels);
          discovered.addAll(otherModels);
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return discovered;
  }

  static Future askPasD(
    String userMessage, {
    List history = const [],
  }) async {
    if (_apiKey.isEmpty) {
      return "API Key அமைக்கப்படவில்லை. GitHub Secrets-இல் GEMINI_API_KEY உள்ளதா எனச் சரிபார்க்கவும்.";
    }

    final List candidatesList = [];
    if (_cachedWorkingModel != null) {
      candidatesList.add(_cachedWorkingModel);
    }

    final liveModels = await _discoverActiveModels();
    for (final m in liveModels) {
      if (!candidatesList.contains(m)) {
        candidatesList.add(m);
      }
    }

    final fallbackModels = [
      'gemini-3.8-flash',
      'gemini-3.0-flash',
      'gemini-3-flash-preview',
      'gemini-2.5-flash',
      'gemini-2.0-flash',
    ];
    for (final m in fallbackModels) {
      if (!candidatesList.contains(m)) {
        candidatesList.add(m);
      }
    }

    final contents = [];
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

    String lastErrorDetail = '';

    for (final model in candidatesList) {
      final client = http.Client();
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
        );

        final response = await client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Connection': 'close',
              },
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
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content != null ? content['parts'] : null;
            if (parts is List && parts.isNotEmpty) {
              final replyText = parts[0]['text']?.toString().trim();
              if (replyText != null && replyText.isNotEmpty) {
                _cachedWorkingModel = model.toString();
                return replyText;
              }
            }
          }
        } else {
          try {
            final errData = jsonDecode(response.body);
            lastErrorDetail = errData['error']?['message']?.toString() ??
                '${response.statusCode}';
          } catch (_) {
            lastErrorDetail = '${response.statusCode}';
          }

          if (response.statusCode == 403) {
            return "API Key அனுமதிப் பிழை (403): $lastErrorDetail";
          }
          continue;
        }
      } catch (e) {
        lastErrorDetail = e.toString();
        continue;
      } finally {
        client.close();
      }
    }

    return "தொடர்புப் பிழை: சற்று நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.\n($lastErrorDetail)";
  }
}
