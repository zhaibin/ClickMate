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
    
    // Use fullSizeContentView to extend content to full window and hide titlebar
    self.styleMask = [.titled, .fullSizeContentView, .closable, .miniaturizable]
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovableByWindowBackground = false
    self.backgroundColor = NSColor(red: 0.118, green: 0.227, blue: 0.373, alpha: 1.0)
    self.minSize = NSSize(width: windowWidth, height: windowHeight)
    self.maxSize = NSSize(width: windowWidth, height: windowHeight)
    
    // Hide all standard window buttons and make titlebar area zero height
    self.standardWindowButton(.closeButton)?.isHidden = true
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true
    
    // Move window buttons superview out of visible area by setting alpha to 0
    if let closeButton = self.standardWindowButton(.closeButton),
       let titlebarView = closeButton.superview?.superview {
      titlebarView.alphaValue = 0
    }
    
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
  
  override var canBecomeKey: Bool { return true }
  override var canBecomeMain: Bool { return true }
}
