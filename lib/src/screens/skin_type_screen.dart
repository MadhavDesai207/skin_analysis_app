import 'dart:io';

import 'package:flutter/material.dart';

import 'package:skin_ai_app/src/models/analysis_models.dart';
import 'package:skin_ai_app/src/models/recommendation_models.dart';
import 'package:skin_ai_app/src/screens/product_recommendation_screen.dart';
import 'package:skin_ai_app/src/widgets/backdrop_orb.dart';

class SkinTypeScreen extends StatelessWidget {
  const SkinTypeScreen({
    super.key,
    required this.imageFile,
    required this.result,
    required this.skinType,
  });

  final File imageFile;
  final AnalysisResult result;
  final SkinTypeProfile skinType;

  @override
  Widget build(BuildContext context) {
    final leadCondition = result.scores.isNotEmpty
        ? result.scores.first.label
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE8),
      body: Stack(
        children: [
          const Positioned(
            top: -50,
            left: -30,
            child: BackdropOrb(
              size: 210,
              colors: [Color(0xFFEFC7AD), Color(0x00EFC7AD)],
            ),
          ),
          const Positioned(
            bottom: -40,
            right: -30,
            child: BackdropOrb(
              size: 240,
              colors: [Color(0xFFDDBAA3), Color(0x00DDBAA3)],
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
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Skin type classification',
                          style: TextStyle(
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            color: Color(0xFF2A211D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your latest scan aligns with a ${skinType.title.toLowerCase()} profile.',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFF5C4A41),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: AspectRatio(
                            aspectRatio: 1.08,
                            child: Image.file(imageFile, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: skinType.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skinType.title,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: skinType.accent,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                skinType.summary,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Color(0xFF4F4038),
                                ),
                              ),
                              if (leadCondition != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    'Primary condition insight: $leadCondition',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4F4038),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Skin profile highlights',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final trait in skinType.traits) ...[
                          _InsightChip(
                            icon: Icons.check_circle_outline_rounded,
                            title: trait,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductRecommendationScreen(
                            analysisResult: result,
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
                    child: const Text('Continue to product recommendations'),
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

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7F3D23)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF4F4038),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
