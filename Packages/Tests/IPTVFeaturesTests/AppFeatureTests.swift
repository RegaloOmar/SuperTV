import Testing
import Foundation
import ComposableArchitecture
import IPTVCore
@testable import IPTVFeatures

@MainActor
@Suite("AppFeature — navegación")
struct AppFeatureTests {
    private let account = IPTVAccount(
        host: URL(string: "http://demo.tv:8080")!,
        username: "user",
        password: "pass"
    )
    private let category = ChannelCategory(id: "1", name: "Deportes")

    @Test("seleccionar una categoría empuja la pantalla de canales")
    func categorySelectionPushesChannels() async {
        var initial = AppFeature.State()
        initial.channelList = ChannelListFeature.State(account: account)

        let store = TestStore(initialState: initial) {
            AppFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.channelList(.delegate(.categorySelected(category, account: account)))) {
            $0.path.append(.channels(ChannelsFeature.State(account: self.account, category: self.category)))
        }
    }

    @Test("pop vacía la pila de navegación")
    func popClearsStack() async {
        var initial = AppFeature.State()
        initial.path.append(.channels(ChannelsFeature.State(account: account, category: category)))

        let store = TestStore(initialState: initial) {
            AppFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.path(.popFrom(id: 0))) {
            $0.path.removeAll()
        }
    }
}
