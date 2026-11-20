import 'dart:convert';
import 'package:http/http.dart' as http;

class PasDService {
  static String get _apiKey =>
      const String.fromEnvironment('GEMINI_API_KEY').trim();

  static String? _cachedWorkingModel;

  static const String _systemPrompt = '''
நீங்கள் "Pas D" (AI Digital Pastor) — "The Holy Nation" செயலியின் பன்மொழி வேதாகம வழிகாட்டி.

மொழி மற்றும் எழுத்து விதிகள் (மிக முக்கியம்):
1. தமிழ் (Tamil), ஆங்கிலம் (English), இந்தி (Hindi), மலையாளம் (Malayalam), தெலுங்கு (Telugu), கன்னடம் (Kannada), பெங்காலி (Bengali), மராத்தி (Marathi), குஜராத்தி (Gujarati), பஞ்சாபி (Punjabi) ஆகிய அனைத்துப் பிரபலமான இந்திய மொழிகளிலும் சரளமாகவும் அன்பாகவும் உரையாட வேண்டும்.
2. பயனர் ஒரு குறிப்பிட்ட மொழியைத் தேர்ந்தெடுத்திருந்தால் அந்த மொழியிலும், "Auto" என இருந்தால் பயனர் கேள்வி கேட்ட அதே மொழியிலும் பதிலளிக்கவும்.
3. தேர்ந்தெடுக்கப்பட்ட மொழியின் 100% தூய எழுத்துக்களை மட்டுமே பயன்படுத்த வேண்டும்; ஒரு மொழியில் எழுதும்போது இடையில் வேறு இந்திய மொழியின் எழுத்துக்கள் கலக்கக் கூடாது.
4. எழுத்துப் பிழை மற்றும் இலக்கணப் பிழையின்றி இயல்பான, மரியாதையான நடையில் எழுதவும்.
5. பதிலில் நட்சத்திரக் குறியீடுகள் (** அல்லது *) மற்றும் > போன்ற குறியீடுகளைப் பயன்படுத்தாமல், தெளிவான தலைப்புகள் மற்றும் பத்திகளாகப் பிரித்து எழுதவும்.

பதிலின் கட்டமைப்பு (பயனர் பேசும் மொழியிலேயே கீழே உள்ள பகுதிகள் இருக்க வேண்டும்):
1. ஆவிக்குரிய ஆலோசனை மற்றும் வேத வசனங்கள்: கேள்விக்குப் பொருத்தமான பரிசுத்த வேதாகம வசனங்களை (புத்தகம், அதிகாரம், வசனம் குறிப்பிட்டு) மேற்கோள் காட்டித் தெளிவான விளக்கம் அளிக்கவும்.
2. சிறிய ஜெபம்: பயனருக்காக ஒரு சுருக்கமான, மனதைத் தொடும் ஜெபத்தை எழுதவும்.
3. தொடர்ந்து வாசிக்க வேண்டிய வேதாகம அதிகாரங்கள்: ஆவிக்குரிய ஜீவியத்தில் வளர வேதாகமத்தில் வாசிக்க வேண்டிய 2 அல்லது 3 முக்கிய அதிகாரங்களைப் பரிந்துரைக்கவும்.
4. ஜெப நேரப் பரிந்துரை: இந்தக் காரியத்திற்காக அதிகாலை, பகல் அல்லது இரவு வேளைகளில் எவ்வாறு ஜெபிக்கலாம் என்ற நடைமுறை ஆலோசனையை வழங்கவும்.
5. அன்பான அழைப்பு: பதிலின் இறுதியில், உங்கள் ஆவிக்குரிய வாழ்க்கையின் ஆழமான சந்தேகங்களையும் கேள்விகளையும் தொடர்ந்து என்னிடத்தில் கேளுங்கள் என உற்சாகப்படுத்தி முடிக்கவும்.
''';

  static String _cleanResponseText(String raw) {
    String cleaned = raw
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('### ', '')
        .replaceAll('## ', '')
        .replaceAll('# ', '')
        .replaceAll(RegExp(r'^\s*>\s*', multiLine: true), '');

    // பதில் தமிழில் இருந்தால் மட்டும், தவறுதலாகக் கலக்கும் பெங்காலி/தேவநாகரி எழுத்துக்களை நீக்குதல்
    final bool hasTamil = RegExp('[\u0B80-\u0BFF]').hasMatch(cleaned);
    if (hasTamil) {
      cleaned = cleaned.replaceAll(RegExp('[\u0980-\u09FF\u0900-\u097F]+'), '');
    }

    cleaned = cleaned.replaceAll(RegExp(r' {2,}'), ' ').trim();
    return cleaned;
  }

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
          final List standardFlashModels = [];
          final List liteFlashModels = [];
          final List otherModels = [];

          for (final m in models) {
            if (m is Map) {
              final rawName = m['name']?.toString() ?? '';
              final methods = m['supportedGenerationMethods'];
              if (methods is List && methods.contains('generateContent')) {
                final cleanName = rawName.replaceFirst('models/', '');
                if (cleanName.contains('embedding') ||
                    cleanName.contains('imagen') ||
                    cleanName.contains('veo') ||
                    cleanName.contains('tts') ||
                    cleanName.contains('audio')) {
                  continue;
                }
                if (cleanName.contains('flash') && !cleanName.contains('lite')) {
                  standardFlashModels.add(cleanName);
                } else if (cleanName.contains('flash')) {
                  liteFlashModels.add(cleanName);
                } else if (cleanName.contains('gemini')) {
                  otherModels.add(cleanName);
                }
              }
            }
          }

          standardFlashModels
              .sort((a, b) => b.toString().compareTo(a.toString()));
          liteFlashModels.sort((a, b) => b.toString().compareTo(a.toString()));
          otherModels.sort((a, b) => b.toString().compareTo(a.toString()));

          discovered.addAll(standardFlashModels);
          discovered.addAll(liteFlashModels);
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
    String? feedbackCorrection,
    String preferredLanguage = 'Auto',
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

    final String langInstruction = (preferredLanguage != 'Auto')
        ? "\n[Response Language Requirement: Please respond strictly and completely in $preferredLanguage language using its native script.]"
        : "\n[Response Language Requirement: Detect the user's language (Tamil, Hindi, Malayalam, Telugu, Kannada, Bengali, Marathi, Gujarati, Punjabi, or English) and respond strictly in that exact same language.]";

    final String finalPrompt = (feedbackCorrection != null &&
            feedbackCorrection.trim().isNotEmpty)
        ? "$userMessage$langInstruction\n\n(User Feedback / Correction: $feedbackCorrection — Please improve the answer carefully according to this feedback.)"
        : "$userMessage$langInstruction";

    contents.add({
      'role': 'user',
      'parts': [
        {'text': finalPrompt}
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
                  'temperature': 0.25,
                  'topP': 0.85,
                  'maxOutputTokens': 1400,
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
                return _cleanResponseText(replyText);
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
