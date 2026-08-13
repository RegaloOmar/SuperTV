import Foundation
import Dependencies
import IPTVCore

/// Cliente HTTP contra un panel Xtream Codes. Implementa el protocolo de dominio
/// `IPTVProviderProtocol`; el resto de la app solo conoce ese protocolo.
public struct XtreamCodesClient: IPTVProviderProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Autenticación (Fase 1)

    public func authenticate(_ account: IPTVAccount) async throws -> AccountStatus {
        guard let url = XtreamCodesEndpoint.playerAPI(account: account) else {
            throw IPTVError.network(reason: "URL de host inválida.")
        }
        let response: AuthResponseDTO = try await get(url)
        guard let userInfo = response.userInfo, userInfo.isAuthenticated else {
            throw IPTVError.invalidCredentials
        }
        let status = userInfo.toDomain()
        if status.state == .expired {
            throw IPTVError.accountExpired
        }
        return status
    }

    // MARK: - Catálogo (Fase 2)

    public func liveCategories(for account: IPTVAccount) async throws -> [ChannelCategory] {
        guard let url = XtreamCodesEndpoint.playerAPI(account: account, action: "get_live_categories") else {
            throw IPTVError.network(reason: "URL de host inválida.")
        }
        let dtos: [CategoryDTO] = try await get(url)
        return dtos.enumerated().map { $0.element.toDomain(displayOrder: $0.offset) }
    }

    public func liveStreams(for account: IPTVAccount, categoryID: String?) async throws -> [Channel] {
        let query = categoryID.map { [URLQueryItem(name: "category_id", value: $0)] } ?? []
        guard let url = XtreamCodesEndpoint.playerAPI(account: account, action: "get_live_streams", queryItems: query) else {
            throw IPTVError.network(reason: "URL de host inválida.")
        }
        let dtos: [LiveStreamDTO] = try await get(url)
        return dtos.map { $0.toDomain() }
    }

    // MARK: - HTTP

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw IPTVError.network(reason: "Respuesta no HTTP.")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw IPTVError.network(reason: "HTTP \(http.statusCode).")
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw IPTVError.decoding(reason: error.localizedDescription)
            }
        } catch let error as IPTVError {
            throw error
        } catch {
            throw IPTVError.network(reason: error.localizedDescription)
        }
    }
}

// MARK: - Registro del liveValue (Dependency Inversion)
//
// Core declaró `IPTVProviderKey: TestDependencyKey`. Aquí, en la capa de red,
// le damos su implementación real sin que Core conozca este tipo.

extension IPTVProviderKey: DependencyKey {
    public static var liveValue: any IPTVProviderProtocol {
        XtreamCodesClient()
    }
}
