import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct FoundationModelsLocalProvider: LocalLanguageModelProvider {
    let providerName = "FoundationModelsLocalProvider"

    var isAvailable: Bool {
        FoundationModelsProbe.isFrameworkAvailableAtCompileTime
    }

    func statusLine() -> String {
        FoundationModelsProbe.statusLine()
    }
}
