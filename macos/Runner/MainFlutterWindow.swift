import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // Set initial window size to match app requirements (400x640)
    let windowWidth: CGFloat = 400
    let windowHeight: CGFloat = 640
    
    // Get the screen size to center the window
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      let originX = (screenFrame.width - windowWidth) / 2 + screenFrame.origin.x
      let originY = (screenFrame.height - windowHeight) / 2 + screenFrame.origin.y
      
      let windowFrame = NSRect(x: originX, y: originY, width: windowWidth, height: windowHeight)
      self.setFrame(windowFrame, display: true)
    } else {
      // Fallback: just set size without centering
      self.setContentSize(NSSize(width: windowWidth, height: windowHeight))
    }
    
    self.contentViewController = flutterViewController
    
    // Set window style
    self.styleMask.remove(.resizable)
    self.minSize = NSSize(width: windowWidth, height: windowHeight)
    self.maxSize = NSSize(width: windowWidth, height: windowHeight)
    
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
