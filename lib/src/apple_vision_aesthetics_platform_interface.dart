import 'dart:typed_data';

import 'package:apple_vision_aesthetics/src/image_aesthetics_result.dart';
import 'package:apple_vision_aesthetics/src/apple_vision_aesthetics_method_channel.dart';

/// The interface that platform-specific implementations must implement.
///
/// This allows for easy mocking/testing and potential alternative
/// implementations (e.g. macOS in the future).
abstract class AppleVisionAestheticsPlatform {
  /// The default instance of [AppleVisionAestheticsPlatform].
  static AppleVisionAestheticsPlatform instance =
      AppleVisionAestheticsMethodChannel();

  /// Analyzes the image at [filePath] and returns its aesthetics scores.
  ///
  /// The file must be a valid image format supported by Apple's Vision
  /// framework (JPEG, PNG, HEIC, TIFF, etc.).
  ///
  /// Throws [UnsupportedError] on non-iOS platforms.
  /// Throws [PlatformException] if the Vision request fails.
  Future<ImageAestheticsResult> analyzeFile(String filePath);

  /// Analyzes raw image bytes and returns aesthetics scores.
  ///
  /// [bytes] must contain a valid encoded image (JPEG, PNG, HEIC, etc.).
  ///
  /// Throws [UnsupportedError] on non-iOS platforms.
  /// Throws [PlatformException] if the Vision request fails.
  Future<ImageAestheticsResult> analyzeBytes(Uint8List bytes);

  /// Analyzes multiple images in batch and returns results in order.
  ///
  /// This is more efficient than calling [analyzeFile] in a loop because
  /// it batches the platform channel calls.
  ///
  /// Any individual failures will throw, aborting the batch.
  Future<List<ImageAestheticsResult>> analyzeBatch(List<String> filePaths);

  /// Returns `true` if the current device supports
  /// `CalculateImageAestheticsScoresRequest` (requires iOS 18.0+).
  Future<bool> isSupported();
}
