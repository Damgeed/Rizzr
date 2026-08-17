import Foundation

enum FeatureGate: String, CaseIterable, Equatable {
    case finesse
    case ghost
    case echo
    case vibe

    var isEnabled: Bool {
        switch self {
        case .finesse:
            true
        case .ghost, .echo, .vibe:
            false
        }
    }
}

struct AppFeatureFlags: Equatable {
    private let overrides: [FeatureGate: Bool]

    init(overrides: [FeatureGate: Bool] = [:]) {
        self.overrides = overrides
    }

    static let production = AppFeatureFlags()

    func isEnabled(_ feature: FeatureGate) -> Bool {
        overrides[feature] ?? feature.isEnabled
    }
}
