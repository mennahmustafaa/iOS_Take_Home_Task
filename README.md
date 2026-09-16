# TripStore - iOS Take-Home Challenge

A SwiftUI e-commerce app for browsing products, managing favourites, and placing orders with local persistence.

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

## Requirements

- iOS 26.1+
- Xcode 26.1.1+
- Swift 5.0+

## Getting Started

```bash
git clone https://github.com/mennahmustafaa/iOS_Take_Home_Task.git
open "iOS task.xcodeproj"
```

## AI Disclosure

This project was developed with the assistance of an AI coding tool (OpenCode/Claude) for code generation, debugging, and architecture guidance.
