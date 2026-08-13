import Dependencies

/// Construye la URL reproducible de un canal a partir de la cuenta.
///
/// Interface Segregation: quien reproduce no necesita conocer el catálogo entero,
/// solo cómo resolver un `Channel` a un `Stream`.
public protocol PlayableStreamProviding: Sendable {
    func stream(for channel: Channel, account: IPTVAccount) throws -> LiveStream
}

// MARK: - Inyección de dependencia (interfaz)

public enum PlayableStreamProviderKey: TestDependencyKey {
    public static var testValue: any PlayableStreamProviding {
        UnimplementedPlayableStreamProvider()
    }
}

public extension DependencyValues {
    var playableStreamProvider: any PlayableStreamProviding {
        get { self[PlayableStreamProviderKey.self] }
        set { self[PlayableStreamProviderKey.self] = newValue }
    }
}

struct UnimplementedPlayableStreamProvider: PlayableStreamProviding {
    func stream(for channel: Channel, account: IPTVAccount) throws -> LiveStream {
        throw IPTVError.notImplemented
    }
}
