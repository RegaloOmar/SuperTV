import Foundation
import IPTVCore

/// Respuesta de `player_api.php` sin acción: info de cuenta + servidor.
struct AuthResponseDTO: Decodable {
    let userInfo: UserInfoDTO?

    enum CodingKeys: String, CodingKey {
        case userInfo = "user_info"
    }
}

/// `user_info` de Xtream Codes. Los números llegan como String a veces, de ahí los helpers.
struct UserInfoDTO: Decodable {
    let auth: Int?
    let status: String?
    let expDate: String?
    let isTrial: String?
    let activeCons: String?
    let maxConnections: String?

    enum CodingKeys: String, CodingKey {
        case auth
        case status
        case expDate = "exp_date"
        case isTrial = "is_trial"
        case activeCons = "active_cons"
        case maxConnections = "max_connections"
    }

    /// Mapeo DTO → dominio. Aquí muere el detalle de Xtream Codes.
    func toDomain() -> AccountStatus {
        AccountStatus(
            state: AccountStatus.State(rawValue: status ?? "") ?? .unknown,
            expiresAt: expDate.flatMap { Double($0) }.map { Date(timeIntervalSince1970: $0) },
            isTrial: isTrial == "1",
            activeConnections: activeCons.flatMap { Int($0) } ?? 0,
            maxConnections: maxConnections.flatMap { Int($0) } ?? 0
        )
    }

    var isAuthenticated: Bool { auth == 1 }
}
