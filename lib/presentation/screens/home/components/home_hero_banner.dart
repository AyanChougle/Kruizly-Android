import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

class HomeHeroBanner extends StatefulWidget {
  final VoidCallback onExploreTap;
  final VoidCallback? onBookTharRoxx;
  final Function(String vehicleModel)? onBookSpecific;

  const HomeHeroBanner({
    super.key,
    required this.onExploreTap,
    this.onBookTharRoxx,
    this.onBookSpecific,
  });

  @override
  State<HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<HomeHeroBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  static const List<Map<String, dynamic>> _heroSlides = [
    {
      'tag': '2026 NEW ARRIVAL',
      'tagColor': Color(0xFF06D6A0),
      'badge': 'SELF-DRIVE 4X4',
      'title': 'Mahindra Thar Roxx 4x4',
      'subtitle': 'Panoramic Sunroof • Diesel Automatic • 5-Door Luxury',
      'image': 'assets/fleet/Thar Roxx.jpg',
      'fallback': 'assets/fleet/Mahindra Thar Roxx.jpg',
      'specs': ['Diesel AT', 'Panoramic Sunroof', '4x4 Trail Ready', '5 Seater'],
      'price': '₹5,500',
      'token': 'Lock for ₹500',
      'modelKey': 'thar',
      'gradient': [Color(0xFF06152B), Color(0xFF0B2144), Color(0xFF13366D)],
    },
    {
      'tag': 'EXECUTIVE LUXURY',
      'tagColor': Color(0xFF93C5FD),
      'badge': 'GERMAN PRECISION',
      'title': 'BMW 520D M-Sport',
      'subtitle': 'TwinPower Turbo • Cognac Leather • Pure Sophistication',
      'image': 'assets/fleet/BMW 520D.png',
      'fallback': 'assets/fleet/BMW 520D.png',
      'specs': ['Diesel AT', 'M-Sport Kit', 'Sunroof', '5 Seater'],
      'price': '₹18,000',
      'token': 'Lock for ₹500',
      'modelKey': 'bmw',
      'gradient': [Color(0xFF160E2E), Color(0xFF281854), Color(0xFF3B237C)],
    },
    {
      'tag': 'FAMILY ROAD TRIPS',
      'tagColor': Color(0xFFFFC078),
      'badge': '7-SEATER KING',
      'title': 'Toyota Innova Crysta',
      'subtitle': 'Captain Seats • Dual AC • Supreme Highway Cruising',
      'image': 'assets/fleet/Toyota Innova Crysta.png',
      'fallback': 'assets/fleet/Toyota Innova Crysta.png',
      'specs': ['Diesel', 'Captain Chairs', '7 Seater', 'Large Boot'],
      'price': '₹3,800',
      'token': 'Lock for ₹500',
      'modelKey': 'innova',
      'gradient': [Color(0xFF1E1508), Color(0xFF38270E), Color(0xFF5A4017)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimer();
  }

  void _startTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _heroSlides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleSlideAction(String modelKey) {
    if (modelKey == 'thar') {
      widget.onBookTharRoxx?.call();
    } else if (widget.onBookSpecific != null) {
      widget.onBookSpecific!(modelKey);
    } else {
      widget.onExploreTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Column(
      children: [
        // Responsive Carousel Card
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _heroSlides.length,
              onPageChanged: (idx) {
                setState(() => _currentPage = idx);
                _startTimer();
              },
              itemBuilder: (context, index) {
                final slide = _heroSlides[index];
                final List<Color> bgGradient = slide['gradient'] as List<Color>;
                final Color tagColor = slide['tagColor'] as Color;
                final List<String> specs = slide['specs'] as List<String>;

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? bgGradient
                          : [
                              bgGradient.first.withValues(alpha: 0.95),
                              bgGradient[1],
                              bgGradient.last,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Ambient light glow
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                tagColor.withValues(alpha: 0.18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Tag & Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tagColor.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: tagColor.withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        color: tagColor,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        slide['tag'] as String,
                                        style: TextStyle(
                                          color: tagColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    slide['badge'] as String,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Car Title & Subtitle
                            Text(
                              slide['title'] as String,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.2,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              slide['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),

                            // Vehicle Showcase Stage
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final imgPath = slide['image'] as String;
                                  final isJpg = imgPath.toLowerCase().endsWith('.jpg');
                                  if (isJpg) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        imgPath,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Image.asset(
                                          slide['fallback'] as String,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Image.asset(
                                            AppAssets.getFleetImage(
                                              slide['title'] as String,
                                            ),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Ambient ground reflection shadow
                                      Positioned(
                                        bottom: 4,
                                        child: Container(
                                          width: 220,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(100),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.5),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Clean vehicle cutout
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Image.asset(
                                          imgPath,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) => Image.asset(
                                            slide['fallback'] as String,
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) => Image.asset(
                                              AppAssets.getFleetImage(
                                                slide['title'] as String,
                                              ),
                                              width: double.infinity,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Specs row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: specs
                                    .map(
                                      (s) => Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: _buildSpecChip(s),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Bottom Price & Action Row
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          slide['price'] as String,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Text(
                                          '/day',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      slide['token'] as String,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: tagColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: () => _handleSlideAction(
                                    slide['modelKey'] as String,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tagColor,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Book Now',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5,
                                          color: Colors.black.withValues(alpha: 0.9),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 15,
                                        color: Colors.black.withValues(alpha: 0.9),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Carousel Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_heroSlides.length, (idx) {
            final isSelected = idx == _currentPage;
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  idx,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: isSelected ? 22 : 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),

        // Kruizly Advantage / Trust Badges Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: context.themeSurfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.themeBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrustBadge(
                icon: Icons.lock_clock_outlined,
                title: '₹500 Token',
                subtitle: 'Lock Any Car',
                color: const Color(0xFF06D6A0),
                context: context,
              ),
              _buildVerticalDivider(context),
              _buildTrustBadge(
                icon: Icons.verified_user_outlined,
                title: 'Fast KYC',
                subtitle: 'Instant Appr.',
                color: AppColors.primaryLight,
                context: context,
              ),
              _buildVerticalDivider(context),
              _buildTrustBadge(
                icon: Icons.local_shipping_outlined,
                title: 'Doorstep',
                subtitle: 'Delivery 24x7',
                color: const Color(0xFFF59E0B),
                context: context,
              ),
              _buildVerticalDivider(context),
              _buildTrustBadge(
                icon: Icons.shield_outlined,
                title: 'Zero Hidden',
                subtitle: 'Insurance Incl.',
                color: const Color(0xFFEC4899),
                context: context,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required BuildContext context,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.themeTextPrimary,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 9,
            color: context.themeTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: context.themeBorder.withValues(alpha: 0.5),
    );
  }
}
