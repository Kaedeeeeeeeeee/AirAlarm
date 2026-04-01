import SwiftUI

enum GlassStyle {
    case regular
    case clear
}

struct GlassModifier<S: Shape>: ViewModifier {
    let effect: GlassStyle
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                effect == .regular ? .regular : .clear,
                in: shape
            )
        } else {
            if effect == .regular {
                content
                    .background(.ultraThinMaterial)
                    .clipShape(shape)
            } else {
                content
            }
        }
    }
}

extension View {
    func glass(_ effect: GlassStyle, in shape: some Shape) -> some View {
        modifier(GlassModifier(effect: effect, shape: shape))
    }
}
