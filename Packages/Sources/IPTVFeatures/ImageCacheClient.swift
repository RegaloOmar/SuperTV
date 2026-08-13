import Dependencies
import IPTVDesignSystem

/// Dependencia fina sobre la caché de imágenes, para poder limpiarla desde las
/// features (Settings) de forma testeable (se sustituye por un doble en tests).
public struct ImageCacheClient: Sendable {
    public var clear: @Sendable () -> Void

    public init(clear: @escaping @Sendable () -> Void) {
        self.clear = clear
    }
}

extension ImageCacheClient: DependencyKey {
    public static let liveValue = ImageCacheClient(clear: { ImageCache.shared.clear() })
    public static let testValue = ImageCacheClient(clear: {})
}

public extension DependencyValues {
    var imageCache: ImageCacheClient {
        get { self[ImageCacheClient.self] }
        set { self[ImageCacheClient.self] = newValue }
    }
}
