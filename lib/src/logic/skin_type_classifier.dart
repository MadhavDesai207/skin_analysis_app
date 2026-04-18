import 'package:flutter/material.dart';

import 'package:skin_ai_app/src/models/analysis_models.dart';
import 'package:skin_ai_app/src/models/recommendation_models.dart';

class SkinTypeClassifier {
  static const List<SkinTypeProfile> _profiles = [
    SkinTypeProfile(
      title: 'Dry Skin',
      summary:
          'This profile benefits from barrier support, richer hydration layers, and moisture-sealing care throughout the routine.',
      traits: [
        'Comfort-first hydration support',
        'Barrier care with nourishing textures',
        'Low-foam cleansing approach',
      ],
      accent: Color(0xFF9E5D40),
    ),
    SkinTypeProfile(
      title: 'Oily Skin',
      summary:
          'This profile responds well to balancing care that keeps shine in check while maintaining a fresh and lightweight finish.',
      traits: [
        'Lightweight hydration and oil balance',
        'Clarifying cleanser support',
        'Non-comedogenic daily layering',
      ],
      accent: Color(0xFF7D6A2F),
    ),
    SkinTypeProfile(
      title: 'Natural Skin',
      summary:
          'This profile suits a simplified routine focused on skin comfort, daily maintenance, and steady hydration.',
      traits: [
        'Steady moisture maintenance',
        'Calm and balanced routine rhythm',
        'Comfortable daytime layering',
      ],
      accent: Color(0xFF4C7A62),
    ),
    SkinTypeProfile(
      title: 'Normal Skin',
      summary:
          'This profile supports a balanced routine with gentle cleansing, consistent hydration, and protective daily care.',
      traits: [
        'Balanced cleansing and moisture',
        'Routine consistency across morning and night',
        'Protective finish with breathable products',
      ],
      accent: Color(0xFF4D6C8C),
    ),
  ];

  static SkinTypeProfile classify(AnalysisResult result) {
    if (result.scores.isEmpty) {
      return _profiles.last;
    }

    final strongest = result.scores.first;
    final index =
        ((strongest.probability * 1000).round() + strongest.label.length) %
        _profiles.length;
    return _profiles[index];
  }
}
