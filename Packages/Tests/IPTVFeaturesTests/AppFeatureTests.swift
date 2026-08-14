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

    // MARK: - Arranque / restauración de sesión

    @Test("con sesión guardada, arranca directo (sin login) en categorías")
    func launchWithStoredSession() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.credentialStore = InMemoryCredentialStore(account)
            $0.iptvProvider = MockIPTVProvider(authResult: .success(.demoActive))
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onLaunch)
        await store.receive(\.restoreFinished) {
            $0.isLaunching = false
            $0.session = .init(account: self.account, status: .demoActive)
            $0.channelList = ChannelListFeature.State(account: self.account)
        }
    }

    @Test("sin credenciales guardadas, arranca en el login")
    func launchWithoutCredentials() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.credentialStore = InMemoryCredentialStore()
            $0.iptvProvider = MockIPTVProvider()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onLaunch)
        await store.receive(\.restoreFinished) {
            $0.isLaunching = false
        }
        #expect(store.state.session == nil)
    }

    @Test("si el re-login falla, arranca en el login con los campos rellenos")
    func launchWithFailedReauth() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.credentialStore = InMemoryCredentialStore(account)
            $0.iptvProvider = MockIPTVProvider(authResult: .failure(.accountExpired))
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onLaunch)
        await store.receive(\.restoreFinished) {
            $0.isLaunching = false
            $0.auth.host = self.account.host.absoluteString
            $0.auth.username = self.account.username
            $0.auth.password = self.account.password
        }
        #expect(store.state.session == nil)
    }

    @Test("seleccionar una categoría abre sus canales (detalle)")
    func categorySelectionOpensChannels() async {
        var initial = AppFeature.State()
        initial.channelList = ChannelListFeature.State(account: account)

        let store = TestStore(initialState: initial) {
            AppFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.channelList(.delegate(.categorySelected(category, account: account)))) {
            $0.channels = ChannelsFeature.State(account: self.account, category: self.category)
        }
    }

    @Test("pedir ajustes presenta la hoja de Settings")
    func settingsRequestPresentsSheet() async {
        let status = AccountStatus.demoActive
        var initial = AppFeature.State()
        initial.session = .init(account: account, status: status)
        initial.channelList = ChannelListFeature.State(account: account)

        let store = TestStore(initialState: initial) {
            AppFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.channelList(.delegate(.settingsRequested))) {
            $0.settings = SettingsFeature.State(account: self.account, status: status)
        }
    }

    @Test("seleccionar un canal presenta el reproductor a pantalla completa")
    func channelSelectionPresentsPlayer() async {
        var initial = AppFeature.State()
        initial.channels = ChannelsFeature.State(account: account, category: category)

        let store = TestStore(initialState: initial) {
            AppFeature()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.channels(.presented(.delegate(.channelSelected(channel, account: account))))) {
            $0.player = PlayerFeature.State(channel: self.channel, account: self.account)
        }
    }

    @Test("logout desde Settings limpia la sesión")
    func logoutFromSettingsClearsSession() async {
        var initial = AppFeature.State()
        initial.session = .init(account: account, status: .demoActive)
        initial.channelList = ChannelListFeature.State(account: account)
        initial.settings = SettingsFeature.State(account: account, status: .demoActive)

        let store = TestStore(initialState: initial) {
            AppFeature()
        } withDependencies: {
            $0.credentialStore = InMemoryCredentialStore(account)
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.settings(.presented(.delegate(.logoutRequested))))
        #expect(store.state.session == nil)
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
}
