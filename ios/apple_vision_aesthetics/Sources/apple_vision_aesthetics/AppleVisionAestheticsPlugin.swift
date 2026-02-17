import Flutter
import UIKit
import Vision

/// Flutter plugin that wraps Apple's Vision framework
/// `CalculateImageAestheticsScoresRequest` for image quality scoring.
///
/// Requires iOS 18.0+ (where the new Swift Vision API is available).
public class AppleVisionAestheticsPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "apple_vision_aesthetics",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppleVisionAestheticsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "analyzeFile":
            handleAnalyzeFile(call: call, result: result)
        case "analyzeBytes":
            handleAnalyzeBytes(call: call, result: result)
        case "analyzeBatch":
            handleAnalyzeBatch(call: call, result: result)
        case "isSupported":
            handleIsSupported(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleAnalyzeFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing filePath", details: nil))
            return
        }

        let url = URL(fileURLWithPath: filePath)

        guard let cgImage = loadCGImage(from: url) else {
            result(FlutterError(
                code: "IMAGE_LOAD_FAILED",
                message: "Could not load image from path: \(filePath)",
                details: nil
            ))
            return
        }

        analyzeImage(cgImage, result: result)
    }

    private func handleAnalyzeBytes(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let bytes = args["bytes"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing bytes", details: nil))
            return
        }

        guard let uiImage = UIImage(data: bytes.data),
              let cgImage = uiImage.cgImage else {
            result(FlutterError(
                code: "IMAGE_DECODE_FAILED",
                message: "Could not decode image from bytes",
                details: nil
            ))
            return
        }

        analyzeImage(cgImage, result: result)
    }

    private func handleAnalyzeBatch(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePaths = args["filePaths"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing filePaths", details: nil))
            return
        }

        if #available(iOS 18.0, *) {
            Task {
                var results: [[String: Any]] = []
                for path in filePaths {
                    let url = URL(fileURLWithPath: path)
                    guard let cgImage = self.loadCGImage(from: url) else {
                        result(FlutterError(
                            code: "IMAGE_LOAD_FAILED",
                            message: "Could not load image from path: \(path)",
                            details: nil
                        ))
                        return
                    }

                    do {
                        let observation = try await self.performAestheticsRequest(on: cgImage)
                        results.append([
                            "overallScore": observation.overallScore,
                            "isUtility": observation.isUtility
                        ])
                    } catch {
                        result(FlutterError(
                            code: "VISION_ERROR",
                            message: "Vision request failed for \(path): \(error.localizedDescription)",
                            details: nil
                        ))
                        return
                    }
                }
                result(results)
            }
        } else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "CalculateImageAestheticsScoresRequest requires iOS 18.0+",
                details: nil
            ))
        }
    }

    private func handleIsSupported(result: @escaping FlutterResult) {
        if #available(iOS 18.0, *) {
            result(true)
        } else {
            result(false)
        }
    }

    // MARK: - Vision Analysis

    private func analyzeImage(_ cgImage: CGImage, result: @escaping FlutterResult) {
        if #available(iOS 18.0, *) {
            Task {
                do {
                    let observation = try await performAestheticsRequest(on: cgImage)
                    result([
                        "overallScore": observation.overallScore,
                        "isUtility": observation.isUtility
                    ])
                } catch {
                    result(FlutterError(
                        code: "VISION_ERROR",
                        message: "Vision request failed: \(error.localizedDescription)",
                        details: "\(error)"
                    ))
                }
            }
        } else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "CalculateImageAestheticsScoresRequest requires iOS 18.0+",
                details: nil
            ))
        }
    }

    @available(iOS 18.0, *)
    private func performAestheticsRequest(
        on cgImage: CGImage
    ) async throws -> ImageAestheticsScoresObservation {
        let request = CalculateImageAestheticsScoresRequest()
        let observation = try await request.perform(on: cgImage)
        return observation
    }

    // MARK: - Helpers

    private func loadCGImage(from url: URL) -> CGImage? {
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else {
            return nil
        }
        return cgImage
    }
}
