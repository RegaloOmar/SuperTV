import Foundation
import AVFoundation
import MediaPlayer
import Dependencies
import IPTVCore

/// Motor de reproducción sobre AVPlayer.
///
/// Observa `timeControlStatus` (playing/buffering/paused) y `AVPlayerItem.status`
/// (fallo) para emitir `PlaybackState`. Integra sesión de audio y NowPlaying.
public final class AVPlayerEngine: PlayerEngine, @unchecked Sendable {
    public let avPlayer = AVPlayer()

    private let lock = NSLock()
    private var continuation: AsyncStream<PlaybackState>.Continuation?
    private var statusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var currentTitle = ""

    public init() {
        activateAudioSession()
        avPlayer.automaticallyWaitsToMinimizeStalling = true
    }

    /// Categoría `.playback`: reproduce aunque el interruptor de silencio esté activo,
    /// permite audio en segundo plano y Control Center. Se activa en cada carga por si
    /// otra parte del sistema (o AVPlayerViewController) cambió la sesión.
    private func activateAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback)
        try? session.setActive(true)
        #endif
    }

    private func yield(_ state: PlaybackState) {
        lock.withLock { continuation }?.yield(state)
    }

    public func stateStream() -> AsyncStream<PlaybackState> {
        let (stream, continuation) = AsyncStream<PlaybackState>.makeStream()
        lock.withLock {
            self.continuation?.finish()
            self.continuation = continuation
        }
        continuation.yield(.idle)
        return stream
    }

    public func load(_ stream: LiveStream, title: String) {
        currentTitle = title
        activateAudioSession()
        avPlayer.isMuted = false
        avPlayer.volume = 1.0
        yield(.loading)

        let item = AVPlayerItem(url: stream.url)
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            if item.status == .failed {
                self?.yield(.failed(.streamUnavailable))
            }
        }
        avPlayer.replaceCurrentItem(with: item)

        timeControlObservation = avPlayer.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            switch player.timeControlStatus {
            case .playing:
                self?.yield(.playing)
            case .waitingToPlayAtSpecifiedRate:
                self?.yield(.buffering)
            case .paused:
                self?.yield(.paused)
            @unknown default:
                break
            }
        }

        updateNowPlaying()
    }

    public func play() {
        avPlayer.play()
        updateNowPlaying()
    }

    public func pause() {
        avPlayer.pause()
    }

    public func stop() {
        avPlayer.pause()
        avPlayer.replaceCurrentItem(with: nil)
        // Invalida los observers KVO (evita callbacks colgando) y cierra el flujo.
        statusObservation = nil
        timeControlObservation = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        lock.withLock {
            continuation?.finish()
            continuation = nil
        }
    }

    deinit {
        statusObservation = nil
        timeControlObservation = nil
        lock.withLock { continuation?.finish() }
    }

    public func setVolume(_ volume: Float) {
        avPlayer.volume = volume
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = currentTitle
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = avPlayer.rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

// MARK: - Registro del liveValue (motor compartido: una reproducción a la vez)

extension PlayerEngineKey: DependencyKey {
    public static let liveValue: any PlayerEngine = AVPlayerEngine()
}
