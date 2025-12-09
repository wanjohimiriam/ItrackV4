import 'package:get/get.dart';
import 'package:itrack/http/controller/audit%20controller.dart';
import 'package:itrack/http/service/authstorage.dart';

class SplashController extends GetxController {
  final AuthStorage _authStorage = AuthStorage.instance;
  
  @override
  void onInit() {
    super.onInit();
    _initializeSplash();
  }

  Future<void> _initializeSplash() async {
    try {
      // Initialize auth storage
      await _authStorage.init();
      
      // Wait for splash duration (5 seconds)
      await Future.delayed(const Duration(seconds: 5));
      
      // Check authentication status
      await _checkAuthAndNavigate();
    } catch (e) {
      // On error, navigate to login
      Get.offAllNamed('/login');
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Check if user is authenticated
      final isAuthenticated = await _authStorage.isAuthenticated();
      
      if (isAuthenticated) {
        print('✅ User is authenticated, navigating to company selection');
        // Navigate to company selection
        Get.offAllNamed('/company');
      } else {
        print('❌ User is not authenticated, navigating to login');
        // User is not authenticated, navigate to login
        Get.offAllNamed('/login');
      }
    } catch (e) {
      print('🔴 Error checking auth: $e');
      // On error, navigate to login
      Get.offAllNamed('/login');
    }
  }
}
