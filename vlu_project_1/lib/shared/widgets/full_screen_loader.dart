import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package

class FullScreenLoader {
  static void openLoadingDialog(String text, {String? animation}) {
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      // ignore: deprecated_member_use
      builder: (_) => WillPopScope(
        onWillPop: () async => false, // Prevent dialog from being dismissed
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Center(
                child: Lottie.asset(
                  filterQuality: FilterQuality.high,
                  'assets/images/animation_loading.json',
                  width: 200,
                  height: 200,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static void stopLoading() {
    Navigator.of(Get.overlayContext!).pop();
  }
}
