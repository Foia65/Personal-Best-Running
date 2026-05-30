import SwiftUI
import AVKit

struct SplashVideoView: UIViewControllerRepresentable {
    let videoName: String
    let videoType: String
    var onVideoEnd: () -> Void

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        // Trova il file video nel bundle
        guard let path = Bundle.main.path(forResource: videoName, ofType: videoType) else {
            print("Video non trovato")
            return controller
        }
        
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        controller.player = player
        controller.showsPlaybackControls = false // Nasconde i tasti play/pausa
        controller.videoGravity = .resizeAspectFill // Riempie lo schermo
        
        // Ascolta la fine del video per triggerare il cambio schermata
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

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
