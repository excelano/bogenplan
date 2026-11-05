// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI
import UIKit

struct MomentProbe: Equatable {
    var y: CGFloat
    var still: CGPoint
    var armed = false
    var token = UUID()
}

struct MomentDraft: Identifiable {
    let instant: Date
    var id: Date { instant }
}

struct ProbeGesture: UIGestureRecognizerRepresentable {
    enum Phase {
        case began
        case moved
        case ended
        case cancelled
    }

    let onChange: (Phase, CGPoint) -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = 0.25
        recognizer.allowableMovement = 10
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        let point = context.converter.localLocation
        switch recognizer.state {
        case .began: onChange(.began, point)
        case .changed: onChange(.moved, point)
        case .ended: onChange(.ended, point)
        default: onChange(.cancelled, point)
        }
    }
}

struct ProbeLine: View {
    let probe: MomentProbe
    let instant: Date
    let readout: Readout

    var body: some View {
        let color = probe.armed ? Palette.sun : Palette.line
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(color)
                .frame(height: 1.5)
                .offset(y: probe.y - 0.75)
            label(color)
                .offset(x: 8, y: max(0, probe.y - 44))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func label(_ color: Color) -> some View {
        HStack(spacing: 8) {
            PositionLabel(readout.position(at: instant), style: .subheadline, weight: .semibold, color: color)
            if readout.showsCivilTime {
                Text(instant.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Palette.label)
            }
            if probe.armed {
                Text("Release to set")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.sun)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Palette.night.opacity(0.92), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 0.5))
        .fixedSize()
    }
}
