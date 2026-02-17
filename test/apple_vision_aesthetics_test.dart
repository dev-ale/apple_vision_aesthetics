import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apple_vision_aesthetics/apple_vision_aesthetics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageAestheticsResult', () {
    test('fromMap creates correct instance', () {
      final result = ImageAestheticsResult.fromMap({
        'overallScore': 0.75,
        'isUtility': false,
      });

      expect(result.overallScore, 0.75);
      expect(result.isUtility, false);
    });

    test('fromMap handles int overallScore', () {
      final result = ImageAestheticsResult.fromMap({
        'overallScore': 1,
        'isUtility': true,
      });

      expect(result.overallScore, 1.0);
      expect(result.isUtility, true);
    });

    test('toMap round-trips correctly', () {
      const original = ImageAestheticsResult(
        overallScore: -0.5,
        isUtility: true,
      );

      final map = original.toMap();
      final restored = ImageAestheticsResult.fromMap(map);

      expect(restored, original);
    });

    test('isLowQuality with default threshold', () {
      const good = ImageAestheticsResult(overallScore: 0.5, isUtility: false);
      const bad = ImageAestheticsResult(overallScore: -0.5, isUtility: false);
      const borderline =
          ImageAestheticsResult(overallScore: -0.25, isUtility: false);

      expect(good.isLowQuality(), false);
      expect(bad.isLowQuality(), true);
      expect(borderline.isLowQuality(), false); // -0.25 is NOT < -0.25
    });

    test('isLowQuality with custom threshold', () {
      const result =
          ImageAestheticsResult(overallScore: 0.1, isUtility: false);

      expect(result.isLowQuality(threshold: 0.5), true);
      expect(result.isLowQuality(threshold: 0.0), false);
    });

    test('equality', () {
      const a = ImageAestheticsResult(overallScore: 0.5, isUtility: false);
      const b = ImageAestheticsResult(overallScore: 0.5, isUtility: false);
      const c = ImageAestheticsResult(overallScore: 0.5, isUtility: true);

      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains values', () {
      const result =
          ImageAestheticsResult(overallScore: 0.42, isUtility: true);

      expect(result.toString(), contains('0.42'));
      expect(result.toString(), contains('true'));
    });
  });

  group('AppleVisionAestheticsMethodChannel', () {
    late AppleVisionAestheticsMethodChannel channel;
    late List<MethodCall> log;

    setUp(() {
      channel = AppleVisionAestheticsMethodChannel();
      log = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel.methodChannel,
        (MethodCall call) async {
          log.add(call);

          switch (call.method) {
            case 'analyzeFile':
              return {
                'overallScore': 0.85,
                'isUtility': false,
              };
            case 'analyzeBytes':
              return {
                'overallScore': -0.3,
                'isUtility': true,
              };
            case 'analyzeBatch':
              return [
                {'overallScore': 0.5, 'isUtility': false},
                {'overallScore': -0.8, 'isUtility': true},
              ];
            case 'isSupported':
              return true;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel.methodChannel, null);
    });

    test('analyzeFile sends correct method and args', () async {
      final result = await channel.analyzeFile('/path/to/image.jpg');

      expect(log, hasLength(1));
      expect(log.first.method, 'analyzeFile');
      expect(log.first.arguments, {'filePath': '/path/to/image.jpg'});
      expect(result.overallScore, 0.85);
      expect(result.isUtility, false);
    });

    test('analyzeBytes sends correct method and args', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = await channel.analyzeBytes(bytes);

      expect(log, hasLength(1));
      expect(log.first.method, 'analyzeBytes');
      expect(result.overallScore, -0.3);
      expect(result.isUtility, true);
    });

    test('analyzeBatch returns list of results', () async {
      final results = await channel.analyzeBatch([
        '/path/a.jpg',
        '/path/b.png',
      ]);

      expect(log, hasLength(1));
      expect(log.first.method, 'analyzeBatch');
      expect(results, hasLength(2));
      expect(results[0].overallScore, 0.5);
      expect(results[1].overallScore, -0.8);
      expect(results[1].isUtility, true);
    });

    test('isSupported returns bool', () async {
      final supported = await channel.isSupported();
      expect(supported, true);
    });

    test('analyzeFile throws on null result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel.methodChannel,
        (MethodCall call) async => null,
      );

      expect(
        () => channel.analyzeFile('/path/to/image.jpg'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('analyzeBytes throws on null result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel.methodChannel,
        (MethodCall call) async => null,
      );

      expect(
        () => channel.analyzeBytes(Uint8List(0)),
        throwsA(isA<PlatformException>()),
      );
    });

    test('analyzeBatch throws on null result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel.methodChannel,
        (MethodCall call) async => null,
      );

      expect(
        () => channel.analyzeBatch(['/a.jpg']),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  group('AppleVisionAestheticsPlatform', () {
    test('default instance is MethodChannel implementation', () {
      expect(
        AppleVisionAestheticsPlatform.instance,
        isA<AppleVisionAestheticsMethodChannel>(),
      );
    });

    test('instance can be overridden', () {
      final mock = _MockPlatform();
      AppleVisionAestheticsPlatform.instance = mock;

      expect(AppleVisionAestheticsPlatform.instance, mock);

      // Reset
      AppleVisionAestheticsPlatform.instance =
          AppleVisionAestheticsMethodChannel();
    });
  });
}

class _MockPlatform extends AppleVisionAestheticsPlatform {
  @override
  Future<ImageAestheticsResult> analyzeFile(String filePath) async =>
      const ImageAestheticsResult(overallScore: 0.0, isUtility: false);

  @override
  Future<ImageAestheticsResult> analyzeBytes(Uint8List bytes) async =>
      const ImageAestheticsResult(overallScore: 0.0, isUtility: false);

  @override
  Future<List<ImageAestheticsResult>> analyzeBatch(
          List<String> filePaths) async =>
      [];

  @override
  Future<bool> isSupported() async => true;
}
