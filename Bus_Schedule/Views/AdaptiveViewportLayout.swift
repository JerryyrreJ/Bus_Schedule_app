import CoreGraphics

/// Classifies the active scene viewport into posture-appropriate layout tiers
/// without relying on `UIScreen.main` or device orientation APIs.
enum AdaptiveViewportMode: Equatable {
    /// Narrow single-column layout (standard iPhones, iPhone Duo outer cover
    /// portrait `466×678`, and narrow Split View).
    case singleColumn(isCompact: Bool)

    /// Short wide viewport (`width >= 580 && height < 500`), such as phone
    /// landscape or iPhone Duo outer cover in landscape (`678×466`).
    case compactLandscape

    /// Medium-wide tall viewport (`580 <= width < 720 && height >= 500`), such as
    /// iPhone Duo inner display rotated vertically / tabletop stand (`669×951`)
    /// or a 2/3 Split View window.
    case tallExpanded

    /// Full two-page horizontal spread (`width >= 720 && height >= 500`), such as
    /// iPhone Duo unfolded book posture (`951×669`) and iPad regular windows.
    case bookSpread

    static func resolve(size: CGSize) -> AdaptiveViewportMode {
        let width = size.width
        let height = size.height

        if width >= 720 && height >= 500 {
            return .bookSpread
        }
        if width >= 580 && height < 500 {
            return .compactLandscape
        }
        if width >= 580 && height >= 500 {
            return .tallExpanded
        }
        return .singleColumn(isCompact: height < 640)
    }
}
