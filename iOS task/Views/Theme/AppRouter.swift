import Combine
import Foundation
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()
    @Published var selectedTab: Int = 0

    func openBrowse() { selectedTab = 0 }
    func openSaved() { selectedTab = 1 }
    func openOrders() { selectedTab = 2 }
}
