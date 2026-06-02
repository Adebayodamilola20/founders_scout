import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_keys.dart';
import '../../radar/models/scout_lead.dart';

class MistralService {
  static const String _baseUrl = 'https://api.mistral.ai/v1/chat/completions';
  static const String _model = 'mistral-small-latest';

  Future<List<String>> generateSuggestions(ScoutLead lead) async {
    // If the API key is empty or default, return mock suggestions
    if (ApiKeys.mistralApiKey == 'YOUR_MISTRAL_API_KEY_HERE') {
      return [
        'Pitch a new website build',
        'Offer to boost their Google rating',
        'Draft a friendly social media intro',
      ];
    }

    final systemPrompt = '''
You are an expert sales outreach strategist. You are helping the user draft an outreach message to a business.
Business Name: ${lead.name}
Category: ${lead.category}
Identified Digital Gaps: ${lead.matchedGaps.join(", ")}
Current Google Rating: ${lead.ratingSnippet}

Based on these specific digital gaps and details, generate exactly 3 short, actionable conversation starters the user can use to begin drafting a pitch.
Each suggestion MUST be 1 sentence, and strictly under 8 words. 
Do NOT use ANY markdown formatting. No asterisks, no hashes, no bullet points, no brackets. Just plain text.
Return the 3 suggestions separated by a pipe character (|) and nothing else.
Example: Pitch a new website|Draft a friendly SMS about reviews|Offer video editing services
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.mistralApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': systemPrompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).take(3).toList();
      } else {
        print('Mistral API Error: ${response.statusCode} - ${response.body}');
        return ['Pitch a new website build', 'Offer to boost their rating', 'Draft a social media intro'];
      }
    } catch (e) {
      print('Mistral Exception: $e');
      return ['Pitch a new website build', 'Offer to boost their rating', 'Draft a social media intro'];
    }
  }

  Future<String> sendMessage(ScoutLead lead, List<Map<String, String>> chatHistory) async {
    if (ApiKeys.mistralApiKey == 'YOUR_MISTRAL_API_KEY_HERE') {
      await Future.delayed(const Duration(seconds: 2));
      return "I noticed you haven't entered your Mistral API key yet! Please go to lib/core/constants/api_keys.dart and add your key to see real AI generation in action.";
    }

    final systemPrompt = '''
You are an expert sales copywriter acting as "Scout AI". 
You are helping the user draft an outreach message to a business.
Business Name: ${lead.name}
Category: ${lead.category}
Identified Digital Gaps: ${lead.matchedGaps.join(", ")}
Current Google Rating: ${lead.ratingSnippet}

CRITICAL RULE: Do NOT use ANY markdown formatting in your responses. Never use asterisks (*) for bolding, hashtags (#) for headers, brackets, or bullet points. Return ONLY raw, plain text formatted with standard spacing and paragraphs.
Be highly conversational, persuasive, and directly reference the business's specific gaps to make the pitch compelling. Keep pitches relatively short (under 3 paragraphs) unless asked otherwise.
''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...chatHistory,
    ];

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.mistralApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        print('Mistral API Error: ${response.statusCode} - ${response.body}');
        return 'I encountered an error connecting to the API. Please try again.';
      }
    } catch (e) {
      print('Mistral Exception: $e');
      return 'I encountered a network error. Please check your connection and try again.';
    }
  }
}
