//
//  Category.swift
//  SuperTV
//
//  Created by Omar Regalado on 12/08/26.
//

import Foundation

/// Categoría de contenido live (p. ej. "Deportes", "Noticias").
///
/// Modelo de dominio puro: sin dependencias de red ni de persistencia.
public struct ChannelCategory: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// Orden sugerido por el panel; útil para ordenar la lista tal como la ve el proveedor.
    public let displayOrder: Int

    public init(id: String, name: String, displayOrder: Int = 0) {
        self.id = id
        self.name = name
        self.displayOrder = displayOrder
    }
}
