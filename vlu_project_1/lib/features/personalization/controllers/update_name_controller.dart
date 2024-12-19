// ignore_for_file: unnecessary_overrides

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vlu_project_1/core/utils/network.dart';
import 'package:vlu_project_1/data/repositories/user/user_repository.dart';
import 'package:vlu_project_1/features/auth/controller/user_controller.dart';
import 'package:vlu_project_1/shared/widgets/full_screen_loader.dart';
import 'package:vlu_project_1/shared/widgets/loaders.dart';

class UpdateNameController extends GetxController {
  static UpdateNameController get instance => Get.find();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final userController = UserController.instance;
  final userRepository = Get.put(UserRepository());
  final GlobalKey<FormState> updateUserNameFormKey = GlobalKey<FormState>();

  // Initialize user data when Home Screen appears
  @override
  void onInit() {
    initializedName();
    super.onInit();
  }

  // Fetch user record
  Future<void> initializedName() async {
    firstName.text = userController.user.value.firstName;
    lastName.text = userController.user.value.lastName;
  }

  Future<void> updateUserName() async {
    try {
      FullScreenLoader.openLoadingDialog("Đang tải ...");

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        Loaders.errorSnackBar(
            title: 'Lỗi', message: 'Không có kết nối Internet');
        FullScreenLoader.stopLoading();
        return;
      }

      // Form Validation
      if (!updateUserNameFormKey.currentState!.validate()) {
        FullScreenLoader.stopLoading();
        return;
      }

      // Update user's first & last name in Firebase Firestore
      Map<String, dynamic> name = {
        'FirstName': firstName.text.trim(),
        'LastName': lastName.text.trim()
      };
      await userRepository.updateSingleField(name);
      // Update the Rx User value
      userController.user.value.firstName = firstName.text.trim();
      userController.user.value.lastName = lastName.text.trim();
      userController.user.refresh();

      Get.back();
      // Remove Loader
      FullScreenLoader.stopLoading();

      // Show success message
      Loaders.successSnackBar(
          title: 'Thành công', message: 'Cập nhật tên thành công');

    } catch (e) {
      FullScreenLoader.stopLoading();
      Loaders.errorSnackBar(title: 'Lỗi', message: e.toString());
    }
  }
}
