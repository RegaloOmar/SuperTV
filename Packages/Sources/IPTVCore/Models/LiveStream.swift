import Foundation

/// Un stream reproducible resuelto para un canal concreto.
///
/// Separado de `Channel` a propósito: la URL reproducible se construye a partir
/// de las credenciales de la cuenta + el `stream_id`, y no forma parte del catálogo.
public struct LiveStream: Equatable, Hashable, Sendable {
    public enum Container: String, Sendable {
        case hls = "m3u8"
        case ts
        case mp4
    }

    public let channelID: Int
    public let url: URL
    public let container: Container

    public init(channelID: Int, url: URL, container: Container) {
        self.channelID = channelID
        self.url = url
        self.container = container
    }
}
