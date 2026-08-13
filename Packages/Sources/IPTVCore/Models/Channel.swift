import Foundation

/// Canal live dentro de una categoría.
public struct Channel: Identifiable, Equatable, Hashable, Sendable {
    /// `stream_id` en Xtream Codes.
    public let id: Int
    public let name: String
    public let categoryID: String
    /// URL del logo del canal (`stream_icon`). Puede no existir.
    public let logoURL: URL?
    /// Número de canal asignado por el proveedor, si lo expone.
    public let channelNumber: Int?
    /// Identificador de EPG (`epg_channel_id`) para cruzar con la guía.
    public let epgChannelID: String?

    public init(
        id: Int,
        name: String,
        categoryID: String,
        logoURL: URL? = nil,
        channelNumber: Int? = nil,
        epgChannelID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.categoryID = categoryID
        self.logoURL = logoURL
        self.channelNumber = channelNumber
        self.epgChannelID = epgChannelID
    }
}
