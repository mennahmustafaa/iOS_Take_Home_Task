import Combine
import Foundation

@MainActor
final class ProductDetailViewModel: ObservableObject {
    @Published var quantity: Int = 1
    @Published var galleryIndex: Int = 0
    let product: ProductEntity

    var stock: Int { product.stock }
    var isOutOfStock: Bool { product.stock == 0 }

    var liveTotal: Double {
        OrderPricing.roundToCents(OrderPricing.subtotal(price: product.price, quantity: quantity))
    }

    var totalWithFee: Double {
        OrderPricing.total(price: product.price, quantity: quantity)
    }

    var serviceFee: Double {
        OrderPricing.roundToCents(OrderPricing.serviceFee(subtotal: OrderPricing.subtotal(price: product.price, quantity: quantity)))
    }

    var canOrder: Bool {
        OrderPricing.isValidQuantity(quantity, stock: product.stock)
    }

    init(product: ProductEntity) {
        self.product = product
        self.quantity = 1
    }

    func changeQuantity(_ delta: Int) {
        guard !isOutOfStock else { return }
        quantity = max(1, min(product.stock, quantity + delta))
    }
}
