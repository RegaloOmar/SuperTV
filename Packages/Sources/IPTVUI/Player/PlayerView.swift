import SwiftUI
import IPTVFeatures
import AVKit
import ComposableArchitecture
import IPTVCore
import IPTVPlayerKit
import IPTVDesignSystem

/// Pantalla de reproducción. La superficie de vídeo usa controles nativos
/// (play/pausa, volumen, fullscreen, PiP); el overlay TCA cubre carga/reconexión/error.
public struct PlayerView: View {
    let store: StoreOf<PlayerFeature>
    @Dependency(\.playerEngine) private var engine

    public init(store: StoreOf<PlayerFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Presentado a pantalla completa (fullScreenCover): AVKit ocupa toda la
            // pantalla y gestiona sus controles nativos (incluida la X de cierre) y la
            // rotación. Al cerrar con la X nativa, el cover se descarta y AppFeature
            // para el motor (`.player(.dismiss)`).
            VideoSurface(player: engine.avPlayer)
                .ignoresSafeArea()

            overlay
        }
        #if os(iOS)
        .statusBarHidden(true)
        #endif
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
            .background(.ultraThinMaterial)
        } else if store.isBuffering {
            VStack(spacing: DesignTokens.Spacing.md) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                if case let .reconnecting(attempt) = store.playback {
                    Text("Reconectando… (intento \(attempt))")
                        .font(.callout)
                        .foregroundStyle(.white)
                }
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Superficie de vídeo (nativa por plataforma)

#if os(iOS)
private struct VideoSurface: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.delegate = context.coordinator
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player {
            controller.player = player
        }
    }

    // OJO: no hacer `controller.player = nil` en dismantle. SwiftUI desmonta/re-crea
    // esta vista al cambiar de estado o al entrar en pantalla completa, y eso cortaba
    // el stream/audio. El motor es compartido y lo para AppFeature al salir de verdad.

    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        // Al volver de pantalla completa a incrustado, el sistema a veces pausa;
        // reanudamos al terminar la transición para que el stream no se corte.
        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
        ) {
            coordinator.animate(alongsideTransition: nil) { _ in
                playerViewController.player?.play()
            }
        }
    }
}
#else
private struct VideoSurface: View {
    let player: AVPlayer
    var body: some View { VideoPlayer(player: player) }
}
#endif
