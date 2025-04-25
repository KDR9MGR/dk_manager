import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/mobile_case_controller.dart';
import '../../models/mobile_case_model.dart';
import '../../utils/app_utils.dart';
import '../../routes/app_routes.dart';
import '../../theme/color_theme.dart';

class CaseDetailsScreen extends StatelessWidget {
  const CaseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mobileCase = Get.arguments as MobileCaseModel;
    final caseController = Get.find<MobileCaseController>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(mobileCase, caseController),
          SliverToBoxAdapter(
            child: _buildDetailsCard(mobileCase, size),
          ),
          SliverToBoxAdapter(
            child: _buildStatsCard(mobileCase),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  String _getBrandLogoPath(String brand) {
    final formattedBrand = brand.toLowerCase().replaceAll(' ', '_');
    return 'assets/images/$formattedBrand.png';
  }

  Widget _buildSliverAppBar(MobileCaseModel mobileCase, MobileCaseController caseController) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: ColorTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: mobileCase.imageUrl != null && mobileCase.imageUrl!.isNotEmpty
            ? Hero(
                tag: 'case_image_${mobileCase.id}',
                child: CachedNetworkImage(
                  imageUrl: mobileCase.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: ColorTheme.surfaceVariant.withOpacity(0.5),
                    child: Center(
                      child: Image.asset(
                        _getBrandLogoPath(mobileCase.brand),
                        width: 120,
                        height: 120,
                        color: ColorTheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: ColorTheme.surfaceVariant.withOpacity(0.5),
                    child: Center(
                      child: Image.asset(
                        _getBrandLogoPath(mobileCase.brand),
                        width: 120,
                        height: 120,
                        color: ColorTheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                color: ColorTheme.surfaceVariant.withOpacity(0.5),
                child: Center(
                  child: Image.asset(
                    _getBrandLogoPath(mobileCase.brand),
                    width: 120,
                    height: 120,
                    color: ColorTheme.primary.withOpacity(0.5),
                  ),
                ),
              ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.edit, color: ColorTheme.onPrimary),
          onPressed: () => Get.toNamed(AppRoutes.editCase, arguments: mobileCase),
        ),
        IconButton(
          icon: const Icon(Iconsax.trash, color: ColorTheme.onPrimary),
          onPressed: () => _showDeleteDialog(mobileCase, caseController),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(MobileCaseModel mobileCase, Size size) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mobileCase.brand} ${mobileCase.model}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ColorTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppUtils.formatPrice(mobileCase.price),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ColorTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Iconsax.box, color: ColorTheme.primary),
                    const SizedBox(height: 4),
                    Text(
                      '${mobileCase.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorTheme.primary,
                      ),
                    ),
                    Text(
                      'in stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorTheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (mobileCase.description != null && mobileCase.description!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorTheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mobileCase.description!,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: ColorTheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(MobileCaseModel mobileCase) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Case Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Added on',
            AppUtils.formatDate(mobileCase.createdAt),
            Iconsax.calendar,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Last updated',
            AppUtils.formatDate(mobileCase.updatedAt),
            Iconsax.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: ColorTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: ColorTheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorTheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog(MobileCaseModel mobileCase, MobileCaseController caseController) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: ColorTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Case',
          style: TextStyle(color: ColorTheme.onSurface),
        ),
        content: const Text(
          'Are you sure you want to delete this case?',
          style: TextStyle(color: ColorTheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ColorTheme.onSurface.withOpacity(0.8)),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Delete',
              style: TextStyle(color: ColorTheme.error),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await caseController.deleteCase(mobileCase.id);
      Get.back();
      Get.snackbar(
        'Success',
        'Case deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ColorTheme.success.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }
} 