import Foundation
import IPTVCore

/// `get_live_categories` devuelve un array de estos objetos.
struct CategoryDTO: Decodable {
    let categoryID: String
    let categoryName: String

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case categoryName = "category_name"
    }

    func toDomain(displayOrder: Int) -> ChannelCategory {
        ChannelCategory(id: categoryID, name: categoryName, displayOrder: displayOrder)
    }
}
