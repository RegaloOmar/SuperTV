import ComposableArchitecture
import Foundation
import IPTVCore

/// Listado de categorías live de la cuenta. Carga cache-first, permite refrescar y
/// buscar por nombre. Al tocar una categoría, delega la navegación al padre.
@Reducer
public struct ChannelListFeature {
    @ObservableState
    public struct State: Equatable {
        public let account: IPTVAccount
        public var categories: [ChannelCategory] = []
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var searchText: String = ""
        /// Evita recargar en cada aparición (solo la primera carga automática).
        public var hasLoaded: Bool = false

        public init(account: IPTVAccount) {
            self.account = account
        }

        public var filteredCategories: [ChannelCategory] {
            guard !searchText.isEmpty else { return categories }
            return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onTask
        case refresh
        case categoriesResponse(Result<[ChannelCategory], IPTVError>)
        case categoryTapped(ChannelCategory)
        case settingsButtonTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case categorySelected(ChannelCategory, account: IPTVAccount)
            case settingsRequested
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
                return load(account: state.account, forceRefresh: false, state: &state)

            case .refresh:
                return load(account: state.account, forceRefresh: true, state: &state)

            case let .categoriesResponse(.success(categories)):
                state.isLoading = false
                state.errorMessage = nil
                state.categories = categories
                return .none

            case let .categoriesResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.errorDescription
                return .none

            case let .categoryTapped(category):
                return .send(.delegate(.categorySelected(category, account: state.account)))

            case .settingsButtonTapped:
                return .send(.delegate(.settingsRequested))

            case .delegate:
                return .none
            }
        }
    }

    private func load(account: IPTVAccount, forceRefresh: Bool, state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        return .run { [repository] send in
            do {
                let categories = try await repository.categories(for: account, forceRefresh: forceRefresh)
                await send(.categoriesResponse(.success(categories)))
            } catch let error as IPTVError {
                await send(.categoriesResponse(.failure(error)))
            } catch {
                await send(.categoriesResponse(.failure(.unknown(reason: error.localizedDescription))))
            }
        }
    }
}
