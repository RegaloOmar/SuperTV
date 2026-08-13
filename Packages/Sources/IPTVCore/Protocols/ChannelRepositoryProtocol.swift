import Dependencies

/// Repositorio de catálogo con estrategia cache-first. Decide cuándo servir de la
/// caché local y cuándo refrescar contra el proveedor. Las Features hablan con esto,
/// nunca con la red directamente.
public protocol ChannelRepositoryProtocol: Sendable {
    /// Categorías live, sirviendo de caché salvo que `forceRefresh` sea `true`
    /// o la caché esté vencida (política interna, p. ej. 6h).
    func categories(for account: IPTVAccount, forceRefresh: Bool) async throws -> [ChannelCategory]
    /// Canales de una categoría (o todos si `categoryID` es `nil`).
    func channels(for account: IPTVAccount, categoryID: String?, forceRefresh: Bool) async throws -> [Channel]
    /// Vacía la caché local (Settings → limpiar caché).
    func clearCache() async throws
}

// MARK: - Inyección de dependencia (interfaz)

public enum ChannelRepositoryKey: TestDependencyKey {
    public static var testValue: any ChannelRepositoryProtocol {
        UnimplementedChannelRepository()
    }
}

public extension DependencyValues {
    var channelRepository: any ChannelRepositoryProtocol {
        get { self[ChannelRepositoryKey.self] }
        set { self[ChannelRepositoryKey.self] = newValue }
    }
}

struct UnimplementedChannelRepository: ChannelRepositoryProtocol {
    func categories(for account: IPTVAccount, forceRefresh: Bool) async throws -> [ChannelCategory] {
        throw IPTVError.notImplemented
    }
    func channels(for account: IPTVAccount, categoryID: String?, forceRefresh: Bool) async throws -> [Channel] {
        throw IPTVError.notImplemented
    }
    func clearCache() async throws {
        throw IPTVError.notImplemented
    }
}
