import 'package:flutter/material.dart';

import 'package:skin_ai_app/src/screens/analysis_screen.dart';
import 'package:skin_ai_app/src/widgets/backdrop_orb.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2D6C4), Color(0xFFF8F2EB), Color(0xFFE2C8B6)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -36,
              right: -24,
              child: BackdropOrb(
                size: 190,
                colors: [Color(0xFFF4C9A8), Color(0x00F4C9A8)],
              ),
            ),
            const Positioned(
              bottom: 90,
              left: -40,
              child: BackdropOrb(
                size: 230,
                colors: [Color(0xFFD9BEAB), Color(0x00D9BEAB)],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'AI skin journey',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.84),
                        borderRadius: BorderRadius.circular(34),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get started with your skin analysis flow.',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.02,
                              color: Color(0xFF2A211D),
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Capture or upload a face image, review the detected skin conditions, continue to skin type classification, and then explore product suggestions matched to the result.',
                            style: TextStyle(
                              height: 1.5,
                              fontSize: 15,
                              color: Color(0xFF5C4A41),
                            ),
                          ),
                          SizedBox(height: 22),
                          _JourneyStep(
                            index: '01',
                            title: 'Condition classification',
                            subtitle:
                                'Run the on-device skin condition scan from camera or gallery.',
                          ),
                          SizedBox(height: 14),
                          _JourneyStep(
                            index: '02',
                            title: 'Skin type result',
                            subtitle:
                                'View a single skin type prediction such as dry, oily, natural, or normal.',
                          ),
                          SizedBox(height: 14),
                          _JourneyStep(
                            index: '03',
                            title: 'Product recommendation',
                            subtitle:
                                'See a curated care routine based on the analysis outcome.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AnalysisScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        backgroundColor: const Color(0xFF7F3D23),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 17,
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

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final String index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF7F3D23).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            index,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF7F3D23),
            ),
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(height: 1.45, color: Color(0xFF5C4A41)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
