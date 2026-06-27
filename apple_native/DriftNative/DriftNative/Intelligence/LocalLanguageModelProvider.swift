import Foundation

protocol LocalLanguageModelProvider {
    var providerName: String { get }
    var isAvailable: Bool { get }

    func statusLine() -> String
}
