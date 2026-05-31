import 'dart:convert';
import 'package:http/http.dart' as http;

class GrogAdvisorService {
  // Paste your Groq API key here
  static const String apiKey = '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';

  // Good fast model for this use-case
  static const String model = 'llama-3.1-8b-instant';

  Future<String?> generateClimateAdvice({
    required Map<String, dynamic>? weatherData,
    required String persona,
    required String question,
  }) async {
    try {
      if (apiKey == 'PASTE_YOUR_GROQ_API_KEY_HERE' ||
          apiKey.trim().isEmpty) {
        return null;
      }

      if (weatherData == null) {
        return 'I’m not able to see reliable climate data right now, so I’d rather not guess. Please try refreshing once.';
      }

      final current = weatherData['current'] as Map<String, dynamic>? ?? {};
      final hourly = weatherData['hourly'] as List<dynamic>? ?? [];
      final cityName = weatherData['name'] ?? 'Unknown Location';

      final systemPrompt = '''
You are Climatea AI, a friendly hyper-local climate advisor.

Your role:
Turn weather data into helpful, real-world advice.

Tone:
- Friendly
- Calm
- Practical
- Human
- Clear
- Confident, but not aggressive
- Direct, but not too blunt

Rules:
- Do not sound robotic.
- Do not dump raw numbers unless useful.
- Focus on what the person should know or do.
- Mention risk clearly: Low, Medium, or High.
- Keep it concise.
- Keep it under 120 words.
- Tailor the answer for the user's persona.
''';

      final userPrompt = '''
Persona:
$persona

Location:
$cityName

User question:
$question

Current weather:
${jsonEncode(current)}

Next hours forecast:
${jsonEncode(hourly.take(6).toList())}

Return format exactly like this:

Risk: <Low/Medium/High>
Advice: <friendly practical answer>
Why: <1 or 2 short reasons>
''';

      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': userPrompt,
            }
          ],
          'temperature': 0.6,
          'max_tokens': 220,
        }),
      );

      if (response.statusCode == 429) {
        print('Groq quota/rate limit hit: ${response.body}');
        return '__QUOTA_EXCEEDED__';
      }

      if (response.statusCode != 200) {
        print('Groq API error: ${response.statusCode}');
        print('Groq API body: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body);
      final choices = data['choices'];

      if (choices == null || choices.isEmpty) {
        print('Groq API returned no choices.');
        return null;
      }

      final message = choices[0]['message'];
      if (message == null) {
        print('Groq API returned no message.');
        return null;
      }

      final content = message['content'];
      if (content == null || content.toString().trim().isEmpty) {
        print('Groq API returned empty content.');
        return null;
      }

      return content.toString().trim();
    } catch (e) {
      print('Error in Groq advisor service: $e');
      return null;
    }
  }
}