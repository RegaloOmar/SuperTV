import ComposableArchitecture
import Foundation
import IPTVCore

/// Listado de canales de una categoría. Cache-first, refrescable y con búsqueda
/// por nombre. Al tocar un canal, delega la reproducción al padre (Fase 3).
@Reducer
public struct ChannelsFeature {
    @ObservableState
    public struct State: Equatable {
        public let account: IPTVAccount
        public let category: ChannelCategory
        public var channels: [Channel] = []
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var searchText: String = ""
        public var hasLoaded: Bool = false

        public init(account: IPTVAccount, category: ChannelCategory) {
            self.account = account
            self.category = category
        }

        public var filteredChannels: [Channel] {
            guard !searchText.isEmpty else { return channels }
            return channels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onTask
        case refresh
        case channelsResponse(Result<[Channel], IPTVError>)
        case channelTapped(Channel)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case channelSelected(Channel, account: IPTVAccount)
        }
    }

    @Dependency(\.channelRepository) var repository

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onTask:
                guard !state.hasLoaded else { return .none }
                state.hasLoaded = true
                return load(state: &state, forceRefresh: false)

            case .refresh:
                return load(state: &state, forceRefresh: true)

            case let .channelsResponse(.success(channels)):
                state.isLoading = false
                state.errorMessage = nil
                state.channels = channels
                return .none

            case let .channelsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.errorDescription
                return .none

            case let .channelTapped(channel):
                return .send(.delegate(.channelSelected(channel, account: state.account)))

            case .delegate:
                return .none
            }
        }
    }

    private func load(state: inout State, forceRefresh: Bool) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        let account = state.account
        let categoryID = state.category.id
        return .run { [repository] send in
            do {
                let channels = try await repository.channels(for: account, categoryID: categoryID, forceRefresh: forceRefresh)
                await send(.channelsResponse(.success(channels)))
            } catch let error as IPTVError {
                await send(.channelsResponse(.failure(error)))
            } catch {
                await send(.channelsResponse(.failure(.unknown(reason: error.localizedDescription))))
            }
        }
    }
}
