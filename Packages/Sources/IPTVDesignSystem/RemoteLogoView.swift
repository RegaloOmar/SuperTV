import SwiftUI

/// Logo remoto (de canal) con placeholder y tamaño fijo. Reutilizable en listas.
///
/// Usa `ImageCache` (memoria → disco → red): al reabrir la lista, los logos ya
/// vistos cargan al instante desde memoria/disco, sin volver a descargarlos.
public struct RemoteLogoView: View {
    let url: URL?
    let size: CGFloat

    @State private var image: PlatformImage?
    @State private var didFail = false

    public init(url: URL?, size: CGFloat = 44) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        content
            .frame(width: size, height: size)
            .background(DesignTokens.Palette.surfaceElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            .accessibilityHidden(true) // Decorativo: el nombre del canal ya lo lee VoiceOver.
            .task(id: url) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            Image(platformImage: image)
                .resizable()
                .scaledToFit()
        } else if url != nil && !didFail {
            ProgressView()
        } else {
            Image(systemName: "tv")
                .resizable()
                .scaledToFit()
                .padding(size * 0.22)
                .foregroundStyle(DesignTokens.Palette.textSecondary)
        }
    }

    private func load() async {
        guard let url else {
            image = nil
            didFail = false
            return
        }
        // Camino rápido: si ya está en memoria (O(1)), pintar al instante sin async.
        if let cached = ImageCache.shared.memoryImage(for: url) {
            image = cached
            return
        }
        // Si no, disco → red (fuera del hilo principal).
        let loaded = await ImageCache.shared.image(for: url)
        image = loaded
        didFail = loaded == nil
    }
}
