class AIInsight {
  final String key;
  final String title;
  final String category;
  final String summary;
  final List<String> details;
  final String? action;
  final String priority;

  const AIInsight({
    required this.key,
    required this.title,
    required this.category,
    required this.summary,
    required this.details,
    this.action,
    required this.priority,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) => AIInsight(
        key: json['key']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        summary: json['summary']?.toString() ?? '',
        details: (json['details'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        action: json['action']?.toString(),
        priority: json['priority']?.toString() ?? 'NORMAL',
      );
}

class AIFutureFeature {
  final String key;
  final String title;
  final String status;
  final String description;

  const AIFutureFeature({
    required this.key,
    required this.title,
    required this.status,
    required this.description,
  });

  factory AIFutureFeature.fromJson(Map<String, dynamic> json) => AIFutureFeature(
        key: json['key']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        status: json['status']?.toString() ?? 'FUTURE',
        description: json['description']?.toString() ?? '',
      );
}

class AIOverview {
  final String role;
  final DateTime generatedAt;
  final Map<String, dynamic> metrics;
  final List<AIInsight> insights;
  final List<AIFutureFeature> futureFeatures;

  const AIOverview({
    required this.role,
    required this.generatedAt,
    required this.metrics,
    required this.insights,
    required this.futureFeatures,
  });

  factory AIOverview.fromJson(Map<String, dynamic> json) => AIOverview(
        role: json['role']?.toString() ?? 'USER',
        generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ?? DateTime.now(),
        metrics: Map<String, dynamic>.from(json['metrics'] as Map? ?? {}),
        insights: (json['insights'] as List? ?? [])
            .map((e) => AIInsight.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        futureFeatures: (json['future_features'] as List? ?? [])
            .map((e) => AIFutureFeature.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
