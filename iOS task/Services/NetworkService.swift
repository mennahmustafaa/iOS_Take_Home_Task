import Foundation

enum NetworkError: LocalizedError, Equatable {
    case connectivity
    case timeout
    case invalidResponse
    case decodingError
    case serverError(Int)
    case cancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .connectivity: return "No internet connection."
        case .timeout: return "Request timed out."
        case .invalidResponse: return "Invalid server response."
        case .decodingError: return "Failed to parse data."
        case .serverError(let code): return "Server error: \(code)."
        case .cancelled: return "Request cancelled."
        case .unknown: return "An unknown error occurred."
        }
    }
}

protocol NetworkServiceProtocol: AnyObject, Sendable {
    func fetchProducts(skip: Int, limit: Int) async throws -> ProductResponse
    func searchProducts(query: String, skip: Int, limit: Int) async throws -> ProductResponse
}

final class URLSessionNetworkService: NetworkServiceProtocol {
    private let baseURL = "https://dummyjson.com/products"
    private let session: URLSession
    private let timeoutInterval: TimeInterval = 15

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProducts(skip: Int, limit: Int) async throws -> ProductResponse {
        guard let url = URL(string: "\(baseURL)?skip=\(skip)&limit=\(limit)") else {
            throw NetworkError.invalidResponse
        }
        return try await perform(url)
    }

    func searchProducts(query: String, skip: Int, limit: Int) async throws -> ProductResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&skip=\(skip)&limit=\(limit)") else {
            throw NetworkError.invalidResponse
        }
        return try await perform(url)
    }

    private func perform(_ url: URL) async throws -> ProductResponse {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            do {
                return try JSONDecoder().decode(ProductResponse.self, from: data)
            } catch {
                throw NetworkError.decodingError
            }
        } catch let error as NetworkError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch {
            if Task.isCancelled { throw NetworkError.cancelled }
            throw NetworkError.unknown
        }
    }

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .connectivity
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .unknown
        }
    }
}
