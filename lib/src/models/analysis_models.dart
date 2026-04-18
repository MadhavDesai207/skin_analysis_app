class AnalysisResult {
  AnalysisResult({required this.scores});

  final List<ConditionScore> scores;
}

class ConditionScore {
  ConditionScore({
    required this.label,
    required this.probability,
    required this.threshold,
    required this.detected,
  });

  final String label;
  final double probability;
  final double threshold;
  final bool detected;
}
