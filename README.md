# apple_vision_aesthetics

A Flutter plugin wrapping Apple's Vision framework **`CalculateImageAestheticsScoresRequest`** to score image quality, detect blur, and identify utility images (screenshots, receipts, documents).

**iOS 18.0+ only.** Uses the modern Swift concurrency Vision API introduced at WWDC24.

## Features

- **Image quality scoring** — get an overall aesthetic score from -1.0 (poor) to 1.0 (excellent)
- **Blur detection** — blurry/out-of-focus images receive lower scores
- **Utility image detection** — identifies screenshots, receipts, documents, QR codes
- **Batch analysis** — efficiently score multiple images in one call
- **Bytes or file path** — analyze from `Uint8List` or a file on disk

The scoring model considers blur, exposure, color balance, composition, and subject matter — powered entirely on-device by Apple's Neural Engine.

## Requirements

| Requirement | Minimum |
|---|---|
| iOS | 18.0 |
| Flutter | 3.29.0 |
| Dart | 3.8.0 |
| Xcode | 16.0 |

> **Note:** `CalculateImageAestheticsScoresRequest` does **not** work on the iOS Simulator. You must test on a physical device.

## Installation

```yaml
dependencies:
  apple_vision_aesthetics: ^1.0.0
```

## Quick Start

```dart
import 'package:apple_vision_aesthetics/apple_vision_aesthetics.dart';

final plugin = AppleVisionAestheticsPlatform.instance;

// Check device support
final supported = await plugin.isSupported();

// Analyze an image file
final result = await plugin.analyzeFile('/path/to/photo.jpg');

print(result.overallScore); // -1.0 to 1.0
print(result.isUtility);    // true for screenshots, receipts, etc.
print(result.isLowQuality()); // convenience: true if score < -0.25
```

## API Reference

### `ImageAestheticsResult`

| Property | Type | Description |
|---|---|---|
| `overallScore` | `double` | Quality score from -1.0 (worst) to 1.0 (best) |
| `isUtility` | `bool` | `true` for screenshots, receipts, documents |
| `isLowQuality({threshold})` | `bool` | Convenience method, default threshold: -0.25 |

### `AppleVisionAestheticsPlatform`

| Method | Description |
|---|---|
| `analyzeFile(String path)` | Analyze image at file path |
| `analyzeBytes(Uint8List bytes)` | Analyze raw image bytes |
| `analyzeBatch(List<String> paths)` | Batch analyze multiple files |
| `isSupported()` | Check if device supports the API |

## Score Interpretation

| Range | Quality |
|---|---|
| `< -0.5` | Very poor (very blurry, badly exposed) |
| `-0.5 .. 0.0` | Below average |
| `0.0 .. 0.5` | Decent quality |
| `> 0.5` | High quality, memorable photo |

## Use with photo_manager

A common pattern is to combine this plugin with `photo_manager` to scan the user's photo library:

```dart
import 'package:photo_manager/photo_manager.dart';
import 'package:apple_vision_aesthetics/apple_vision_aesthetics.dart';

Future<List<AssetEntity>> findBlurryPhotos() async {
  final plugin = AppleVisionAestheticsPlatform.instance;
  final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
  final recent = await albums.first.getAssetListRange(start: 0, end: 100);

  final blurry = <AssetEntity>[];
  for (final asset in recent) {
    final file = await asset.file;
    if (file == null) continue;

    final result = await plugin.analyzeFile(file.path);
    if (result.isLowQuality()) {
      blurry.add(asset);
    }
  }
  return blurry;
}
```

## Testing

### Unit tests (Dart side)

```bash
flutter test
```

### Integration tests (requires physical iOS 18+ device)

The plugin ships with integration tests using images from the
[Kwentar/blur_dataset](https://github.com/Kwentar/blur_dataset) — 3 triplets
of sharp, defocused-blur, and motion-blur photos taken with real cameras.

```bash
cd example
flutter test integration_test/plugin_integration_test.dart
```

The integration tests verify that:
- Sharp images score higher than blurred ones
- `analyzeBytes` and `analyzeBatch` return consistent results
- Error handling works for invalid file paths

### Test fixtures

The `test/fixtures/` directory contains 9 images (3 triplets) from the
blur_dataset for local testing:

| File pattern | Type |
|---|---|
| `*_S.*` | Sharp |
| `*_F.*` | Defocused blur |
| `*_M.*` | Motion blur |

### Mocking in your own tests

```dart
class MockAesthetics extends AppleVisionAestheticsPlatform {
  @override
  Future<ImageAestheticsResult> analyzeFile(String path) async =>
    const ImageAestheticsResult(overallScore: 0.5, isUtility: false);

  // ... implement other methods
}

// In setUp:
AppleVisionAestheticsPlatform.instance = MockAesthetics();
```

## Limitations

- **iOS only** — Apple Vision framework is not available on Android
- **Physical device required** — the aesthetics model doesn't run on the Simulator
- **iOS 18.0+** — uses the new Swift Vision API from WWDC24
- **No macOS support yet** — contributions welcome!

## License

MIT — see [LICENSE](LICENSE) for details.
