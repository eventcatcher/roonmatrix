import Cocoa
import FlutterMacOS
import macos_window_utils

class MainFlutterWindow: NSWindow {

  override func awakeFromNib() {
    let windowFrame = self.frame
    let macOSWindowUtilsViewController = MacOSWindowUtilsViewController()
    self.contentViewController = macOSWindowUtilsViewController
    self.setFrame(windowFrame, display: true)

    /* Initialize the macos_window_utils plugin */
    MainFlutterWindowManipulator.start(mainFlutterWindow: self)

    let channel = FlutterMethodChannel(
      name: "roonmatrix/macos",
      binaryMessenger:
        macOSWindowUtilsViewController
          .flutterViewController
          .engine
          .binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "terminate":
        NSApp.terminate(nil)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: macOSWindowUtilsViewController.flutterViewController)

    super.awakeFromNib()

    self.setFrameAutosaveName("RoonMatrix")
  }
}