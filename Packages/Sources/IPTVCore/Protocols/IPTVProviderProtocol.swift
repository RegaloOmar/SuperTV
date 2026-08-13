import Dependencies

/// Proveedor de catálogo y autenticación contra un panel IPTV (Xtream Codes).
///
/// Interface Segregation: solo describe *obtener datos del panel*. La reproducción
/// y la caché viven en protocolos aparte.
public protocol IPTVProviderProtocol: Sendable {
    /// Valida credenciales contra `player_api.php` y devuelve el estado de la cuenta.
    func authenticate(_ account: IPTVAccount) async throws -> AccountStatus
    /// `get_live_categories`.
    func liveCategories(for account: IPTVAccount) async throws -> [ChannelCategory]
    /// `get_live_streams` (opcionalmente filtrado por categoría).
    func liveStreams(for account: IPTVAccount, categoryID: String?) async throws -> [Channel]
}

// MARK: - Inyección de dependencia (interfaz)
//
// El `liveValue` se define en `IPTVNetworking` (Dependency Inversion): Core no conoce
// la implementación concreta, solo su forma. `testValue` falla ruidosamente si un test
// usa el proveedor sin sustituirlo.

public enum IPTVProviderKey: TestDependencyKey {
    public static var testValue: any IPTVProviderProtocol {
        UnimplementedIPTVProvider()
    }
}

public extension DependencyValues {
    var iptvProvider: any IPTVProviderProtocol {
        get { self[IPTVProviderKey.self] }
        set { self[IPTVProviderKey.self] = newValue }
    }
}

/// Implementación por defecto para tests/previews que no deberían tocar el proveedor real.
struct UnimplementedIPTVProvider: IPTVProviderProtocol {
    func authenticate(_ account: IPTVAccount) async throws -> AccountStatus {
        throw IPTVError.notImplemented
    }
    func liveCategories(for account: IPTVAccount) async throws -> [ChannelCategory] {
        throw IPTVError.notImplemented
    }
    func liveStreams(for account: IPTVAccount, categoryID: String?) async throws -> [Channel] {
        throw IPTVError.notImplemented
    }
}
