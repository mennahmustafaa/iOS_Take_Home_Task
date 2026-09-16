import Foundation

protocol CatalogueRepositoryProtocol: AnyObject {
    func loadCatalogue(skip: Int, limit: Int) async throws -> (products: [ProductEntity], total: Int, isStale: Bool)
    func searchCatalogue(query: String, skip: Int, limit: Int) async throws -> (products: [ProductEntity], total: Int, isStale: Bool)
    func loadCatalogueCached() -> [ProductEntity]?
}

final class CatalogueRepository: CatalogueRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let cacheService: CatalogueCacheProtocol

    init(networkService: NetworkServiceProtocol, cacheService: CatalogueCacheProtocol) {
        self.networkService = networkService
        self.cacheService = cacheService
    }

    func loadCatalogue(skip: Int, limit: Int) async throws -> (products: [ProductEntity], total: Int, isStale: Bool) {
        do {
            let response = try await networkService.fetchProducts(skip: skip, limit: limit)
            if skip == 0 {
                cacheService.save(products: response.products, total: response.total)
            }
            return (response.products, response.total, false)
        } catch {
            if skip == 0, let cached = cacheService.load() {
                return (cached.products, cached.total, true)
            }
            throw error
        }
    }

    func searchCatalogue(query: String, skip: Int, limit: Int) async throws -> (products: [ProductEntity], total: Int, isStale: Bool) {
        do {
            let response = try await networkService.searchProducts(query: query, skip: skip, limit: limit)
            return (response.products, response.total, false)
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch let error as NetworkError where error == .cancelled {
            throw error
        } catch {
            if let cached = cacheService.load() {
                let filtered = cached.products.filter {
                    ($0.title + " " + $0.category + " " + $0.description)
                        .lowercased()
                        .contains(query.lowercased())
                }
                return (filtered, filtered.count, true)
            }
            throw error
        }
    }

    func loadCatalogueCached() -> [ProductEntity]? {
        cacheService.load().map { $0.products }
    }
}

protocol CatalogueCacheProtocol: AnyObject {
    func save(products: [ProductEntity], total: Int)
    func load() -> (products: [ProductEntity], total: Int)?
}

final class CatalogueDiskCache: CatalogueCacheProtocol {
    private let fileManager: FileManager
    private let cacheURL: URL
    private let totalKey = "catalogue_total"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.cacheURL = dir.appendingPathComponent("catalogue_cache.json")
    }

    func save(products: [ProductEntity], total: Int) {
        do {
            let payload = CachedCatalogue(products: products, total: total)
            let data = try JSONEncoder().encode(payload)
            try data.write(to: cacheURL, options: .atomic)
            UserDefaults.standard.set(total, forKey: totalKey)
        } catch {
            // Cache write failures are non-fatal.
        }
    }

    func load() -> (products: [ProductEntity], total: Int)? {
        do {
            let data = try Data(contentsOf: cacheURL)
            if let payload = try? JSONDecoder().decode(CachedCatalogue.self, from: data) {
                return (payload.products, payload.total)
            }
            // Backward compatibility with older array-only cache files.
            let products = try JSONDecoder().decode([ProductEntity].self, from: data)
            let total = UserDefaults.standard.integer(forKey: totalKey)
            return (products, total > 0 ? total : products.count)
        } catch {
            return nil
        }
    }
}

private struct CachedCatalogue: Codable {
    let products: [ProductEntity]
    let total: Int
}
