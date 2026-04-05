// Feature: Prediction
// Layer: Domain

class ExpensePredictionEntity {
  const ExpensePredictionEntity({
    required this.predictedTotal,
    required this.confidence,
    required this.daysRemaining,
    required this.remainingBudget,
    required this.trend,
    required this.categoryPredictions,
    required this.explanation,
    required this.generatedAt,
  });

  final double predictedTotal;
  final String confidence;
  final int daysRemaining;
  final double remainingBudget;
  final String trend;
  final Map<String, double> categoryPredictions;
  final String explanation;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() {
    return {
      'predictedTotal': predictedTotal,
      'confidence': confidence,
      'daysRemaining': daysRemaining,
      'remainingBudget': remainingBudget,
      'trend': trend,
      'categoryPredictions': categoryPredictions,
      'explanation': explanation,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory ExpensePredictionEntity.fromJson(Map<String, dynamic> json) {
    final categoryPredictions = <String, double>{};
    final rawPredictions = json['categoryPredictions'];
    if (rawPredictions is Map) {
      for (final entry in rawPredictions.entries) {
        final value = entry.value;
        if (value is num) {
          categoryPredictions[entry.key.toString()] = value.toDouble();
        }
      }
    }

    return ExpensePredictionEntity(
      predictedTotal: (json['predictedTotal'] as num?)?.toDouble() ?? 0,
      confidence: json['confidence']?.toString() ?? 'low',
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
      remainingBudget: (json['remainingBudget'] as num?)?.toDouble() ?? 0,
      trend: json['trend']?.toString() ?? 'stable',
      categoryPredictions: categoryPredictions,
      explanation: json['explanation']?.toString() ?? '',
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
