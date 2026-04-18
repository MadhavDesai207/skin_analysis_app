import 'package:skin_ai_app/src/models/analysis_models.dart';
import 'package:skin_ai_app/src/models/recommendation_models.dart';

class RecommendationEngine {
  static RecommendationPlan build({
    required AnalysisResult analysisResult,
    required SkinTypeProfile skinType,
  }) {
    final lead = analysisResult.scores.isNotEmpty
        ? analysisResult.scores.first.label
        : 'Overall skin balance';

    final focusAreas = [skinType.title, 'Barrier support', lead];

    final items = <ProductRecommendation>[
      ProductRecommendation(
        step: 'Step 1',
        category: 'Cleanser',
        productName: _cleanserName(skinType.title),
        reason:
            'A gentle first step helps align the routine with ${skinType.title.toLowerCase()} needs while supporting $lead care goals.',
        keyIngredient: _cleanserIngredient(skinType.title),
      ),
      ProductRecommendation(
        step: 'Step 2',
        category: 'Serum',
        productName: _serumName(lead),
        reason:
            'Targeted serum layering keeps the routine focused on the strongest condition signal from the latest analysis.',
        keyIngredient: _serumIngredient(lead),
      ),
      ProductRecommendation(
        step: 'Step 3',
        category: 'Moisturizer',
        productName: _moisturizerName(skinType.title),
        reason:
            'This moisturizer stage helps lock in comfort and supports a more stable finish across the day.',
        keyIngredient: _moisturizerIngredient(skinType.title),
      ),
      const ProductRecommendation(
        step: 'Step 4',
        category: 'Daily sunscreen',
        productName: 'Broad Spectrum UV Shield SPF 50',
        reason:
            'Daily UV protection completes the routine and helps preserve skin comfort after active-care steps.',
        keyIngredient: 'Photostable UV filters',
      ),
    ];

    return RecommendationPlan(focusAreas: focusAreas, items: items);
  }

  static String _cleanserName(String skinType) {
    switch (skinType) {
      case 'Dry Skin':
        return 'Cream Barrier Cleanser';
      case 'Oily Skin':
        return 'Purifying Gel Cleanser';
      case 'Natural Skin':
        return 'Soft Balance Cleanser';
      default:
        return 'Daily Comfort Cleanser';
    }
  }

  static String _cleanserIngredient(String skinType) {
    switch (skinType) {
      case 'Dry Skin':
        return 'Ceramides';
      case 'Oily Skin':
        return 'Zinc PCA';
      case 'Natural Skin':
        return 'Glycerin';
      default:
        return 'Panthenol';
    }
  }

  static String _serumName(String lead) {
    final normalized = lead.toLowerCase();
    if (normalized.contains('acne') || normalized.contains('blemish')) {
      return 'Clarifying Blemish Control Serum';
    }
    if (normalized.contains('pigment') || normalized.contains('spot')) {
      return 'Tone Refining Radiance Serum';
    }
    if (normalized.contains('wrinkle') || normalized.contains('age')) {
      return 'Smoothing Renewal Serum';
    }
    return 'Calm Restore Treatment Serum';
  }

  static String _serumIngredient(String lead) {
    final normalized = lead.toLowerCase();
    if (normalized.contains('acne') || normalized.contains('blemish')) {
      return 'Niacinamide';
    }
    if (normalized.contains('pigment') || normalized.contains('spot')) {
      return 'Vitamin C';
    }
    if (normalized.contains('wrinkle') || normalized.contains('age')) {
      return 'Peptides';
    }
    return 'Centella asiatica';
  }

  static String _moisturizerName(String skinType) {
    switch (skinType) {
      case 'Dry Skin':
        return 'Rich Repair Moisture Cream';
      case 'Oily Skin':
        return 'Oil-Free Hydrating Gel';
      case 'Natural Skin':
        return 'Balanced Dew Moisturizer';
      default:
        return 'Skin Comfort Lotion';
    }
  }

  static String _moisturizerIngredient(String skinType) {
    switch (skinType) {
      case 'Dry Skin':
        return 'Shea butter';
      case 'Oily Skin':
        return 'Hyaluronic acid';
      case 'Natural Skin':
        return 'Squalane';
      default:
        return 'Ceramide complex';
    }
  }
}
