// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:vlu_project_1/core/utils/extensions/img_extensions.dart';
import 'package:vlu_project_1/features/chat_ai/controllers/storage_nodejs_repository.dart';
import 'package:vlu_project_1/features/chat_ai/model/message.dart';
import 'package:vlu_project_1/shared/widgets/loaders.dart';

@immutable
class ChatRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  
  Future sendMessage({
    required String apiKey,
    required XFile? image,
    required String promptText,
  }) async {
    // Define your model
    final textModel = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    final imageModel = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
    );

    final userId = _auth.currentUser!.uid;
    final sentMessageId = const Uuid().v4();

    Message message = Message(
      id: sentMessageId,
      message: promptText,
      createdAt: DateTime.now(),
      isMine: true,
    );

    if (image != null) {
      // Save image to backend server and get the URL
      final downloadUrl = await StorageNodejsRepository().saveImageToStorage(
        image: image,
        messageId: sentMessageId,
      );

      message = message.copyWith(
        imageUrl: downloadUrl,
      );
    }

    // Save Message to Firebase
    await _firestore
        .collection('conversations')
        .doc(userId)
        .collection('messages')
        .doc(sentMessageId)
        .set(message.toMap());

    // Create a response
    GenerateContentResponse response;

    try {
      if (image == null) {
        // Make a text only request to Gemini API
        response = await textModel.generateContent([Content.text(promptText)]);
      } else {
        // convert it to Uint8List
        final imageBytes = await image.readAsBytes();

        // Define your parts
        final prompt = TextPart(promptText);
        final mimeType = image.getMimeTypeFromExtension();
        final imagePart = DataPart(mimeType, imageBytes);

        // Make a multi-model request to Gemini API
        response = await imageModel.generateContent([
          Content.multi([
            prompt,
            imagePart,
          ])
        ]);
      }

      final responseText = response.text;

      // Save the response in Firebase
      final receivedMessageId = const Uuid().v4();

      final responseMessage = Message(
        id: receivedMessageId,
        message: responseText!,
        createdAt: DateTime.now(),
        isMine: false,
      );

      // Save Message to Firebase
      await _firestore
          .collection('conversations')
          .doc(userId)
          .collection('messages')
          .doc(receivedMessageId)
          .set(responseMessage.toMap());
    } catch (e) {
      // Handle specific error for safety block
      if (e.toString().contains("Candidate was blocked due to safety")) {
        throw Exception("Nội dung của bạn đã bị chặn do vấn đề an toàn. Vui lòng kiểm tra lại.");
      } else {
        throw Exception("Lỗi không xác định: ${e.toString()}");
      }
    }
  }

  //! Send Text Only Prompt
  Future sendTextMessage({
    required String textPrompt,
    required String apiKey,
  }) async {
    try {
      // Define your model
      final textModel = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

      final userId = _auth.currentUser!.uid;
      final sentMessageId = const Uuid().v4();

      Message message = Message(
        id: sentMessageId,
        message: textPrompt,
        createdAt: DateTime.now(),
        isMine: true,
      );

      // Save Message to Firebase
      await _firestore
          .collection('conversations')
          .doc(userId)
          .collection('messages')
          .doc(sentMessageId)
          .set(message.toMap());

      // Make a text only request to Gemini API and save the response
      final response =
          await textModel.generateContent([Content.text(textPrompt)]);

      final responseText = response.text;

      // Save the response in Firebase
      final receivedMessageId = const Uuid().v4();

      final responseMessage = Message(
        id: receivedMessageId,
        message: responseText!,
        createdAt: DateTime.now(),
        isMine: false,
      );

      // Save Message to Firebase
      await _firestore
          .collection('conversations')
          .doc(userId)
          .collection('messages')
          .doc(receivedMessageId)
          .set(responseMessage.toMap());
    } catch (e) {
      // Handle specific error for safety block
      if (e.toString().contains("Candidate was blocked due to safety")) {
        Loaders.warningSnackBar(title: "Cảnh báo", message: "Nội dung không phù hợp");
        // throw Exception("Nội dung của bạn đã bị chặn do vấn đề an toàn. Vui lòng kiểm tra lại.");
      } else {
        throw Exception("Lỗi không xác định: ${e.toString()}");
      }
    }
  }

  Future<void> clearChatHistory() async {
    final userId = _auth.currentUser!.uid;

    try {
      // Xóa tất cả tài liệu trong Firestore collection 'messages'
      final messagesRef = _firestore
          .collection('conversations')
          .doc(userId)
          .collection('messages');

      final snapshot = await messagesRef.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception("Không thể xóa lịch sử đoạn chat: ${e.toString()}");
    }
  }
}
