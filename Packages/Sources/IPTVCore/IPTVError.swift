import Foundation

/// Errores de dominio compartidos por toda la app. Las capas concretas
/// (red, persistencia) mapean sus errores a este tipo para que las Features
/// no dependan de detalles de implementación.
public enum IPTVError: Error, Equatable, Sendable {
    case invalidCredentials
    case accountExpired
    case network(reason: String)
    case decoding(reason: String)
    case streamUnavailable
    case notImplemented
    case unknown(reason: String)
}

extension IPTVError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Incorrect username or password."
        case .accountExpired:
            return "Your subscription has expired."
        case .network(let reason):
            return "Connection error: \(reason)"
        case .decoding(let reason):
            return "Unexpected server response: \(reason)"
        case .streamUnavailable:
            return "This channel isn't available right now."
        case .notImplemented:
            return "Feature not implemented."
        case .unknown(let reason):
            return reason
        }
    }
}
