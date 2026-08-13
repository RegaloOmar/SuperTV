import Foundation

/// Cuenta de un panel Xtream Codes. Las credenciales viven aquí en dominio,
/// pero su *almacenamiento* seguro (Keychain) es responsabilidad de otra capa.
public struct IPTVAccount: Equatable, Hashable, Sendable, Codable {
    public let host: URL
    public let username: String
    public let password: String

    public init(host: URL, username: String, password: String) {
        self.host = host
        self.username = username
        self.password = password
    }

    /// Clave estable para segmentar la caché local por cuenta (host + usuario).
    public var cacheKey: String {
        "\(host.absoluteString)|\(username)"
    }
}

/// Información de la cuenta que devuelve el panel tras autenticar.
/// Xtream Codes la expone y es valiosa mostrarla al usuario (Fase 4 / Settings).
public struct AccountStatus: Equatable, Hashable, Sendable {
    public enum State: String, Sendable {
        case active = "Active"
        case expired = "Expired"
        case banned = "Banned"
        case disabled = "Disabled"
        case unknown
    }

    public let state: State
    public let expiresAt: Date?
    public let isTrial: Bool
    public let activeConnections: Int
    public let maxConnections: Int

    public init(
        state: State,
        expiresAt: Date?,
        isTrial: Bool,
        activeConnections: Int,
        maxConnections: Int
    ) {
        self.state = state
        self.expiresAt = expiresAt
        self.isTrial = isTrial
        self.activeConnections = activeConnections
        self.maxConnections = maxConnections
    }
}
