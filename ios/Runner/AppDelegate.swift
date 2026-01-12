import Flutter
import UIKit

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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
