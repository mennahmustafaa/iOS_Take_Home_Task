import SwiftUI

struct CheckoutView: View {
    let product: ProductEntity
    let quantity: Int
    let subtotal: Double
    let serviceFee: Double
    let total: Double

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var ordersVM = OrdersViewModel.shared
    @State private var isConfirming = false
    @State private var didConfirm = false
    @State private var showSuccessAlert = false
    @State private var confirmedOrderID: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                reviewSection
                orderCard
                confirmButton
                Text("Confirm once to save a unique order ID and timestamp.")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Theme.bg)
        .navigationTitle("Review order")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ordersVM.resetSubmitFlag()
            isConfirming = false
            didConfirm = false
        }
        .alert("Order confirmed", isPresented: $showSuccessAlert) {
            Button("View orders") {
                ToastCenter.shared.show("Order \(confirmedOrderID) saved")
                AppRouter.shared.openOrders()
                dismiss()
            }
            Button("OK", role: .cancel) {
                ToastCenter.shared.show("Order confirmed")
                AppRouter.shared.openOrders()
                dismiss()
            }
        }         message: {
            Text("Order \(confirmedOrderID) confirmed. No payment was processed.")
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Review before confirming")
                .font(.title3.bold())
                .foregroundStyle(Theme.ink)
            Text("Local booking-style order · no payment or backend order is required.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var orderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    RemoteProductImage(urlString: product.image)
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title)
                        .font(.subheadline.bold())
                    Text("\(product.categoryDisplayName) · Quantity \(quantity)")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                    HStack(spacing: 4) {
                        Text(product.price, format: .currency(code: "USD"))
                            .font(.subheadline.bold())
                        Text("each")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                }
            }

            Divider()

            row("Subtotal", value: subtotal, bold: true)
            row("Service fee · 5%", value: serviceFee, muted: true)

            HStack {
                Text("Final total")
                    .font(.headline)
                Spacer()
                Text(total, format: .currency(code: "USD"))
                    .font(.headline)
            }
        }
        .padding(15)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 19)
                .stroke(Theme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 19))
    }

    private func row(_ title: String, value: Double, bold: Bool = false, muted: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(muted ? Theme.muted : Theme.ink)
            Spacer()
            Text(value, format: .currency(code: "USD"))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(muted ? Theme.muted : Theme.ink)
        }
        .font(.subheadline)
    }

    private var confirmButton: some View {
        Button {
            guard !isConfirming, !didConfirm else { return }
            isConfirming = true
            if let order = ordersVM.createOrder(product: product, quantity: quantity) {
                didConfirm = true
                confirmedOrderID = order.id
                ToastCenter.shared.show("Order confirmed")
                showSuccessAlert = true
            } else {
                isConfirming = false
                ToastCenter.shared.show("Could not create order. Check stock and try again.")
            }
        } label: {
            Text(didConfirm ? "Order confirmed" : "Confirm order · \(total, format: .currency(code: "USD"))")
                .font(.body.bold())
                .foregroundStyle((isConfirming || didConfirm) ? Color(red: 125/255, green: 135/255, blue: 148/255) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background((isConfirming || didConfirm) ? Color(red: 203/255, green: 211/255, blue: 222/255) : Theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .disabled(isConfirming || didConfirm)
        .buttonStyle(.plain)
        .accessibilityLabel("Confirm order")
    }
}

#Preview {
    NavigationStack {
        CheckoutView(
            product: ProductEntity(id: 1, title: "Sample", category: "beauty", price: 29.99, rating: 4.5, stock: 10, image: "", images: [], description: ""),
            quantity: 2,
            subtotal: 59.98,
            serviceFee: 3.0,
            total: 62.98
        )
    }
}
