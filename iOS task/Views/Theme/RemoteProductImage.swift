import SwiftUI
import UIKit

/// Reliable remote image view for DummyJSON thumbnails (handles awkward URL characters + shared URLCache).
struct RemoteProductImage: View {
    let urlString: String
    var contentMode: ContentMode = .fill

    @State private var loadedImage: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if failed {
                placeholder
            } else {
                placeholder
                    .overlay(ProgressView().scaleEffect(0.8))
            }
        }
        .task(id: urlString) {
            await load()
        }
    }

    private var placeholder: some View {
        Color(red: 238/255, green: 241/255, blue: 245/255)
            .overlay(
                Image(systemName: "photo")
                    .foregroundStyle(Theme.muted)
            )
    }

    @MainActor
    private func load() async {
        loadedImage = nil
        failed = false
        guard let url = ImageURLFactory.make(urlString) else {
            failed = true
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 20

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                failed = true
                return
            }
            guard let image = UIImage(data: data) else {
                failed = true
                return
            }
            loadedImage = image
        } catch {
            if !Task.isCancelled {
                failed = true
            }
        }
    }
}
