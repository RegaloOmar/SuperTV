import Foundation
import SwiftData
import IPTVCore

/// Caché local de una categoría, segmentada por cuenta.
@Model
final class CachedCategory {
    var id: String
    var name: String
    var displayOrder: Int
    var accountKey: String
    var cachedAt: Date

    init(id: String, name: String, displayOrder: Int, accountKey: String, cachedAt: Date) {
        self.id = id
        self.name = name
        self.displayOrder = displayOrder
        self.accountKey = accountKey
        self.cachedAt = cachedAt
    }

    func toDomain() -> ChannelCategory {
        ChannelCategory(id: id, name: name, displayOrder: displayOrder)
    }
}

/// Caché local de un canal live, segmentada por cuenta.
@Model
final class CachedChannel {
    var id: Int
    var name: String
    var categoryID: String
    var logoURLString: String?
    var channelNumber: Int?
    var epgChannelID: String?
    var accountKey: String
    var cachedAt: Date

    init(
        id: Int,
        name: String,
        categoryID: String,
        logoURLString: String?,
        channelNumber: Int?,
        epgChannelID: String?,
        accountKey: String,
        cachedAt: Date
    ) {
        self.id = id
        self.name = name
        self.categoryID = categoryID
        self.logoURLString = logoURLString
        self.channelNumber = channelNumber
        self.epgChannelID = epgChannelID
        self.accountKey = accountKey
        self.cachedAt = cachedAt
    }

    func toDomain() -> Channel {
        Channel(
            id: id,
            name: name,
            categoryID: categoryID,
            logoURL: logoURLString.flatMap(URL.init(string:)),
            channelNumber: channelNumber,
            epgChannelID: epgChannelID
        )
    }
}
