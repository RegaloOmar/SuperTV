import Testing
import Foundation
@testable import IPTVCore

@Suite("Modelos de dominio")
struct DomainModelTests {
    @Test("EPGEntry.isLive detecta el programa en emisión")
    func epgIsLive() {
        let now = Date(timeIntervalSince1970: 1_000)
        let entry = EPGEntry(
            id: "1",
            channelID: 42,
            title: "Noticias",
            description: "",
            start: now.addingTimeInterval(-60),
            end: now.addingTimeInterval(60)
        )
        #expect(entry.isLive(at: now))
        #expect(!entry.isLive(at: now.addingTimeInterval(120)))
    }

    @Test("AccountStatus.State mapea strings desconocidos a .unknown")
    func unknownState() {
        #expect(AccountStatus.State(rawValue: "Active") == .active)
        #expect(AccountStatus.State(rawValue: "???") == nil)
    }
}
