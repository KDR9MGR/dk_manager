import 'package:dk_manager/views/search/search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../controllers/auth_controller.dart';
import '../controllers/mobile_case_controller.dart';
import '../models/mobile_case_model.dart';
import '../routes/app_routes.dart';
import '../utils/app_utils.dart';
import '../theme/color_theme.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

// Grid pattern painter for placeholder backgrounds
class GridPatternPainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final double spacing;

  GridPatternPainter({
    required this.color,
    required this.lineWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom cache manager for thumbnails
class CustomCacheManager {
  static const key = 'customCacheKey';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

class BrandStats {
  final int quantity;
  final int models;
  final double totalValue;

  BrandStats({
    required this.quantity,
    required this.models,
    required this.totalValue,
  });
}

// Add this custom painter class at the top level
class CircularProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  CircularProgressPainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * (percentage / 100), // Convert percentage to radians
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final caseController = Get.find<MobileCaseController>();
  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (caseController.cases.isEmpty) {
      await caseController.loadCases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (caseController.isLoading.value && caseController.cases.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: ColorTheme.primary),
          );
        }

        return RefreshIndicator(
          color: ColorTheme.primary,
          backgroundColor: ColorTheme.surface,
          onRefresh: () async {
            await caseController.refreshData();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildFlexibleHeader(context, authController, caseController),
              _buildSearchBar(context, caseController),
              _buildStatsSection(caseController),
              _buildBrandDistributionChart(caseController),
              _buildRecentCases(caseController),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addCase),
        backgroundColor: Colors.transparent,
        elevation: 4,
        heroTag: 'addCaseButton',
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: ColorTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: ColorTheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Iconsax.add, color: ColorTheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildRecentCases(MobileCaseController caseController) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Cases',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorTheme.onBackground,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Show all cases
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (caseController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: ColorTheme.primary),
                );
              }

              if (caseController.cases.isEmpty) {
                return _buildEmptyState();
              }

              final recentCases = caseController.cases.take(5).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentCases.length,
                itemBuilder: (context, index) {
                  final mobileCase = recentCases[index];
                  return _buildCaseCard(mobileCase);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getBrandLogoPath(String brand) {
    // Convert brand name to lowercase and remove spaces for asset path
    final formattedBrand = brand.toLowerCase().replaceAll(' ', '_');
    return 'assets/images/$formattedBrand.png';
  }

  Widget _buildCaseCard(MobileCaseModel mobileCase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Get.toNamed(
          AppRoutes.caseDetails,
          arguments: mobileCase,
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: ColorTheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: ColorTheme.primary.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background gradient accent
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [
                        ColorTheme.surface,
                        ColorTheme.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Image with brand logo fallback
                    Hero(
                      tag: 'case_image_${mobileCase.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: ColorTheme.primary.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: mobileCase.imageUrl != null && mobileCase.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: mobileCase.imageUrl!,
                                cacheManager: CustomCacheManager.instance,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => _buildImagePlaceholder(mobileCase.brand),
                                errorWidget: (context, url, error) => _buildImagePlaceholder(mobileCase.brand),
                              )
                            : _buildImagePlaceholder(mobileCase.brand),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      ColorTheme.primary.withOpacity(0.1),
                                      ColorTheme.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  mobileCase.brand,
                                  style: GoogleFonts.inter(
                                    color: ColorTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (mobileCase.quantity < 5) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        ColorTheme.warning.withOpacity(0.1),
                                        ColorTheme.warning.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.warning_2,
                                        size: 12,
                                        color: ColorTheme.warning.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Low Stock',
                                        style: GoogleFonts.inter(
                                          color: ColorTheme.warning.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            mobileCase.model,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ColorTheme.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppUtils.formatPrice(mobileCase.price),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              background: Paint()
                                ..color = ColorTheme.primary.withOpacity(0.1)
                                ..strokeWidth = 16
                                ..style = PaintingStyle.stroke
                                ..strokeJoin = StrokeJoin.round,
                              color: ColorTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: ColorTheme.surfaceVariant.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Iconsax.box,
                                  size: 14,
                                  color: ColorTheme.onBackground.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${mobileCase.quantity} units',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: ColorTheme.onBackground.withOpacity(0.6),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: ColorTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Iconsax.arrow_right_3,
                                  color: ColorTheme.onPrimary,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String brand) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: ColorTheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(
                color: ColorTheme.primary.withOpacity(0.05),
                lineWidth: 1,
                spacing: 10,
              ),
            ),
          ),
          // Brand logo
          Center(
            child: Image.asset(
              _getBrandLogoPath(brand),
              width: 70,
              height: 70,
              color: ColorTheme.primary.withOpacity(0.5),
              errorBuilder: (context, error, stackTrace) => Icon(
                Iconsax.mobile,
                size: 40,
                color: ColorTheme.primary.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlexibleHeader(BuildContext context, AuthController authController, MobileCaseController caseController) {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ColorTheme.primaryGradient,
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/dk_logo.png',
                    width: 28,
                    height: 28,
                    color: ColorTheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DK Manager',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColorTheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.profile),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: ColorTheme.onPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorTheme.onPrimary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: ColorTheme.onPrimary,
                    child: Icon(
                      Iconsax.user,
                      color: ColorTheme.primary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          background: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Logo in larger size
                  // Row(
                  //   children: [
                  //     Container(
                  //       padding: const EdgeInsets.all(12),
                  //       decoration: BoxDecoration(
                  //         color: ColorTheme.onPrimary.withOpacity(0.1),
                  //         borderRadius: BorderRadius.circular(16),
                  //       ),
                  //       child: Image.asset(
                  //         'assets/images/dk_logo.png',
                  //         width: 32,
                  //         height: 32,
                  //         color: ColorTheme.onPrimary,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 16),
                  Obx(() => Text(
                    'Hello, ${authController.userModel?.name ?? 'User'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ColorTheme.onPrimary.withOpacity(0.8),
                    ),
                  )),
                  const SizedBox(height: 4),
                  Obx(() {
                    // Calculate total inventory value
                    double totalValue = 0;
                    for (var mobileCase in caseController.cases) {
                      totalValue += mobileCase.price * mobileCase.quantity;
                    }
                    
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        'Inventory Value: ${AppUtils.formatPrice(totalValue)}',
                        key: ValueKey<double>(totalValue),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: ColorTheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, MobileCaseController caseController) {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () {
          showSearch(
            context: context,
            delegate: CaseSearchDelegate(),
          );
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorTheme.surfaceVariant,
                ColorTheme.surfaceVariant.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.search_normal,
                  color: ColorTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Search cases...',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: ColorTheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorTheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.setting_4,
                  color: ColorTheme.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(MobileCaseController caseController) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final stats = caseController.stats;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Cases',
                  '${stats['totalCases'] ?? 0}',
                  Iconsax.mobile,
                  ColorTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Quantity',
                  '${stats['totalQuantity'] ?? 0}',
                  Iconsax.box,
                  ColorTheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Models',
                  '${stats['uniqueModels'] ?? 0}',
                  Iconsax.code,
                  ColorTheme.accent1,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: ColorTheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorTheme.onBackground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: ColorTheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandDistributionChart(MobileCaseController caseController) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Brand Distribution',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorTheme.onBackground,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorTheme.primary.withOpacity(0.15),
                        ColorTheme.primary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.chart_2,
                        size: 16,
                        color: ColorTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Analytics',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: ColorTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Obx(() {
              if (caseController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: ColorTheme.primary),
                );
              }

              final brandData = _calculateBrandDistribution(caseController.cases);
              if (brandData.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Iconsax.chart,
                        size: 64,
                        color: ColorTheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No data available',
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorTheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final brandStats = _calculateBrandStats(caseController.cases);
              final sortedBrands = brandData.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: sortedBrands.length,
                itemBuilder: (context, index) {
                  final entry = sortedBrands[index];
                  final brand = entry.key;
                  final percentage = entry.value * 100;
                  final stats = brandStats[brand]!;
                  final color = _getColorForBrand(brand, brandData.length);

                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: ColorTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(15),
                              child: CustomPaint(
                                painter: CircularProgressPainter(
                                  percentage: percentage,
                                  color: color,
                                  strokeWidth: 4,
                                ),
                                child: Center(
                                  child: ClipOval(

                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.asset(
                                        _getBrandLogoPath(brand),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Text(
                                            brand[0].toUpperCase(),
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          brand,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorTheme.onBackground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.box,
                              size: 14,
                              color: ColorTheme.onBackground.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${stats.quantity} units',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: ColorTheme.onBackground.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppUtils.formatPrice(stats.totalValue),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBrandStats(MobileCaseController caseController) {
    return Obx(() {
      if (caseController.isLoading.value) {
        return const SizedBox.shrink();
      }

      final brandStats = _calculateBrandStats(caseController.cases);
      if (brandStats.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performing Brands',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...brandStats.entries.take(3).map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getColorForBrand(entry.key, brandStats.length).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      entry.key[0].toUpperCase(),
                      style: Get.textTheme.titleMedium?.copyWith(
                        color: _getColorForBrand(entry.key, brandStats.length),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: Get.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.value.quantity} units • ${AppUtils.formatPrice(entry.value.totalValue)}',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: ColorTheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColorTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${entry.value.models} models',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: ColorTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      );
    });
  }

  Map<String, double> _calculateBrandDistribution(List<MobileCaseModel> cases) {
    if (cases.isEmpty) return {};

    final brandCounts = <String, int>{};
    for (final mobileCase in cases) {
      brandCounts[mobileCase.brand] = (brandCounts[mobileCase.brand] ?? 0) + mobileCase.quantity;
    }

    final totalQuantity = brandCounts.values.fold<int>(0, (sum, count) => sum + count);
    return Map.fromEntries(
      brandCounts.entries.map(
        (entry) => MapEntry(entry.key, entry.value / totalQuantity),
      ),
    );
  }

  Map<String, BrandStats> _calculateBrandStats(List<MobileCaseModel> cases) {
    final brandStats = <String, BrandStats>{};
    final brandModels = <String, Set<String>>{};

    for (final mobileCase in cases) {
      final brand = mobileCase.brand;
      brandModels.putIfAbsent(brand, () => {}).add(mobileCase.model);
      
      final currentStats = brandStats[brand];
      final newQuantity = (currentStats?.quantity ?? 0) + mobileCase.quantity;
      final newTotalValue = (currentStats?.totalValue ?? 0) + (mobileCase.price * mobileCase.quantity);
      
      brandStats[brand] = BrandStats(
        quantity: newQuantity,
        models: brandModels[brand]!.length,
        totalValue: newTotalValue,
      );
    }

    // Sort by total value and return
    final sortedEntries = brandStats.entries.toList()
      ..sort((a, b) => b.value.totalValue.compareTo(a.value.totalValue));
    
    return Map.fromEntries(sortedEntries);
  }

  Color _getColorForBrand(String brand, int totalBrands) {
    final index = brand.hashCode % totalBrands;
    final baseColors = [
      const Color(0xFF6C5CE7), // Soft Purple
      const Color(0xFF00B894), // Mint
      const Color(0xFFFF7675), // Coral
      const Color(0xFF0984E3), // Ocean Blue
      const Color(0xFFFDAA3F), // Orange
      const Color(0xFF00CEC9), // Robin's Egg
      const Color(0xFFE056FD), // Pink
      const Color(0xFF45AAF2), // Sky Blue
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4CAF50), // Green
    ];

    if (index < baseColors.length) {
      return baseColors[index];
    }

    // Generate additional colors if needed
    final random = math.Random(brand.hashCode);
    return Color.fromRGBO(
      random.nextInt(255),
      random.nextInt(255),
      random.nextInt(255),
      1,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/dk_logo.png',
              width: 48,
              height: 48,
              color: ColorTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No cases found',
            style: TextStyle(
              fontSize: 16,
              color: ColorTheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first case by clicking the + button',
            style: TextStyle(
              fontSize: 14,
              color: ColorTheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

