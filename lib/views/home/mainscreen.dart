import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itrack/http/controller/audit%20controller.dart';
import 'package:itrack/views/home/audit.dart';
import 'package:itrack/views/home/dashboard.dart';
import 'package:itrack/views/widget/colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize CaptureController if not already created
    if (!Get.isRegistered<CaptureController>()) {
      Get.put(CaptureController());
    }
    
    _screens = [
      DashboardScreen(), // Your dashboard screen
      const CaptureScreen(),   // Your capture screen
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Navigate back to company selection instead of exiting
          Get.offAllNamed('/company');
        }
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items:[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Capture',
          ),
        ],
        backgroundColor: Colors.white,
        selectedItemColor:AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      ),
    );
  }
}