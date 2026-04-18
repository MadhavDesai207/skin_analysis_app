import 'package:flutter/material.dart';

import 'package:skin_ai_app/src/logic/recommendation_engine.dart';
import 'package:skin_ai_app/src/models/analysis_models.dart';
import 'package:skin_ai_app/src/models/recommendation_models.dart';
import 'package:skin_ai_app/src/widgets/backdrop_orb.dart';

class ProductRecommendationScreen extends StatelessWidget {
  const ProductRecommendationScreen({
    super.key,
    required this.analysisResult,
    required this.skinType,
  });

  final AnalysisResult analysisResult;
  final SkinTypeProfile skinType;

  @override
  Widget build(BuildContext context) {
    final recommendations = RecommendationEngine.build(
      analysisResult: analysisResult,
      skinType: skinType,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE8),
      body: Stack(
        children: [
          const Positioned(
            top: -50,
            right: -30,
            child: BackdropOrb(
              size: 220,
              colors: [Color(0xFFF0C7AC), Color(0x00F0C7AC)],
            ),
          ),
          const Positioned(
            bottom: -55,
            left: -35,
            child: BackdropOrb(
              size: 240,
              colors: [Color(0xFFE1C4B1), Color(0x00E1C4B1)],
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
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product recommendation',
                          style: TextStyle(
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            color: Color(0xFF2A211D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Recommended routine for ${skinType.title.toLowerCase()} skin based on the latest skin analysis.',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFF5C4A41),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RoutineSummaryCard(
                          skinType: skinType.title,
                          focusAreas: recommendations.focusAreas,
                        ),
                        const SizedBox(height: 18),
                        for (final item in recommendations.items) ...[
                          _RecommendationCard(item: item),
                          const SizedBox(height: 14),
                        ],
                      ],
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

class _RoutineSummaryCard extends StatelessWidget {
  const _RoutineSummaryCard({required this.skinType, required this.focusAreas});

  final String skinType;
  final List<String> focusAreas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F3D23), Color(0xFFA55A32)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$skinType routine focus',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            focusAreas.join('  •  '),
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final ProductRecommendation item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F3D23).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item.step,
                  style: const TextStyle(
                    color: Color(0xFF7F3D23),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.productName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            item.reason,
            style: const TextStyle(color: Color(0xFF5C4A41), height: 1.45),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5ECE4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Suggested ingredient focus: ${item.keyIngredient}',
              style: const TextStyle(
                color: Color(0xFF4F4038),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
