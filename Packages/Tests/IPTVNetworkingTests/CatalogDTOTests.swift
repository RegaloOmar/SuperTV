import Testing
import Foundation
import IPTVCore
@testable import IPTVNetworking

@Suite("Decodificación del catálogo Xtream")
struct CatalogDTOTests {
    @Test("get_live_categories mapea a dominio con orden")
    func categories() throws {
        let json = """
        [
          {"category_id":"1","category_name":"Deportes","parent_id":0},
          {"category_id":"2","category_name":"Noticias","parent_id":0}
        ]
        """.data(using: .utf8)!

        let dtos = try JSONDecoder().decode([CategoryDTO].self, from: json)
        let domain = dtos.enumerated().map { $0.element.toDomain(displayOrder: $0.offset) }

        #expect(domain.count == 2)
        #expect(domain[0] == ChannelCategory(id: "1", name: "Deportes", displayOrder: 0))
        #expect(domain[1].displayOrder == 1)
    }

    @Test("get_live_streams tolera tipos inconsistentes y logos vacíos")
    func streams() throws {
        let json = """
        [
          {
            "num": 1, "name": "ESPN", "stream_id": 100,
            "stream_icon": "http://logo/espn.png",
            "epg_channel_id": "espn.us", "category_id": "1"
          },
          {
            "num": "2", "name": "Fox", "stream_id": "101",
            "stream_icon": "", "epg_channel_id": null, "category_id": 1
          }
        ]
        """.data(using: .utf8)!

        let channels = try JSONDecoder().decode([LiveStreamDTO].self, from: json).map { $0.toDomain() }

        #expect(channels.count == 2)
        // Primer canal: todo bien formado.
        #expect(channels[0] == Channel(
            id: 100, name: "ESPN", categoryID: "1",
            logoURL: URL(string: "http://logo/espn.png"),
            channelNumber: 1, epgChannelID: "espn.us"
        ))
        // Segundo: num/stream_id como String, category_id numérico, logo vacío → nil.
        #expect(channels[1].id == 101)
        #expect(channels[1].channelNumber == 2)
        #expect(channels[1].categoryID == "1")
        #expect(channels[1].logoURL == nil)
        #expect(channels[1].epgChannelID == nil)
    }
}
