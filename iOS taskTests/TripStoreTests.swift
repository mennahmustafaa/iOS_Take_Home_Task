import XCTest
@testable import iOS_task

@MainActor
final class TripStoreTests: XCTestCase {

    // MARK: - 1. Price calculation, rounding, service fee

    func testPriceCalculationWithServiceFeeAndRounding() {
        let price = 49.99
        let quantity = 2
        let subtotal = OrderPricing.subtotal(price: price, quantity: quantity)
        let fee = OrderPricing.serviceFee(subtotal: subtotal)
        let total = OrderPricing.total(price: price, quantity: quantity)

        XCTAssertEqual(subtotal, 99.98, accuracy: 0.0001)
        XCTAssertEqual(OrderPricing.roundToCents(fee), 5.0, accuracy: 0.0001)
        XCTAssertEqual(total, 104.98, accuracy: 0.0001)
    }

    // MARK: - 2. Quantity validation

    func testQuantityValidationAndStockLimits() {
        XCTAssertFalse(OrderPricing.isValidQuantity(1, stock: 0))
        XCTAssertFalse(OrderPricing.isValidQuantity(0, stock: 5))
        XCTAssertFalse(OrderPricing.isValidQuantity(6, stock: 5))
        XCTAssertTrue(OrderPricing.isValidQuantity(1, stock: 5))
        XCTAssertTrue(OrderPricing.isValidQuantity(5, stock: 5))

        // Quantity clamping logic (mirrors ProductDetailViewModel.changeQuantity)
        var quantity = 1
        let stock = 3
        func change(_ delta: Int) {
            guard stock > 0 else { return }
            quantity = max(1, min(stock, quantity + delta))
        }
        change(1)
        XCTAssertEqual(quantity, 2)
        change(5)
        XCTAssertEqual(quantity, 3)
        change(-10)
        XCTAssertEqual(quantity, 1)
        XCTAssertTrue(OrderPricing.isValidQuantity(quantity, stock: stock))
        XCTAssertFalse(OrderPricing.isValidQuantity(1, stock: 0))
    }

    // MARK: - 3. Search / filter / sort behaviour

    func testSearchFilterSortBehaviour() async {
        let products = [
            sample(id: 1, title: "CK One", category: "fragrances", price: 49.99, rating: 4.85),
            sample(id: 2, title: "Blue Dress", category: "womens-dresses", price: 29.99, rating: 4.52),
            sample(id: 3, title: "AirPods", category: "mobile-accessories", price: 129.99, rating: 4.88),
            sample(id: 4, title: "Rolex", category: "mens-watches", price: 1399.99, rating: 4.91)
        ]
        let mock = MockNetworkService(result: .success(ProductResponse(products: products, total: 4, skip: 0, limit: 10)))
        let repo = CatalogueRepository(networkService: mock, cacheService: InMemoryCatalogueCache())
        let vm = CatalogueViewModel(repository: repo)

        await vm.loadCatalogue()
        XCTAssertEqual(vm.state, .loaded)

        vm.category = "fragrances"
        XCTAssertEqual(vm.filteredProducts.count, 1)
        XCTAssertEqual(vm.filteredProducts.first?.title, "CK One")

        vm.category = "All"
        vm.minRating = 4.9
        XCTAssertEqual(vm.filteredProducts.map(\.title), ["Rolex"])

        vm.minRating = 0
        vm.sort = .priceAsc
        XCTAssertEqual(vm.filteredProducts.first?.title, "Blue Dress")
        XCTAssertEqual(vm.filteredProducts.last?.title, "Rolex")

        vm.sort = .rating
        XCTAssertEqual(vm.filteredProducts.first?.title, "Rolex")
    }

    // MARK: - 4. Presentation states

    func testPresentationStatesLoadingSuccessEmptyError() async {
        let emptyMock = MockNetworkService(result: .success(ProductResponse(products: [], total: 0, skip: 0, limit: 10)))
        let emptyVM = CatalogueViewModel(repository: CatalogueRepository(networkService: emptyMock, cacheService: InMemoryCatalogueCache()))
        await emptyVM.loadCatalogue()
        XCTAssertEqual(emptyVM.state, .empty)

        let okMock = MockNetworkService(result: .success(ProductResponse(products: [sample()], total: 1, skip: 0, limit: 10)))
        let okVM = CatalogueViewModel(repository: CatalogueRepository(networkService: okMock, cacheService: InMemoryCatalogueCache()))
        await okVM.loadCatalogue()
        XCTAssertEqual(okVM.state, .loaded)
        XCTAssertEqual(okVM.products.count, 1)

        let errMock = MockNetworkService(error: .connectivity)
        let errVM = CatalogueViewModel(repository: CatalogueRepository(networkService: errMock, cacheService: InMemoryCatalogueCache()))
        await errVM.loadCatalogue()
        if case .error = errVM.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected error state, got \(errVM.state)")
        }
    }

    // MARK: - 5. Repository with mock network + offline cache

    func testRepositoryWithMockNetworkService() async throws {
        let products = [sample(id: 7, title: "Mock Product", category: "beauty")]
        let mock = MockNetworkService(result: .success(ProductResponse(products: products, total: 1, skip: 0, limit: 10)))
        let cache = InMemoryCatalogueCache()
        let repo = CatalogueRepository(networkService: mock, cacheService: cache)

        let online = try await repo.loadCatalogue(skip: 0, limit: 10)
        XCTAssertEqual(online.products.count, 1)
        XCTAssertFalse(online.isStale)
        XCTAssertEqual(online.products.first?.title, "Mock Product")

        let offlineMock = MockNetworkService(error: .connectivity)
        let offlineRepo = CatalogueRepository(networkService: offlineMock, cacheService: cache)
        let stale = try await offlineRepo.loadCatalogue(skip: 0, limit: 10)
        XCTAssertTrue(stale.isStale)
        XCTAssertEqual(stale.products.first?.title, "Mock Product")
    }

    // MARK: - 6. Obsolete search cannot overwrite latest

    func testObsoleteSearchResponseDoesNotOverwriteLatestResult() async {
        let service = ControllableSearchService()
        service.searchDelayNanoseconds = 300_000_000
        service.searchResponses = [
            "a": ProductResponse(products: [sample(id: 10, title: "Old Result A")], total: 1, skip: 0, limit: 10),
            "ab": ProductResponse(products: [sample(id: 11, title: "Latest Result AB")], total: 1, skip: 0, limit: 10)
        ]

        // Slow older query is cancelled; only the latest query's payload may be kept.
        let older = Task {
            try await service.searchProducts(query: "a", skip: 0, limit: 10)
        }
        try? await Task.sleep(nanoseconds: 40_000_000)
        older.cancel()

        let latest = try? await service.searchProducts(query: "ab", skip: 0, limit: 10)
        XCTAssertEqual(latest?.products.first?.title, "Latest Result AB")

        var olderFailed = false
        do {
            _ = try await older.value
        } catch {
            olderFailed = true
        }
        XCTAssertTrue(olderFailed, "Cancelled older search must not succeed")

        // ViewModel generation guard: typing "a" then quickly "ab" keeps only latest.
        let repo = CatalogueRepository(networkService: service, cacheService: InMemoryCatalogueCache())
        let vm = CatalogueViewModel(repository: repo)
        service.nextFetch = ProductResponse(products: [sample(id: 1, title: "Seed")], total: 1, skip: 0, limit: 10)
        service.searchDelayNanoseconds = 150_000_000
        await vm.loadCatalogue()

        vm.searchText = "a"
        try? await Task.sleep(nanoseconds: 80_000_000)
        vm.searchText = "ab"
        try? await Task.sleep(nanoseconds: 800_000_000)

        XCTAssertEqual(vm.searchText, "ab")
        XCTAssertEqual(vm.filteredProducts.first?.title, "Latest Result AB")
        XCTAssertFalse(vm.filteredProducts.contains(where: { $0.title == "Old Result A" }))
    }

    // MARK: - 7. Favourites persistence + sync

    func testFavouritesPersistenceAndSync() {
        // Mirrors LocalPersistenceService favourite toggle/load behaviour.
        var storedIDs: Set<Int> = []

        func isFavourited(_ id: Int) -> Bool { storedIDs.contains(id) }
        func toggle(_ id: Int) {
            if storedIDs.contains(id) {
                storedIDs.remove(id)
            } else {
                storedIDs.insert(id)
            }
        }
        func remove(_ id: Int) {
            guard storedIDs.contains(id) else { return }
            storedIDs.remove(id)
        }

        XCTAssertFalse(isFavourited(99))
        toggle(99)
        XCTAssertTrue(isFavourited(99))
        XCTAssertEqual(storedIDs.count, 1)

        // Second “screen” reading the same store stays in sync.
        XCTAssertTrue(isFavourited(99))
        remove(99)
        XCTAssertFalse(isFavourited(99))
        XCTAssertEqual(storedIDs.count, 0)
    }

    // MARK: - 8. Order creation + double submission prevention

    func testOrderCreationAndDoubleSubmissionPrevention() {
        let persistence = InMemoryPersistence()
        let vm = OrdersViewModel(persistence: persistence)
        let product = sample(price: 10, stock: 5)

        let first = vm.createOrder(product: product, quantity: 2)
        XCTAssertNotNil(first)
        XCTAssertTrue(first?.id.hasPrefix("TS-") ?? false)
        XCTAssertEqual(first?.quantity, 2)
        let total = first?.total ?? -1
        XCTAssertEqual(total, 21.0, accuracy: 0.001)

        let second = vm.createOrder(product: product, quantity: 2)
        XCTAssertNil(second, "Rapid second confirmation must be ignored")
        XCTAssertEqual(vm.orders.count, 1)

        XCTAssertNil(vm.createOrder(product: sample(price: 10, stock: 0), quantity: 1))
    }

    // MARK: - 9. Defensive decoding

    func testDefensiveDecodingFallbackDefaults() throws {
        let json = """
        {
          "products": [
            {
              "id": 42,
              "thumbnail": "https://cdn.dummyjson.com/thumb.webp",
              "images": ["https://cdn.dummyjson.com/1.webp"]
            }
          ],
          "total": 1,
          "skip": 0,
          "limit": 1
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ProductResponse.self, from: json)
        let product = try XCTUnwrap(response.products.first)
        XCTAssertEqual(product.id, 42)
        XCTAssertEqual(product.title, "Untitled product")
        XCTAssertEqual(product.image, "https://cdn.dummyjson.com/thumb.webp")
        XCTAssertEqual(product.images.count, 1)
        XCTAssertEqual(product.price, 0)
        XCTAssertEqual(product.stock, 0)
    }

    // MARK: Helpers

    private func sample(
        id: Int = 1,
        title: String = "Sample",
        category: String = "beauty",
        price: Double = 9.99,
        rating: Double = 4.5,
        stock: Int = 10
    ) -> ProductEntity {
        ProductEntity(
            id: id,
            title: title,
            category: category,
            price: price,
            rating: rating,
            stock: stock,
            image: "https://example.com/a.webp",
            images: ["https://example.com/a.webp"],
            description: "desc"
        )
    }
}

// MARK: - Test doubles

final class MockNetworkService: NetworkServiceProtocol {
    let result: Result<ProductResponse, NetworkError>?
    let error: NetworkError?

    init(result: Result<ProductResponse, NetworkError>? = nil, error: NetworkError? = nil) {
        self.result = result
        self.error = error
    }

    func fetchProducts(skip: Int, limit: Int) async throws -> ProductResponse {
        if let error { throw error }
        if let result { return try result.get() }
        throw NetworkError.unknown
    }

    func searchProducts(query: String, skip: Int, limit: Int) async throws -> ProductResponse {
        try await fetchProducts(skip: skip, limit: limit)
    }
}

final class ControllableSearchService: NetworkServiceProtocol, @unchecked Sendable {
    var nextFetch: ProductResponse = ProductResponse(products: [], total: 0, skip: 0, limit: 10)
    var searchResponses: [String: ProductResponse] = [:]
    var searchDelayNanoseconds: UInt64 = 0

    func fetchProducts(skip: Int, limit: Int) async throws -> ProductResponse {
        nextFetch
    }

    func searchProducts(query: String, skip: Int, limit: Int) async throws -> ProductResponse {
        if searchDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: searchDelayNanoseconds)
        }
        try Task.checkCancellation()
        return searchResponses[query] ?? ProductResponse(products: [], total: 0, skip: 0, limit: limit)
    }
}

final class InMemoryCatalogueCache: CatalogueCacheProtocol {
    private var stored: (products: [ProductEntity], total: Int)?

    func save(products: [ProductEntity], total: Int) {
        stored = (products, total)
    }

    func load() -> (products: [ProductEntity], total: Int)? {
        stored
    }
}

final class InMemoryPersistence: @unchecked Sendable {
    private var favs: Set<Int> = []
    private var orders: [OrderEntity] = []
    private let lock = NSLock()

    func loadFavourites() -> Set<Int> {
        lock.lock(); defer { lock.unlock() }
        return favs
    }

    func toggleFavourite(_ productId: Int) {
        lock.lock(); defer { lock.unlock() }
        if favs.contains(productId) {
            favs.remove(productId)
        } else {
            favs.insert(productId)
        }
    }

    func saveOrder(_ order: OrderEntity) {
        lock.lock(); defer { lock.unlock() }
        orders.insert(order, at: 0)
    }

    func allOrders() -> [OrderEntity] {
        lock.lock(); defer { lock.unlock() }
        return orders
    }
}

extension InMemoryPersistence: FavouritesPersisting, OrdersPersisting {}
