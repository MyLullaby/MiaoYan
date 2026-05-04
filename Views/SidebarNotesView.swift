import Cocoa

@MainActor
class SidebarNotesView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        fillMiaoYanPaneBackground(dirtyRect)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated { [self] in
            applyMiaoYanPaneBackground()
            var f = frame
            f.size.width = 280
            frame = f
            setFrameSize(f.size)
            setBoundsSize(f.size)
        }
    }
}
