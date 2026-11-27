// Licensed under GPL-3.0. See LICENSE.
import Foundation

/// The language selection stored by Lelele Browser.
public enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case simplifiedChinese

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return L("Follow System")
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }

    /// The `.lproj` folder name, or nil when the system language should be used.
    public var bundleIdentifier: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .simplifiedChinese: return "zh-Hans"
        }
    }
}

/// Resolves localized strings for the app's selected language.
///
/// English is the source language: every key is the English text itself. If a key has no
/// translation, the English key is returned, so untranslated UI stays readable.
public enum LeleleLocalization {
    public static private(set) var current: AppLanguage = .system

    public static func configure(_ language: AppLanguage) {
        current = language
    }

    public static func string(_ key: String, comment: String = "") -> String {
        let candidates: [String]
        if let explicit = current.bundleIdentifier {
            candidates = [explicit]
        } else {
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            candidates = [code, String(code.prefix(2))]
        }

        for identifier in candidates where !identifier.isEmpty {
            guard let url = Bundle.module.url(forResource: identifier, withExtension: "lproj"),
                  let bundle = Bundle(url: url) else { continue }
            let resolved = NSLocalizedString(
                key, tableName: "Localizable", bundle: bundle, value: key, comment: comment)
            if resolved != key { return resolved }
        }
        return key
    }
}

public func L(_ key: String, comment: String = "") -> String {
    LeleleLocalization.string(key, comment: comment)
}
