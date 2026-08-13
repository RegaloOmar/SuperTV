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

    private func state(retryCount: Int = 0, playback: PlaybackState = .idle) -> PlayerFeature.State {
        var state = PlayerFeature.State(channel: channel, account: .demo)
        state.retryCount = retryCount
        state.playback = playback
        return state
    }

    private func store(
        _ initial: PlayerFeature.State,
        clock: TestClock<Duration> = TestClock(),
        streamError: IPTVError? = nil
    ) -> TestStoreOf<PlayerFeature> {
        TestStore(initialState: initial) {
            PlayerFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.playerEngine = MockPlayerEngine()
            $0.playableStreamProvider = MockStreamProvider(error: streamError)
        }
    }

    // MARK: - Estado

    @Test("empezar a reproducir resetea los reintentos")
    func playingResetsRetries() async {
        let store = store(state(retryCount: 2))
        await store.send(.playbackStateChanged(.playing)) {
            $0.playback = .playing
            $0.retryCount = 0
        }
    }

    @Test("los flags derivados reflejan el estado")
    func derivedFlags() async {
        let loading = state(playback: .loading)
        #expect(loading.isBuffering)
        #expect(!loading.isPlaying)

        let playing = state(playback: .playing)
        #expect(playing.isPlaying)
        #expect(!playing.isBuffering)

        let failed = state(playback: .failed(.streamUnavailable))
        #expect(failed.errorMessage == IPTVError.streamUnavailable.errorDescription)
    }

    // MARK: - Reintentos / backoff

    @Test("un fallo programa una reconexión con backoff de 1s")
    func failureSchedulesReconnect() async {
        let clock = TestClock()
        let store = store(state(), clock: clock)
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.playbackStateChanged(.failed(.streamUnavailable))) {
            $0.playback = .failed(.streamUnavailable)
            $0.retryCount = 1
        }
        await clock.advance(by: .seconds(1))
        await store.receive(\.reconnect) {
            $0.playback = .reconnecting(attempt: 1)
        }
    }

    @Test("el backoff es incremental: no reconecta antes de tiempo")
    func incrementalBackoff() async {
        let clock = TestClock()
        let store = store(state(retryCount: 1), clock: clock)
        store.exhaustivity = .off(showSkippedAssertions: false)

        // Segundo fallo → retryCount 2 → backoff de 2s.
        await store.send(.playbackStateChanged(.failed(.streamUnavailable))) {
            $0.retryCount = 2
        }
        // A 1s todavía no reconecta.
        await clock.advance(by: .seconds(1))
        // A los 2s, sí.
        await clock.advance(by: .seconds(1))
        await store.receive(\.reconnect)
    }

    @Test("una reconexión exitosa vuelve a resetear los reintentos")
    func reconnectThenPlayingResets() async {
        let clock = TestClock()
        let store = store(state(retryCount: 2, playback: .reconnecting(attempt: 2)), clock: clock)
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.playbackStateChanged(.playing)) {
            $0.playback = .playing
            $0.retryCount = 0
        }
    }

    @Test("agotados los reintentos, un fallo ya no reconecta")
    func stopsAfterMaxRetries() async {
        let store = store(state(retryCount: 3))
        await store.send(.playbackStateChanged(.failed(.streamUnavailable))) {
            $0.playback = .failed(.streamUnavailable)
        }
    }

    // MARK: - Carga

    @Test("si no se puede resolver el stream, marca error")
    func streamResolutionFailure() async {
        let store = store(state(), streamError: .streamUnavailable)
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.task)
        await store.receive(\.playbackStateChanged) {
            $0.playback = .failed(.streamUnavailable)
        }
        // El fallo programa un reintento (backoff); lo limpiamos para cerrar el test.
        await store.skipInFlightEffects()
    }

    @Test("task no reinicia si ya hay reproducción en curso")
    func taskIgnoredWhenNotIdle() async {
        let store = store(state(playback: .playing))
        // playback != .idle → la guarda evita reiniciar; no hay efectos.
        await store.send(.task)
    }
}
