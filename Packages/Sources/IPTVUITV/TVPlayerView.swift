#if os(tvOS)
import SwiftUI
import AVKit
import ComposableArchitecture
import IPTVFeatures
import IPTVPlayerKit
import IPTVDesignSystem

/// Reproductor de tvOS: `AVPlayerViewController` nativo (transporte con el mando).
/// El botón Menu del mando descarta el cover → AppFeature para el motor.
struct TVPlayerView: View {
    let store: StoreOf<PlayerFeature>
    @Dependency(\.playerEngine) private var engine

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TVVideoSurface(player: engine.avPlayer).ignoresSafeArea()
            overlay
        }
        .task { await store.send(.task).finish() }
    }

    @ViewBuilder
    private var overlay: some View {
        if let errorMessage = store.errorMessage {
            StatusView(
                systemImage: "exclamationmark.triangle.fill",
                title: "No se pudo reproducir",
                message: errorMessage,
                action: .init(title: "Reintentar") { store.send(.retryTapped) }
            )
            .background(.black.opacity(0.6))
        } else if store.isBuffering {
            ProgressView().controlSize(.large).tint(.white)
        }
    }
}

private struct TVVideoSurface: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player {
            controller.player = player
        }
    }
}
#endif
