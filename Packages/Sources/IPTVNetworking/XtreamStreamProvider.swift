import Foundation
import Dependencies
import IPTVCore

/// Resuelve un `Channel` a un `Stream` reproducible usando el esquema de URLs de Xtream.
public struct XtreamStreamProvider: PlayableStreamProviding {
    private let preferredContainer: LiveStream.Container

    /// HLS por defecto: es lo que AVPlayer reproduce de forma nativa y estable.
    public init(preferredContainer: LiveStream.Container = .hls) {
        self.preferredContainer = preferredContainer
    }

    public func stream(for channel: Channel, account: IPTVAccount) throws -> LiveStream {
        guard let url = XtreamCodesEndpoint.liveStream(
            account: account,
            streamID: channel.id,
            container: preferredContainer
        ) else {
            throw IPTVError.streamUnavailable
        }
        return LiveStream(channelID: channel.id, url: url, container: preferredContainer)
    }
}

// MARK: - Registro del liveValue (Dependency Inversion)

extension PlayableStreamProviderKey: DependencyKey {
    public static var liveValue: any PlayableStreamProviding {
        XtreamStreamProvider()
    }
}
