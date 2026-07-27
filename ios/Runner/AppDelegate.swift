import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ライブテキスト対応のUIImageViewプラットフォームビューを登録
    let registrar = self.registrar(forPlugin: "LiveTextImageView")!
    let factory = LiveTextImageViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "live_text_image_view")

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "noesis_flutter/audio_editing",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(FlutterError(code: "unavailable", message: "AppDelegate unavailable", details: nil))
          return
        }
        switch call.method {
        case "mergeAudioSegments":
          guard
            let args = call.arguments as? [String: Any],
            let inputPaths = args["inputPaths"] as? [String],
            let outputPath = args["outputPath"] as? String
          else {
            result(FlutterError(code: "bad_args", message: "Invalid merge args", details: nil))
            return
          }
          self.mergeAudioSegments(inputPaths: inputPaths, outputPath: outputPath, result: result)
        case "trimAudio":
          guard
            let args = call.arguments as? [String: Any],
            let inputPath = args["inputPath"] as? String,
            let outputPath = args["outputPath"] as? String,
            let startSeconds = args["startSeconds"] as? Double,
            let endSeconds = args["endSeconds"] as? Double
          else {
            result(FlutterError(code: "bad_args", message: "Invalid trim args", details: nil))
            return
          }
          self.trimAudio(
            inputPath: inputPath,
            outputPath: outputPath,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            result: result
          )
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func mergeAudioSegments(
    inputPaths: [String],
    outputPath: String,
    result: @escaping FlutterResult
  ) {
    guard !inputPaths.isEmpty else {
      result(FlutterError(code: "empty_input", message: "No input segments", details: nil))
      return
    }

    let composition = AVMutableComposition()
    guard let track = composition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid
    ) else {
      result(FlutterError(code: "track_error", message: "Failed to create audio track", details: nil))
      return
    }

    var cursor = CMTime.zero
    do {
      for path in inputPaths {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        guard let sourceTrack = try awaitTrack(for: asset) else {
          continue
        }
        let range = CMTimeRange(start: .zero, duration: asset.duration)
        try track.insertTimeRange(range, of: sourceTrack, at: cursor)
        cursor = cursor + asset.duration
      }
    } catch {
      result(FlutterError(code: "merge_failed", message: error.localizedDescription, details: nil))
      return
    }

    exportComposition(composition, outputPath: outputPath, result: result)
  }

  private func trimAudio(
    inputPath: String,
    outputPath: String,
    startSeconds: Double,
    endSeconds: Double,
    result: @escaping FlutterResult
  ) {
    let asset = AVURLAsset(url: URL(fileURLWithPath: inputPath))
    let composition = AVMutableComposition()
    guard let sourceTrack = awaitTrack(for: asset),
          let outputTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
          ) else {
      result(FlutterError(code: "track_error", message: "Failed to prepare trim track", details: nil))
      return
    }

    let start = CMTime(seconds: startSeconds, preferredTimescale: 600)
    let end = CMTime(seconds: endSeconds, preferredTimescale: 600)
    let duration = CMTimeSubtract(end, start)

    guard duration > .zero else {
      result(FlutterError(code: "invalid_range", message: "Invalid trim range", details: nil))
      return
    }

    do {
      try outputTrack.insertTimeRange(
        CMTimeRange(start: start, duration: duration),
        of: sourceTrack,
        at: .zero
      )
    } catch {
      result(FlutterError(code: "trim_failed", message: error.localizedDescription, details: nil))
      return
    }

    exportComposition(composition, outputPath: outputPath, result: result)
  }

  private func exportComposition(
    _ composition: AVMutableComposition,
    outputPath: String,
    result: @escaping FlutterResult
  ) {
    let outputURL = URL(fileURLWithPath: outputPath)
    try? FileManager.default.removeItem(at: outputURL)

    guard let exporter = AVAssetExportSession(
      asset: composition,
      presetName: AVAssetExportPresetAppleM4A
    ) else {
      result(FlutterError(code: "exporter_error", message: "Failed to create exporter", details: nil))
      return
    }

    exporter.outputURL = outputURL
    exporter.outputFileType = .m4a
    exporter.exportAsynchronously {
      DispatchQueue.main.async {
        switch exporter.status {
        case .completed:
          result(outputPath)
        case .failed, .cancelled:
          result(
            FlutterError(
              code: "export_failed",
              message: exporter.error?.localizedDescription ?? "Audio export failed",
              details: nil
            )
          )
        default:
          result(
            FlutterError(code: "export_unknown", message: "Unexpected export status", details: nil)
          )
        }
      }
    }
  }

  private func awaitTrack(for asset: AVURLAsset) -> AVAssetTrack? {
    asset.tracks(withMediaType: .audio).first
  }
}
