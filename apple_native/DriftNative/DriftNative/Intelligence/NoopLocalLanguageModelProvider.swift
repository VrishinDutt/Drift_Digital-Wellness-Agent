import Foundation

struct NoopLocalLanguageModelProvider: LocalLanguageModelProvider {
    let providerName = "NoopLocalLanguageModelProvider"
    let isAvailable = true

    func statusLine() -> String {
        "No local language model provider is currently active."
    }
}
