import Foundation
import Security
import Dependencies
import IPTVCore

/// Almacén de credenciales sobre Keychain (`kSecClassGenericPassword`).
///
/// Guarda una única cuenta como JSON cifrado por el sistema. Nunca UserDefaults:
/// las credenciales del panel son sensibles.
public struct KeychainCredentialStore: CredentialStoreProtocol {
    private let service: String
    private let accountKey: String

    public init(
        service: String = "com.regy.SuperTV.credentials",
        accountKey: String = "primary"
    ) {
        self.service = service
        self.accountKey = accountKey
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey,
        ]
    }

    public func save(_ account: IPTVAccount) throws {
        let data = try JSONEncoder().encode(account)

        // Reemplazo idempotente: borra el item previo y añade el nuevo.
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw IPTVError.unknown(reason: "Keychain: no se pudo guardar (OSStatus \(status)).")
        }
    }

    public func load() throws -> IPTVAccount? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw IPTVError.unknown(reason: "Keychain: no se pudo leer (OSStatus \(status)).")
        }
        return try JSONDecoder().decode(IPTVAccount.self, from: data)
    }

    public func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw IPTVError.unknown(reason: "Keychain: no se pudo borrar (OSStatus \(status)).")
        }
    }
}

// MARK: - Registro del liveValue (Dependency Inversion)

extension CredentialStoreKey: DependencyKey {
    public static var liveValue: any CredentialStoreProtocol {
        KeychainCredentialStore()
    }
}
