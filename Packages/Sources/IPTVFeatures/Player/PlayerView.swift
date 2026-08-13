import SwiftUI
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

            VideoSurface(player: engine.avPlayer)
                .ignoresSafeArea()

            overlay
        }
        .navigationTitle(store.channel.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { await store.send(.task).finish() }
        .onDisappear { store.send(.onDisappear) }
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
            .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
    }
}

// MARK: - Superficie de vídeo (nativa por plataforma)

#if os(iOS)
private struct VideoSurface: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
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

    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: ()) {
        // Suelta el player compartido al salir de la pantalla (evita retención).
        controller.player = nil
    }
}
#else
private struct VideoSurface: View {
    let player: AVPlayer
    var body: some View { VideoPlayer(player: player) }
}
#endif
