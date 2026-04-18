import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_pytorch_lite/flutter_pytorch_lite.dart';
import 'package:path_provider/path_provider.dart';

import 'package:skin_ai_app/src/models/analysis_models.dart';
import 'package:skin_ai_app/src/models/model_config.dart';

class SkinModelService {
  static const String _metadataAsset = 'assets/config/condition_metadata.json';
  static const String _preferredLiteModelAsset =
      'assets/models/efficientnet_b0_cbam_condition_mobile.ptl';
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
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();

    final safeWidth = math.min(cropWidth, image.width);
    final safeHeight = math.min(cropHeight, image.height);
    final left = math.max(0.0, (image.width - safeWidth) / 2);
    final top = math.max(0.0, (image.height - safeHeight) / 2);

    final src = ui.Rect.fromLTWH(
      left,
      top,
      safeWidth.toDouble(),
      safeHeight.toDouble(),
    );
    final dst = ui.Rect.fromLTWH(
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
