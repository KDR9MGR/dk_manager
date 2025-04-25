import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/mobile_case_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    Get.put(MobileCaseController(), permanent: true);
  }
} 