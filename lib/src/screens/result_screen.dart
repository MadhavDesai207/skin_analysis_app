import 'dart:io';

import 'package:flutter/material.dart';

import 'package:skin_ai_app/src/logic/skin_type_classifier.dart';
import 'package:skin_ai_app/src/models/analysis_models.dart';
import 'package:skin_ai_app/src/models/model_config.dart';
import 'package:skin_ai_app/src/screens/skin_type_screen.dart';
import 'package:skin_ai_app/src/widgets/backdrop_orb.dart';

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
    final skinType = SkinTypeClassifier.classify(widget.result);

    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE8),
      body: Stack(
        children: [
          const Positioned(
            top: -70,
            left: -50,
            child: BackdropOrb(
              size: 230,
              colors: [Color(0xFFF0CCB4), Color(0x00F0CCB4)],
            ),
          ),
          const Positioned(
            bottom: -30,
            right: -40,
            child: BackdropOrb(
              size: 250,
              colors: [Color(0xFFE1C5B0), Color(0x00E1C5B0)],
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
                      child: Column(
                        children: [
                          _ResultsCard(
                            result: widget.result,
                            config: widget.config,
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SkinTypeScreen(
                                    imageFile: widget.imageFile,
                                    result: widget.result,
                                    skinType: skinType,
                                  ),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(58),
                              backgroundColor: const Color(0xFF7F3D23),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: const Text(
                              'Continue to skin type classification',
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
