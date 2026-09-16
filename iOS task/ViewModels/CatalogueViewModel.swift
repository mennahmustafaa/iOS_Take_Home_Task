import Combine
import Foundation

@MainActor
final class CatalogueViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var products: [ProductEntity] = []
    @Published private(set) var filteredProducts: [ProductEntity] = []
    @Published private(set) var availableCategories: [CategoryInfo] = []
    @Published private(set) var isOffline: Bool = false
    @Published private(set) var totalCount: Int = 0
    @Published private(set) var currentPage: Int = 0
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var hasMorePages: Bool = false

    @Published var searchText: String = "" {
        didSet { scheduleSearch() }
    }

    @Published var category: String = "All" {
        didSet { applyFiltersAndSort() }
    }

    @Published var minRating: Double = 0 {
        didSet { applyFiltersAndSort() }
    }

    @Published var sort: SortOption = .featured {
        didSet { applyFiltersAndSort() }
    }

    private let repository: CatalogueRepositoryProtocol
    private var searchTask: Task<Void, Never>?
    private var searchGeneration: Int = 0
    private let pageSize: Int = 20
    private var activeSearchQuery: String = ""

    init(repository: CatalogueRepositoryProtocol) {
        self.repository = repository
    }

    func loadCatalogue() async {
        state = .loading
        isOffline = false
        activeSearchQuery = ""
        do {
            let result = try await repository.loadCatalogue(skip: 0, limit: pageSize)
            totalCount = result.total
            currentPage = 1
            products = Self.applyStockDemoOverrides(result.products)
            isOffline = result.isStale
            refreshCategories()
            hasMorePages = products.count < totalCount
            applyFiltersAndSort()
        } catch {
            if let cached = repository.loadCatalogueCached(), !cached.isEmpty {
                products = Self.applyStockDemoOverrides(cached)
                isOffline = true
                refreshCategories()
                applyFiltersAndSort()
            } else {
                state = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }

    func loadNextPage() async {
        guard !isLoadingMore, state == .loaded || state == .empty else { return }
        guard hasMorePages, activeSearchQuery.isEmpty else { return }
        isLoadingMore = true
        do {
            let result = try await repository.loadCatalogue(skip: currentPage * pageSize, limit: pageSize)
            let existingIDs = Set(products.map(\.id))
            let newItems = Self.applyStockDemoOverrides(result.products).filter { !existingIDs.contains($0.id) }
            products.append(contentsOf: newItems)
            currentPage += 1
            isOffline = result.isStale
            hasMorePages = products.count < totalCount
            refreshCategories()
            applyFiltersAndSort()
        } catch {
            // Keep current page visible on pagination failure.
        }
        isLoadingMore = false
    }

    func refresh() async {
        await loadCatalogue()
    }

    func retry() async {
        await loadCatalogue()
    }

    func resetFilters() {
        category = "All"
        minRating = 0
        sort = .featured
        searchText = ""
        activeSearchQuery = ""
        applyFiltersAndSort()
    }

    func applyFiltersAndSort() {
        var result = products

        if category != "All" {
            result = result.filter {
                $0.category.caseInsensitiveCompare(category) == .orderedSame
                    || $0.categoryDisplayName.caseInsensitiveCompare(category) == .orderedSame
            }
        }

        if minRating > 0 {
            result = result.filter { $0.rating >= minRating }
        }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty, activeSearchQuery.isEmpty {
            result = result.filter {
                ($0.title + " " + $0.category + " " + $0.description).lowercased().contains(q)
            }
        }

        switch sort {
        case .priceAsc: result.sort { $0.price < $1.price }
        case .priceDesc: result.sort { $0.price > $1.price }
        case .rating: result.sort { $0.rating > $1.rating }
        case .featured: break
        }

        filteredProducts = result

        switch state {
        case .error:
            break
        default:
            if products.isEmpty && !isOffline {
                // Keep loading/error as set by network path.
            }
            state = result.isEmpty ? .empty : .loaded
        }
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        searchGeneration += 1
        let generation = searchGeneration

        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled, let self else { return }
            guard generation == self.searchGeneration else { return }

            if query.isEmpty {
                self.activeSearchQuery = ""
                await self.loadCatalogue()
                return
            }

            await self.performRemoteSearch(query: query, generation: generation)
        }
    }

    private func performRemoteSearch(query: String, generation: Int) async {
        state = .loading
        do {
            let result = try await repository.searchCatalogue(query: query, skip: 0, limit: pageSize)
            guard !Task.isCancelled, generation == searchGeneration else { return }
            activeSearchQuery = query
            products = Self.applyStockDemoOverrides(result.products)
            totalCount = result.total
            currentPage = 1
            isOffline = result.isStale
            hasMorePages = false
            refreshCategories()
            applyFiltersAndSort()
        } catch {
            guard !Task.isCancelled, generation == searchGeneration else { return }
            if error is CancellationError || (error as? NetworkError) == .cancelled {
                return
            }
            // Fall back to local filter of whatever we already have.
            activeSearchQuery = ""
            applyFiltersAndSort()
            if filteredProducts.isEmpty && products.isEmpty {
                state = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }

    private func refreshCategories() {
        var seen = Set<String>()
        var cats: [CategoryInfo] = []
        for product in products {
            let slug = product.category.lowercased()
            if seen.insert(slug).inserted {
                cats.append(CategoryInfo(slug: product.category, name: product.categoryDisplayName))
            }
        }
        availableCategories = cats.sorted { $0.name < $1.name }
    }

    /// DummyJSON often returns high stock for every item. Mark every 4th product
    /// (and any API stock already ≤ 0) as out of stock so the catalogue clearly
    /// demonstrates the unavailable / no-order path required by the brief.
    static func applyStockDemoOverrides(_ products: [ProductEntity]) -> [ProductEntity] {
        products.map { product in
            var updated = product
            if product.stock <= 0 || product.id % 4 == 0 {
                updated.stock = 0
            }
            return updated
        }
    }
}

extension CatalogueViewModel {
    static let shared = CatalogueViewModel(
        repository: CatalogueRepository(
            networkService: URLSessionNetworkService(),
            cacheService: CatalogueDiskCache()
        )
    )
}
