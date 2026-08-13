import Foundation
import AVFoundation
import IPTVCore
import IPTVPlayerKit

/// Proveedor de stream de prueba: resuelve una URL fija, o lanza si `error != nil`.
struct MockStreamProvider: PlayableStreamProviding {
    var error: IPTVError?
    func stream(for channel: Channel, account: IPTVAccount) throws -> LiveStream {
        if let error { throw error }
        return LiveStream(channelID: channel.id, url: URL(string: "http://demo.tv/stream.m3u8")!, container: .hls)
    }
}

/// Motor de reproducción de prueba (sin reproducción real; el flujo de estados
/// se controla desde el test enviando `.playbackStateChanged`).
final class MockPlayerEngine: PlayerEngine, @unchecked Sendable {
    let avPlayer = AVPlayer()
    func stateStream() -> AsyncStream<PlaybackState> { AsyncStream { $0.finish() } }
    func load(_ stream: LiveStream, title: String) {}
    func play() {}
    func pause() {}
    func stop() {}
    func setVolume(_ volume: Float) {}
}

/// Repositorio de catálogo de prueba con resultados fijos.
struct MockChannelRepository: ChannelRepositoryProtocol {
    var categoriesResult: Result<[ChannelCategory], IPTVError> = .success([])
    var channelsResult: Result<[Channel], IPTVError> = .success([])

    func categories(for account: IPTVAccount, forceRefresh: Bool) async throws -> [ChannelCategory] {
        try categoriesResult.get()
    }
    func channels(for account: IPTVAccount, categoryID: String?, forceRefresh: Bool) async throws -> [Channel] {
        try channelsResult.get()
    }
    func clearCache() async throws {}
}

extension IPTVAccount {
    static let demo = IPTVAccount(
        host: URL(string: "http://demo.tv:8080")!,
        username: "user",
        password: "pass"
    )
}
