import Foundation

// MARK: - Order DTO

/// Data transfer object for order persistence and mapping.
struct OrderDTO: Codable, Identifiable, Hashable {
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

    init(from order: OrderEntity) {
        id = order.id
        timestamp = order.timestamp
        productId = order.productId
        productTitle = order.productTitle
        productCategory = order.productCategory
        productImage = order.productImage
        productPrice = order.productPrice
        quantity = order.quantity
        subtotal = order.subtotal
        serviceFee = order.serviceFee
        total = order.total
    }

    func toDomain() -> OrderEntity {
        OrderEntity(
            id: id,
            timestamp: timestamp,
            productId: productId,
            productTitle: productTitle,
            productCategory: productCategory,
            productImage: productImage,
            productPrice: productPrice,
            quantity: quantity,
            subtotal: subtotal,
            serviceFee: serviceFee,
            total: total
        )
    }
}

// MARK: - Order list response DTO

struct OrderListResponseDTO: Codable {
    let orders: [OrderDTO]?
    let total: Int?
}

extension OrderListResponseDTO {
    func toDomain() -> [OrderEntity] {
        (orders ?? []).map { $0.toDomain() }
    }
}
