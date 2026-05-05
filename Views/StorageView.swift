import Cocoa
import Foundation

@MainActor
class StorageView: NSVisualEffectView {
    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated { [self] in
            configureSidebarMaterial()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureSidebarMaterial()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        configureSidebarMaterial()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        configureSidebarMaterial()
        guard !Theme.usesModernSystemChrome else { return }

        fillMiaoYanPaneBackground(dirtyRect)
        applyMiaoYanPaneBackground()
    }

    private func configureSidebarMaterial() {
        if Theme.usesModernSystemChrome {
            material = .sidebar
            blendingMode = .behindWindow
            state = .active
            isEmphasized = false
            wantsLayer = true
            layer?.backgroundColor = NSColor.clear.cgColor
        } else {
            material = .contentBackground
            blendingMode = .withinWindow
            state = .inactive
        }
    }
}
