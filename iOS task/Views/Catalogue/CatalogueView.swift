import SwiftUI

struct CatalogueView: View {
    @ObservedObject private var viewModel = CatalogueViewModel.shared
    @ObservedObject private var favouritesVM = FavouritesViewModel.shared
    @State private var showFilterSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    searchBar
                    if viewModel.isOffline { offlineBanner }
                    if case .error = viewModel.state { errorBanner }
                    heroBanner
                    categorySection
                    resultsHeader
                    sortToolbar
                    contentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Theme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.ink)
                        .accessibilityHidden(true)
                }
            }
            .refreshable {
                await viewModel.refresh()
                ToastCenter.shared.show("Catalogue refreshed")
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(showing: $showFilterSheet)
                    .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: ProductEntity.self) { product in
                ProductDetailView(product: product)
            }
        }
        .task {
            if viewModel.products.isEmpty {
                await viewModel.loadCatalogue()
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text("Trip")
                    .foregroundStyle(Theme.ink)
                Text("Store")
                    .foregroundStyle(Theme.primary)
            }
            .font(.system(size: 28, weight: .black, design: .rounded))
            Text("Travel lighter. Choose better.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("TripStore")
    }

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.muted)
            TextField("Search travel essentials…", text: $viewModel.searchText)
                .font(.system(size: 14))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Search products")
        }
        .frame(height: 52)
        .padding(.horizontal, 14)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 17)
                .stroke(Theme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }

    private var offlineBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
            Text("You're offline · Showing your last successful catalogue. It may be stale.")
                .font(.system(size: 11, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 1, green: 244/255, blue: 220/255))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color(red: 240/255, green: 216/255, blue: 168/255), lineWidth: 1)
        )
        .foregroundStyle(Color(red: 134/255, green: 99/255, blue: 31/255))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .accessibilityLabel("Offline. Showing cached catalogue which may be stale.")
    }

    private var errorBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("We couldn't load the catalogue. Check your connection and try again.")
                .font(.system(size: 11, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button("Retry") {
                Task { await viewModel.retry() }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Theme.primary)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 1, green: 240/255, blue: 242/255))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color(red: 240/255, green: 201/255, blue: 207/255), lineWidth: 1)
        )
        .foregroundStyle(Color(red: 161/255, green: 46/255, blue: 64/255))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Travel edit")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .opacity(0.75)
            Text("Smart picks for your next journey.")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Text("Curated accessories, honest ratings and simple local checkout.")
                .font(.system(size: 12))
                .opacity(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Button("Explore filters →") {
                showFilterSheet = true
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white)
            .foregroundStyle(Color(red: 21/255, green: 57/255, blue: 103/255))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .buttonStyle(.plain)
            .padding(.top, 4)
            .accessibilityLabel("Explore filters")
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(slug: "All", title: "All")
                    ForEach(viewModel.availableCategories) { cat in
                        categoryChip(slug: cat.slug, title: cat.name)
                    }
                }
            }
        }
    }

    private func categoryChip(slug: String, title: String) -> some View {
        let selected = viewModel.category == slug || viewModel.category == title
        return Button {
            viewModel.category = slug
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? .white : Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(selected ? Theme.ink : Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? Theme.ink : Theme.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(title)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var resultsHeader: some View {
        HStack {
            Text(viewModel.searchText.isEmpty ? "Popular picks" : "Results for “\(viewModel.searchText)”")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(viewModel.filteredProducts.count) items")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.primary)
        }
    }

    private var sortToolbar: some View {
        HStack(spacing: 8) {
            toolButton(title: filtersApplied ? "Filter · Applied" : "Filter", systemImage: "line.3.horizontal.decrease.circle", emphasized: true) {
                showFilterSheet = true
            }
            toolButton(title: viewModel.sort.displayName, systemImage: "arrow.up.arrow.down") {
                cycleSort()
            }
            toolButton(title: "Refresh", systemImage: "arrow.clockwise") {
                Task {
                    await viewModel.refresh()
                    ToastCenter.shared.show("Catalogue refreshed")
                }
            }
        }
    }

    private var filtersApplied: Bool {
        viewModel.minRating > 0 || viewModel.category != "All"
    }

    private func toolButton(title: String, systemImage: String, emphasized: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(emphasized ? Theme.primary : Theme.ink.opacity(0.75))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(emphasized ? Theme.soft : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(emphasized ? Theme.primary.opacity(0.25) : Theme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.state {
        case .loading:
            loadingGrid
        case .empty:
            emptyState
        case .error:
            errorState
        case .loaded:
            productGrid
            if viewModel.hasMorePages {
                Button {
                    Task {
                        await viewModel.loadNextPage()
                        ToastCenter.shared.show("Next catalogue page loaded")
                    }
                } label: {
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding(.vertical, 16)
                    } else {
                        Text("Load more products ↓")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.primary)
                            .padding(.vertical, 16)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Load more products")
            } else if !viewModel.filteredProducts.isEmpty {
                Text("You've reached the end of the catalogue.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }

    private var loadingGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 19)
                    .fill(Color(red: 238/255, green: 241/255, blue: 245/255))
                    .frame(height: 220)
                    .shimmer()
            }
        }
        .accessibilityLabel("Loading products")
    }

    private var productGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(viewModel.filteredProducts) { product in
                NavigationLink(value: product) {
                    ProductCardView(product: product)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 38))
                .foregroundStyle(Theme.muted)
            Text("No matches found")
                .font(.system(size: 16, weight: .semibold))
            Text("Try a different keyword or clear your filters to discover more products.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Reset filters") {
                viewModel.resetFilters()
                ToastCenter.shared.show("Filters reset")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 21)
                .stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
        .clipShape(RoundedRectangle(cornerRadius: 21))
    }

    private var errorState: some View {
        VStack(spacing: 12) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 38))
                .foregroundStyle(Theme.muted)
            Text("Something went wrong")
                .font(.system(size: 16, weight: .semibold))
            Text("We couldn't reach the catalogue right now. Your favourites and orders are still available.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task {
                    await viewModel.retry()
                    if case .loaded = viewModel.state {
                        ToastCenter.shared.show("Catalogue loaded")
                    } else if case .empty = viewModel.state {
                        ToastCenter.shared.show("Catalogue loaded")
                    }
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .buttonStyle(.plain)
            .accessibilityLabel("Try again")
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 21)
                .stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
        .clipShape(RoundedRectangle(cornerRadius: 21))
    }

    private func cycleSort() {
        let options = SortOption.allCases
        guard let idx = options.firstIndex(of: viewModel.sort) else { return }
        viewModel.sort = options[(idx + 1) % options.count]
    }
}

struct ProductCardView: View {
    let product: ProductEntity
    @ObservedObject private var favouritesVM = FavouritesViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RemoteProductImage(urlString: product.image)
                    .frame(height: 142)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay {
                        if product.isOutOfStock {
                            Color.black.opacity(0.35)
                            VStack {
                                Spacer()
                                Text("OUT OF STOCK")
                                    .font(.system(size: 10, weight: .heavy))
                                    .tracking(0.6)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.danger)
                            }
                        }
                    }

                Button {
                    let wasFavourited = favouritesVM.isFavourited(product.id)
                    favouritesVM.toggle(product.id)
                    ToastCenter.shared.show(wasFavourited ? "Removed from favourites" : "Saved to favourites")
                } label: {
                    Image(systemName: favouritesVM.isFavourited(product.id) ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(favouritesVM.isFavourited(product.id) ? Theme.danger : Theme.ink)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .padding(8)
                .accessibilityLabel(
                    favouritesVM.isFavourited(product.id)
                        ? "Remove \(product.title) from favourites"
                        : "Add \(product.title) to favourites"
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(product.categoryDisplayName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.muted)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(product.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 34, alignment: .topLeading)

                HStack {
                    Text(product.price, format: .currency(code: "USD"))
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("★ \(String(format: "%.1f", product.rating))")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color(red: 1, green: 247/255, blue: 223/255))
                        .foregroundStyle(Color(red: 134/255, green: 98/255, blue: 27/255))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }

                Text(stockLabel)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, product.isOutOfStock ? 7 : 0)
                    .padding(.vertical, product.isOutOfStock ? 4 : 0)
                    .foregroundStyle(product.isOutOfStock ? .white : stockColor)
                    .background(product.isOutOfStock ? Theme.danger : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .padding(11)
        }
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 19)
                .stroke(product.isOutOfStock ? Theme.danger.opacity(0.35) : Theme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 19))
        .opacity(product.isOutOfStock ? 0.96 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            product.isOutOfStock
                ? "\(product.title), out of stock, \(product.categoryDisplayName), \(product.price, format: .currency(code: "USD"))"
                : "\(product.title), \(product.categoryDisplayName), \(product.price, format: .currency(code: "USD"))"
        )
    }

    private var stockLabel: String {
        switch product.stock {
        case ...0: return "Out of stock"
        case 1...4: return "Only \(product.stock) left"
        default: return "In stock"
        }
    }

    private var stockColor: Color {
        switch product.stock {
        case ...0: return Theme.danger
        case 1...4: return Theme.warn
        default: return Theme.success
        }
    }
}

#Preview {
    CatalogueView()
}
