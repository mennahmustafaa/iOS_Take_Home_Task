import SwiftUI

struct ProductDetailView: View {
    let product: ProductEntity
    @StateObject private var vm: ProductDetailViewModel
    @ObservedObject private var favouritesVM = FavouritesViewModel.shared
    @State private var showCheckout = false
    @ScaledMetric(relativeTo: .title2) private var priceSize: CGFloat = 26

    init(product: ProductEntity) {
        self.product = product
        _vm = StateObject(wrappedValue: ProductDetailViewModel(product: product))
    }

    private var galleryImages: [String] {
        if !product.images.isEmpty { return product.images }
        if !product.image.isEmpty { return [product.image] }
        return []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                gallerySection
                detailSection
            }
        }
        .background(Theme.bg)
        .navigationTitle("Product details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let wasFavourited = favouritesVM.isFavourited(product.id)
                    favouritesVM.toggle(product.id)
                    ToastCenter.shared.show(wasFavourited ? "Removed from favourites" : "Saved to favourites")
                } label: {
                    Image(systemName: favouritesVM.isFavourited(product.id) ? "heart.fill" : "heart")
                        .foregroundStyle(favouritesVM.isFavourited(product.id) ? Theme.danger : Theme.ink)
                }
                .accessibilityLabel(favouritesVM.isFavourited(product.id) ? "Remove favourite" : "Add favourite")
            }
        }
        .navigationDestination(isPresented: $showCheckout) {
            CheckoutView(
                product: product,
                quantity: vm.quantity,
                subtotal: vm.liveTotal,
                serviceFee: vm.serviceFee,
                total: vm.totalWithFee
            )
        }
    }

    private var gallerySection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                TabView(selection: $vm.galleryIndex) {
                    ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, urlString in
                        RemoteProductImage(urlString: urlString)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 275)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay {
                    if product.isOutOfStock {
                        VStack {
                            Spacer()
                            Text("OUT OF STOCK")
                                .font(.caption.bold())
                                .tracking(0.8)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Theme.danger)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }

                if galleryImages.count > 1 {
                    HStack(spacing: 5) {
                        ForEach(0..<min(galleryImages.count, 5), id: \.self) { i in
                            Capsule()
                                .fill(i == vm.galleryIndex ? Color.white : Color.white.opacity(0.55))
                                .frame(width: i == vm.galleryIndex ? 18 : 6, height: 6)
                        }
                    }
                    .padding(.bottom, product.isOutOfStock ? 44 : 12)
                }
            }

            if galleryImages.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, urlString in
                        Button {
                            withAnimation { vm.galleryIndex = index }
                        } label: {
                            RemoteProductImage(urlString: urlString)
                                .frame(width: 53, height: 53)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(index == vm.galleryIndex ? Theme.primary : Color.clear, lineWidth: 2)
                                )
                        }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Image \(index + 1)")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(product.categoryDisplayName)
                .font(.caption.bold())
                .foregroundStyle(Theme.primary)

            Text(product.title)
                .font(.title2.bold())
                .foregroundStyle(Theme.ink)

            Text(product.description.isEmpty ? "No description available." : product.description)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Text(product.price, format: .currency(code: "USD"))
                .font(.system(size: priceSize, weight: .heavy))

            Text("★ \(String(format: "%.2f", product.rating)) · Rated by travellers")
                .font(.footnote.bold())
                .foregroundStyle(Color(red: 134/255, green: 98/255, blue: 27/255))

            HStack(spacing: 8) {
                infoTile(title: "\(product.stock)", subtitle: "Available")
                infoTile(title: "5%", subtitle: "Service fee")
                infoTile(title: product.stock == 0 ? "Unavailable" : "Ready", subtitle: "Order status")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Quantity")
                    .font(.subheadline.bold())
                Text(product.stock == 0
                     ? "Ordering is disabled because this item is out of stock."
                     : "Choose from 1 to available stock.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)

                HStack(spacing: 12) {
                    Button {
                        vm.changeQuantity(-1)
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 34, height: 34)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .disabled(!vm.canOrder || vm.quantity <= 1)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Decrease quantity")

                    Text("\(vm.quantity)")
                        .font(.body.bold())
                        .frame(minWidth: 24)
                        .accessibilityLabel("Quantity \(vm.quantity)")

                    Button {
                        vm.changeQuantity(1)
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 34, height: 34)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .disabled(!vm.canOrder || vm.quantity >= product.stock)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Increase quantity")
                }
                .padding(6)
                .background(Color(red: 240/255, green: 243/255, blue: 247/255))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                if vm.canOrder {
                    showCheckout = true
                } else if product.isOutOfStock {
                    ToastCenter.shared.show("This item is out of stock")
                }
            } label: {
                Text(product.isOutOfStock ? "Out of stock — can't order" : "Continue · \(vm.totalWithFee, format: .currency(code: "USD"))")
                    .font(.body.bold())
                    .foregroundStyle(vm.canOrder ? .white : Color(red: 125/255, green: 135/255, blue: 148/255))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(vm.canOrder ? Theme.primary : Color(red: 203/255, green: 211/255, blue: 222/255))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .disabled(!vm.canOrder)
            .buttonStyle(.plain)
            .accessibilityLabel(product.isOutOfStock ? "Out of stock, ordering disabled" : "Continue to checkout")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    private func infoTile(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote.bold())
                .foregroundStyle(Theme.ink)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(red: 242/255, green: 245/255, blue: 249/255))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(
            product: ProductEntity(
                id: 1,
                title: "Essence Mascara",
                category: "beauty",
                price: 9.99,
                rating: 4.5,
                stock: 10,
                image: "",
                images: [],
                description: "A travel-ready mascara."
            )
        )
    }
}
