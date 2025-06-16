import 'dart:convert';
import 'package:http/http.dart' as http;

class HighlightService {
  static Future<List<String>> extractHighlights({
    required String flowText,
    required String prompt,
    int maxHighlights = 3,
  }) async {
    final apiKey = const String.fromEnvironment('OPENAI_API_KEY');
    if (apiKey.isEmpty) return [];
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': flowText},
        ],
        'max_tokens': 150,
        'n': 1,
      }),
    );
    if (res.statusCode != 200) return [];
    try {
      final data = jsonDecode(res.body);
      final content = data['choices'][0]['message']['content'] as String;
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