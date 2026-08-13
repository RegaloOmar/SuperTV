import Foundation
import Dependencies

/// Almacén seguro de la cuenta del usuario. Las credenciales son sensibles, así que
/// su implementación real vive en Keychain (nunca UserDefaults).
///
/// Interface Segregation: solo persistencia de credenciales, nada de catálogo.
public protocol CredentialStoreProtocol: Sendable {
    /// Guarda (o reemplaza) la cuenta.
    func save(_ account: IPTVAccount) throws
    /// Devuelve la cuenta guardada, o `nil` si no hay sesión.
    func load() throws -> IPTVAccount?
    /// Borra la cuenta (logout).
    func delete() throws
}

// MARK: - Inyección de dependencia (interfaz)

public enum CredentialStoreKey: TestDependencyKey {
    public static var testValue: any CredentialStoreProtocol {
        UnimplementedCredentialStore()
    }
}

public extension DependencyValues {
    var credentialStore: any CredentialStoreProtocol {
        get { self[CredentialStoreKey.self] }
        set { self[CredentialStoreKey.self] = newValue }
    }
}

struct UnimplementedCredentialStore: CredentialStoreProtocol {
    func save(_ account: IPTVAccount) throws { throw IPTVError.notImplemented }
    func load() throws -> IPTVAccount? { throw IPTVError.notImplemented }
    func delete() throws { throw IPTVError.notImplemented }
}

/// Implementación en memoria para tests y previews (no toca Keychain).
public final class InMemoryCredentialStore: CredentialStoreProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: IPTVAccount?

    public init(_ initial: IPTVAccount? = nil) {
        self.stored = initial
    }

    public func save(_ account: IPTVAccount) throws {
        lock.withLock { stored = account }
    }

    public func load() throws -> IPTVAccount? {
        lock.withLock { stored }
    }

    public func delete() throws {
        lock.withLock { stored = nil }
    }
}
