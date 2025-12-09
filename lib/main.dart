import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itrack/http/controller/audit%20controller.dart';
import 'package:itrack/http/controller/authcontroller.dart';
import 'package:itrack/http/controller/companycontroller.dart';
import 'package:itrack/http/controller/dashboardcontroller.dart';
import 'package:itrack/http/controller/listcontroller.dart';
import 'package:itrack/views/auth/forgotpassword.dart';
import 'package:itrack/views/auth/login.dart';
import 'package:itrack/views/auth/reset.dart';
import 'package:itrack/views/home/audit.dart';
import 'package:itrack/views/home/company.dart';
import 'package:itrack/views/home/listofAuditedAssets.dart';
import 'package:itrack/views/home/mainscreen.dart';
import 'package:itrack/views/splashscreen.dart';
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
        Get.put(AuthController(), permanent: true);
         Get.put(CaptureScreen(), permanent: true);
      }),
      getPages: [
        GetPage(
          name: "/",
          page: () => SplashScreen(), // ✅ Splash is now the first screen
        ),
        GetPage(
          name: "/login",
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: "/home",
          page: () => MainScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => DashboardController());
          }),
        ),
        GetPage(
          name: "/company",
          page: () => const CompanyLocationScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => CompanyController());
          }),
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
          binding: BindingsBuilder(() {
            Get.lazyPut(() => AuditListController());
          }),
        ),
        GetPage(
          name: "/capture",
          page: () => CaptureScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => CaptureController());
          }),
        ),
      ],
      initialRoute: "/", // ✅ Start at splash
      unknownRoute: GetPage(
        name: "/notfound",
        page: () => Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 80),
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
                  onPressed: () => Get.offAllNamed('/login'),
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
