import SwiftUI
import UIKit

/// Wraps `UIActivityViewController` for sharing files via the system share sheet.
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {
    }
}
