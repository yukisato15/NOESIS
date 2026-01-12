import Flutter
import UIKit
import VisionKit

class LiveTextImageViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return LiveTextImageView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class LiveTextImageView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var imageView: UIImageView
    private var scrollView: UIScrollView
    private var interaction: Any?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView(frame: frame)
        scrollView = UIScrollView(frame: frame)
        imageView = UIImageView()

        super.init()

        // UIScrollViewの設定
        scrollView.frame = _view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = self
        scrollView.backgroundColor = .clear

        // UIImageViewの設定
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true

        scrollView.addSubview(imageView)
        _view.addSubview(scrollView)

        // iOS 16以降でライブテキスト機能を有効化
        if #available(iOS 16.0, *) {
            Task { @MainActor in
                let interaction = ImageAnalysisInteraction()
                interaction.preferredInteractionTypes = [.automatic, .textSelection]
                self.imageView.addInteraction(interaction)
                self.interaction = interaction
            }
        }

        // 引数から画像パスを取得
        if let args = args as? [String: Any],
           let imagePath = args["imagePath"] as? String {
            // レイアウト完了後に画像を読み込む
            DispatchQueue.main.async {
                self.loadImage(path: imagePath)
            }
        }
    }

    func view() -> UIView {
        return _view
    }

    private func loadImage(path: String) {
        print("Loading image from path: \(path)")

        if let image = UIImage(contentsOfFile: path) {
            print("Image loaded successfully: \(image.size)")
            imageView.image = image

            // 画像サイズに合わせてimageViewのframeを設定
            let imageSize = image.size
            let scrollViewSize = scrollView.bounds.size

            print("ScrollView size: \(scrollViewSize)")

            // ScrollViewのサイズがまだ0の場合は後で再試行
            if scrollViewSize.width == 0 || scrollViewSize.height == 0 {
                print("ScrollView not laid out yet, retrying...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.loadImage(path: path)
                }
                return
            }

            let widthRatio = scrollViewSize.width / imageSize.width
            let heightRatio = scrollViewSize.height / imageSize.height
            let scale = min(widthRatio, heightRatio)

            let scaledWidth = imageSize.width * scale
            let scaledHeight = imageSize.height * scale

            imageView.frame = CGRect(
                x: 0,
                y: 0,
                width: scaledWidth,
                height: scaledHeight
            )

            scrollView.contentSize = CGSize(width: scaledWidth, height: scaledHeight)
            print("ImageView frame: \(imageView.frame)")
            print("ScrollView contentSize: \(scrollView.contentSize)")

            // iOS 16以降でライブテキスト解析を開始
            if #available(iOS 16.0, *),
               let interaction = self.interaction as? ImageAnalysisInteraction {
                Task { @MainActor in
                    do {
                        let analyzer = ImageAnalyzer()
                        let configuration = ImageAnalyzer.Configuration([.text])
                        let analysis = try await analyzer.analyze(image, configuration: configuration)
                        interaction.analysis = analysis
                    } catch {
                        print("Image analysis failed: \(error)")
                    }
                }
            }
        } else {
            print("Failed to load image from path: \(path)")
        }
    }
}

extension LiveTextImageView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // ズーム後に画像を中央に配置
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width * 0.5 + offsetX,
            y: scrollView.contentSize.height * 0.5 + offsetY
        )
    }
}
