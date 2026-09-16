import Foundation

struct ProductEntity: Identifiable, Hashable, Codable {
    var id: Int
    var title: String
    var category: String
    var price: Double
    var rating: Double
    var stock: Int
    var image: String
    var images: [String]
    var description: String

    /// Human-readable category label (e.g. "kitchen-accessories" → "Kitchen Accessories").
    var categoryDisplayName: String {
        category
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    var isOutOfStock: Bool { stock <= 0 }

    init(
        id: Int = 0,
        title: String = "",
        category: String = "",
        price: Double = 0,
        rating: Double = 0,
        stock: Int = 0,
        image: String = "",
        images: [String] = [],
        description: String = ""
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.price = price
        self.rating = rating
        self.stock = stock
        self.image = image
        self.images = images
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case id, title, category, price, rating, stock, images, description
        case thumbnail
        case image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Untitled product"
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "unknown"
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0
        rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        stock = try container.decodeIfPresent(Int.self, forKey: .stock) ?? 0
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []

        // DummyJSON uses `thumbnail`; fall back to `image` or first gallery image.
        if let thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail), !thumbnail.isEmpty {
            image = thumbnail
        } else if let legacy = try container.decodeIfPresent(String.self, forKey: .image), !legacy.isEmpty {
            image = legacy
        } else {
            image = images.first ?? ""
        }

        if images.isEmpty, !image.isEmpty {
            images = [image]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encode(price, forKey: .price)
        try container.encode(rating, forKey: .rating)
        try container.encode(stock, forKey: .stock)
        try container.encode(image, forKey: .image)
        try container.encode(images, forKey: .images)
        try container.encode(description, forKey: .description)
    }
}

struct ProductResponse: Codable {
    let products: [ProductEntity]
    let total: Int
    let skip: Int
    let limit: Int

    init(products: [ProductEntity], total: Int, skip: Int, limit: Int) {
        self.products = products
        self.total = total
        self.skip = skip
        self.limit = limit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        products = try container.decodeIfPresent([ProductEntity].self, forKey: .products) ?? []
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? products.count
        skip = try container.decodeIfPresent(Int.self, forKey: .skip) ?? 0
        limit = try container.decodeIfPresent(Int.self, forKey: .limit) ?? products.count
    }

    private enum CodingKeys: String, CodingKey {
        case products, total, skip, limit
    }
}

struct CategoryInfo: Identifiable, Hashable {
    var id: String { slug }
    let slug: String
    let name: String
}
