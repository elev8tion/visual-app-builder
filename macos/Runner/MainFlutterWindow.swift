import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Set minimum window size
    self.minSize = NSSize(width: 1200, height: 700)

    // Set initial window size and center
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let initialWidth: CGFloat = min(1440, screenFrame.width * 0.9)
    let initialHeight: CGFloat = min(900, screenFrame.height * 0.9)
    let initialX = screenFrame.origin.x + (screenFrame.width - initialWidth) / 2
    let initialY = screenFrame.origin.y + (screenFrame.height - initialHeight) / 2
    self.setFrame(NSRect(x: initialX, y: initialY, width: initialWidth, height: initialHeight), display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
