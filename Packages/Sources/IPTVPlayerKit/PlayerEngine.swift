import AVFoundation
import Dependencies
import IPTVCore

/// Estado de reproducción expuesto a las capas superiores, independiente del motor.
public enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case buffering
    case playing
    case paused
    case reconnecting(attempt: Int)
    case failed(IPTVError)
}

/// Abstracción del motor de reproducción (Open-Closed / Liskov).
///
/// Hoy lo implementa `AVPlayerEngine`; mañana un `VLCPlayerEngine` como fallback,
/// sin que `PlayerFeature` tenga que cambiar.
public protocol PlayerEngine: AnyObject, Sendable {
    /// Reproductor subyacente para la capa de vista (render / PiP).
    var avPlayer: AVPlayer { get }

    /// Crea un flujo de estados nuevo para esta sesión de reproducción.
    /// Cada llamada reemplaza al anterior (una sola sesión activa a la vez).
    func stateStream() -> AsyncStream<PlaybackState>

    func load(_ stream: LiveStream, title: String)
    func play()
    func pause()
    func stop()
    func setVolume(_ volume: Float)
}

// MARK: - Inyección de dependencia

public enum PlayerEngineKey: TestDependencyKey {
    public static var testValue: any PlayerEngine {
        UnimplementedPlayerEngine()
    }
}

public extension DependencyValues {
    var playerEngine: any PlayerEngine {
        get { self[PlayerEngineKey.self] }
        set { self[PlayerEngineKey.self] = newValue }
    }
}

/// Motor inerte para tests/previews que no deben tocar reproducción real.
public final class UnimplementedPlayerEngine: PlayerEngine, @unchecked Sendable {
    public let avPlayer = AVPlayer()
    public init() {}
    public func stateStream() -> AsyncStream<PlaybackState> { AsyncStream { $0.finish() } }
    public func load(_ stream: LiveStream, title: String) {}
    public func play() {}
    public func pause() {}
    public func stop() {}
    public func setVolume(_ volume: Float) {}
}
