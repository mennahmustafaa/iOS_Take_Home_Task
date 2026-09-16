import Foundation

/// Lightweight local persistence behind a clear boundary.
/// Favourites and orders are always available offline.
protocol FavouritesPersisting: AnyObject {
    func loadFavourites() -> Set<Int>
    func toggleFavourite(_ productId: Int)
}

protocol OrdersPersisting: AnyObject {
    func saveOrder(_ order: OrderEntity)
    func allOrders() -> [OrderEntity]
}

final class LocalPersistenceService: FavouritesPersisting, OrdersPersisting, @unchecked Sendable {
    private let ordersKey = "tripstore.saved_orders"
    private let favsKey = "tripstore.favourite_ids"
    private let lock = NSLock()

    func isFavourited(_ productId: Int) -> Bool {
        loadFavourites().contains(productId)
    }

    func toggleFavourite(_ productId: Int) {
        lock.lock()
        defer { lock.unlock() }
        var ids = unlockedLoadFavourites()
        if ids.contains(productId) {
            ids.remove(productId)
        } else {
            ids.insert(productId)
        }
        unlockedSaveFavourites(ids)
    }

    func loadFavourites() -> Set<Int> {
        lock.lock()
        defer { lock.unlock() }
        return unlockedLoadFavourites()
    }

    private func unlockedLoadFavourites() -> Set<Int> {
        guard let data = UserDefaults.standard.data(forKey: favsKey),
              let ids = try? JSONDecoder().decode(Set<Int>.self, from: data) else {
            return []
        }
        return ids
    }

    private func unlockedSaveFavourites(_ ids: Set<Int>) {
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: favsKey)
        }
    }

    func saveOrder(_ order: OrderEntity) {
        lock.lock()
        defer { lock.unlock() }
        var orders = unlockedLoadOrders()
        orders.insert(order, at: 0)
        if let data = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(data, forKey: ordersKey)
        }
    }

    func allOrders() -> [OrderEntity] {
        lock.lock()
        defer { lock.unlock() }
        return unlockedLoadOrders()
    }

    private func unlockedLoadOrders() -> [OrderEntity] {
        guard let data = UserDefaults.standard.data(forKey: ordersKey),
              let orders = try? JSONDecoder().decode([OrderEntity].self, from: data) else {
            return []
        }
        return orders
    }
}

/// Kept for existing call sites / README naming continuity.
typealias SwiftDataPersistenceService = LocalPersistenceService
