import Testing
import Foundation
import ComposableArchitecture
import IPTVCore
@testable import IPTVFeatures

@MainActor
@Suite("SettingsFeature")
struct SettingsFeatureTests {
    private let status = AccountStatus(
        state: .active,
        expiresAt: Date(timeIntervalSince1970: 2_000_000_000),
        isTrial: false,
        activeConnections: 1,
        maxConnections: 2
    )

    @Test("limpiar caché muestra progreso y confirma")
    func clearsCache() async {
        let store = TestStore(initialState: SettingsFeature.State(account: .demo, status: status)) {
            SettingsFeature()
        } withDependencies: {
            $0.channelRepository = MockChannelRepository()
        }

        await store.send(.clearCacheTapped) {
            $0.isClearingCache = true
            $0.cacheCleared = false
        }
        await store.receive(\.cacheCleared) {
            $0.isClearingCache = false
            $0.cacheCleared = true
        }
    }

    @Test("cerrar sesión delega al padre")
    func logoutDelegates() async {
        let store = TestStore(initialState: SettingsFeature.State(account: .demo, status: status)) {
            SettingsFeature()
        }
        store.exhaustivity = .off

        await store.send(.logoutTapped)
        await store.receive(\.delegate)
    }
}
