// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import EventKit
import EventKitUI
import SwiftUI

struct EventEditor: UIViewControllerRepresentable {
    let event: EKEvent
    let store: EKEventStore
    let completed: (EKEventEditViewAction) -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let editor = EKEventEditViewController()
        editor.eventStore = store
        editor.event = event
        editor.editViewDelegate = context.coordinator
        editor.view.tintColor = UIColor(Palette.sun)
        return editor
    }

    func updateUIViewController(_ editor: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completed: completed)
    }

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let completed: (EKEventEditViewAction) -> Void

        init(completed: @escaping (EKEventEditViewAction) -> Void) {
            self.completed = completed
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            completed(action)
        }
    }
}
