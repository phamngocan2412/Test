// ignore: depend_on_referenced_packages
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:vlu_project_1/data/repositories/authentication/authentication_repository.dart';
import 'package:vlu_project_1/features/auth/screens/sign_in/sign_in_screen.dart';
import 'package:vlu_project_1/features/auth/screens/success/sign_up_success/success_screen.dart';
import 'package:vlu_project_1/shared/widgets/loaders.dart';
import 'package:vlu_project_1/shared/widgets/text_string.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  // Send Email Verify appear & Set Timer for auto redirect
  @override
  void onInit() {
    setTimeForAutoRedirect();
    super.onInit();
  }

  // Send Email Verification link
  Future<void> sendEmailVerification() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        Get.offAll(() => const SignInScreen());
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Người dùng chưa đăng nhập hoặc không tồn tại.',
        );
      }

      await currentUser.sendEmailVerification();
      Loaders.successSnackBar(
        title: 'Thành công',
        message: 'Làm ơn kiểm tra tin nhắn và xác thực đã được gửi đến email của bạn',
      );
    } catch (e) {
      Loaders.errorSnackBar(title: 'Lỗi', message: e.toString());
    }
  }

  // Timer to automatically redirect on Email Verification
  void setTimeForAutoRedirect() {
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      timer.cancel(); // Hủy timer nếu không có người dùng nào đăng nhập
      return;
    }

    await user.reload();
    
    if (user.emailVerified) {
      timer.cancel();
      Get.off(
        () => SuccessScreen(
          image: 'assets/images/verify_email.png',
          title: TText.yourAccountCreatedTitle,
          subTitle: TText.yourAccountCreatedSubTitle,
          onPressed: () => AuthenticationRepository.instance.screenRedirect(),
        ),
      );
    }
  });
}


  // Manually Check if Email Verified
  checkEmailVerificationStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.emailVerified) {
      Get.off(
        () => SuccessScreen(
          image: 'assets/images/check_email.png',
          title: TText.yourAccountCreatedTitle,
          subTitle: TText.yourAccountCreatedSubTitle,
          onPressed: () => AuthenticationRepository.instance.screenRedirect(),
        ),
      );
    } else {
      Loaders.errorSnackBar(
          title: 'Chưa xác thực', message: 'Email của bạn chưa được xác thực.');
    }
  }
}
