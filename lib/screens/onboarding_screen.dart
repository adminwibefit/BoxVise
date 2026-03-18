import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Create Storage Boxes',
      subtitle:
          'Start by creating virtual boxes that match your real storage containers. '
          'Label them, add photos, and assign locations so you always know where things are.',
      image: Icons.inventory_2_rounded,
      color: AppTheme.primaryColor,
    ),
    OnboardingData(
      title: 'Add Items Inside',
      subtitle:
          'Add items to each box with details like quantity, value, and expiry dates. '
          'Take photos or use AI Vision to quickly catalog everything you store.',
      image: Icons.add_box_rounded,
      color: AppTheme.accentColor,
    ),
    OnboardingData(
      title: 'Scan & Find Instantly',
      subtitle:
          'Generate QR codes for each box. Scan them anytime to instantly see what\'s inside '
          'without opening a single box. No more guessing!',
      image: Icons.qr_code_scanner_rounded,
      color: Colors.orange,
    ),
    OnboardingData(
      title: 'Track & Get Insights',
      subtitle:
          'See the total value of your inventory, get expiry alerts, and use smart search '
          'to find any item across all your boxes in seconds.',
      image: Icons.analytics_rounded,
      color: const Color(0xFF7C4DFF),
    ),
  ];

  void _finish() {
    context.read<InventoryProvider>().finishOnboarding();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1829) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index], isDark: isDark),
              ),
            ),

            // Bottom: dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  // Next / Get Started button
                  _currentPage == _pages.length - 1
                      ? ElevatedButton(
                          onPressed: _finish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : FloatingActionButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          backgroundColor: _pages[_currentPage].color,
                          elevation: 2,
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 28 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? _pages[_currentPage].color
            : Colors.grey.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData image;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final bool isDark;

  const _OnboardingPage({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: data.color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(data.image, size: 80, color: data.color),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            data.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
