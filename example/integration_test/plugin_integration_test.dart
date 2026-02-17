/// Integration tests for apple_vision_aesthetics.
///
/// Run on a PHYSICAL iOS 18+ device:
/// ```
/// cd example
/// flutter test integration_test/plugin_integration_test.dart
/// ```
///
/// These tests use images from the Kwentar/blur_dataset:
/// - _S = Sharp image
/// - _F = Defocused-blurred image
/// - _M = Motion-blurred image
///
/// Expected behavior:
/// - Sharp images should have the highest overallScore
/// - Blurred images (defocused + motion) should score lower
/// - None of these are utility images (they're real photos, not screenshots)
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:apple_vision_aesthetics/apple_vision_aesthetics.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final plugin = AppleVisionAestheticsPlatform.instance;

  group('Device support', () {
    testWidgets('isSupported returns true on iOS 18+', (tester) async {
      final supported = await plugin.isSupported();
      expect(supported, isTrue,
          reason: 'These tests must run on a physical iOS 18+ device');
    });
  });

  group('Single image analysis (analyzeFile)', () {
    late String sharpPath;
    late String defocusedPath;
    late String motionPath;

    setUpAll(() async {
      sharpPath = await _copyAssetToTemp('sample_sharp.jpg');
      defocusedPath = await _copyAssetToTemp('sample_defocused.jpg');
      motionPath = await _copyAssetToTemp('sample_motion_blur.jpg');
    });

    tearDownAll(() async {
      await File(sharpPath).delete();
      await File(defocusedPath).delete();
      await File(motionPath).delete();
    });

    testWidgets('sharp image returns valid result', (tester) async {
      final result = await plugin.analyzeFile(sharpPath);

      expect(result.overallScore, inInclusiveRange(-1.0, 1.0));
      expect(result.isUtility, isFalse,
          reason: 'A real photo should not be classified as utility');
    });

    testWidgets('defocused image returns valid result', (tester) async {
      final result = await plugin.analyzeFile(defocusedPath);

      expect(result.overallScore, inInclusiveRange(-1.0, 1.0));
    });

    testWidgets('motion blur image returns valid result', (tester) async {
      final result = await plugin.analyzeFile(motionPath);

      expect(result.overallScore, inInclusiveRange(-1.0, 1.0));
    });

    testWidgets('sharp image scores higher than blurred ones',
        (tester) async {
      final sharp = await plugin.analyzeFile(sharpPath);
      final defocused = await plugin.analyzeFile(defocusedPath);
      final motion = await plugin.analyzeFile(motionPath);

      expect(sharp.overallScore, greaterThan(defocused.overallScore),
          reason:
              'Sharp (${sharp.overallScore}) should score higher than '
              'defocused (${defocused.overallScore})');

      expect(sharp.overallScore, greaterThan(motion.overallScore),
          reason:
              'Sharp (${sharp.overallScore}) should score higher than '
              'motion blur (${motion.overallScore})');
    });
  });

  group('Bytes analysis (analyzeBytes)', () {
    testWidgets('analyzeBytes works with sharp image data', (tester) async {
      final data = await rootBundle.load('assets/sample_sharp.jpg');
      final bytes = data.buffer.asUint8List();

      final result = await plugin.analyzeBytes(bytes);

      expect(result.overallScore, inInclusiveRange(-1.0, 1.0));
      expect(result.isUtility, isFalse);
    });
  });

  group('Batch analysis (analyzeBatch)', () {
    late List<String> paths;

    setUpAll(() async {
      paths = [
        await _copyAssetToTemp('sample_sharp.jpg'),
        await _copyAssetToTemp('sample_defocused.jpg'),
        await _copyAssetToTemp('sample_motion_blur.jpg'),
      ];
    });

    tearDownAll(() async {
      for (final path in paths) {
        await File(path).delete();
      }
    });

    testWidgets('batch returns correct number of results', (tester) async {
      final results = await plugin.analyzeBatch(paths);

      expect(results, hasLength(3));
      for (final result in results) {
        expect(result.overallScore, inInclusiveRange(-1.0, 1.0));
      }
    });

    testWidgets('batch results match individual results', (tester) async {
      final batch = await plugin.analyzeBatch(paths);

      final individual0 = await plugin.analyzeFile(paths[0]);
      final individual1 = await plugin.analyzeFile(paths[1]);
      final individual2 = await plugin.analyzeFile(paths[2]);

      // Scores should be identical (deterministic model)
      expect(batch[0].overallScore, individual0.overallScore);
      expect(batch[1].overallScore, individual1.overallScore);
      expect(batch[2].overallScore, individual2.overallScore);
    });
  });

  group('Error handling', () {
    testWidgets('analyzeFile throws for non-existent file', (tester) async {
      expect(
        () => plugin.analyzeFile('/nonexistent/path/image.jpg'),
        throwsA(anything),
      );
    });
  });
}

/// Copies a bundled asset to a temp file and returns the path.
Future<String> _copyAssetToTemp(String assetName) async {
  final data = await rootBundle.load('assets/$assetName');
  final tempFile = File('${Directory.systemTemp.path}/$assetName');
  await tempFile.writeAsBytes(data.buffer.asUint8List());
  return tempFile.path;
}
