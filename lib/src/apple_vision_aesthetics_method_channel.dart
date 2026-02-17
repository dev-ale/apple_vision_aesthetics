import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'apple_vision_aesthetics_platform_interface.dart';
import 'image_aesthetics_result.dart';

/// Method channel implementation of [AppleVisionAestheticsPlatform].
///
/// Communicates with the native iOS Swift code via a [MethodChannel].
class AppleVisionAestheticsMethodChannel
    extends AppleVisionAestheticsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('apple_vision_aesthetics');

  @override
  Future<ImageAestheticsResult> analyzeFile(String filePath) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'analyzeFile',
      {'filePath': filePath},
    );

    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Native platform returned null for analyzeFile.',
      );
    }

    return ImageAestheticsResult.fromMap(result);
  }

  @override
  Future<ImageAestheticsResult> analyzeBytes(Uint8List bytes) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'analyzeBytes',
      {'bytes': bytes},
    );

    if (result == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Native platform returned null for analyzeBytes.',
      );
    }

    return ImageAestheticsResult.fromMap(result);
  }

  @override
  Future<List<ImageAestheticsResult>> analyzeBatch(
      List<String> filePaths) async {
    final results = await methodChannel.invokeListMethod<Map>(
      'analyzeBatch',
      {'filePaths': filePaths},
    );

    if (results == null) {
      throw PlatformException(
        code: 'NULL_RESULT',
        message: 'Native platform returned null for analyzeBatch.',
      );
    }

    return results
        .map((m) =>
            ImageAestheticsResult.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<bool> isSupported() async {
    final supported =
        await methodChannel.invokeMethod<bool>('isSupported');
    return supported ?? false;
  }
}
