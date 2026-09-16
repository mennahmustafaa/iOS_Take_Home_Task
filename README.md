# TripStore - iOS Take-Home Challenge

A SwiftUI e-commerce app for browsing products, managing favourites, and placing orders with local persistence.

## Architecture

- **Models**: `Product`, `Order` entities with `Codable` decoding
- **DTOs**: `ProductDTO`, `OrderDTO` with `toDomain()` mapping
- **Services**: `NetworkService` (async/await), `PersistenceService` (UserDefaults + NSLock)
- **Repositories**: `CatalogueRepository` with disk caching (`CatalogueDiskCache`)
- **ViewModels**: `@MainActor` ViewModels with `@Published` state, dependency injection via initialisers
- **Views**: SwiftUI with TabView navigation, Dynamic Type support, VoiceOver accessibility

## Features

| Feature | Branch | Description |
|---------|--------|-------------|
| Project Setup | `feature/project-setup` | Core architecture, models, DTOs, services, repositories, viewmodels |
| Image Loading | `feature/image-loading` | `RemoteProductImage` with URL encoding via `ImageURLFactory` |
| Catalogue | `feature/catalogue` | Product browsing with search, filter, sort, pagination |
| Favourites | `feature/favourites` | Persistent favourite system with badge count |
| Orders | `feature/orders` | Checkout flow and order history |
| Theme | `feature/theme` | `AppRouter`, colour palette, `ToastView`, `MainTabView` |
| Product Detail | `feature/product-detail` | Product info, add-to-cart, favourite toggle |
| Tests | `feature/tests` | Unit tests for models, DTOs, repositories, viewmodels |

## Accessibility

- **Dynamic Type**: All text uses system text styles (`.caption2`, `.caption`, `.footnote`, `.subheadline`, `.body`, `.headline`, `.title3`, `.title2`) or `@ScaledMetric` for custom display sizes. Text scales with the user's preferred content size.
- **VoiceOver**: Meaningful accessibility labels on all primary controls and content (search, filters, product cards, favourite toggles, checkout button, order cards).

## Offline & Caching

- **Catalogue cache**: `CatalogueDiskCache` persists products to a JSON file on disk. On network failure, the repository returns the last cached snapshot marked as stale.
- **Favourites**: Persisted via `UserDefaults` through `LocalPersistenceService` with `NSLock` for thread safety.
- **Orders**: Persisted locally via `UserDefaults`. No backend required.

## Test Coverage

9 automated unit tests covering:

- Price calculation, rounding, and 5% service fee
- Quantity validation and stock limits
- Search, filter, and sort behaviour
- Presentation states (loading, loaded, empty, error)
- Repository with mock network and offline cache fallback
- Obsolete search response cancellation (latest response wins)
- Favourites persistence and cross-screen sync
- Order creation and double-submission prevention
- Defensive JSON decoding with fallback defaults

## Requirements

- iOS 16.0+
- Xcode 26.1.1+
- Swift 5.9+

## Getting Started

```bash
git clone https://github.com/mennahmustafaa/iOS_Take_Home_Task.git
open "iOS task.xcodeproj"
```

## AI Disclosure

This project was developed with the assistance of an AI coding tool (OpenCode/Claude) for code generation, debugging, and architecture guidance.
