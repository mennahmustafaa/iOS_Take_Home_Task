import SwiftUI

struct OrdersView: View {
    @ObservedObject private var vm = OrdersViewModel.shared
    @ScaledMetric(relativeTo: .title) private var headerSize: CGFloat = 28
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 38

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    headerSection
                    banner
                    if vm.orders.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(vm.orders) { order in
                                OrderCard(order: order, formattedDate: vm.formattedDate)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Theme.bg)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Orders")
                .font(.system(size: headerSize, weight: .black, design: .rounded))
                .foregroundStyle(Theme.primary)
            Text("Local order history · available offline")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var banner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
            Text("Offline-ready")
                .font(.caption.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(red: 234/255, green: 248/255, blue: 243/255))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 204/255, green: 235/255, blue: 221/255), lineWidth: 1)
        )
        .foregroundStyle(Color(red: 20/255, green: 118/255, blue: 91/255))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: emptyIconSize))
                .foregroundStyle(Theme.muted)
            Text("No orders yet")
                .font(.headline)
            Text("Your orders will appear here.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
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
}

struct OrderCard: View {
    let order: OrderEntity
    let formattedDate: (Date) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(order.id) · \(formattedDate(order.timestamp))")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text("Confirmed")
                    .font(.caption2.bold())
                    .foregroundStyle(Theme.success)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(Color(red: 232/255, green: 247/255, blue: 241/255))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }

                HStack(spacing: 10) {
                    RemoteProductImage(urlString: order.productImage)
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(order.productTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.ink)
                    Text("Quantity \(order.quantity) · \(order.productCategory)")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
            }

            Divider()

            HStack {
                Text("Final total")
                    .font(.subheadline)
                Spacer()
                Text(order.total, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
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
    OrdersView()
}
