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
  AnalysisResult? _lastResult;
  bool _isBusy = true;
  String? _error;
  String _busyLabel = 'Preparing local model...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isBusy = true;
      _busyLabel = 'Preparing local model...';
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
          _busyLabel = 'Ready';
        });
      }
    }
  }

  Future<void> _analyzeFromSource(ImageSource source) async {
    if (_config == null || _isBusy) {
      return;
    }

    final sourceLabel = source == ImageSource.camera ? 'camera' : 'gallery';
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      preferredCameraDevice: CameraDevice.front,
    );

    if (pickedFile == null) {
      return;
    }

    final imageFile = File(pickedFile.path);

    setState(() {
      _isBusy = true;
      _busyLabel = 'Analyzing from $sourceLabel...';
      _error = null;
      _selectedImage = imageFile;
    });

    try {
      final result = await _service.runOnImage(imageFile);
      if (!mounted) {
        return;
      }

      setState(() {
        _lastResult = result;
      });

      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 650),
          reverseTransitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (context, animation, secondaryAnimation) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: ResultScreen(
                  imageFile: imageFile,
                  result: result,
                  config: _config!,
                ),
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation =
                Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
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
          _busyLabel = 'Ready';
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
    final lastDetected = _lastResult?.scores
        .where((score) => score.detected)
        .length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4E1D2), Color(0xFFF8F3ED), Color(0xFFE6D4C5)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -20,
              child: _BackdropOrb(
                size: 180,
                colors: const [Color(0xFFF1C7A8), Color(0x00F1C7A8)],
              ),
            ),
            Positioned(
              bottom: 120,
              left: -30,
              child: _BackdropOrb(
                size: 220,
                colors: const [Color(0xFFD9C0AF), Color(0x00D9C0AF)],
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                        'Live capture + offline scan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Capture skin photos live or upload one and view the result on a dedicated screen.',
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        color: Color(0xFF2A211D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 22),
                    _StatusCard(
                      isBusy: _isBusy,
                      config: _config,
                      error: _error,
                      busyLabel: _busyLabel,
                    ),
                    const SizedBox(height: 18),
                    _PreviewCard(imageFile: _selectedImage, isBusy: _isBusy),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Open Camera',
                            onPressed: _isBusy
                                ? null
                                : () => _analyzeFromSource(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Upload Photo',
                            onPressed: _isBusy
                                ? null
                                : () => _analyzeFromSource(ImageSource.gallery),
                            isPrimary: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_lastResult != null &&
                        _selectedImage != null &&
                        lastDetected != null)
                      _LastScanCard(
                        imageFile: _selectedImage!,
                        positiveCount: lastDetected,
                        totalConditions: _config?.labels.length ?? 0,
                      )
                    else
                      const _EmptyResultCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.result,
    required this.config,
  });

  final File imageFile;
  final AnalysisResult result;
  final ModelConfig config;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerOffset;
  late final Animation<double> _imageScale;
  late final Animation<double> _imageGlow;
  late final Animation<double> _resultsOpacity;
  late final Animation<Offset> _resultsOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _headerOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _headerOffset =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
          ),
        );
    _imageScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.58, curve: Curves.easeOutBack),
      ),
    );
    _imageGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.6, curve: Curves.easeOut),
      ),
    );
    _resultsOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 1.0, curve: Curves.easeOut),
    );
    _resultsOffset =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positiveCount = widget.result.scores
        .where((score) => score.detected)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE8),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            left: -50,
            child: _BackdropOrb(
              size: 230,
              colors: const [Color(0xFFF0CCB4), Color(0x00F0CCB4)],
            ),
          ),
          Positioned(
            bottom: -30,
            right: -40,
            child: _BackdropOrb(
              size: 250,
              colors: const [Color(0xFFE1C5B0), Color(0x00E1C5B0)],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.72),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _headerOpacity,
                    child: SlideTransition(
                      position: _headerOffset,
                      child: _ResultHeroCard(
                        imageFile: widget.imageFile,
                        imageScale: _imageScale,
                        glowAnimation: _imageGlow,
                        positiveCount: positiveCount,
                        totalConditions: widget.config.labels.length,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _resultsOpacity,
                    child: SlideTransition(
                      position: _resultsOffset,
                      child: _ResultsCard(
                        result: widget.result,
                        config: widget.config,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isBusy,
    required this.config,
    required this.error,
    required this.busyLabel,
  });

  final bool isBusy;
  final ModelConfig? config;
  final String? error;
  final String busyLabel;

  @override
  Widget build(BuildContext context) {
    final accent = error != null
        ? const Color(0xFF9C2F2F)
        : config == null
        ? const Color(0xFF9B6B3A)
        : const Color(0xFF2F7A4A);

    final title = error != null
        ? 'Model setup issue'
        : isBusy
        ? busyLabel
        : 'Model ready on device';

    final body =
        error ??
        (config == null
            ? 'The app is reading the local TorchScript model and metadata.'
            : 'Input: 1x3x${config!.inputSize}x${config!.inputSize}. Results open on a dedicated screen after capture or upload.');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final background = isPrimary ? const Color(0xFF7F3D23) : Colors.white;
    final foreground = isPrimary ? Colors.white : const Color(0xFF5A3020);

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: isPrimary ? 0 : 1,
        minimumSize: const Size.fromHeight(58),
        side: isPrimary
            ? null
            : const BorderSide(color: Color(0xFFE3C9B5), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.imageFile, required this.isBusy});

  final File? imageFile;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: imageFile == null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.2, -0.35),
                        radius: 1.15,
                        colors: [
                          Color(0xFFF7CFAF),
                          Color(0xFFE7C7B4),
                          Color(0xFFDAB7A1),
                        ],
                      ),
                    ),
                  ),
                  Container(color: Colors.white.withValues(alpha: 0.08)),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.center_focus_strong_rounded, size: 58),
                        SizedBox(height: 14),
                        Text(
                          'Use the live camera or upload a photo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'A dedicated result screen will open after analysis.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF5C4A41),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'analysis-image',
                    child: Image.file(imageFile!, fit: BoxFit.cover),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              isBusy ? 'Analyzing now' : 'Last selected image',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No scan yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'Capture a live image or upload one from the gallery to start the on-device screening flow.',
            style: TextStyle(height: 1.45, color: Color(0xFF5C4A41)),
          ),
        ],
      ),
    );
  }
}

class _LastScanCard extends StatelessWidget {
  const _LastScanCard({
    required this.imageFile,
    required this.positiveCount,
    required this.totalConditions,
  });

  final File imageFile;
  final int positiveCount;
  final int totalConditions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              imageFile,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last completed scan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '$positiveCount of $totalConditions conditions crossed the threshold. Open a new capture or upload another image to refresh the result screen.',
                  style: const TextStyle(
                    color: Color(0xFF5C4A41),
                    height: 1.45,
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

class _ResultHeroCard extends StatelessWidget {
  const _ResultHeroCard({
    required this.imageFile,
    required this.imageScale,
    required this.glowAnimation,
    required this.positiveCount,
    required this.totalConditions,
  });

  final File imageFile;
  final Animation<double> imageScale;
  final Animation<double> glowAnimation;
  final int positiveCount;
  final int totalConditions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan result',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: Color(0xFF2A211D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$positiveCount of $totalConditions conditions crossed your saved thresholds.',
            style: const TextStyle(
              height: 1.5,
              color: Color(0xFF5C4A41),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFB86B40,
                      ).withValues(alpha: 0.12 + (0.18 * glowAnimation.value)),
                      blurRadius: 32 + (16 * glowAnimation.value),
                      spreadRadius: 2 + (4 * glowAnimation.value),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: ScaleTransition(
              scale: imageScale,
              child: Hero(
                tag: 'analysis-image',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 0.88,
                        child: Image.file(imageFile, fit: BoxFit.cover),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'result view for the latest uploaded or captured image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
        color: Colors.white.withValues(alpha: 0.9),
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

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
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
