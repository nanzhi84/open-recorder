import AVFoundation
import AppKit
import CoreGraphics
import SwiftUI
import UniformTypeIdentifiers

struct SourceSelectorWindowView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismissWindow) private var dismissWindow
    private var sourceSelector: SourceSelectorDriver {
        model.appShell.floatingSourceSelector
    }

    private var visibleTabs: [SourceSelectorTab] {
        [.windows, .area]
    }

    var body: some View {
        VStack(spacing: 0) {
            SourceSelectorCard(
                sourceTab: sourceSelector.sourceTabBinding,
                visibleTabs: sourceSelector.state.visibleTabs,
                allSources: model.capture.sources,
                selectedSourceID: model.selectedSource?.id,
                captureMode: model.captureMode,
                onCancel: {
                    sourceSelector.send(.cancelRequested)
                },
                onRefresh: {
                    sourceSelector.send(.refreshRequested)
                },
                onSelectSource: { source in
                    model.selectSource(source)
                },
                onShare: {
                    sourceSelector.send(.shareRequested)
                },
                onDrawArea: {
                    sourceSelector.send(.drawAreaRequested)
                }
            )
            .padding(16)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SourceSelectorCardHeightPreferenceKey.self, value: proxy.size.height)
                }
            }
        }
        .background(SourceSelectorWindowSizer(size: CGSize(width: SourceSelectorWindowMetrics.width, height: sourceSelector.state.preferredHeight)))
        .background(Theme.appBg.ignoresSafeArea())
        .onPreferenceChange(SourceSelectorCardHeightPreferenceKey.self) { cardHeight in
            sourceSelector.send(.heightMeasured(cardHeight))
        }
        .onAppear {
            sourceSelector.configure(
                refreshSources: {
                    model.reloadSourcesForPreview()
                },
                cancel: {
                    model.cancelCapture()
                },
                share: {
                    if let selectedSource = model.selectedSource {
                        model.selectSource(selectedSource)
                    }
                    dismissWindow(id: "source-selector")
                },
                drawArea: {
                    model.selectInteractiveAreaSource()
                    dismissWindow(id: "source-selector")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        model.requestInteractiveAreaSelection()
                    }
                }
            )
            applyPreferredSourceTab()
            sourceSelector.send(.refreshRequested)
        }
        .onChange(of: model.preferredSourceSelectorKind) { _, _ in
            applyPreferredSourceTab()
        }
    }

    private func applyPreferredSourceTab() {
        let preferredKind = model.preferredSourceSelectorKind ?? model.selectedSource?.kind ?? .window
        sourceSelector.send(.tabSelected(preferredKind == .display ? .windows : SourceSelectorTab(sourceKind: preferredKind)))
    }
}



enum SourceSelectorTab: String, CaseIterable, Identifiable {
    case screens
    case windows
    case area

    var id: String { rawValue }

    init(sourceKind: CaptureSourceKind) {
        switch sourceKind {
        case .display:
            self = .screens
        case .window:
            self = .windows
        case .area:
            self = .area
        }
    }

    var title: String {
        switch self {
        case .screens: "Screens"
        case .windows: "Windows"
        case .area: "Area"
        }
    }

    var symbolName: String {
        switch self {
        case .screens: "display"
        case .windows: "macwindow"
        case .area: "rectangle.dashed"
        }
    }
}


struct SourceSelectorCard: View {
    @Binding var sourceTab: SourceSelectorTab
    var visibleTabs: [SourceSelectorTab]
    var allSources: [CaptureSource]
    var selectedSourceID: String?
    var captureMode: CaptureMode
    var onCancel: (() -> Void)? = nil
    var onRefresh: (() -> Void)? = nil
    var onSelectSource: (CaptureSource) -> Void = { _ in }
    var onShare: (() -> Void)? = nil
    var onDrawArea: (() -> Void)? = nil

    private var sources: [CaptureSource] {
        switch sourceTab {
        case .screens:
            allSources.filter { $0.kind == .display }
        case .windows:
            allSources.filter { $0.kind == .window }
        case .area:
            allSources.filter { $0.kind == .area }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Choose what to share")
                        .font(.system(size: 18, weight: .semibold))
                    Text(L10n.string(selectorDescription))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(L10n.string("%d sources", allSources.filter { $0.kind != .area }.count))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.border)
                    }
            }
            .padding(16)

            VStack(spacing: 14) {
                SourceTabs(sourceTab: $sourceTab, visibleTabs: visibleTabs)

                if sources.isEmpty {
                    SourceEmptyState(sourceTab: sourceTab, onDrawArea: onDrawArea)
                } else {
                    SourceGrid(
                        sources: sources,
                        sourceTab: sourceTab,
                        selectedSourceID: selectedSourceID,
                        onSelectSource: onSelectSource
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            HStack {
                StudioButton(hitTarget: .rounded(8)) {
                    onCancel?()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .frame(height: 34)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
                }
                .foregroundStyle(.secondary)

                StudioButton(hitTarget: .rounded(8)) {
                    onRefresh?()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .frame(height: 34)
                        .padding(.horizontal, 12)
                        .background(Theme.overlay, in: RoundedRectangle(cornerRadius: 8))
                }
                .foregroundStyle(.secondary)

                Spacer()

                StudioButton(hitTarget: .rounded(8)) {
                    onShare?()
                } label: {
                    Text("Share Source")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(height: 34)
                        .padding(.horizontal, 14)
                        .background(canShareSource ? Theme.accent : Theme.border, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(canShareSource ? Color.white : Color.secondary)
                }
                .disabled(!canShareSource || onShare == nil)
            }
            .padding(16)
        }
        .background(Theme.surface.opacity(0.96), in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border)
        }
        .shadow(color: Color.black.opacity(0.35), radius: 26, y: 18)
    }

    private var selectorDescription: String {
        if captureMode == .screenshot {
            "Pick a screen, app window, or drawn area for this screenshot."
        } else {
            "Pick a screen, app window, or drawn area for the next recording."
        }
    }

    private var canShareSource: Bool {
        guard let selectedSourceID else {
            return false
        }
        return sources.contains { $0.id == selectedSourceID }
    }
}

struct SourceTabs: View {
    @Binding var sourceTab: SourceSelectorTab
    var visibleTabs: [SourceSelectorTab]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(visibleTabs) { tab in
                StudioSegmentedTabButton(
                    title: tab.title,
                    symbolName: tab.symbolName,
                    isSelected: sourceTab == tab
                ) {
                    sourceTab = tab
                }
            }
        }
        .padding(4)
        .background(Theme.surfaceControl, in: RoundedRectangle(cornerRadius: 9))
    }
}

struct StudioSegmentedTabButton: View {
    var title: String
    var symbolName: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        StudioButton(hitTarget: .rounded(7), action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                Text(L10n.string(title))
            }
            .font(.system(size: 12, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .background(isSelected ? Theme.border : Color.clear, in: RoundedRectangle(cornerRadius: 7))
        }
    }
}

struct SourceGrid: View {
    var sources: [CaptureSource]
    var sourceTab: SourceSelectorTab
    var selectedSourceID: String?
    var onSelectSource: (CaptureSource) -> Void

    private var columns: [GridItem] {
        let count = sourceTab == .windows ? 3 : min(max(sources.count, 1), 3)
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    var body: some View {
        if sourceTab == .windows {
            ScrollView(.vertical) {
                grid
                    .padding(.trailing, 2)
            }
            .frame(maxHeight: 356)
            .scrollClipDisabled(false)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            grid
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(sources) { source in
                SourceTile(
                    source: source,
                    isSelected: selectedSourceID == source.id,
                    isCompact: sourceTab == .windows
                ) {
                    onSelectSource(source)
                }
            }
        }
        .clipped()
    }
}

struct SourceTile: View {
    var source: CaptureSource
    var isSelected: Bool
    var isCompact: Bool
    var action: () -> Void

    var body: some View {
        StudioButton(hitTarget: .rounded(9), action: action) {
            if isCompact {
                squareContent
            } else {
                standardContent
            }
        }
    }

    private var standardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            SourceThumbnailPreview(
                source: source,
                isSelected: isSelected,
                isCompact: isCompact
            )
            .aspectRatio(previewAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)

            labels
        }
        .padding(8)
        .background(Theme.surfaceRaised.opacity(0.8), in: RoundedRectangle(cornerRadius: 9))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(isSelected ? Theme.accent : Theme.border, lineWidth: isSelected ? 2 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var squareContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            SourceThumbnailPreview(
                source: source,
                isSelected: isSelected,
                isCompact: isCompact
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            labels
        }
        .padding(4)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceRaised.opacity(0.8), in: RoundedRectangle(cornerRadius: 9))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(isSelected ? Theme.accent : Theme.border, lineWidth: isSelected ? 2 : 1)
        }
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(source.name)
                    .font(.system(size: isCompact ? 12 : 13, weight: .medium))
                    .lineLimit(1)
                Spacer()
                if isSelected {
                    Text("Selected")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.overlay, in: RoundedRectangle(cornerRadius: 5))
                }
            }
            Text(L10n.string(source.subtitle))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewAspectRatio: CGFloat {
        source.kind == .window ? 1.6 : 16.0 / 9.0
    }
}

struct SourceThumbnailPreview: View {
    var source: CaptureSource
    var isSelected: Bool
    var isCompact: Bool

    private var aspectRatio: CGFloat {
        source.kind == .window ? 1.6 : 16.0 / 9.0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Theme.overlay)

            if let thumbnail = source.thumbnailData,
               let image = NSImage(data: thumbnail) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                thumbnailPlaceholder
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if isSelected {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 18, height: 18)
                            .background(Theme.accent, in: Circle())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(6)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        }
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            Image(systemName: source.kind == .window ? "macwindow" : source.kind == .area ? "rectangle.dashed" : "display")
                .font(.system(size: isCompact ? 18 : 24, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

}

struct SourceEmptyState: View {
    var sourceTab: SourceSelectorTab
    var onDrawArea: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: sourceTab.symbolName)
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .frame(width: 64, height: 64)
                .background(Theme.overlay, in: RoundedRectangle(cornerRadius: 14))
            Text(L10n.string(sourceTab == .area ? "Draw a capture area" : "No sources available"))
                .font(.system(size: 15, weight: .semibold))
            Text(L10n.string(sourceTab == .area ? "Select the part of the screen you want to capture." : "Try a different tab or make sure the source is visible."))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            if sourceTab == .area {
                StudioButton(hitTarget: .rounded(8)) {
                    onDrawArea?()
                } label: {
                    Label("Draw Selection", systemImage: "rectangle.dashed")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(height: 34)
                        .padding(.horizontal, 12)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 210)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
    }
}
