import Foundation
import IPTVCore

/// Construcción de URLs del API de Xtream Codes (`player_api.php`).
///
/// Aislado para poder testear el armado de URLs sin tocar la red.
enum XtreamCodesEndpoint {
    /// URL base de `player_api.php` con credenciales.
    static func playerAPI(
        account: IPTVAccount,
        action: String? = nil,
        queryItems: [URLQueryItem] = []
    ) -> URL? {
        guard var components = URLComponents(url: account.host, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.path = "/player_api.php"
        var items = [
            URLQueryItem(name: "username", value: account.username),
            URLQueryItem(name: "password", value: account.password),
        ]
        if let action {
            items.append(URLQueryItem(name: "action", value: action))
        }
        items.append(contentsOf: queryItems)
        components.queryItems = items
        return components.url
    }

    /// URL reproducible de un canal live: `<host>/live/<user>/<pass>/<stream_id>.<ext>`.
    static func liveStream(
        account: IPTVAccount,
        streamID: Int,
        container: LiveStream.Container
    ) -> URL? {
        account.host
            .appendingPathComponent("live")
            .appendingPathComponent(account.username)
            .appendingPathComponent(account.password)
            .appendingPathComponent("\(streamID).\(container.rawValue)")
    }
}
