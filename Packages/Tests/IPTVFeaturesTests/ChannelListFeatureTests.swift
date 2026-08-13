import Testing
import Foundation
import ComposableArchitecture
import IPTVCore
@testable import IPTVFeatures

@MainActor
@Suite("ChannelListFeature")
struct ChannelListFeatureTests {
    private let categories = [
        ChannelCategory(id: "1", name: "Deportes", displayOrder: 0),
        ChannelCategory(id: "2", name: "Noticias", displayOrder: 1),
    ]

    @Test("onTask carga categorías cache-first")
    func loadsCategories() async {
        let store = TestStore(initialState: ChannelListFeature.State(account: .demo)) {
            ChannelListFeature()
        } withDependencies: {
            $0.channelRepository = MockChannelRepository(categoriesResult: .success(categories))
        }

        await store.send(.onTask) {
            $0.hasLoaded = true
            $0.isLoading = true
        }
        await store.receive(\.categoriesResponse) {
            $0.isLoading = false
            $0.categories = self.categories
        }
    }

    @Test("la búsqueda filtra por nombre")
    func searchFilters() async {
        let store = TestStore(initialState: ChannelListFeature.State(account: .demo)) {
            ChannelListFeature()
        } withDependencies: {
            $0.channelRepository = MockChannelRepository(categoriesResult: .success(categories))
        }
        store.exhaustivity = .off

        await store.send(.onTask)
        await store.receive(\.categoriesResponse)
        await store.send(.set(\.searchText, "noti"))

        #expect(store.state.filteredCategories == [ChannelCategory(id: "2", name: "Noticias", displayOrder: 1)])
    }

    @Test("tocar una categoría delega la selección")
    func categoryTapDelegates() async {
        let store = TestStore(initialState: ChannelListFeature.State(account: .demo)) {
            ChannelListFeature()
        } withDependencies: {
            $0.channelRepository = MockChannelRepository(categoriesResult: .success(categories))
        }
        store.exhaustivity = .off

        await store.send(.categoryTapped(categories[0]))
        await store.receive(\.delegate)
    }

    @Test("error de red muestra mensaje")
    func showsError() async {
        let store = TestStore(initialState: ChannelListFeature.State(account: .demo)) {
            ChannelListFeature()
        } withDependencies: {
            $0.channelRepository = MockChannelRepository(categoriesResult: .failure(.network(reason: "timeout")))
        }

        await store.send(.onTask) {
            $0.hasLoaded = true
            $0.isLoading = true
        }
        await store.receive(\.categoriesResponse) {
            $0.isLoading = false
            $0.errorMessage = IPTVError.network(reason: "timeout").errorDescription
        }
    }
}
