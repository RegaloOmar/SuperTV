import Testing
import Foundation
import ComposableArchitecture
import IPTVCore
@testable import IPTVFeatures

@MainActor
@Suite("AppFeature — navegación y reproductor")
struct AppFeatureTests {
    private let account = IPTVAccount(
        host: URL(string: "http://demo.tv:8080")!,
        username: "user",
        password: "pass"
    )
    private let category = ChannelCategory(id: "1", name: "Deportes")
    private let channel = Channel(id: 10, name: "ESPN", categoryID: "1")

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

    @Test("seleccionar un canal presenta el reproductor a pantalla completa")
    func channelSelectionPresentsPlayer() async {
        var initial = AppFeature.State()
        initial.path.append(.channels(ChannelsFeature.State(account: account, category: category)))

        let store = TestStore(initialState: initial) {
            AppFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.path(.element(id: 0, action: .channels(.delegate(.channelSelected(channel, account: account)))))) {
            $0.player = PlayerFeature.State(channel: self.channel, account: self.account)
        }
    }

    @Test("cerrar el reproductor lo descarta")
    func dismissingPlayerClearsIt() async {
        var initial = AppFeature.State()
        initial.player = PlayerFeature.State(channel: channel, account: account)

        let store = TestStore(initialState: initial) {
            AppFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.player(.dismiss)) {
            $0.player = nil
        }
    }

    @Test("el botón de cerrar del reproductor descarta la presentación")
    func closeButtonDismissesPlayer() async {
        var initial = AppFeature.State()
        initial.player = PlayerFeature.State(channel: channel, account: account)

        let store = TestStore(initialState: initial) {
            AppFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.player(.presented(.closeButtonTapped)))
        await store.receive(\.player.dismiss) {
            $0.player = nil
        }
    }
}
