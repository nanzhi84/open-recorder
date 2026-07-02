import Foundation
import SwiftUI

enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: .main, value: key, comment: "")
    }

    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }

    static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }
}
