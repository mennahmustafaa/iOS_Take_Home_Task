import Foundation

// MARK: - API DTOs (DummyJSON contract)

/// Raw product payload from DummyJSON. Kept separate from domain models.
struct ProductDTO: Decodable {
    let id: Int?
    let title: String?
    let description: String?
    let category: String?
    let price: Double?
    let rating: Double?
    let stock: Int?
    let thumbnail: String?
    let images: [String]?
}

struct ProductListResponseDTO: Decodable {
    let products: [ProductDTO]?
    let total: Int?
    let skip: Int?
    let limit: Int?
}

// MARK: - Mapping

extension ProductDTO {
    func toDomain() -> ProductEntity {
        let gallery = (images ?? []).filter { !$0.isEmpty }
        let thumb = thumbnail?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let resolvedImage = !thumb.isEmpty ? thumb : (gallery.first ?? "")
        let titleValue = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let categoryValue = category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return ProductEntity(
            id: id ?? 0,
            title: titleValue.isEmpty ? "Untitled product" : titleValue,
            category: categoryValue.isEmpty ? "unknown" : categoryValue,
            price: price ?? 0,
            rating: rating ?? 0,
            stock: stock ?? 0,
            image: resolvedImage,
            images: gallery.isEmpty && !resolvedImage.isEmpty ? [resolvedImage] : gallery,
            description: description ?? ""
        )
    }
}

extension ProductListResponseDTO {
    func toDomain() -> ProductResponse {
        let mapped = (products ?? []).map { $0.toDomain() }
        return ProductResponse(
            products: mapped,
            total: total ?? mapped.count,
            skip: skip ?? 0,
            limit: limit ?? mapped.count
        )
    }
}

// MARK: - Local favourite snapshot DTO

/// Persisted favourite product so Saved remains usable offline with images.
struct FavouriteProductDTO: Codable, Identifiable, Hashable {
    var id: Int
    var title: String
    var category: String
    var price: Double
    var rating: Double
    var stock: Int
    var image: String
    var images: [String]
    var description: String

    init(from product: ProductEntity) {
        id = product.id
        title = product.title
        category = product.category
        price = product.price
        rating = product.rating
        stock = product.stock
        image = product.image
        images = product.images
        description = product.description
    }

    func toDomain() -> ProductEntity {
        ProductEntity(
            id: id,
            title: title,
            category: category,
            price: price,
            rating: rating,
            stock: stock,
            image: image,
            images: images,
            description: description
        )
    }
}

// MARK: - URL helpers

enum ImageURLFactory {
    /// Builds a URL even when the remote path contains characters like `'`.
    static func make(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let escaped = trimmed
            .replacingOccurrences(of: " ", with: "%20")
            .replacingOccurrences(of: "'", with: "%27")

        // Prefer escaped form when raw parsing fails or contains apostrophes.
        if trimmed.contains("'") {
            return URL(string: escaped)
        }
        return URL(string: trimmed) ?? URL(string: escaped)
    }
}
