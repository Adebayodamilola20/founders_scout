import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pitch_template.dart';

class PitchTemplateRepository {
  PitchTemplateRepository._();

  static final PitchTemplateRepository instance = PitchTemplateRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  List<PitchTemplate> getBuiltinTemplates() {
    return const [
      PitchTemplate(
        id: 'cold_email_intro',
        title: 'Cold Email Intro',
        category: 'Email',
        scenario: 'First Contact',
        prompt: 'Write a cold email introduction for {businessName}, a {category} business at {location}. Mention their digital gaps: {gaps}. Keep it short, confident, and personalized. Use this structure: friendly opening, specific observation about their business, clear value proposition, soft call to action.',
        description: 'Professional cold email for first outreach to a new lead.',
      ),
      PitchTemplate(
        id: 'social_dm',
        title: 'Social Media DM',
        category: 'Social',
        scenario: 'First Contact',
        prompt: 'Write a casual, friendly social media direct message to {businessName}, a {category} business. Keep it conversational and under 100 words. Mention something specific about their business: {gaps}. End with a low-pressure invitation to chat.',
        description: 'Casual DM for Instagram, Facebook, or LinkedIn outreach.',
      ),
      PitchTemplate(
        id: 'follow_up_3day',
        title: '3-Day Follow Up',
        category: 'Email',
        scenario: 'Follow Up',
        prompt: 'Write a polite 3-day follow-up message to {businessName}. I contacted them 3 days ago about {gaps}. Keep it short and non-pushy. Reference my previous message casually. Add one new value point or insight. End with a gentle ask for their time.',
        description: 'Follow-up message 3 days after initial contact.',
      ),
      PitchTemplate(
        id: 'follow_up_7day',
        title: '7-Day Follow Up',
        category: 'Email',
        scenario: 'Follow Up',
        prompt: 'Write a final 7-day follow-up message to {businessName}. I reached out a week ago about {gaps}. Keep it brief and respectful. Offer one last piece of value. Make it clear this is my final outreach attempt. Leave the door open for them to reach out later.',
        description: 'Final follow-up after a week of no response.',
      ),
      PitchTemplate(
        id: 'website_pitch',
        title: 'Website Build Pitch',
        category: 'Service',
        scenario: 'Specific Service',
        prompt: 'Write a pitch to {businessName}, a {category} at {location} that does not have a website. Explain why having a website matters for their specific business type. Mention their current gaps: {gaps}. Include a clear offer to build them a professional site. Keep it focused on their customers, not on technology.',
        description: 'Pitch a website build to a business without one.',
      ),
      PitchTemplate(
        id: 'review_boost',
        title: 'Review Boost Offer',
        category: 'Service',
        scenario: 'Specific Service',
        prompt: 'Write a pitch to {businessName}, a {category} with only {rating} stars from {reviews} reviews. Explain how more positive reviews would directly impact their revenue. Offer a specific strategy to help them collect more reviews. Keep it practical and results-focused.',
        description: 'Offer to help a business improve their Google reviews.',
      ),
      PitchTemplate(
        id: 'photo_upgrade',
        title: 'Photo Upgrade Pitch',
        category: 'Service',
        scenario: 'Specific Service',
        prompt: 'Write a pitch to {businessName}, a {category} with only {photoCount} photos on their Google listing. Explain how professional photos increase customer trust and conversion. Offer to take or create better visuals for their profile. Keep it under 150 words.',
        description: 'Pitch professional photo services to a business.',
      ),
      PitchTemplate(
        id: 'phone_script',
        title: 'Phone Call Script',
        category: 'Phone',
        scenario: 'First Contact',
        prompt: 'Write a short phone call script for calling {businessName}, a {category}. I want to offer help with {gaps}. Include: a quick intro, a reason for calling, a clear pitch, and a natural close. Make it sound conversational, not robotic. Include suggested pauses and responses to common objections.',
        description: 'Script for a live phone call to a lead.',
      ),
      PitchTemplate(
        id: 'whatsapp_intro',
        title: 'WhatsApp Intro',
        category: 'WhatsApp',
        scenario: 'First Contact',
        prompt: 'Write a short WhatsApp message to {businessName}, a {category} at {location}. Keep it casual and friendly. Mention their gaps: {gaps}. Make it feel like a real person wrote it, not a template. Include a clear but low-pressure next step.',
        description: 'Casual WhatsApp message for direct outreach.',
      ),
      PitchTemplate(
        id: 'pricing_quote',
        title: 'Pricing Quote Template',
        category: 'Service',
        scenario: 'Closing',
        prompt: 'Write a professional pricing quote message for services offered to {businessName}, a {category}. The service is about {gaps}. Include a clear breakdown of what is included, a price range, and a timeline. Make it sound confident and fair. End with an invitation to discuss details.',
        description: 'Send a clear pricing quote after initial interest.',
      ),
      PitchTemplate(
        id: 're_engagement',
        title: 'Re-Engagement Message',
        category: 'Email',
        scenario: 'Follow Up',
        prompt: 'Write a re-engagement message to {businessName}. I contacted them weeks ago about {gaps} but never heard back. Reference something timely or seasonal for their business type ({category}). Offer a limited-time incentive or new insight. Keep it warm and non-guilt-inducing.',
        description: 'Re-engage a lead that went cold after initial contact.',
      ),
      PitchTemplate(
        id: 'testimonial_request',
        title: 'Testimonial Request',
        category: 'Email',
        scenario: 'Closing',
        prompt: 'Write a polite testimonial request to a client I successfully helped. The service was about {gaps} for their {category} business. Ask for a short Google review. Make it easy for them by suggesting what they could mention. Express genuine gratitude.',
        description: 'Request a testimonial or Google review after closing a deal.',
      ),
    ];
  }

  Future<void> saveCustomTemplate(PitchTemplate template) async {
    final uid = currentUid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('customTemplates')
        .doc(template.id)
        .set(template.toFirestore(), SetOptions(merge: true));
  }

  Future<List<PitchTemplate>> loadCustomTemplates() async {
    final uid = currentUid;
    if (uid == null) return const [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('customTemplates')
          .orderBy('title')
          .get();
      return snapshot.docs
          .map((doc) => PitchTemplate.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      if (e.toString().contains('unavailable') ||
          e.toString().contains('Unavailable')) {
        return const [];
      }
      rethrow;
    }
  }

  Future<void> deleteCustomTemplate(String templateId) async {
    final uid = currentUid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('customTemplates')
        .doc(templateId)
        .delete();
  }

  String fillTemplatePrompt(PitchTemplate template, Map<String, String> context) {
    String filled = template.prompt;
    for (final entry in context.entries) {
      filled = filled.replaceAll('{${entry.key}}', entry.value);
    }
    return filled;
  }

  Map<String, String> buildContextFromLead({
    required String businessName,
    required String category,
    required String location,
    required List<String> gaps,
    String? rating,
    String? reviews,
    String? photoCount,
  }) {
    return {
      'businessName': businessName,
      'category': category,
      'location': location,
      'gaps': gaps.isEmpty ? 'general digital presence gaps' : gaps.join(', '),
      'rating': rating ?? 'no visible ratings',
      'reviews': reviews ?? '0',
      'photoCount': photoCount ?? '0',
    };
  }
}
