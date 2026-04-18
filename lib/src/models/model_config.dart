class ModelConfig {
  ModelConfig({
    required this.inputSize,
    required this.resize,
    required this.centerCrop,
    required this.mean,
    required this.std,
    required this.labels,
    required this.thresholds,
    required this.modelAssetPath,
  });

  final int inputSize;
  final int resize;
  final int centerCrop;
  final List<double> mean;
  final List<double> std;
  final List<String> labels;
  final List<double> thresholds;
  final String modelAssetPath;

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    final preprocess = json['preprocess'] as Map<String, dynamic>;
    return ModelConfig(
      inputSize: json['image_size'] as int,
      resize: preprocess['resize'] as int,
      centerCrop: preprocess['center_crop'] as int,
      mean: (preprocess['normalize_mean'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(),
      std: (preprocess['normalize_std'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(),
      labels: (json['labels'] as List<dynamic>).cast<String>(),
      thresholds: (json['thresholds'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(),
      modelAssetPath: json['torchscript_path'] as String? ?? '',
    );
  }

  ModelConfig copyWith({String? modelAssetPath}) {
    return ModelConfig(
      inputSize: inputSize,
      resize: resize,
      centerCrop: centerCrop,
      mean: mean,
      std: std,
      labels: labels,
      thresholds: thresholds,
      modelAssetPath: modelAssetPath ?? this.modelAssetPath,
    );
  }
}
