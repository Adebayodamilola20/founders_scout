import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/app_config_service.dart';
import '../../radar/models/scout_lead.dart';
import '../../radar/models/scout_scan_result.dart';

class MistralPitchService {
  MistralPitchService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://api.mistral.ai/v1/chat/completions';
  static const _model = 'mistral-small-latest';

  String buildLeadSystemPrompt(ScoutLead lead) {
    final rating = lead.hasRatings
        ? '${lead.rating!.toStringAsFixed(1)} stars from ${lead.userRatingsTotal} reviews'
        : 'no visible ratings yet';
    final gaps = lead.matchedGaps.isEmpty
        ? 'No clear digital gap detected'
        : lead.matchedGaps.join(', ');
    final opportunityLevel = _opportunityLevelForLead(lead);
    final opportunityReason = _opportunityReasonForLead(lead);
    final websiteStatus = lead.hasWebsite ? 'Has a website' : 'Missing website';
    final phoneStatus = (lead.phoneNumber == null || lead.phoneNumber!.trim().isEmpty)
        ? 'No visible phone number'
        : 'Phone number available';

    return '''
You are Scout AI, a lead-closing assistant for freelancers using Founders Scout.
Your job is to help the user identify the best lead angle, write outreach that gets replies, follow up properly, and move leads toward a paying client.

Business name: ${lead.name}
Category: ${lead.selectedCategory}
Address: ${lead.address}
Rating context: $rating
Detected digital gaps: $gaps
Website status: $websiteStatus
Photo count: ${lead.photoCount}
Phone status: $phoneStatus
Opportunity level: $opportunityLevel
Opportunity reason: $opportunityReason

Behavior rules:
- Think like a sales strategist, not a generic copy assistant.
- Always explain whether this lead is a good or weak opportunity when the user asks for analysis.
- Always tie advice to the business weaknesses, visibility gaps, and likely conversion probability.
- When generating a pitch, make it personalized, short, clear, confident, and human.
- Use this structure by default for outreach: opening, observation, value, soft close.
- When the user asks who to contact or what angle to use, prioritize highest-conversion opportunities first.
- When the user asks for follow-up help, produce polite follow-ups for 2 to 3 days after first contact or 5 to 7 days after no reply.
- When the user asks what to charge, give a practical price range based on business type, location, and problem severity.
- Give the user the next best action and suggest timing when relevant.
- Assume lead status can be New, Contacted, Replied, or Closed. Adapt advice to that context if the user mentions status.
- You do not have access to WhatsApp replies or real conversations. Never claim a business replied unless the user says so.
- If data is missing or weak, say that directly instead of pretending certainty.
- Keep answers concise, practical, strategic, and focused on getting the user paid.
- If the user asks for multiple options, give at most 3 strong options.
- If the user asks for lead value, classify it as High, Medium, or Low and explain why in one short line.
- If the user asks for rewrite help, preserve the business context automatically.
- NEVER use markdown formatting. Do NOT use asterisks (**), hashtags (###), underscores, or any special formatting characters.
- Respond in plain text only.
''';
  }

  String buildScanSystemPrompt(ScoutScanResult scanResult) {
    final rankedLeads = _rankLeads(scanResult.leads).take(8).toList();
    final leadSummary = rankedLeads.isEmpty
        ? 'No matching leads are available right now.'
        : rankedLeads.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final lead = entry.value;
            final rating = lead.hasRatings
                ? '${lead.rating!.toStringAsFixed(1)} stars from ${lead.userRatingsTotal} reviews'
                : 'no visible ratings';
            final website = lead.hasWebsite ? 'has website' : 'no website';
            final gaps = lead.matchedGaps.isEmpty ? 'no clear gap' : lead.matchedGaps.join(', ');
            return '$index. ${lead.name} | ${lead.selectedCategory} | $website | $rating | gaps: $gaps | opportunity: ${_opportunityLevelForLead(lead)}';
          }).join('\n');

    return '''
You are Scout AI, a lead-closing assistant for freelancers using Founders Scout.
You are helping the user choose the best local businesses to contact, decide what to say, and move outreach toward a paying client.

Current scout area: ${scanResult.request.locationLabel}
Selected categories: ${scanResult.request.categories.join(', ')}
Selected service focus: ${scanResult.request.digitalGaps.join(', ')}
Total matched leads: ${scanResult.totalLeads}

Current ranked leads:
$leadSummary

Behavior rules:
- This app is for local business outreach, not startup investing, fundraising, hiring, recruiting, or B2B SaaS prospecting.
- When the user asks for top leads, rank the best 3 local business leads from the current scan and explain each choice briefly.
- Base rankings on conversion probability, visible digital weakness, and how easy the pitch angle is.
- Prefer leads with missing websites, weak reviews, low visual presence, or multiple matched gaps.
- If the user asks for a pitch, write it for one of the scanned businesses, using the business name and its actual weaknesses.
- If the user asks a broad question like "what are my top 3 leads right now", answer from the current scan only.
- If there are no good leads, say that clearly and suggest the next best action.
- Do not ask the user about investors, customers, funding, geography segments, or startup sectors.
- Keep answers concise, practical, strategic, and focused on getting the user paid.
- NEVER use markdown formatting. Do NOT use asterisks (**), hashtags (###), underscores, or any special formatting characters.
- Respond in plain text only.
''';
  }

  Future<List<String>> generateSuggestions(ScoutLead lead) async {
    final response = await _postChatCompletion(
      messages: [
        {
          'role': 'system',
          'content': buildLeadSystemPrompt(lead),
        },
        {
          'role': 'user',
          'content':
              'Generate exactly 3 short conversation starter prompts for me to tap. '
              'They should reflect the most valuable actions for this lead: opportunity analysis, personalized outreach, follow-up, pricing, or next action. '
              'Each should be specific to this business and its weaknesses. '
              'Return JSON only in this format: {"suggestions":["...","...","..."]}',
        },
      ],
      temperature: 0.7,
      maxTokens: 220,
    );

    final content = _extractContent(response);
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final suggestions = (decoded['suggestions'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList();

    if (suggestions.length != 3) {
      throw StateError('Suggestion generation returned an unexpected format.');
    }

    return suggestions;
  }

  Future<String> sendConversation({
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    final response = await _postChatCompletion(
      messages: [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        ...history.map((message) => {
              'role': message['role'],
              'content': message['content'],
            }),
      ],
      temperature: 0.75,
      maxTokens: 500,
    );

    return _extractContent(response).trim();
  }

  Future<Map<String, dynamic>> _postChatCompletion({
    required List<Map<String, Object?>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer ${AppConfigService.getMistralApiKey()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Mistral request failed with status ${response.statusCode}.',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _extractContent(Map<String, dynamic> response) {
    final choices = response['choices'] as List<dynamic>? ?? const [];
    if (choices.isEmpty) {
      throw StateError('Mistral returned no response choices.');
    }
    final message = choices.first['message'] as Map<String, dynamic>? ?? const {};
    final content = message['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw StateError('Mistral returned an empty response.');
    }
    return _stripMarkdown(content.trim());
  }

  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        .replaceAll(RegExp(r'`(.+?)`'), r'$1')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
  }

  String _opportunityLevelForLead(ScoutLead lead) {
    if (!lead.hasWebsite && lead.matchedGaps.length >= 2) {
      return 'High';
    }
    if (!lead.hasWebsite || lead.matchedGaps.length >= 2) {
      return 'Medium';
    }
    return 'Low';
  }

  String _opportunityReasonForLead(ScoutLead lead) {
    if (!lead.hasWebsite && lead.userRatingsTotal <= 5) {
      return 'No website and weak review visibility.';
    }
    if (lead.matchedGaps.length >= 3) {
      return 'Multiple digital gaps are visible.';
    }
    if (lead.hasMediaDeficit) {
      return 'Weak visual presence creates an easy pitch angle.';
    }
    if (lead.matchedGaps.isNotEmpty) {
      return 'There is a visible service gap to pitch around.';
    }
    return 'The lead may need a more specific audit before outreach.';
  }

  List<ScoutLead> _rankLeads(List<ScoutLead> leads) {
    final ranked = List<ScoutLead>.from(leads);
    ranked.sort((a, b) => _leadScore(b).compareTo(_leadScore(a)));
    return ranked;
  }

  int _leadScore(ScoutLead lead) {
    var score = 0;
    score += lead.matchedGaps.length * 3;
    if (!lead.hasWebsite) {
      score += 4;
    }
    if (lead.photoCount < 3) {
      score += 2;
    }
    if (!lead.hasRatings) {
      score += 2;
    } else {
      if ((lead.rating ?? 0) < 4.0) {
        score += 2;
      }
      if (lead.userRatingsTotal < 10) {
        score += 2;
      }
    }
    if (lead.phoneNumber != null && lead.phoneNumber!.trim().isNotEmpty) {
      score += 1;
    }
    return score;
  }
}
