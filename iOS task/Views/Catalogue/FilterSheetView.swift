import SwiftUI

struct FilterSheetView: View {
    @Binding var showing: Bool
    @ObservedObject private var vm: CatalogueViewModel

    init(showing: Binding<Bool>) {
        _showing = showing
        _vm = ObservedObject(wrappedValue: CatalogueViewModel.shared)
    }

    private var categories: [CategoryInfo] {
        [CategoryInfo(slug: "All", name: "All")] + vm.availableCategories
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Filter & Sort")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button("Reset") {
                        vm.resetFilters()
                        ToastCenter.shared.show("Filters reset")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.primary)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset filters")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        categoryPicker
                        ratingSlider
                        sortPicker
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                }

                Button {
                    showing = false
                    ToastCenter.shared.show("Filters applied")
                } label: {
                    Text("Show results")
                        .font(.body.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .accessibilityLabel("Show filtered results")
            }
            .background(Theme.bg.ignoresSafeArea())
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.ink)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(categories) { cat in
                    let selected = vm.category == cat.slug || vm.category == cat.name
                        || (vm.category == "All" && cat.slug == "All")
                    Button {
                        vm.category = cat.slug
                    } label: {
                        Text(cat.name)
                            .font(.footnote.bold())
                            .foregroundStyle(selected ? Theme.primary : Theme.ink)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(selected ? Theme.soft : Theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selected ? Theme.primary.opacity(0.35) : Theme.line, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Category \(cat.name)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    private var ratingSlider: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Minimum rating")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(vm.minRating, specifier: "%.1f")+")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.primary)
            }
            Slider(value: $vm.minRating, in: 0...5, step: 0.5)
                .tint(Theme.primary)
                .accessibilityLabel("Minimum rating")
                .accessibilityValue("\(vm.minRating, specifier: "%.1f") stars")
        }
    }

    private var sortPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sort by")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.ink)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    let selected = vm.sort == option
                    Button {
                        vm.sort = option
                    } label: {
                        Text(option.displayName)
                            .font(.footnote.bold())
                            .foregroundStyle(selected ? Theme.primary : Theme.ink)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(selected ? Theme.soft : Theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selected ? Theme.primary.opacity(0.35) : Theme.line, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Sort by \(option.displayName)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }
}

#Preview {
    FilterSheetView(showing: .constant(true))
}
