import Foundation
import CryptoKit
import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#else
import AppKit
public typealias PlatformImage = NSImage
#endif

/// Caché de imágenes de tres niveles para los logos de canal:
/// 1. **Memoria** (`NSCache`, diccionario clave→imagen, búsqueda O(1)).
/// 2. **Disco** (un archivo por URL en Caches) → carga instantánea al reabrir la app.
/// 3. **Red** (descarga y guarda en 1 y 2).
///
/// `NSCache` en vez de un `Dictionary` porque es thread-safe y se auto-vacía bajo
/// presión de memoria (miles de logos no deben agotar la RAM).
public final class ImageCache: @unchecked Sendable {
    public static let shared = ImageCache()

    private let memory = NSCache<NSURL, PlatformImage>()
    private let directory: URL
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
        memory.countLimit = 500

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("ChannelLogos", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Búsqueda O(1) SOLO en memoria (síncrona, sin tocar disco ni red).
    /// La vista la usa para pintar al instante si el logo ya está cacheado.
    public func memoryImage(for url: URL) -> PlatformImage? {
        memory.object(forKey: url as NSURL)
    }

    /// Devuelve la imagen: memoria → disco → red (descargando y guardando si hace falta).
    /// Se ejecuta fuera del hilo principal (método async no aislado).
    public func image(for url: URL) async -> PlatformImage? {
        if let cached = memory.object(forKey: url as NSURL) { return cached }

        // Disco
        let file = fileURL(for: url)
        if let data = try? Data(contentsOf: file), let image = PlatformImage(data: data) {
            memory.setObject(image, forKey: url as NSURL)
            return image
        }

        // Red
        guard
            let (data, response) = try? await session.data(from: url),
            (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true,
            let image = PlatformImage(data: data)
        else {
            return nil
        }
        memory.setObject(image, forKey: url as NSURL)
        try? data.write(to: file, options: .atomic)
        return image
    }

    /// Vacía la caché: memoria (NSCache) + carpeta de logos en disco.
    public func clear() {
        memory.removeAllObjects()
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Nombre de archivo estable y seguro derivado de la URL (hash SHA-256).
    private func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name)
    }
}

extension Image {
    /// Inicializa una `Image` de SwiftUI desde la imagen nativa de cada plataforma.
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}
