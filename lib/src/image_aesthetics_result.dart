/// Result of an image aesthetics analysis performed by Apple's Vision framework.
///
/// The Vision framework's `CalculateImageAestheticsScoresRequest` evaluates
/// multiple factors including blur, exposure, color balance, composition,
/// and subject matter to produce these scores.
class ImageAestheticsResult {
  /// Creates an [ImageAestheticsResult].
  const ImageAestheticsResult({
    required this.overallScore,
    required this.isUtility,
  });

  /// Creates an [ImageAestheticsResult] from a platform channel map.
  factory ImageAestheticsResult.fromMap(Map<String, dynamic> map) {
    return ImageAestheticsResult(
      overallScore: (map['overallScore'] as num).toDouble(),
      isUtility: map['isUtility'] as bool,
    );
  }

  /// The overall aesthetic quality score of the image.
  ///
  /// Ranges from **-1.0** (very low quality) to **1.0** (very high quality).
  ///
  /// Factors that influence this score include:
  /// - **Blur / sharpness** — out-of-focus images score lower
  /// - **Exposure** — over/under-exposed images score lower
  /// - **Color balance** — natural colors score higher
  /// - **Composition** — well-composed images score higher
  /// - **Subject matter** — memorable scenes score higher
  ///
  /// A rough guideline:
  /// - `< -0.5` — very poor quality (very blurry, badly exposed)
  /// - `-0.5 .. 0.0` — below average
  /// - `0.0 .. 0.5` — decent quality
  /// - `> 0.5` — high quality, memorable photo
  final double overallScore;

  /// Whether the image is classified as a "utility" image.
  ///
  /// Utility images are photos that may be technically well-taken but contain
  /// non-memorable content, such as:
  /// - Screenshots
  /// - Photos of receipts or documents
  /// - QR codes
  /// - Whiteboards
  ///
  /// This is useful for filtering out non-personal photos in a gallery cleaner.
  final bool isUtility;

  /// Convenience getter: `true` when [overallScore] is below the given
  /// [threshold] (default `-0.25`), indicating a likely blurry or
  /// low-quality image.
  bool isLowQuality({double threshold = -0.25}) => overallScore < threshold;

  /// Converts this result back to a map (useful for serialization).
  Map<String, dynamic> toMap() => {
        'overallScore': overallScore,
        'isUtility': isUtility,
      };

  @override
  String toString() =>
      'ImageAestheticsResult(overallScore: $overallScore, isUtility: $isUtility)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageAestheticsResult &&
          runtimeType == other.runtimeType &&
          overallScore == other.overallScore &&
          isUtility == other.isUtility;

  @override
  int get hashCode => overallScore.hashCode ^ isUtility.hashCode;
}
