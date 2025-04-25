import 'package:get/get.dart';
import '../views/auth/login_screen.dart';
import '../views/splash_screen.dart';
import '../views/home_screen.dart';
import '../views/case/add_case_screen.dart';
import '../views/case/edit_case_screen.dart';
import '../views/case/case_details_screen.dart';
import '../views/profile/profile_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: AppRoutes.addCase,
      page: () => const AddCaseScreen(),
    ),
    GetPage(
      name: AppRoutes.editCase,
      page: () => const EditCaseScreen(),
    ),
    GetPage(
      name: AppRoutes.caseDetails,
      page: () => const CaseDetailsScreen(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
    ),
  ];
} 