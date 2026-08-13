import Testing
import Foundation
import ComposableArchitecture
import IPTVCore
import IPTVPlayerKit
@testable import IPTVFeatures

@MainActor
@Suite("PlayerFeature")
struct PlayerFeatureTests {
    private let channel = Channel(id: 1, name: "ESPN", categoryID: "1")

    private func state(retryCount: Int = 0) -> PlayerFeature.State {
        var state = PlayerFeature.State(channel: channel, account: .demo)
        state.retryCount = retryCount
        return state
    }

    @Test("empezar a reproducir resetea los reintentos")
    func playingResetsRetries() async {
        let store = TestStore(initialState: state(retryCount: 2)) {
            PlayerFeature()
        }

        await store.send(.playbackStateChanged(.playing)) {
            $0.playback = .playing
            $0.retryCount = 0
        }
    }

    @Test("un fallo programa una reconexión con backoff")
    func failureSchedulesReconnect() async {
        let clock = TestClock()
        let store = TestStore(initialState: state()) {
            PlayerFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.playerEngine = MockPlayerEngine()
            $0.playableStreamProvider = MockStreamProvider()
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.playbackStateChanged(.failed(.streamUnavailable))) {
            $0.playback = .failed(.streamUnavailable)
            $0.retryCount = 1
        }
        // El backoff es de 1s tras el primer fallo.
        await clock.advance(by: .seconds(1))
        await store.receive(\.reconnect) {
            $0.playback = .reconnecting(attempt: 1)
        }

        await store.send(.onDisappear)
    }

    @Test("agotados los reintentos, un fallo ya no reconecta")
    func stopsAfterMaxRetries() async {
        let store = TestStore(initialState: state(retryCount: 3)) {
            PlayerFeature()
        }

        // retryCount ya está en el máximo (3): no incrementa ni programa reconexión.
        await store.send(.playbackStateChanged(.failed(.streamUnavailable))) {
            $0.playback = .failed(.streamUnavailable)
        }
    }
}
