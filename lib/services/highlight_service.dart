import 'dart:convert';
import 'package:http/http.dart' as http;

class HighlightService {
  static Future<List<String>> extractHighlights({
    required String flowText,
    required String prompt,
    int maxHighlights = 3,
  }) async {
    final apiKey = const String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) return [];
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey',
    );
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': '$prompt\n$flowText',
              }
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 150,
        }
      }),
    );
    if (res.statusCode != 200) return [];
    try {
      final data = jsonDecode(res.body);
      final content = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final lines = content
          .split(RegExp(r'[\n\r]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(maxHighlights)
          .toList();
      return lines;
    } catch (_) {
      return [];
    }
  }
}