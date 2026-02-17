## 1.0.0

- Initial release
- `analyzeFile` — analyze image at file path
- `analyzeBytes` — analyze raw image bytes
- `analyzeBatch` — batch analyze multiple files
- `isSupported` — check device compatibility
- `ImageAestheticsResult` with `overallScore`, `isUtility`, and `isLowQuality()`
- Wraps Apple Vision `CalculateImageAestheticsScoresRequest` (iOS 18.0+)
