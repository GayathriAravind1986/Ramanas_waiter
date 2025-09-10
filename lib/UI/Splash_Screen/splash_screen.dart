import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ramanas_waiter/Reusable/color.dart';
import 'package:ramanas_waiter/Reusable/image.dart';
import 'package:ramanas_waiter/UI/Authentication/login_screen.dart';
import 'package:ramanas_waiter/UI/Dashboard/dasboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  dynamic token;
  dynamic role;

  @override
  void initState() {
    super.initState();
    callApis();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 2), () => onTimerFinished());
    });
  }

  Future<void> callApis() async {
    await getToken();
  }

  Future<void> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString("token");
      role = prefs.getString("role");
    });
    debugPrint("SplashToken: $token");
    debugPrint("SplashRole: $role");
  }

  void onTimerFinished() {
    if (mounted) {
      token == null && role == null
          ?
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      )
      :
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
          (Route<dynamic> route) => false,
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: whiteColor,
      body: Stack(
        children: [
          Container(height: size.height, width: size.width, color: whiteColor),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(opacity: _controller.value, child: child),
                );
              },
              child: Image.asset(Images.logoWithName, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
