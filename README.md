# TripStore - iOS Take-Home Challenge

A SwiftUI e-commerce app for browsing products, managing favourites, and placing orders with local persistence. powered by DummyJSON, with offline favourites/orders, search/filter/sort, and a local booking-style checkout.


## Architecture

- **Models**: `Product`, `Order` entities with `Codable` decoding
- **DTOs**: `ProductDTO`, `OrderDTO` with `toDomain()` mapping
- **Services**: `NetworkService` (async/await), `PersistenceService` (UserDefaults)
- **Repositories**: `CatalogueRepository` with disk caching
- **ViewModels**: `@MainActor` ViewModels with `@Published` state
- **Views**: SwiftUI with TabView navigation

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

Dependency injection uses protocols (`NetworkServiceProtocol`, `CatalogueRepositoryProtocol`, `FavouritesPersisting`, `OrdersPersisting`, `CatalogueCacheProtocol`) so tests can inject mocks. All image loading uses `RemoteProductImage` with `ImageURLFactory` for proper URL encoding.

## Requirements

- iOS 26.1+
- Xcode 26.1.1+
- Swift 5.0+

## Getting Started

```bash
git clone https://github.com/mennahmustafaa/iOS_Take_Home_Task.git
open "iOS task.xcodeproj"
```



---

## Setup

1. Open `iOS task/iOS task.xcodeproj` in Xcode 15+.
2. Select the **iOS task** scheme and an iOS Simulator.
3. Run with **Cmd+R**.
4. Run tests with **Cmd+U**, or:

```bash
xcodebuild test \
  -project "iOS task/iOS task.xcodeproj" \
  -scheme "iOS task" \
  -destination "platform=iOS Simulator,name=iPhone 17"
```

---




---

## Cache & offline policy

- On a successful first-page catalogue load, products are written to a JSON file in Caches.
- If the network fails and a cache exists, the app shows cached products with a yellow **offline / may be stale** banner.
- If the network fails and there is no cache, the app shows an actionable error with **Retry**.
- Favourites and confirmed orders are stored locally and remain available offline.
- Cache is overwritten on the next successful page-0 fetch (no TTL in this submission).

---

## Persistence choice

Favourites and orders use a **lightweight local store** behind protocols (`LocalPersistenceService`). Catalogue cache uses a disk JSON file. No credentials or sensitive data are stored. This keeps the project buildable under the current MainActor / concurrency compiler settings without SwiftData runtime crashes, while still meeting the “justified lightweight persistence + protocol boundary” requirement.

---

## UX feedback (design parity)

Matches the HTML prototype toast pattern, plus a confirmation alert for orders:

- Order confirmed → toast + alert → Orders tab
- Favourite add/remove → toast
- Filters applied / reset → toast
- Refresh / load more / retry success → toast

---

## Assumptions & trade-offs

- DummyJSON categories arrive as slugs (`beauty`); the UI shows title-cased names and filters against either form.
- Product decoding maps `thumbnail` → `image` and tolerates missing optional fields.
- Search is debounced (300ms) and uses the DummyJSON search endpoint; obsolete responses are ignored via a generation token.
- Service fee is fixed at 5%; totals are rounded to two decimal places.

### Would improve with more time

- Explicit cache TTL / stale-while-revalidate
- Persist full favourite product snapshots for offline Saved details
- UI tests for the order journey
- Structured logging

---

## AI disclosure

Cursor AI assisted with scaffolding, UI polish against the HTML prototype, decoding/filter fixes, toast/alert UX, tests. All networking, pricing, concurrency, and persistence behaviour was reviewed and verified against the DummyJSON API and the candidate brief.

---

## Known limitations

- Image loading uses `RemoteProductImage` with `ImageURLFactory` for proper URL encoding and `URLSession`/`URLCache`.
- Saved tab shows products that are already present in the loaded/cached catalogue.

