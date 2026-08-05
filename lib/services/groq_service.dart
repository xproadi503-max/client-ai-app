import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('groq_api_key') ?? '';
  }

  static Future<List<String>> generateReplies({
    required String clientMessage,
    required String businessType,
    required String tone,
    required String language,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('API key not set. Please go to Settings.');
    }

    final systemPrompt = _buildSystemPrompt(businessType, tone, language);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content':
                'Client ne yeh message bheja hai:\n"$clientMessage"\n\nMujhe 3 alag reply options do JSON format mein.'
          }
        ],
        'temperature': 0.8,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;

    return _parseReplies(content);
  }

  static String _buildSystemPrompt(
      String businessType, String tone, String language) {
    final langInstructions = {
      'English': 'Reply in English only.',
      'Hinglish':
          'Reply in Hinglish (Hindi + English mixed, Roman script). Example: "Bhai aapka kaam 3 din mein ho jayega!"',
      'Hindi': 'Reply in Hindi (Devanagari script).',
    };

    return '''You are an expert freelance business assistant helping with client communication.
Business Type: $businessType
Tone: $tone
${langInstructions[language] ?? langInstructions['Hinglish']}

Generate exactly 3 different reply options for the client message.
Each reply should be practical, professional, and conversion-focused.

Respond ONLY with a valid JSON array like this:
["Reply option 1 here", "Reply option 2 here", "Reply option 3 here"]

No extra text, no markdown, just the JSON array.''';
  }

  static List<String> _parseReplies(String content) {
    try {
      final clean = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final list = jsonDecode(clean) as List;
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      // fallback: split by newlines
      final lines = content
          .split('\n')
          .where((l) => l.trim().isNotEmpty && !l.startsWith('```'))
          .toList();
      if (lines.length >= 3) return lines.take(3).toList();
      return [content];
    }
  }
}
