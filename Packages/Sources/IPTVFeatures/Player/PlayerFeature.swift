import ComposableArchitecture
import Foundation
import IPTVCore
import IPTVPlayerKit

/// Reproducción de un canal. Resuelve el stream, arranca el motor, refleja su estado
/// y reintenta automáticamente (backoff simple) ante fallos.
@Reducer
public struct PlayerFeature {
    private static let maxRetries = 3

    @ObservableState
    public struct State: Equatable {
        public let channel: Channel
        public let account: IPTVAccount
        public var playback: PlaybackState = .idle
        public var retryCount = 0

        public init(channel: Channel, account: IPTVAccount) {
            self.channel = channel
            self.account = account
        }

        public var isBuffering: Bool {
            switch playback {
            case .loading, .buffering, .reconnecting: return true
            default: return false
            }
        }

        public var isPlaying: Bool { playback == .playing }

        public var errorMessage: String? {
            if case let .failed(error) = playback { return error.errorDescription }
            return nil
        }
    }

    public enum Action {
        case task
        case onDisappear
        case playbackStateChanged(PlaybackState)
        case playPauseTapped
        case retryTapped
        case reconnect
        case closeButtonTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case dismiss
        }
    }

    @Dependency(\.playableStreamProvider) var streamProvider
    @Dependency(\.playerEngine) var engine
    @Dependency(\.continuousClock) var clock

    public init() {}

    private enum CancelID { case session }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.retryCount = 0
                return startPlayback(state: &state, isReconnect: false)

            case .onDisappear:
                return .merge(
                    .cancel(id: CancelID.session),
                    .run { [engine] _ in engine.stop() }
                )

            case .closeButtonTapped:
                return .send(.delegate(.dismiss))

            case let .playbackStateChanged(newState):
                state.playback = newState
                switch newState {
                case .playing:
                    state.retryCount = 0
                    return .none
                case .failed:
                    guard state.retryCount < Self.maxRetries else { return .none }
                    state.retryCount += 1
                    let backoff = state.retryCount  // 1s, 2s, 3s
                    return .run { [clock] send in
                        try await clock.sleep(for: .seconds(backoff))
                        await send(.reconnect)
                    }
                    .cancellable(id: CancelID.session)
                default:
                    return .none
                }

            case .playPauseTapped:
                let isPlaying = state.isPlaying
                return .run { [engine] _ in
                    isPlaying ? engine.pause() : engine.play()
                }

            case .retryTapped:
                state.retryCount = 0
                return startPlayback(state: &state, isReconnect: false)

            case .reconnect:
                return startPlayback(state: &state, isReconnect: true)

            case .delegate:
                return .none
            }
        }
    }

    private func startPlayback(state: inout State, isReconnect: Bool) -> Effect<Action> {
        state.playback = isReconnect ? .reconnecting(attempt: state.retryCount) : .loading
        let channel = state.channel
        let account = state.account
        return .run { [engine, streamProvider] send in
            let stream: LiveStream
            do {
                stream = try streamProvider.stream(for: channel, account: account)
            } catch {
                await send(.playbackStateChanged(.failed(.streamUnavailable)))
                return
            }
            let states = engine.stateStream()
            engine.load(stream, title: channel.name)
            engine.play()
            for await playbackState in states {
                await send(.playbackStateChanged(playbackState))
            }
        }
        .cancellable(id: CancelID.session, cancelInFlight: true)
    }
}
