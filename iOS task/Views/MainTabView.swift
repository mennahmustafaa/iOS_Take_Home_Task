import SwiftUI

struct MainTabView: View {
    @ObservedObject private var favouritesVM = FavouritesViewModel.shared
    @ObservedObject private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.selectedTab) {
            CatalogueView()
                .tabItem {
                    Label("Browse", systemImage: "house.fill")
                }
                .tag(0)

            FavouritesView()
                .tabItem {
                    Label("Saved", systemImage: "heart.fill")
                }
                .badge(favouritesVM.count > 0 ? Text("\(favouritesVM.count)") : nil)
                .tag(1)

            OrdersView()
                .tabItem {
                    Label("Orders", systemImage: "shippingbox.fill")
                }
                .tag(2)
        }
        .tint(Theme.primary)
        .tripStoreToasts()
    }
}

#Preview {
    MainTabView()
}
