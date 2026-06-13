import SwiftUI
import AVKit

/// Wraps `AVPlayerViewController` to display a full-screen splash video.
/// Calls `onVideoEnd` when playback finishes.
struct SplashVideoView: UIViewControllerRepresentable {
    let videoName: String
    let videoType: String
    var onVideoEnd: () -> Void

    func makeUIViewController(context _: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        guard let path = Bundle.main.path(forResource: videoName, ofType: videoType) else {
            print("Video not found")
            return controller
        }

        let player = AVPlayer(url: URL(fileURLWithPath: path))
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            onVideoEnd()
        }
        
        player.play()
        return controller
    }

    func updateUIViewController(_: AVPlayerViewController, context _: Context) {}
}
