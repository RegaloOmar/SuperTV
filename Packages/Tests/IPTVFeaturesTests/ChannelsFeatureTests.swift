import Testing
import Foundation
import ComposableArchitecture
import IPTVCore
@testable import IPTVFeatures

@MainActor
@Suite("ChannelsFeature")
struct ChannelsFeatureTests {
    private let category = ChannelCategory(id: "1", name: "Deportes")
    private let channels = [
        Channel(id: 10, name: "ESPN", categoryID: "1"),
        Channel(id: 11, name: "Fox Sports", categoryID: "1"),
    ]

    private func state() -> ChannelsFeature.State {
        ChannelsFeature.State(account: .demo, category: category)
    }

    @Test("onTask carga los canales de la categoría")
    func loadsChannels() async {
        let store = TestStore(initialState: state()) {
            ChannelsFeature()
        } withDependencies: {
            $0.channelRepository = MockChannelRepository(channelsResult: .success(channels))
        }

        await store.send(.onTask) {
            $0.hasLoaded = true
            $0.isLoading = true
        }
        await store.receive(\.channelsResponse) {
            $0.isLoading = false
            $0.channels = self.channels
        }
    }

    @Test("la búsqueda filtra por nombre de canal")
    func searchFilters() async {
        let store = TestStore(initialState: state()) {
            ChannelsFeature()
        } withDependencies: {
            $0.channelRepository = MockChannelRepository(channelsResult: .success(channels))
        }
        store.exhaustivity = .off

        await store.send(.onTask)
        await store.receive(\.channelsResponse)
        await store.send(.set(\.searchText, "fox"))

        #expect(store.state.filteredChannels == [Channel(id: 11, name: "Fox Sports", categoryID: "1")])
    }

    @Test("tocar un canal delega la reproducción")
    func channelTapDelegates() async {
        let store = TestStore(initialState: state()) {
            ChannelsFeature()
        } withDependencies: {
            $0.channelRepository = MockChannelRepository(channelsResult: .success(channels))
        }
        store.exhaustivity = .off

        await store.send(.channelTapped(channels[0]))
        await store.receive(\.delegate)
    }
}
