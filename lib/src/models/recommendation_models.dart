import 'package:flutter/material.dart';

class SkinTypeProfile {
  const SkinTypeProfile({
    required this.title,
    required this.summary,
    required this.traits,
    required this.accent,
  });

  final String title;
  final String summary;
  final List<String> traits;
  final Color accent;
}

class ProductRecommendation {
  const ProductRecommendation({
    required this.step,
    required this.category,
    required this.productName,
    required this.reason,
    required this.keyIngredient,
  });

  final String step;
  final String category;
  final String productName;
  final String reason;
  final String keyIngredient;
}

class RecommendationPlan {
  const RecommendationPlan({required this.focusAreas, required this.items});

  final List<String> focusAreas;
  final List<ProductRecommendation> items;
}
