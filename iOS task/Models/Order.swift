import Foundation

struct OrderEntity: Codable, Identifiable, Hashable {
    var id: String
    var timestamp: Date
    var productId: Int
    var productTitle: String
    var productCategory: String
    var productImage: String
    var productPrice: Double
    var quantity: Int
    var subtotal: Double
    var serviceFee: Double
    var total: Double

    init(
        id: String = "",
        timestamp: Date = Date(),
        productId: Int = 0,
        productTitle: String = "",
        productCategory: String = "",
        productImage: String = "",
        productPrice: Double = 0,
        quantity: Int = 1,
        subtotal: Double = 0,
        serviceFee: Double = 0,
        total: Double = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.productId = productId
        self.productTitle = productTitle
        self.productCategory = productCategory
        self.productImage = productImage
        self.productPrice = productPrice
        self.quantity = quantity
        self.subtotal = subtotal
        self.serviceFee = serviceFee
        self.total = total
    }
}

enum SortOption: String, CaseIterable, Hashable, Equatable {
    case featured
    case priceAsc
    case priceDesc
    case rating

    var displayName: String {
        switch self {
        case .featured: return "Featured"
        case .priceAsc: return "Price ↑"
        case .priceDesc: return "Price ↓"
        case .rating: return "Rating"
        }
    }
}

enum OrderPricing {
    static let serviceFeeRate: Double = 0.05

    static func subtotal(price: Double, quantity: Int) -> Double {
        price * Double(quantity)
    }

    static func serviceFee(subtotal: Double) -> Double {
        subtotal * serviceFeeRate
    }

    static func total(price: Double, quantity: Int) -> Double {
        let sub = subtotal(price: price, quantity: quantity)
        return roundToCents(sub + serviceFee(subtotal: sub))
    }

    static func roundToCents(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    static func isValidQuantity(_ quantity: Int, stock: Int) -> Bool {
        stock > 0 && quantity >= 1 && quantity <= stock
    }
}
