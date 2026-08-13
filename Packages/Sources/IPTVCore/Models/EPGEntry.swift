import Foundation

/// Entrada de la guía de programación electrónica (EPG) para un canal.
public struct EPGEntry: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let channelID: Int
    public let title: String
    public let description: String
    public let start: Date
    public let end: Date

    public init(
        id: String,
        channelID: Int,
        title: String,
        description: String,
        start: Date,
        end: Date
    ) {
        self.id = id
        self.channelID = channelID
        self.title = title
        self.description = description
        self.start = start
        self.end = end
    }

    /// `true` si el programa está emitiéndose en `date` (por defecto, ahora).
    public func isLive(at date: Date = .now) -> Bool {
        (start...end).contains(date)
    }
}
