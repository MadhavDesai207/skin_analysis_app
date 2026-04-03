import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pytorch_lite/flutter_pytorch_lite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const SkinSenseApp());
}

class SkinSenseApp extends StatelessWidget {
  const SkinSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Sense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB65F35),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F1EA),
        useMaterial3: true,
      ),
      home: const AnalysisScreen(),
    );
  }
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final SkinModelService _service = SkinModelService();
  final ImagePicker _picker = ImagePicker();

  ModelConfig? _config;
  File? _selectedImage;
  AnalysisResult? _result;
  bool _isBusy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final config = await _service.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _config = config;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _pickAndAnalyze() async {
    if (_config == null || _isBusy) {
      return;
    }

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
      _selectedImage = File(pickedFile.path);
      _result = null;
    });

    try {
      final result = await _service.runOnImage(_selectedImage!);
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4E1D2), Color(0xFFF7F1EA), Color(0xFFEADFD2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Offline skin screening',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Analyze a face image directly on the phone.',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: Color(0xFF2A211D),
                  ),
                ),
                const SizedBox(height: 10),
                // const Text(
                //   'No API calls, no backend. The app preprocesses the image using your JSON settings, runs the TorchScript model locally, and compares each score with its threshold.',
                //   style: TextStyle(height: 1.45, color: Color(0xFF5C4A41)),
                // ),
                const SizedBox(height: 20),
                _StatusCard(isBusy: _isBusy, config: _config, error: _error),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isBusy ? null : _pickAndAnalyze,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7F3D23),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_isBusy ? 'Preparing model...' : 'Pick Image'),
                ),
                const SizedBox(height: 20),
                _PreviewCard(imageFile: _selectedImage),
                const SizedBox(height: 16),
                if (_result != null && _config != null)
                  _ResultsCard(result: _result!, config: _config!)
                else
                  const _EmptyResultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isBusy,
    required this.config,
    required this.error,
  });

  final bool isBusy;
  final ModelConfig? config;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final accent = error != null
        ? const Color(0xFF9C2F2F)
        : config == null
        ? const Color(0xFF9B6B3A)
        : const Color(0xFF2F7A4A);

    final title = error != null
        ? 'Model setup issue'
        : config == null
        ? 'Loading local model'
        : 'Model ready on device';

    final body =
        error ??
        (config == null
            ? 'The app is reading the metadata JSON and looking for the local TorchScript file in assets/models/.'
            : 'Input: 1x3x${config!.inputSize}x${config!.inputSize}. Labels: ${config!.labels.join(', ')}');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              error != null
                  ? Icons.error_outline
                  : isBusy
                  ? Icons.hourglass_top_rounded
                  : Icons.check_circle_outline,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    height: 1.45,
                    color: Color(0xFF5C4A41),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.imageFile});

  final File? imageFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: imageFile == null
            ? Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.35),
                    radius: 1.2,
                    colors: [
                      Color(0xFFF7CFAF),
                      Color(0xFFE7C7B4),
                      Color(0xFFDAB7A1),
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 54),
                      SizedBox(height: 12),
                      Text(
                        'Pick a clear face image\nfrom the gallery',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(imageFile!, fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Selected image',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results will appear here',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'The model returns one score per condition. The app applies sigmoid and checks each score against its threshold from the JSON metadata.',
            style: TextStyle(height: 1.45, color: Color(0xFF5C4A41)),
          ),
        ],
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.result, required this.config});

  final AnalysisResult result;
  final ModelConfig config;

  @override
  Widget build(BuildContext context) {
    final positiveCount = result.scores.where((score) => score.detected).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis summary',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            '$positiveCount of ${config.labels.length} conditions crossed the decision threshold.',
            style: const TextStyle(color: Color(0xFF5C4A41), height: 1.45),
          ),
          const SizedBox(height: 16),
          for (final score in result.scores) ...[
            _ConditionTile(score: score),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          const Text(
            'This is a screening-style output from your model, not a medical diagnosis.',
            style: TextStyle(
              color: Color(0xFF765D51),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionTile extends StatelessWidget {
  const _ConditionTile({required this.score});

  final ConditionScore score;

  @override
  Widget build(BuildContext context) {
    final color = score.detected
        ? const Color(0xFFB5572A)
        : const Color(0xFF3D7A56);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  score.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                score.detected ? 'Detected' : 'Below threshold',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: score.probability,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.16),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Probability ${(score.probability * 100).toStringAsFixed(1)}%  |  Threshold ${(score.threshold * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Color(0xFF5C4A41),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SkinModelService {
  static const String _metadataAsset = 'assets/config/condition_metadata.json';
  static const String _preferredLiteModelAsset = 'assets/models/model.ptl';
  static const String _fallbackModelAsset =
      'assets/models/efficientnet_b0_cbam_condition_mobile.pt';

  Module? _module;
  ModelConfig? _config;

  Future<ModelConfig> initialize() async {
    if (_config != null) {
      return _config!;
    }

    final metadataText = await rootBundle.loadString(_metadataAsset);
    final json = jsonDecode(metadataText) as Map<String, dynamic>;
    final config = ModelConfig.fromJson(json);

    final modelAssetPath = await _resolveModelAssetPath(config.modelAssetPath);
    final modelBytes = await _loadModelBytes(modelAssetPath);
    _assertLiteModel(modelBytes);
    final modelFilePath = await _writeTempModel(modelAssetPath, modelBytes);
    _module = await FlutterPytorchLite.load(modelFilePath);
    _config = config.copyWith(modelAssetPath: modelAssetPath);
    return _config!;
  }

  Future<AnalysisResult> runOnImage(File file) async {
    final config = _config ?? await initialize();
    final module = _module;

    if (module == null) {
      throw Exception('Model is not loaded yet.');
    }

    final imageBytes = await file.readAsBytes();
    final tensor = await _imageToTensor(imageBytes, config);
    final output = await module.forward([IValue.from(tensor)]);
    final values = output.toTensor().dataAsFloat32List;

    if (values.length != config.labels.length) {
      throw Exception(
        'Model output length (${values.length}) does not match labels (${config.labels.length}).',
      );
    }

    final scores = <ConditionScore>[];
    for (var index = 0; index < values.length; index++) {
      final probability = _sigmoid(values[index]);
      final threshold = config.thresholds[index];
      scores.add(
        ConditionScore(
          label: _displayLabel(config.labels[index]),
          probability: probability,
          threshold: threshold,
          detected: probability >= threshold,
        ),
      );
    }

    scores.sort((a, b) => b.probability.compareTo(a.probability));
    return AnalysisResult(scores: scores);
  }

  Future<void> dispose() async {
    final module = _module;
    if (module != null) {
      await module.destroy();
    }
  }

  Future<String> _resolveModelAssetPath(String sourcePath) async {
    if (await _assetExists(_preferredLiteModelAsset)) {
      return _preferredLiteModelAsset;
    }

    final normalized = sourcePath.replaceAll('\\', '/').replaceFirst('./', '');
    if (normalized.startsWith('models/')) {
      return 'assets/$normalized';
    }
    return _fallbackModelAsset;
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List> _loadModelBytes(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  Future<String> _writeTempModel(String assetPath, Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final filename = assetPath.split('/').last;
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  void _assertLiteModel(Uint8List bytes) {
    final header = bytes.length >= 4
        ? String.fromCharCodes(bytes.sublist(0, 4))
        : '';
    final content = latin1.decode(bytes, allowInvalid: true);

    if (header != 'PK\x03\x04') {
      throw Exception(
        'The model file is not a valid TorchScript archive. Export a mobile TorchScript model and place it in assets/models/.',
      );
    }

    if (!content.contains('bytecode.pkl')) {
      throw Exception(
        'This .pt file is not a Lite/mobile TorchScript model. Re-export it with optimize_for_mobile(...) and _save_for_lite_interpreter(...), then replace assets/models/efficientnet_b0_cbam_condition_mobile.pt.',
      );
    }
  }

  Future<Tensor> _imageToTensor(
    Uint8List imageBytes,
    ModelConfig config,
  ) async {
    final resized = await _decodeResizedImage(imageBytes, config.resize);
    final cropped = await _centerCropToRgbaBytes(
      resized,
      config.centerCrop,
      config.centerCrop,
    );
    final input = Float32List(1 * 3 * config.inputSize * config.inputSize);
    final planeSize = config.inputSize * config.inputSize;
    final rgba = cropped.buffer.asUint8List();

    for (var y = 0; y < config.inputSize; y++) {
      for (var x = 0; x < config.inputSize; x++) {
        final offset = y * config.inputSize + x;
        final pixelOffset = offset * 4;
        final red = rgba[pixelOffset] / 255.0;
        final green = rgba[pixelOffset + 1] / 255.0;
        final blue = rgba[pixelOffset + 2] / 255.0;

        input[offset] = (red - config.mean[0]) / config.std[0];
        input[planeSize + offset] = (green - config.mean[1]) / config.std[1];
        input[(planeSize * 2) + offset] =
            (blue - config.mean[2]) / config.std[2];
      }
    }

    return Tensor.fromBlobFloat32(
      input,
      Int64List.fromList([1, 3, config.inputSize, config.inputSize]),
    );
  }

  Future<ui.Image> _decodeResizedImage(
    Uint8List imageBytes,
    int targetShortestSide,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(imageBytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);

    final width = descriptor.width;
    final height = descriptor.height;

    final targetWidth = width <= height
        ? targetShortestSide
        : (width * targetShortestSide / height).round();
    final targetHeight = width <= height
        ? (height * targetShortestSide / width).round()
        : targetShortestSide;

    final codec = await descriptor.instantiateCodec(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return frame.image;
  }

  Future<ByteData> _centerCropToRgbaBytes(
    ui.Image image,
    int cropWidth,
    int cropHeight,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    final safeWidth = math.min(cropWidth, image.width);
    final safeHeight = math.min(cropHeight, image.height);
    final left = math.max(0.0, (image.width - safeWidth) / 2);
    final top = math.max(0.0, (image.height - safeHeight) / 2);

    final src = Rect.fromLTWH(
      left,
      top,
      safeWidth.toDouble(),
      safeHeight.toDouble(),
    );
    final dst = Rect.fromLTWH(
      0,
      0,
      cropWidth.toDouble(),
      cropHeight.toDouble(),
    );
    canvas.drawImageRect(image, src, dst, paint);

    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(cropWidth, cropHeight);
    final byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    image.dispose();
    croppedImage.dispose();

    if (byteData == null) {
      throw Exception(
        'Unable to convert the selected image into model input bytes.',
      );
    }

    return byteData;
  }

  double _sigmoid(double value) => 1.0 / (1.0 + math.exp(-value));

  String _displayLabel(String label) {
    return label
        .split('_')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

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
