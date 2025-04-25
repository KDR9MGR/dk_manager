import 'package:get/get.dart';
import '../views/splash_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/home_screen.dart';
import '../views/case/add_case_screen.dart';
import '../views/case/case_details_screen.dart';
import '../views/case/edit_case_screen.dart';
import '../views/profile/profile_screen.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String addCase = '/add-case';
  static const String caseDetails = '/case-details';
  static const String editCase = '/edit-case';
  static const String profile = '/profile';

  static final List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: addCase,
      page: () => const AddCaseScreen(),
    ),
    GetPage(
      name: caseDetails,
      page: () => const CaseDetailsScreen(),
    ),
    GetPage(
      name: editCase,
      page: () => const EditCaseScreen(),
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
    ),
  ];
} 