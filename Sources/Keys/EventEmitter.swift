import AppKit
import MacAppKit

enum EventEmitter {
    /// Magic value to tag events we emit, so we can skip them in the tap callback.
    static let marker: Int64 = 0x4B455953 // "KEYS"

    static func emit(keyCode: UInt16, flags: CGEventFlags = [], keyDown: Bool) {
        guard let event = CGEvent(keyboardEventSource: nil,
                                  virtualKey: keyCode, keyDown: keyDown) else { return }
        event.flags = flags
        event.setIntegerValueField(.eventSourceUserData, value: marker)
        event.post(tap: .cghidEventTap)
    }

    static func emitKeyPress(keyCode: UInt16, flags: CGEventFlags = []) {
        emit(keyCode: keyCode, flags: flags, keyDown: true)
        emit(keyCode: keyCode, flags: flags, keyDown: false)
    }

    /// Inject text into the active app. Delegates to MacAppKit.TextInjector, which
    /// uses per-char keycodes (Screen Sharing-safe) and falls back to a single
    /// clipboard paste when any char can't be resolved in the current layout.
    /// 10ms between chars, so apps that do heavy work per keystroke keep up.
    /// All emitted events are tagged with our marker so the local CGEventTap
    /// skips them. Called on main (DispatchQueue.main.async), hence assumeIsolated.
    static func pasteText(_ text: String) {
        _ = MainActor.assumeIsolated { TextInjector.inject(text, marker: marker, charDelay: .milliseconds(5)) }
    }
}
