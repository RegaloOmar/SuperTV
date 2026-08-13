import Foundation
import SwiftData
import IPTVCore

/// Acceso a la caché SwiftData aislado en un actor (seguro bajo Swift 6 concurrency).
///
/// Guarda todas las categorías y todos los canales de una cuenta; el filtrado por
/// categoría lo hace el repositorio en memoria (una sola descarga de red).
@ModelActor
actor SwiftDataChannelCache {

    // MARK: - Categorías

    func loadCategories(accountKey: String) throws -> (items: [ChannelCategory], cachedAt: Date?) {
        let descriptor = FetchDescriptor<CachedCategory>(
            predicate: #Predicate { $0.accountKey == accountKey },
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        let rows = try modelContext.fetch(descriptor)
        return (rows.map { $0.toDomain() }, rows.map(\.cachedAt).max())
    }

    func replaceCategories(_ categories: [ChannelCategory], accountKey: String, cachedAt: Date) throws {
        try modelContext.delete(model: CachedCategory.self, where: #Predicate { $0.accountKey == accountKey })
        for category in categories {
            modelContext.insert(
                CachedCategory(
                    id: category.id,
                    name: category.name,
                    displayOrder: category.displayOrder,
                    accountKey: accountKey,
                    cachedAt: cachedAt
                )
            )
        }
        try modelContext.save()
    }

    // MARK: - Canales

    func loadChannels(accountKey: String) throws -> (items: [Channel], cachedAt: Date?) {
        let descriptor = FetchDescriptor<CachedChannel>(
            predicate: #Predicate { $0.accountKey == accountKey },
            sortBy: [SortDescriptor(\.name)]
        )
        let rows = try modelContext.fetch(descriptor)
        return (rows.map { $0.toDomain() }, rows.map(\.cachedAt).max())
    }

    func replaceChannels(_ channels: [Channel], accountKey: String, cachedAt: Date) throws {
        try modelContext.delete(model: CachedChannel.self, where: #Predicate { $0.accountKey == accountKey })
        for channel in channels {
            modelContext.insert(
                CachedChannel(
                    id: channel.id,
                    name: channel.name,
                    categoryID: channel.categoryID,
                    logoURLString: channel.logoURL?.absoluteString,
                    channelNumber: channel.channelNumber,
                    epgChannelID: channel.epgChannelID,
                    accountKey: accountKey,
                    cachedAt: cachedAt
                )
            )
        }
        try modelContext.save()
    }

    // MARK: - Limpieza

    func clearAll() throws {
        try modelContext.delete(model: CachedCategory.self)
        try modelContext.delete(model: CachedChannel.self)
        try modelContext.save()
    }
}
