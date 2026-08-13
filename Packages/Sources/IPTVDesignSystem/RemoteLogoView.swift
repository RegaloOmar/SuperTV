import SwiftUI

/// Logo remoto (de canal) con placeholder y tamaño fijo. Reutilizable en listas.
///
/// Usa `AsyncImage`, que descarga vía `URLSession.shared` → `URLCache.shared`
/// (configurado con capacidad amplia en el arranque de la app para cachear logos).
public struct RemoteLogoView: View {
    let url: URL?
    let size: CGFloat

    public init(url: URL?, size: CGFloat = 44) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .empty where url != nil:
                ProgressView()
            default:
                Image(systemName: "tv")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .background(.quinary, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        .accessibilityHidden(true) // Decorativo: el nombre del canal ya lo lee VoiceOver.
    }
}
