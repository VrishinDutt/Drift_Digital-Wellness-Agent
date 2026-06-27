import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum FoundationModelsProbe {
    static var isFrameworkAvailableAtCompileTime: Bool {
        #if canImport(FoundationModels)
        return true
        #else
        return false
        #endif
    }

    static func statusLine() -> String {
        #if canImport(FoundationModels)
        return "FoundationModels framework is available at compile time."
        #else
        return "FoundationModels framework is not available in this SDK."
        #endif
    }
}
