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
            return "Usuario o contraseña incorrectos."
        case .accountExpired:
            return "Tu suscripción ha expirado."
        case .network(let reason):
            return "Error de conexión: \(reason)"
        case .decoding(let reason):
            return "Respuesta inesperada del servidor: \(reason)"
        case .streamUnavailable:
            return "Este canal no está disponible ahora mismo."
        case .notImplemented:
            return "Función no implementada."
        case .unknown(let reason):
            return reason
        }
    }
}
