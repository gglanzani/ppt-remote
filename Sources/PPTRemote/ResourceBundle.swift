import Foundation

// SwiftPM's generated `Bundle.module` only looks next to the .app (not in
// Contents/Resources, where build.sh puts the bundle) and then falls back to
// the absolute .build path on the machine that compiled it, calling
// `fatalError` when neither exists. That works on the build machine but
// crashes everywhere else on the first request, so look the bundle up here.
enum ResourceBundle {
    static let bundle: Bundle? = {
        let name = "PPTRemote_PPTRemote.bundle"
        let candidates = [
            Bundle.main.resourceURL,                                // PPT Remote.app/Contents/Resources
            Bundle.main.bundleURL,                                  // `swift run`: next to the executable
            Bundle.main.executableURL?.deletingLastPathComponent(),
        ]
        for case let dir? in candidates {
            if let bundle = Bundle(url: dir.appendingPathComponent(name)) {
                return bundle
            }
        }
        NSLog("PPT Remote: resource bundle %@ not found", name)
        return nil
    }()

    static func url(forResource name: String, withExtension ext: String, subdirectory: String? = nil) -> URL? {
        bundle?.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
    }
}
