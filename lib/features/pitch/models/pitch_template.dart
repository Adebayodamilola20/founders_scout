class PitchTemplate {
  final String id;
  final String title;
  final String category;
  final String scenario;
  final String prompt;
  final String description;

  const PitchTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.scenario,
    required this.prompt,
    required this.description,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'scenario': scenario,
      'prompt': prompt,
      'description': description,
    };
  }

  factory PitchTemplate.fromFirestore(Map<String, dynamic> data) {
    return PitchTemplate(
      id: data['id'] as String,
      title: data['title'] as String,
      category: data['category'] as String,
      scenario: data['scenario'] as String,
      prompt: data['prompt'] as String,
      description: data['description'] as String? ?? '',
    );
  }
}
