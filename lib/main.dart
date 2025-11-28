import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itrack/http/controller/audit%20controller.dart';
import 'package:itrack/http/controller/authcontroller.dart';
import 'package:itrack/views/auth/forgotpassword.dart';
import 'package:itrack/views/auth/login.dart';
import 'package:itrack/views/auth/reset.dart';
import 'package:itrack/views/home/company.dart';
import 'package:itrack/views/home/listofAuditedAssets.dart';
import 'package:itrack/views/home/mainscreen.dart';
import 'package:itrack/views/widget/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'iTrak Asset Management',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      initialBinding: BindingsBuilder(() {
        // ✅ Only put AuthController as permanent
        Get.put(AuthController(), permanent: true);
        Get.put(CaptureController(), permanent: true);
        // ❌ DON'T put CaptureController here - it should be created only when needed
      }),
      getPages: [
        GetPage(
          name: "/",
          page: () => const AuthCheckScreen(),
        ),
        GetPage(
          name: "/login",
          page: () {
            print('🟢 ROUTE: Navigating to LoginScreen');
            return const LoginScreen();
          },
        ),
        GetPage(
          name: "/home",
          page: () {
            print('🟢 ROUTE: Navigating to MainScreen (Home)');
            return MainScreen();
          },
        ),
        GetPage(
          name: "/company",
          page: () {
            print('🟢 ROUTE: Navigating to CompanyLocationScreen');
            return const CompanyLocationScreen();
          },
        ),
        GetPage(
          name: "/forgot-password",
          page: () => ForgotPasswordScreen(),
        ),
        GetPage(
          name: "/reset-password",
          page: () => ResetPasswordScreen(),
        ),
        GetPage(
          name: "/assets-list",
          page: () => ListofTodaysAudit(),
        ),
      ],
      initialRoute: "/login",
      unknownRoute: GetPage(
        name: "/notfound",
        page: () => Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Page not found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/company'),  // ✅ Changed from /home to /login
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Auth Check Screen
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    print('🟡 AuthCheckScreen: Checking auth status...');
    final authController = Get.find<AuthController>();
    
    // Give a small delay for splash effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if user is authenticated
    await authController.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo matching login screen
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'iTrak',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Asset Management System',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}