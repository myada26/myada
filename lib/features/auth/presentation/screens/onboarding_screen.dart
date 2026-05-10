import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../main.dart'; // For AppRoutes

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.rocket_launch,
      'heading': "The Pioneer Spirit",
      'body':
          "Inspired by Ada Lovelace, MyADA helps you master code even without a signal. You were born to create.",
    },
    {
      'icon': Icons.wifi_off,
      'heading': "No Signal? No Problem.",
      'body':
          "Your lessons stay with you. Learn, practice, and code anywhere—no Wi-Fi or data required.",
    },
    {
      'icon': Icons.emoji_events,
      'heading': "Be the Pride of Your Batch",
      'body':
          "Your hard work deserves to be seen. Rise to the top of the college leaderboard and show your batchmates what you're capable of.",
    },
    {
      'icon': Icons.map,
      'heading': "Your Story Starts Here",
      'body':
          "No more feeling left behind. We find your level and guide you step-by-step toward your future in tech.",
    },
  ];

  void _onNext() {
    if (_currentIndex == _slides.length - 1) {
      // Last slide
      Navigator.pushNamed(context, AppRoutes.permissions);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkip() {
    Navigator.pushNamed(context, AppRoutes.entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mutedForeground,
                  ),
                  child: Text(
                    'Skip',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withOpacity(0.1),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              slide['icon'],
                              size: 80,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 48),
                          Text(
                            slide['heading'],
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h1.copyWith(fontSize: 26),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide['body'],
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLg.copyWith(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      height: 8.0,
                      width: _currentIndex == index ? 24.0 : 8.0,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ),
              ),
              AppButton(
                label: _currentIndex == _slides.length - 1
                    ? "Get Started"
                    : "Next",
                onPressed: _onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
