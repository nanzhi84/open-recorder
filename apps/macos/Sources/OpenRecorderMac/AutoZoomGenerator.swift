import Foundation

enum AutoZoomGenerator {
    static let defaultDepth = 1.8
    static let leadInSeconds = 0.25
    static let holdAfterClickSeconds = 1.35
    static let mergeThresholdSeconds = 0.9
    static let minimumGapSeconds = 0.2
    static let minimumDurationSeconds = 0.10
    static let focusClampRange = 0.08...0.92

    static func generate(from telemetry: CursorTelemetryPayload, duration: Double) -> [TimelineZoomRegion] {
        guard duration.isFinite, duration > 0 else { return [] }
        guard telemetry.width > 0, telemetry.height > 0 else { return [] }

        let sortedClicks = telemetry.clicks
            .filter { $0.timestamp >= 0 }
            .sorted { $0.timestamp < $1.timestamp }
        guard !sortedClicks.isEmpty else { return [] }

        let clusters = clusteredClicks(sortedClicks)
        var generated: [TimelineZoomRegion] = []

        for cluster in clusters {
            guard let first = cluster.first, let last = cluster.last else { continue }
            let firstTime = Double(first.timestamp) / 1_000
            let lastTime = Double(last.timestamp) / 1_000
            var start = max(0, firstTime - leadInSeconds)
            let end = min(duration, max(firstTime, lastTime) + holdAfterClickSeconds)

            if let previous = generated.last {
                start = max(start, previous.span.end + minimumGapSeconds)
            }
            guard end - start >= minimumDurationSeconds else { continue }

            generated.append(TimelineZoomRegion(
                span: TimelineSpan(start: start, end: end).normalized(duration: duration, minimumDuration: minimumDurationSeconds),
                depth: defaultDepth,
                focusX: clampedFocus(Double(last.x) / Double(telemetry.width)),
                focusY: clampedFocus(Double(last.y) / Double(telemetry.height)),
                mode: .auto,
                sourceClickTimestamp: last.timestamp
            ))
        }

        return generated
    }

    static func generate(from telemetryURL: URL, duration: Double) -> [TimelineZoomRegion] {
        guard let telemetry = try? CursorTelemetryPayload.load(from: telemetryURL) else { return [] }
        return generate(from: telemetry, duration: duration)
    }

    private static func clusteredClicks(_ clicks: [CursorTelemetryClick]) -> [[CursorTelemetryClick]] {
        clicks.reduce(into: [[CursorTelemetryClick]]()) { clusters, click in
            guard var current = clusters.popLast(), let previous = current.last else {
                clusters.append([click])
                return
            }

            let gap = Double(click.timestamp - previous.timestamp) / 1_000
            if gap <= mergeThresholdSeconds {
                current.append(click)
                clusters.append(current)
            } else {
                clusters.append(current)
                clusters.append([click])
            }
        }
    }

    private static func clampedFocus(_ value: Double) -> Double {
        min(max(value, focusClampRange.lowerBound), focusClampRange.upperBound)
    }
}
