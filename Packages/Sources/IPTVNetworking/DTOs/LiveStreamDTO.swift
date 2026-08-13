import Foundation
import IPTVCore

/// `get_live_streams` devuelve un array de estos objetos.
///
/// Xtream Codes es inconsistente: `stream_id`/`num` a veces llegan como número y a
/// veces como String; `category_id` puede ser String, número o `null`. Por eso el
/// decoding es tolerante.
struct LiveStreamDTO: Decodable {
    let streamID: Int
    let num: Int?
    let name: String
    let streamIcon: String?
    let epgChannelID: String?
    let categoryID: String?

    enum CodingKeys: String, CodingKey {
        case streamID = "stream_id"
        case num
        case name
        case streamIcon = "stream_icon"
        case epgChannelID = "epg_channel_id"
        case categoryID = "category_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        streamID = try c.lenientInt(forKey: .streamID) ?? 0
        num = try c.lenientInt(forKey: .num)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        streamIcon = try? c.decode(String.self, forKey: .streamIcon)
        epgChannelID = c.lenientString(forKey: .epgChannelID)
        categoryID = c.lenientString(forKey: .categoryID)
    }

    func toDomain() -> Channel {
        Channel(
            id: streamID,
            name: name,
            categoryID: categoryID ?? "",
            logoURL: streamIcon.flatMap { $0.isEmpty ? nil : URL(string: $0) },
            channelNumber: num,
            epgChannelID: epgChannelID.flatMap { $0.isEmpty ? nil : $0 }
        )
    }
}

private extension KeyedDecodingContainer {
    /// Decodifica un entero aceptando también String numérica; `nil` si falta o es null.
    func lenientInt(forKey key: Key) throws -> Int? {
        if let value = try? decode(Int.self, forKey: key) { return value }
        if let string = try? decode(String.self, forKey: key) { return Int(string) }
        return nil
    }

    /// Decodifica una String aceptando también número; `nil` si falta, es null o vacía tras trim.
    func lenientString(forKey key: Key) -> String? {
        if let value = try? decode(String.self, forKey: key) { return value }
        if let int = try? decode(Int.self, forKey: key) { return String(int) }
        return nil
    }
}
