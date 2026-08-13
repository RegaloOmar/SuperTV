import Testing
import Foundation
import IPTVCore
@testable import IPTVNetworking

@Suite("Construcción de URLs Xtream Codes")
struct XtreamCodesEndpointTests {
    let account = IPTVAccount(
        host: URL(string: "http://demo.tv:8080")!,
        username: "user",
        password: "pass"
    )

    @Test("player_api incluye credenciales y acción")
    func playerAPIURL() throws {
        let url = try #require(
            XtreamCodesEndpoint.playerAPI(account: account, action: "get_live_categories")
        )
        let string = url.absoluteString
        #expect(string.contains("/player_api.php"))
        #expect(string.contains("username=user"))
        #expect(string.contains("password=pass"))
        #expect(string.contains("action=get_live_categories"))
    }

    @Test("URL de stream live respeta el esquema <host>/live/<user>/<pass>/<id>.<ext>")
    func liveStreamURL() throws {
        let url = try #require(
            XtreamCodesEndpoint.liveStream(account: account, streamID: 55, container: .hls)
        )
        #expect(url.absoluteString == "http://demo.tv:8080/live/user/pass/55.m3u8")
    }
}
