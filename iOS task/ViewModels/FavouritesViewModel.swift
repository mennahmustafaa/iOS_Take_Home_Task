import Combine
import Foundation

@MainActor
final class FavouritesViewModel: ObservableObject {
    static let shared = FavouritesViewModel()

    private let persistence: FavouritesPersisting
    @Published private(set) var favouriteIDs: Set<Int> = []

    init(persistence: FavouritesPersisting? = nil) {
        let store = persistence ?? LocalPersistenceService()
        self.persistence = store
        self.favouriteIDs = store.loadFavourites()
    }

    func isFavourited(_ productId: Int) -> Bool {
        favouriteIDs.contains(productId)
    }

    func toggle(_ productId: Int) {
        persistence.toggleFavourite(productId)
        favouriteIDs = persistence.loadFavourites()
    }

    func remove(_ productId: Int) {
        guard favouriteIDs.contains(productId) else { return }
        persistence.toggleFavourite(productId)
        favouriteIDs = persistence.loadFavourites()
    }

    var count: Int { favouriteIDs.count }
}
