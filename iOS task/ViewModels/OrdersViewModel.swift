import Combine
import Foundation

@MainActor
final class OrdersViewModel: ObservableObject {
    static let shared = OrdersViewModel()

    private let persistence: OrdersPersisting
    @Published private(set) var orders: [OrderEntity] = []
    private var isSubmitting = false

    init(persistence: OrdersPersisting? = nil) {
        let store = persistence ?? LocalPersistenceService()
        self.persistence = store
        self.orders = store.allOrders()
    }

    func createOrder(product: ProductEntity, quantity: Int) -> OrderEntity? {
        guard !isSubmitting else { return nil }
        guard OrderPricing.isValidQuantity(quantity, stock: product.stock) else { return nil }

        isSubmitting = true

        let subtotal = OrderPricing.subtotal(price: product.price, quantity: quantity)
        let serviceFee = OrderPricing.serviceFee(subtotal: subtotal)
        let total = OrderPricing.roundToCents(subtotal + serviceFee)
        let id = "TS-" + String(UUID().uuidString.prefix(4)).uppercased()

        let order = OrderEntity(
            id: id,
            timestamp: Date(),
            productId: product.id,
            productTitle: product.title,
            productCategory: product.categoryDisplayName,
            productImage: product.image,
            productPrice: product.price,
            quantity: quantity,
            subtotal: OrderPricing.roundToCents(subtotal),
            serviceFee: OrderPricing.roundToCents(serviceFee),
            total: total
        )

        persistence.saveOrder(order)
        orders.insert(order, at: 0)

        // Allow a later, separate order after this confirmation finishes.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            self.isSubmitting = false
        }

        return order
    }

    func resetSubmitFlag() {
        isSubmitting = false
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
