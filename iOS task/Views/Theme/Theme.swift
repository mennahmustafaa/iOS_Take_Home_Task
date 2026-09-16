import SwiftUI

enum Theme {
    static let primary = Color(red: 23/255, green: 92/255, blue: 211/255)
    static let ink = Color(red: 18/255, green: 32/255, blue: 51/255)
    static let muted = Color(red: 112/255, green: 128/255, blue: 150/255)
    static let line = Color(red: 229/255, green: 234/255, blue: 241/255)
    static let success = Color(red: 19/255, green: 138/255, blue: 105/255)
    static let warn = Color(red: 169/255, green: 109/255, blue: 23/255)
    static let danger = Color(red: 198/255, green: 56/255, blue: 75/255)
    static let bg = Color(red: 245/255, green: 247/255, blue: 251/255)
    static let card = Color.white
    static let soft = Color(red: 237/255, green: 244/255, blue: 255/255)

    static let brandGradient = LinearGradient(
        colors: [
            Color(red: 16/255, green: 47/255, blue: 92/255),
            Color(red: 23/255, green: 101/255, blue: 199/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func shimmer() -> some View {
        self.redacted(reason: .placeholder)
    }
}
