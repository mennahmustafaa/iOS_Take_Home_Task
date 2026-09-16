import SwiftUI

struct FavouritesView: View {
    @ObservedObject private var vm = FavouritesViewModel.shared
    @ObservedObject private var catalogueVM = CatalogueViewModel.shared
    @ScaledMetric(relativeTo: .title) private var headerSize: CGFloat = 28
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 38

    private var favouriteProducts: [ProductEntity] {
        catalogueVM.products.filter { vm.favouriteIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    headerSection
                    if vm.favouriteIDs.isEmpty {
                        emptyState
                    } else if favouriteProducts.isEmpty {
                        offlineHint
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(favouriteProducts) { product in
                                NavigationLink(value: product) {
                                    favouriteRow(product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Theme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ProductEntity.self) { product in
                ProductDetailView(product: product)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Saved")
                .font(.system(size: headerSize, weight: .black, design: .rounded))
                .foregroundStyle(Theme.primary)
            Text("\(vm.count) favourites · available offline")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var offlineHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: headerSize))
                .foregroundStyle(Theme.primary)
            Text("\(vm.count) saved item\(vm.count == 1 ? "" : "s")")
                .font(.headline)
            Text("Open Browse to load product details for your saved IDs. Favourite IDs stay on this device.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 21)
                .stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: emptyIconSize))
                .foregroundStyle(Theme.muted)
            Text("Your saved list is empty")
                .font(.headline)
            Text("Favourite items stay here across app launches and remain usable offline.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            Button("Browse products") {
                AppRouter.shared.openBrowse()
                ToastCenter.shared.show("Browse travel essentials")
            }
            .font(.footnote.bold())
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

    private func favouriteRow(_ product: ProductEntity) -> some View {
        HStack(spacing: 11) {
            RemoteProductImage(urlString: product.image)
                .frame(width: 82, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(product.categoryDisplayName)
                    .font(.caption2.bold())
                    .foregroundStyle(Theme.muted)
                Text(product.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text("★ \(String(format: "%.1f", product.rating)) · \(product.isOutOfStock ? "Out of stock" : "In stock")")
                    .font(.caption2)
                    .foregroundStyle(product.isOutOfStock ? Theme.danger : Theme.muted)
                HStack {
                    Text(product.price, format: .currency(code: "USD"))
                        .font(.body.bold())
                    Spacer()
                    Button("Remove") {
                        vm.remove(product.id)
                        ToastCenter.shared.show("Removed from favourites")
                    }
                    .font(.footnote.bold())
                    .foregroundStyle(Theme.primary)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(product.title) from favourites")
                }
            }
        }
        .padding(14)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    FavouritesView()
}
