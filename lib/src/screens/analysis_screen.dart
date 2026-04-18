import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:skin_ai_app/src/models/analysis_models.dart';
import 'package:skin_ai_app/src/models/model_config.dart';
import 'package:skin_ai_app/src/screens/result_screen.dart';
import 'package:skin_ai_app/src/services/skin_model_service.dart';
import 'package:skin_ai_app/src/widgets/backdrop_orb.dart';

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
            const Positioned(
              top: -40,
              right: -20,
              child: BackdropOrb(
                size: 180,
                colors: [Color(0xFFF1C7A8), Color(0x00F1C7A8)],
              ),
            ),
            const Positioned(
              bottom: 120,
              left: -30,
              child: BackdropOrb(
                size: 220,
                colors: [Color(0xFFD9C0AF), Color(0x00D9C0AF)],
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
