import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_utils.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final user = authController.userModel!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Text(
                AppUtils.getInitials(user.name),
                style: AppTextStyles.headline1.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Text(
              user.name,
              style: AppTextStyles.headline1,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              user.email,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Account Type'),
              subtitle: Text(
                user.role.toUpperCase(),
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Member Since'),
              subtitle: Text(
                AppUtils.formatDate(user.createdAt),
                style: AppTextStyles.body2,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXL),
            CustomButton(
              text: AppStrings.logout,
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.back();
                          authController.signOut();
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
              backgroundColor: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
} 