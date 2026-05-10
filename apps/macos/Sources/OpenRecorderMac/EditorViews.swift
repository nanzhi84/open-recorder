import AVFoundation
import AppKit
import CoreGraphics
import SwiftUI
import UniformTypeIdentifiers

struct EditorStudioView: View {
    @EnvironmentObject private var model: AppModel
    var editorSession: EditorSession?
    @ObservedObject var timelineEdits: TimelineEditController
    @ObservedObject var screenshotEditor: ScreenshotEditorController

    var body: some View {
        if screenshotURL != nil {
            ScreenshotEditorStudioView(screenshotURL: screenshotURL, editor: screenshotEditor)
        } else {
            VideoEditorStudioView(
                videoURL: videoURL,
                recordingSession: recordingSession,
                initialTimelineEdits: editorSession?.timelineEditSnapshot,
                editorSessionID: editorSession?.id,
                timelineEdits: timelineEdits
            )
        }
    }

    private var videoURL: URL? {
        if let editorSession {
            return editorSession.kind == .video ? editorSession.url : nil
        }
        return model.currentVideoURL
    }

    private var screenshotURL: URL? {
        if let editorSession {
            return editorSession.kind == .screenshot ? editorSession.url : nil
        }
        return model.currentScreenshotURL
    }

    private var recordingSession: RecordingSession? {
        editorSession?.recordingSession ?? model.lastEditorSession?.recordingSession
    }
}

struct VideoEditorStudioView: View {
    @EnvironmentObject private var model: AppModel
    var videoURL: URL?
    var recordingSession: RecordingSession?
    var initialTimelineEdits: TimelineEditSnapshot?
    var editorSessionID: UUID?
    @StateObject private var playback = VideoPlaybackController()
    @ObservedObject var timelineEdits: TimelineEditController
    @State private var borderRadius = 12.0
    @State private var padding = 18.0
    @State private var shadow = 0.35
    @State private var backgroundBlur = 0.0
    @State private var background: BackgroundStyle = BackgroundPresets.default
    @State private var inset = 0.0
    @State private var insetColor = SerializableColor(hex: "#276FAA")
    @State private var insetOpacity = 1.0
    @State private var insetBalance = VideoInsetBalance.centered
    @State private var showCursorOverlay = true
    @State private var loopCursor = false
    @State private var cursorSize = 1.0
    @State private var cursorSmoothing = 0.40
    @State private var activeSheet: VideoEditorSheet?
    @State private var presentedSheet: VideoEditorSheet?
    @State private var videoCropSelection = VideoCropSelection.fullFrame
    @State private var previewAspectPreset: VideoPreviewAspectPreset = .auto
    @State private var appliedTimelineIdentity: String?
    @State private var appliedCursorSettingsIdentity: String?
    private let sidebarWidth: CGFloat = 320
    private let timelineHeight = TimelineMetrics.compactPanelHeight

    var body: some View {
        StudioSplitPane(
            axis: .horizontal,
            secondarySize: sidebarWidth,
            minPrimarySize: 520,
            minSecondarySize: 280,
            maxSecondarySize: 440
        ) {
            editorColumn
        } secondary: {
            sidebarContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
        .background(Color.studioMutedBackground)
        .sheet(item: $activeSheet, onDismiss: handleSheetDismiss) { sheet in
            switch sheet {
            case .export:
                exportDialog
            case .crop(let cropVideoURL):
                cropDialog(videoURL: cropVideoURL)
            }
        }
        .onChange(of: model.videoExportRequestID) { _, requestID in
            guard requestID != nil, videoURL != nil else { return }
            presentSheet(.export)
        }
        .onChange(of: videoURL) { _, _ in
            videoCropSelection = .fullFrame
            previewAspectPreset = .auto
            applyInitialTimelineEdits()
            applyInitialCursorSettings()
        }
        .onChange(of: editorSessionID) { _, _ in
            videoCropSelection = .fullFrame
            previewAspectPreset = .auto
            applyInitialTimelineEdits()
            applyInitialCursorSettings()
        }
        .onAppear {
            applyInitialTimelineEdits()
            applyInitialCursorSettings()
        }
        .background {
            StudioKeyDownMonitor { event in
                handleEditorShortcut(event)
            }
            .frame(width: 0, height: 0)
        }
    }

    private var editorColumn: some View {
        StudioSplitPane(
            axis: .vertical,
            secondarySize: timelineHeight,
            minPrimarySize: 260,
            minSecondarySize: TimelineMetrics.compactPanelHeight,
            maxSecondarySize: TimelineMetrics.compactPanelHeight
        ) {
            VideoPreviewPanel(
                videoURL: videoURL,
                recordingSession: recordingSession,
                playback: playback,
                timelineEdits: timelineEdits,
                background: background,
                padding: padding,
                borderRadius: borderRadius,
                shadow: shadow,
                backgroundBlur: backgroundBlur,
                inset: inset,
                insetColor: insetColor,
                insetOpacity: insetOpacity,
                insetBalance: insetBalance,
                cursorTelemetryURL: cursorTelemetryURL,
                cursorSettings: cursorOverlaySettings,
                cropSelection: videoCropSelection,
                previewAspectPreset: $previewAspectPreset,
                onCropVideo: {
                    guard let videoURL else { return }
                    playback.pause()
                    presentSheet(.crop(videoURL))
                },
                onRequestClearSelection: {
                    timelineEdits.clearSelection()
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } secondary: {
            TimelinePanel(videoURL: videoURL, playback: playback, edits: timelineEdits)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var sidebarContent: some View {
        if timelineEdits.hasSelection {
            TimelineSelectionSidebar(edits: timelineEdits, playback: playback)
        } else {
            SettingsInspector(
                borderRadius: $borderRadius,
                padding: $padding,
                shadow: $shadow,
                backgroundBlur: $backgroundBlur,
                background: $background,
                inset: $inset,
                insetColor: $insetColor,
                insetOpacity: $insetOpacity,
                insetBalance: $insetBalance,
                showCursor: $showCursorOverlay,
                loopCursor: $loopCursor,
                cursorSize: $cursorSize,
                cursorSmoothing: $cursorSmoothing,
                recordingSession: recordingSession
            )
        }
    }

    private func handleEditorShortcut(_ event: NSEvent) -> Bool {
        guard !isTextInputActive else { return false }
        guard editorShortcutModifiersAreAllowed(event.modifierFlags) else { return false }

        let key = (event.charactersIgnoringModifiers ?? event.characters ?? "").lowercased()
        switch key {
        case " ":
            guard !event.isARepeat else { return true }
            playback.togglePlayback()
            return true
        case "z":
            guard !event.isARepeat else { return true }
            timelineEdits.add(.zoom, at: playback.currentTime, duration: playback.duration)
            return true
        case "s":
            guard !event.isARepeat else { return true }
            timelineEdits.cycleClipSpeed(at: playback.currentTime, duration: playback.duration)
            return true
        case "t":
            guard !event.isARepeat else { return true }
            timelineEdits.addClipSplit(at: playback.currentTime, duration: playback.duration)
            return true
        default:
            return false
        }
    }

    private var isTextInputActive: Bool {
        guard let responder = NSApp.keyWindow?.firstResponder else { return false }
        return responder is NSTextView || responder is NSTextField
    }

    private func editorShortcutModifiersAreAllowed(_ modifiers: NSEvent.ModifierFlags) -> Bool {
        modifiers.intersection([.command, .control, .option]).isEmpty
    }

    private var exportDialog: some View {
        VideoExportDialog(
            phase: model.videoExportPhase,
            progress: model.videoExportProgress,
            errorMessage: model.videoExportError,
            exportedFileName: model.exportedVideoURL?.lastPathComponent,
            isExporting: model.isVideoExporting,
            initialOptions: VideoExportOptions.default.withCropSelection(videoCropSelection),
            onExport: { options in
                let styled = options.with(
                    background: background,
                    padding: padding,
                    borderRadius: borderRadius,
                    shadow: shadow,
                    backgroundBlur: backgroundBlur,
                    inset: inset,
                    insetColor: insetColor,
                    insetOpacity: insetOpacity,
                    insetBalance: insetBalance
                )
                .withCursorOverlay(cursorOverlaySettings, telemetryURL: cursorTelemetryURL)
                model.exportCurrentRecording(model.videoExportRequestURL ?? videoURL, options: styled, edits: timelineEdits.snapshot)
            },
            onRetrySave: {
                model.retryPendingVideoExportSave()
            },
            onShowInFinder: {
                model.revealExportedVideoInFinder()
            },
            onCancelExport: {
                model.cancelVideoExport()
            },
            onClose: {
                activeSheet = nil
            }
        )
        .frame(width: 420)
        .interactiveDismissDisabled(model.videoExportPhase.isBusy)
    }

    private func cropDialog(videoURL: URL) -> some View {
        VideoCropDialog(
            videoURL: videoURL,
            initialSelection: videoCropSelection,
            initialTime: playback.currentTime,
            sourceSize: playback.naturalVideoSize,
            onConfirm: { selection in
                videoCropSelection = selection
                activeSheet = nil
            },
            onCancel: {
                activeSheet = nil
            }
        )
    }

    private func presentSheet(_ sheet: VideoEditorSheet) {
        presentedSheet = sheet
        activeSheet = sheet
    }

    private func handleSheetDismiss() {
        if presentedSheet == .export, !model.videoExportPhase.isBusy {
            model.clearVideoExportDialogState()
        }
        presentedSheet = nil
    }

    private func applyInitialTimelineEdits() {
        let identity = editorSessionID?.uuidString ?? videoURL?.path ?? "empty"
        guard appliedTimelineIdentity != identity else { return }
        appliedTimelineIdentity = identity
        timelineEdits.applySnapshot(initialTimelineEdits ?? .empty)
    }

    private var cursorOverlaySettings: CursorOverlaySettings {
        CursorOverlaySettings(
            isVisible: showCursorOverlay,
            loops: loopCursor,
            size: cursorSize,
            smoothing: cursorSmoothing
        )
        .clamped
    }

    private var cursorTelemetryURL: URL? {
        if let path = recordingSession?.cursorTelemetryPath {
            return URL(fileURLWithPath: path)
        }

        guard let videoURL else { return nil }
        let derivedURL = CursorTelemetryRecorder.telemetryURL(for: videoURL)
        return FileManager.default.fileExists(atPath: derivedURL.path) ? derivedURL : nil
    }

    private func applyInitialCursorSettings() {
        let identity = editorSessionID?.uuidString ?? recordingSession?.screenVideoPath ?? videoURL?.path ?? "empty"
        guard appliedCursorSettingsIdentity != identity else { return }
        appliedCursorSettingsIdentity = identity

        let defaults = CursorOverlaySettings.default
        showCursorOverlay = recordingSession?.showCursorOverlay ?? model.showCursor
        loopCursor = defaults.loops
        cursorSize = defaults.size
        cursorSmoothing = defaults.smoothing
    }
}

private enum VideoEditorSheet: Identifiable, Equatable {
    case export
    case crop(URL)

    var id: String {
        switch self {
        case .export:
            "export"
        case .crop(let videoURL):
            "crop:\(videoURL.path)"
        }
    }
}
