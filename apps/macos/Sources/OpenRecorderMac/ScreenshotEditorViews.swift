import AVFoundation
import AppKit
import CoreGraphics
import SwiftUI
import UniformTypeIdentifiers

struct ScreenshotEditorStudioView: View {
    @EnvironmentObject private var model: AppModel
    var screenshotURL: URL?
    @ObservedObject var editor: ScreenshotEditorController
    @State private var isExportDialogPresented = false
    private let sidebarWidth: CGFloat = 320

    var body: some View {
        StudioSplitPane(
            axis: .horizontal,
            secondarySize: sidebarWidth,
            minPrimarySize: 520,
            minSecondarySize: 280,
            maxSecondarySize: 440
        ) {
            ScreenshotCanvas(
                image: image,
                background: editor.state.background,
                padding: editor.state.padding,
                backgroundRoundness: editor.state.backgroundRoundness,
                backgroundShadow: editor.state.backgroundShadow,
                imageRoundness: editor.state.imageRoundness,
                imageShadow: editor.state.imageShadow
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } secondary: {
            ScreenshotSettingsPanel(
                background: editor.binding(for: \.background),
                padding: editor.binding(for: \.padding),
                backgroundRoundness: editor.binding(for: \.backgroundRoundness),
                backgroundShadow: editor.binding(for: \.backgroundShadow),
                imageRoundness: editor.binding(for: \.imageRoundness),
                imageShadow: editor.binding(for: \.imageShadow),
                onEditingChanged: handleUndoTransaction,
                onExport: {
                    isExportDialogPresented = true
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .background(Color.studioMutedBackground)
        .sheet(isPresented: $isExportDialogPresented) {
            ScreenshotExportDialog(
                onSave: saveComposedPNG,
                onCopy: copyComposedPNG
            )
            .frame(width: 360)
        }
        .onChange(of: model.screenshotExportRequestID) { _, requestID in
            guard requestID != nil, screenshotURL != nil else { return }
            isExportDialogPresented = true
        }
        .onChange(of: screenshotURL) { _, _ in
            editor.resetHistory()
        }
    }

    private var image: NSImage? {
        guard let url = screenshotURL else { return nil }
        return NSImage(contentsOf: url)
    }

    private func saveComposedPNG() {
        guard let data = renderComposedPNG() else {
            model.statusMessage = "Failed to render screenshot."
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedExportFileName

        guard panel.runModal() == .OK, let targetURL = panel.url else {
            return
        }

        do {
            try data.write(to: targetURL, options: .atomic)
            model.statusMessage = "Exported \(targetURL.lastPathComponent)"
        } catch {
            model.statusMessage = error.localizedDescription
        }
    }

    private func copyComposedPNG() {
        guard let data = renderComposedPNG() else {
            model.statusMessage = "Failed to render screenshot."
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
        if let image = NSImage(data: data), let tiffData = image.tiffRepresentation {
            pasteboard.setData(tiffData, forType: .tiff)
        }
        model.statusMessage = "Screenshot PNG copied"
    }

    private var suggestedExportFileName: String {
        ScreenshotExportRenderer.suggestedFileName(for: screenshotURL)
    }

    private func renderComposedPNG() -> Data? {
        guard let image else { return nil }
        let renderer = ScreenshotExportRenderer(configuration: ScreenshotExportConfiguration(
            background: editor.state.background,
            padding: editor.state.padding,
            backgroundRoundness: editor.state.backgroundRoundness,
            backgroundShadow: editor.state.backgroundShadow,
            imageRoundness: editor.state.imageRoundness,
            imageShadow: editor.state.imageShadow
        ))
        return renderer.renderPNG(from: image)
    }

    private func handleUndoTransaction(_ isEditing: Bool) {
        if isEditing {
            editor.beginUndoTransaction()
        } else {
            editor.endUndoTransaction()
        }
    }
}

struct ScreenshotExportDialog: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: () -> Void
    var onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 34, height: 34)
                    .background(Color.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Export PNG")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Save or copy the composed screenshot.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 8) {
                StudioButton(hitTarget: .rounded(8)) {
                    onSave()
                    dismiss()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 36)
                        .padding(.horizontal, 12)
                        .background(Color.brand, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.white)
                }

                StudioButton(hitTarget: .rounded(8)) {
                    onCopy()
                    dismiss()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 36)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.primary)
                }
            }

            StudioButton(hitTarget: .rectangle) {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .background(Color.studioPanel)
    }
}

struct ScreenshotCanvas: View {
    var image: NSImage?
    var background: BackgroundStyle
    var padding: Double
    var backgroundRoundness: Double
    var backgroundShadow: Double
    var imageRoundness: Double
    var imageShadow: Double

    var body: some View {
        ZStack {
            if let image {
                screenshotStage(image)
                    .padding(32)
            } else {
                EmptyEditorState()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .studioEditorPaneChrome()
    }

    private func screenshotStage(_ image: NSImage) -> some View {
        ZStack {
            BackgroundFillView(style: background)
                .clipShape(RoundedRectangle(cornerRadius: backgroundRoundness, style: .continuous))
                .shadow(
                    color: Color.black.opacity(0.45 * backgroundShadow),
                    radius: 34 * backgroundShadow,
                    y: 14 * backgroundShadow
                )
                .overlay {
                    RoundedRectangle(cornerRadius: backgroundRoundness, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }

            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: imageRoundness, style: .continuous))
                .shadow(
                    color: Color.black.opacity(0.55 * imageShadow),
                    radius: 38 * imageShadow,
                    y: 18 * imageShadow
                )
                .padding(CGFloat(padding))
        }
    }
}

struct ScreenshotSettingsPanel: View {
    @EnvironmentObject private var model: AppModel
    @Binding var background: BackgroundStyle
    @Binding var padding: Double
    @Binding var backgroundRoundness: Double
    @Binding var backgroundShadow: Double
    @Binding var imageRoundness: Double
    @Binding var imageShadow: Double
    var onEditingChanged: (Bool) -> Void = { _ in }
    var onExport: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    BackgroundPickerView(selection: $background)
                    InspectorGroup(title: "Background Layer", symbolName: "rectangle.fill") {
                        InspectorSlider(title: "Padding", valueText: "\(Int(padding))px", value: $padding, range: 0...140, step: 1, onEditingChanged: onEditingChanged)
                        InspectorSlider(title: "Roundness", valueText: "\(Int(backgroundRoundness))px", value: $backgroundRoundness, range: 0...64, step: 1, onEditingChanged: onEditingChanged)
                        InspectorSlider(title: "Shadow", valueText: "\(Int(backgroundShadow * 100))%", value: $backgroundShadow, range: 0...1, step: 0.01, onEditingChanged: onEditingChanged)
                    }
                    InspectorGroup(title: "Image Layer", symbolName: "photo") {
                        InspectorSlider(title: "Roundness", valueText: "\(Int(imageRoundness))px", value: $imageRoundness, range: 0...48, step: 1, onEditingChanged: onEditingChanged)
                        InspectorSlider(title: "Shadow", valueText: "\(Int(imageShadow * 100))%", value: $imageShadow, range: 0...1, step: 0.01, onEditingChanged: onEditingChanged)
                    }
                }
                .padding(14)
            }

            Rectangle()
                .fill(Color.studioBorder)
                .frame(height: 1)

            HStack(spacing: 8) {
                InspectorFooterButton(title: "Reveal File", symbolName: "folder") {
                    if let url = model.currentScreenshotURL {
                        model.reveal(url.path)
                    }
                }
                InspectorFooterButton(title: "Export", symbolName: "square.and.arrow.up") {
                    onExport()
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.025))
        }
        .studioEditorPaneChrome()
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "photo")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.brand)
                .frame(width: 30, height: 30)
                .background(Color.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 3) {
                Text("Screenshot Settings")
                    .font(.system(size: 14, weight: .semibold))
                Text("Separate background and image layer styling.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.06))
        }
    }

}

struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let tile: CGFloat = 18
            let columns = Int(ceil(size.width / tile))
            let rows = Int(ceil(size.height / tile))
            for row in 0...rows {
                for column in 0...columns {
                    let isLight = (row + column).isMultiple(of: 2)
                    let rect = CGRect(x: CGFloat(column) * tile, y: CGFloat(row) * tile, width: tile, height: tile)
                    context.fill(Path(rect), with: .color(isLight ? Color.white.opacity(0.18) : Color.white.opacity(0.08)))
                }
            }
        }
        .background(Color.black.opacity(0.25))
    }
}
