## 1.0.1

- Add Swift Package Manager support
- Add pub.dev badges to README
- Shorten package description to meet pub.dev requirements

## 1.0.0

- Initial release
- `analyzeFile` — analyze image at file path
- `analyzeBytes` — analyze raw image bytes
- `analyzeBatch` — batch analyze multiple files
- `isSupported` — check device compatibility
- `ImageAestheticsResult` with `overallScore`, `isUtility`, and `isLowQuality()`
- Wraps Apple Vision `CalculateImageAestheticsScoresRequest` (iOS 18.0+)
