import Foundation
import SwiftData
import Dependencies
import IPTVCore

/// Repositorio de catálogo cache-first.
///
/// Política: si la caché es fresca (< `ttl`) y no se fuerza refresco, se sirve local.
/// Si no, se pide a la red y se reemplaza la caché. Si la red falla pero hay caché,
/// se sirve la caché (modo offline).
public struct LiveChannelRepository: ChannelRepositoryProtocol {
    private let cache: SwiftDataChannelCache
    private let ttl: TimeInterval

    @Dependency(\.iptvProvider) private var provider
    @Dependency(\.date) private var date

    // Interno a propósito: `SwiftDataChannelCache` es un detalle de implementación.
    // El repositorio se construye vía el `liveValue` de este módulo.
    init(cache: SwiftDataChannelCache, ttl: TimeInterval = 6 * 60 * 60) {
        self.cache = cache
        self.ttl = ttl
    }

    private func isFresh(_ cachedAt: Date?) -> Bool {
        guard let cachedAt else { return false }
        return date.now.timeIntervalSince(cachedAt) < ttl
    }

    public func categories(for account: IPTVAccount, forceRefresh: Bool) async throws -> [ChannelCategory] {
        let key = account.cacheKey
        let cached = try await cache.loadCategories(accountKey: key)

        if !forceRefresh, !cached.items.isEmpty, isFresh(cached.cachedAt) {
            return cached.items
        }

        do {
            let fresh = try await provider.liveCategories(for: account)
            try await cache.replaceCategories(fresh, accountKey: key, cachedAt: date.now)
            return fresh
        } catch {
            if !cached.items.isEmpty { return cached.items }  // offline fallback
            throw error
        }
    }

    public func channels(for account: IPTVAccount, categoryID: String?, forceRefresh: Bool) async throws -> [Channel] {
        let key = account.cacheKey
        let cached = try await cache.loadChannels(accountKey: key)

        func filtered(_ all: [Channel]) -> [Channel] {
            guard let categoryID else { return all }
            return all.filter { $0.categoryID == categoryID }
        }

        if !forceRefresh, !cached.items.isEmpty, isFresh(cached.cachedAt) {
            return filtered(cached.items)
        }

        do {
            // Una sola descarga de todos los streams; el filtrado por categoría es local.
            let all = try await provider.liveStreams(for: account, categoryID: nil)
            try await cache.replaceChannels(all, accountKey: key, cachedAt: date.now)
            return filtered(all)
        } catch {
            if !cached.items.isEmpty { return filtered(cached.items) }  // offline fallback
            throw error
        }
    }

    public func clearCache() async throws {
        try await cache.clearAll()
    }
}

// MARK: - Registro del liveValue (Dependency Inversion)

extension ChannelRepositoryKey: DependencyKey {
    public static var liveValue: any ChannelRepositoryProtocol {
        // Contenedor SwiftData persistente en disco. Si falla la creación (caso
        // extremo), se cae a un contenedor en memoria para no bloquear la app.
        let container: ModelContainer
        do {
            container = try ModelContainer(for: CachedCategory.self, CachedChannel.self)
        } catch {
            container = try! ModelContainer(
                for: CachedCategory.self, CachedChannel.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
        return LiveChannelRepository(cache: SwiftDataChannelCache(modelContainer: container))
    }
}
