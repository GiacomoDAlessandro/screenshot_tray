import Carbon
import Foundation

final class HotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    var onToggle: (() -> Void)?

    init() {
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue().onToggle?()
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    func configure(_ shortcut: TrayShortcut?) throws {
        guard let shortcut else {
            if let reference { UnregisterEventHotKey(reference) }
            reference = nil
            return
        }
        guard let code = shortcut.keyCode, handler != nil else {
            throw NSError(domain: "Shortcut", code: 1, userInfo: [NSLocalizedDescriptionKey: "Choose a letter from A to Z."])
        }
        var candidate: EventHotKeyRef?
        let modifiers = UInt32(cmdKey | controlKey | optionKey) | (shortcut.shift ? UInt32(shiftKey) : 0)
        let status = RegisterEventHotKey(code, modifiers, EventHotKeyID(signature: 0x53535452, id: 1),
                                         GetApplicationEventTarget(), 0, &candidate)
        guard status == noErr else {
            throw NSError(domain: "Shortcut", code: Int(status), userInfo: [NSLocalizedDescriptionKey:
                "Could not register \(shortcut.label) (error \(status)). It may be in use. Try another shortcut."])
        }
        if let reference { UnregisterEventHotKey(reference) }
        reference = candidate
    }

    deinit {
        if let reference { UnregisterEventHotKey(reference) }
        if let handler { RemoveEventHandler(handler) }
    }
}
