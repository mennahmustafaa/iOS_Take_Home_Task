import Combine
import Foundation
import SwiftUI

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    @Published private(set) var message: String?
    private var hideTask: Task<Void, Never>?

    func show(_ text: String) {
        hideTask?.cancel()
        message = text
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            if message == text {
                message = nil
            }
        }
    }
}

struct ToastBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(red: 23/255, green: 37/255, blue: 54/255))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.18), radius: 16, y: 8)
            .padding(.horizontal, 17)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityLabel(message)
    }
}

struct ToastOverlayModifier: ViewModifier {
    @ObservedObject private var toast = ToastCenter.shared

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message = toast.message {
                ToastBanner(message: message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 88)
                    .zIndex(50)
            }
        }
        .animation(.easeOut(duration: 0.2), value: toast.message)
    }
}

extension View {
    func tripStoreToasts() -> some View {
        modifier(ToastOverlayModifier())
    }
}
