import ComposableArchitecture
import Foundation
import IPTVCore

/// Ajustes: info de la cuenta (expiración, conexiones), limpiar caché y cerrar sesión.
@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public let account: IPTVAccount
        public let status: AccountStatus
        public var isClearingCache = false
        public var cacheCleared = false

        public init(account: IPTVAccount, status: AccountStatus) {
            self.account = account
            self.status = status
        }
    }

    public enum Action {
        case clearCacheTapped
        case cacheCleared
        case logoutTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case logoutRequested
        }
    }

    @Dependency(\.channelRepository) var repository
    @Dependency(\.imageCache) var imageCache

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .clearCacheTapped:
                state.isClearingCache = true
                state.cacheCleared = false
                return .run { [repository, imageCache] send in
                    imageCache.clear()                 // logos (memoria + disco)
                    try? await repository.clearCache()  // catálogo (SwiftData)
                    await send(.cacheCleared)
                }

            case .cacheCleared:
                state.isClearingCache = false
                state.cacheCleared = true
                return .none

            case .logoutTapped:
                return .send(.delegate(.logoutRequested))

            case .delegate:
                return .none
            }
        }
    }
}
