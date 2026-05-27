import SwiftUI
import UIKit

/// Captures Siri Remote presses when playback controls are hidden (VideoPlayer otherwise steals focus).
struct PlaybackRemoteActivityBridge: UIViewControllerRepresentable {
    let isCapturing: Bool
    let onActivity: () -> Void

    func makeUIViewController(context: Context) -> RemoteActivityViewController {
        let controller = RemoteActivityViewController()
        controller.onActivity = onActivity
        return controller
    }

    func updateUIViewController(_ controller: RemoteActivityViewController, context: Context) {
        controller.onActivity = onActivity
        controller.isCapturing = isCapturing
        if isCapturing {
            controller.claimRemoteFocus()
        }
    }
}

final class RemoteActivityViewController: UIViewController {
    var onActivity: (() -> Void)?
    var isCapturing = false

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isCapturing {
            claimRemoteFocus()
        }
    }

    func claimRemoteFocus() {
        guard isCapturing else { return }
        DispatchQueue.main.async { [weak self] in
            _ = self?.becomeFirstResponder()
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if isCapturing {
            onActivity?()
        }
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if isCapturing {
            onActivity?()
        }
        super.pressesEnded(presses, with: event)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if isCapturing {
            onActivity?()
        }
        super.pressesCancelled(presses, with: event)
    }
}
