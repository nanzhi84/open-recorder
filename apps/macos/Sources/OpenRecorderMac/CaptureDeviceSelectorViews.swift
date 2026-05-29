import SwiftUI

enum CaptureDeviceSelectorWindowMetrics {
    static let width: CGFloat = 360
    static let height: CGFloat = 360
    static let minWidth: CGFloat = 320
    static let minHeight: CGFloat = 260
}

private enum CaptureDeviceDialogSelection: Equatable {
    case noInput
    case systemDefault
    case device(String)
}

struct MicrophoneSelectorWindowView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var pendingSelection: CaptureDeviceDialogSelection = .systemDefault
    private var options: CaptureOptionsState {
        model.captureOptions.state
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(Color.white.opacity(0.78))
                    .background(Theme.overlay, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Theme.border, lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Choose Microphone")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Pick the input to use for the next recording.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)

            ScrollView(.vertical) {
                VStack(spacing: 6) {
                    StudioButton(hitTarget: .rounded(8)) {
                        pendingSelection = .noInput
                    } label: {
                        microphoneRow(
                            title: "No Microphone",
                            subtitle: "Do not record microphone audio",
                            isSelected: pendingSelection == .noInput
                        )
                    }

                    StudioButton(hitTarget: .rounded(8)) {
                        pendingSelection = .systemDefault
                    } label: {
                        microphoneRow(
                            title: "System Default",
                            subtitle: "Use the current macOS default",
                            isSelected: pendingSelection == .systemDefault
                        )
                    }

                    ForEach(options.microphoneDevices) { device in
                        StudioButton(hitTarget: .rounded(8)) {
                            pendingSelection = .device(device.id)
                        } label: {
                            microphoneRow(
                                title: device.name,
                                subtitle: device.isDefault ? "Current macOS default" : "Microphone",
                                isSelected: pendingSelection == .device(device.id)
                            )
                        }
                    }

                    if options.microphoneDevices.isEmpty {
                        Text("No devices found")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 220)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            HStack {
                Spacer()
                StudioButton(hitTarget: .rounded(8)) {
                    model.cancelMicrophoneSelection()
                    dismissWindow(id: "microphone-selector")
                } label: {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .frame(height: 34)
                        .padding(.horizontal, 14)
                        .background(Theme.overlay, in: RoundedRectangle(cornerRadius: 8))
                }
                .foregroundStyle(.secondary)

                StudioButton(hitTarget: .rounded(8)) {
                    applyMicrophoneSelection()
                } label: {
                    Text("OK")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(height: 34)
                        .padding(.horizontal, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }
            }
            .padding(14)
        }
        .background(Theme.surface.opacity(0.96), in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border)
        }
        .padding(16)
        .background(Theme.appBg.ignoresSafeArea())
        .onAppear {
            resetPendingMicrophoneSelection()
        }
    }

    private func applyMicrophoneSelection() {
        switch pendingSelection {
        case .noInput:
            model.selectNoMicrophoneInput()
        case .systemDefault:
            model.selectMicrophoneDevice(nil)
        case .device(let deviceID):
            model.selectMicrophoneDevice(deviceID)
        }
        dismissWindow(id: "microphone-selector")
    }

    private func resetPendingMicrophoneSelection() {
        guard options.includeMicrophone else {
            pendingSelection = .systemDefault
            return
        }
        if let selectedMicrophoneDeviceID = options.selectedMicrophoneDeviceID {
            pendingSelection = .device(selectedMicrophoneDeviceID)
        } else {
            pendingSelection = .systemDefault
        }
    }

    private func microphoneRow(title: String, subtitle: String, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.accent : Theme.fgSubtle)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 48)
        .background(isSelected ? Theme.accent.opacity(0.14) : Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Theme.accent.opacity(0.36) : Theme.overlay, lineWidth: 1)
        }
    }
}

struct CameraSelectorWindowView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var pendingSelection: CaptureDeviceDialogSelection = .systemDefault
    private var options: CaptureOptionsState {
        model.captureOptions.state
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "video.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(Color.white.opacity(0.78))
                    .background(Theme.overlay, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Theme.border, lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Choose Camera")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Pick the camera to use for the next recording.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)

            ScrollView(.vertical) {
                VStack(spacing: 6) {
                    StudioButton(hitTarget: .rounded(8)) {
                        pendingSelection = .noInput
                    } label: {
                        cameraRow(
                            title: "No Camera",
                            subtitle: "Do not record facecam video",
                            isSelected: pendingSelection == .noInput
                        )
                    }

                    StudioButton(hitTarget: .rounded(8)) {
                        pendingSelection = .systemDefault
                    } label: {
                        cameraRow(
                            title: "System Default",
                            subtitle: "Use the current macOS default",
                            isSelected: pendingSelection == .systemDefault
                        )
                    }

                    ForEach(options.cameraDevices) { device in
                        StudioButton(hitTarget: .rounded(8)) {
                            pendingSelection = .device(device.id)
                        } label: {
                            cameraRow(
                                title: device.name,
                                subtitle: device.isDefault ? "Current macOS default" : "Camera",
                                isSelected: pendingSelection == .device(device.id)
                            )
                        }
                    }

                    if options.cameraDevices.isEmpty {
                        Text("No devices found")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 220)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            HStack {
                Spacer()
                StudioButton(hitTarget: .rounded(8)) {
                    model.cancelCameraSelection()
                    dismissWindow(id: "camera-selector")
                } label: {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .frame(height: 34)
                        .padding(.horizontal, 14)
                        .background(Theme.overlay, in: RoundedRectangle(cornerRadius: 8))
                }
                .foregroundStyle(.secondary)

                StudioButton(hitTarget: .rounded(8)) {
                    applyCameraSelection()
                } label: {
                    Text("OK")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(height: 34)
                        .padding(.horizontal, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }
            }
            .padding(14)
        }
        .background(Theme.surface.opacity(0.96), in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.border)
        }
        .padding(16)
        .background(Theme.appBg.ignoresSafeArea())
        .onAppear {
            resetPendingCameraSelection()
        }
    }

    private func applyCameraSelection() {
        switch pendingSelection {
        case .noInput:
            model.selectNoCameraInput()
        case .systemDefault:
            model.selectCameraDevice(nil)
        case .device(let deviceID):
            model.selectCameraDevice(deviceID)
        }
        dismissWindow(id: "camera-selector")
    }

    private func resetPendingCameraSelection() {
        guard options.includeCamera else {
            pendingSelection = .systemDefault
            return
        }
        if let selectedCameraDeviceID = options.selectedCameraDeviceID {
            pendingSelection = .device(selectedCameraDeviceID)
        } else {
            pendingSelection = .systemDefault
        }
    }

    private func cameraRow(title: String, subtitle: String, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? Theme.accent : Theme.fgSubtle)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 48)
        .background(isSelected ? Theme.accent.opacity(0.14) : Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Theme.accent.opacity(0.36) : Theme.overlay, lineWidth: 1)
        }
    }
}
