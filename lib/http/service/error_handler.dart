import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itrack/views/widget/colors.dart';

/// Centralized error handling for the application
class ErrorHandler {
  // Private constructor to prevent instantiation
  ErrorHandler._();

  /// Handle errors with consistent logging and user feedback
  static void handle(
    dynamic error, {
    String? context,
    bool showSnackbar = true,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = _getErrorMessage(error);
    final logContext = context ?? 'App';

    // Log the error
    developer.log(
      'Error: $message',
      name: logContext,
      error: error,
      level: 1000, // Error level
    );

    // Show user feedback if requested
    if (showSnackbar && Get.context != null) {
      Get.snackbar(
        'Error',
        message,
        snackPosition: snackPosition,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: duration,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// Handle success messages
  static void showSuccess(
    String message, {
    String title = 'Success',
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: snackPosition,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: duration,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// Handle info messages
  static void showInfo(
    String message, {
    String title = 'Info',
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: snackPosition,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        duration: duration,
        icon: const Icon(Icons.info_outline, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// Handle warning messages
  static void showWarning(
    String message, {
    String title = 'Warning',
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: snackPosition,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: duration,
        icon: const Icon(Icons.warning_amber, color: Colors.white),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// Extract user-friendly error message from various error types
  static String _getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unknown error occurred';
    }

    // Handle string errors
    if (error is String) {
      return error;
    }

    // Handle Exception types
    if (error is Exception) {
      final errorString = error.toString();
      
      // Remove "Exception: " prefix if present
      if (errorString.startsWith('Exception: ')) {
        return errorString.substring(11);
      }
      
      return errorString;
    }

    // Handle Error types
    if (error is Error) {
      return error.toString();
    }

    // Fallback
    return error.toString();
  }

  /// Log info messages
  static void logInfo(String message, {String? context}) {
    developer.log(
      message,
      name: context ?? 'App',
      level: 800, // Info level
    );
  }

  /// Log warning messages
  static void logWarning(String message, {String? context}) {
    developer.log(
      message,
      name: context ?? 'App',
      level: 900, // Warning level
    );
  }

  /// Log debug messages
  static void logDebug(String message, {String? context}) {
    developer.log(
      message,
      name: context ?? 'App',
      level: 500, // Debug level
    );
  }
}
