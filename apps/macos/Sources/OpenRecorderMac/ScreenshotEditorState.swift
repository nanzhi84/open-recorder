import Foundation
import SwiftUI

struct ScreenshotEditorState: Equatable {
    var background: BackgroundStyle = BackgroundPresets.default
    var padding = 56.0
    var backgroundRoundness = 28.0
    var backgroundShadow = 0.0
    var imageRoundness = 10.0
    var imageShadow = 0.45

    static let `default` = ScreenshotEditorState()
}

@MainActor
final class ScreenshotEditorController: ObservableObject {
    @Published private(set) var state = ScreenshotEditorState.default
    private var history = EditorHistory<ScreenshotEditorState>()

    var canUndo: Bool { history.canUndo }
    var canRedo: Bool { history.canRedo }

    func undo() {
        guard let previous = history.undo(current: state) else { return }
        state = previous
    }

    func redo() {
        guard let next = history.redo(current: state) else { return }
        state = next
    }

    func resetHistory() {
        history.reset()
        objectWillChange.send()
    }

    func beginUndoTransaction() {
        history.beginTransaction(current: state)
    }

    func endUndoTransaction() {
        if history.commitTransaction(current: state) {
            objectWillChange.send()
        }
    }

    func update<Value: Equatable>(_ keyPath: WritableKeyPath<ScreenshotEditorState, Value>, to value: Value) {
        var next = state
        guard next[keyPath: keyPath] != value else { return }
        let before = state
        next[keyPath: keyPath] = value
        state = next
        history.recordChange(from: before, to: next)
    }

    func binding<Value: Equatable>(for keyPath: WritableKeyPath<ScreenshotEditorState, Value>) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.update(keyPath, to: $0) }
        )
    }
}
