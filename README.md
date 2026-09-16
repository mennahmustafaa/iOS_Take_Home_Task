# TripStore - iOS Take-Home Challenge

A SwiftUI e-commerce app for browsing products, managing favourites, and placing orders with local persistence. powered by DummyJSON, with offline favourites/orders, search/filter/sort, and a local booking-style checkout.

https://github.com/user-attachments/assets/11c90b97-003c-4718-b4c3-b5f8f4e8307f



https://github.com/user-attachments/assets/02f2796d-de84-4781-ad04-9254ab4a9235


## Architecture

- **Models**: `Product`, `Order` entities with `Codable` decoding
- **DTOs**: `ProductDTO`, `OrderDTO` with `toDomain()` mapping
- **Services**: `NetworkService` (async/await), `PersistenceService` (UserDefaults + NSLock)
- **Repositories**: `CatalogueRepository` with disk caching (`CatalogueDiskCache`)
- **ViewModels**: `@MainActor` ViewModels with `@Published` state, dependency injection via initialisers
- **Views**: SwiftUI with TabView navigation, Dynamic Type support, VoiceOver accessibility

Dependency injection uses protocols (`NetworkServiceProtocol`, `CatalogueRepositoryProtocol`, `FavouritesPersisting`, `OrdersPersisting`, `CatalogueCacheProtocol`) so tests can inject mocks. All image loading uses `RemoteProductImage` with `ImageURLFactory` for proper URL encoding.

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

## Cache & offline policy

- On a successful first-page catalogue load, products are written to a JSON file in Caches.
- If the network fails and a cache exists, the app shows cached products with a yellow **offline / may be stale** banner.
- If the network fails and there is no cache, the app shows an actionable error with **Retry**.
- Favourites and confirmed orders are stored locally and remain available offline.
- Cache is overwritten on the next successful page-0 fetch (no TTL in this submission).

---

## Persistence choice

Favourites and orders use a **lightweight local store** behind protocols (`LocalPersistenceService`). Catalogue cache uses a disk JSON file. No credentials or sensitive data are stored. This keeps the project buildable under the current MainActor / concurrency compiler settings without SwiftData runtime crashes, while still meeting the "justified lightweight persistence + protocol boundary" requirement.

---
## Networking & Concurrency

Networking is implemented using URLSession and Swift Concurrency (async/await).

Search input is debounced by 300ms to avoid unnecessary requests.

Search uses the DummyJSON search endpoint.

Obsolete search responses are ignored using a generation token, ensuring an older request cannot overwrite a newer query.

Pagination uses the API's skip and limit parameters instead of repeatedly fetching the entire catalogue.

UI-related state updates are handled by @MainActor ViewModels.

Network failures are surfaced through application error state

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
- Orders are local only; no real payment or backend order API is required.
### Would improve with more time

- Explicit cache TTL / stale-while-revalidate
- Persist full favourite product snapshots for offline Saved details
- UI tests for the order journey
- Structured logging

---

## Product Details & Ordering

Product details include the available product information and image gallery.

Users can:

Mark or unmark a product as a favourite.

Select a quantity between 1 and the available stock.

See the live order total.

Confirm a local order.

The order calculation is:

Subtotal = Product Price × Quantity
Service Fee = Subtotal × 5%
Final Total = Subtotal + Service Fee

Totals are rounded to two decimal places.

Products with zero stock cannot be ordered, and quantities exceeding available stock are prevented.

Repeated confirmation is protected so that only one local order is created.

Each confirmed order contains a unique ID and timestamp.

Error & Edge-Case Handling

Case

Behaviour

No internet + cache exists

Cached catalogue is displayed with an offline/stale indicator

No internet + no cache

Error state with Retry

Rapid search changes

Latest query wins; obsolete responses are ignored

Empty result

Purposeful empty state

Stock = 0

Ordering is disabled

Quantity exceeds stock

Confirmation is prevented

Repeated confirmation

Only one local order is created

Missing/partial API fields

Optional data is decoded safely with display fallbacks
## AI disclosure

Cursor AI assisted with scaffolding, decoding/filter fixes, toast/alert UX, tests. persistence behaviour was reviewed and verified against the DummyJSON API and the candidate brief.

---
## Testing

The project includes automated tests covering business logic, presentation state, repository behaviour, and search concurrency.

Tests cover:

Price calculation

Service fee calculation

Two-decimal rounding

Quantity validation against available stock

Search behaviour

Category filtering

Minimum-rating filtering

Price sorting

Rating sorting

ViewModel loading state

ViewModel success state

ViewModel empty state

ViewModel error state

Repository behaviour using a mock network service

Search concurrency to ensure an obsolete response cannot replace the latest result

Tests are located in TripStoreTests/.

Run tests using Product → Test (⌘U) in Xcode, or:

xcodebuild test \
  -project "iOS task/iOS task.xcodeproj" \
  -scheme "iOS task" \

## Accessibility

The application is designed to support Dynamic Type and provides meaningful accessibility labels for primary controls and product content.

----------
## Getting Started

git clone https://github.com/mennahmustafaa/iOS_Take_Home_Task.git
open "iOS task.xcodeproj"

Setup

Open iOS task/iOS task.xcodeproj in Xcode.

Select the iOS task scheme.

Select an iOS 16+ Simulator or device.

Run with Cmd+R.

Run tests with Cmd+U.

No API keys or additional credentials are required.

## Known limitations

- Image loading uses `RemoteProductImage` with `ImageURLFactory` for proper URL encoding and `URLSession`/`URLCache`.
- Saved tab shows products that are already present in the loaded/cached catalogue.
