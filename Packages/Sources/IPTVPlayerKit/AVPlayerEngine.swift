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

    /// Ejecuta en el hilo principal. Todas las mutaciones de `avPlayer` deben pasar por
    /// aquí: hay un `AVPlayerViewController` enganchado que reacciona haciendo *layout*,
    /// y UIKit prohíbe tocar el motor de layout desde un hilo en segundo plano.
    private func onMain(_ work: @escaping @Sendable () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
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
        yield(.loading)

        onMain { [weak self] in
            guard let self else { return }
            self.avPlayer.isMuted = false
            self.avPlayer.volume = 1.0

            let item = AVPlayerItem(url: stream.url)
            self.statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                if item.status == .failed {
                    self?.yield(.failed(.streamUnavailable))
                }
            }
            self.avPlayer.replaceCurrentItem(with: item)

            self.timeControlObservation = self.avPlayer.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
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

            self.updateNowPlaying()
        }
    }

    public func play() {
        onMain { [weak self] in
            self?.avPlayer.play()
            self?.updateNowPlaying()
        }
    }

    public func pause() {
        onMain { [weak self] in self?.avPlayer.pause() }
    }

    public func stop() {
        // Cierra el flujo primero para que el `for await` del reducer termine ya.
        lock.withLock {
            continuation?.finish()
            continuation = nil
        }
        onMain { [weak self] in
            guard let self else { return }
            self.avPlayer.pause()
            self.avPlayer.replaceCurrentItem(with: nil)
            // Invalida los observers KVO (evita callbacks colgando).
            self.statusObservation = nil
            self.timeControlObservation = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }

    deinit {
        statusObservation = nil
        timeControlObservation = nil
        lock.withLock { continuation?.finish() }
    }

    public func setVolume(_ volume: Float) {
        onMain { [weak self] in self?.avPlayer.volume = volume }
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
