/// A Flutter plugin wrapping Apple's Vision framework
/// `CalculateImageAestheticsScoresRequest` to score image quality,
/// detect blur, and identify utility images.
///
/// iOS 18.0+ required. Returns [UnsupportedError] on other platforms.
library;

export 'src/apple_vision_aesthetics_method_channel.dart';
export 'src/apple_vision_aesthetics_platform_interface.dart';
export 'src/image_aesthetics_result.dart';
