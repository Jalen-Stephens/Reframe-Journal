import SwiftUI

struct NotesPalette {
    let colorScheme: ColorScheme
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let separator: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let promptLabel: Color
    let icon: Color
    let tint: Color
    let muted: Color
    let border: Color
    let placeholder: Color
    let accent: Color
    let onAccent: Color

    init(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
        background = Color("NotesBackground")
        surface = Color("NotesSurface")
        surfaceElevated = Color("NotesSurfaceElevated")
        separator = Color("NotesSeparator")
        textPrimary = Color.primary
        textSecondary = Color("NotesSecondaryText")
        textTertiary = Color("NotesTertiaryText")
        promptLabel = Color("NotesTertiaryText")
        icon = Color("NotesIcon")
        tint = colorScheme == .dark ? Color("NotesSurfaceElevated") : Color("NotesSeparator")
        muted = colorScheme == .dark ? Color("NotesSurfaceElevated") : Color("NotesSeparator").opacity(0.7)
        border = Color("NotesSeparator")
        placeholder = Color("NotesTertiaryText")
        accent = tint
        onAccent = colorScheme == .dark ? Color.white : Color.black
    }

    var glassFill: Color {
        colorScheme == .dark ? surface.opacity(0.94) : surface.opacity(0.96)
    }

    var glassFillEmphasized: Color {
        colorScheme == .dark ? surfaceElevated.opacity(0.96) : surface.opacity(0.98)
    }

    var glassBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    var glassShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.08)
    }

    var glassHighlight: LinearGradient {
        let top = Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2)
        let mid = Color.white.opacity(colorScheme == .dark ? 0.04 : 0.12)
        let bottom = Color.white.opacity(colorScheme == .dark ? 0.02 : 0.06)
        return LinearGradient(colors: [top, mid, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct NotesPaletteKey: EnvironmentKey {
    static let defaultValue = NotesPalette(colorScheme: .light)
}

extension EnvironmentValues {
    var notesPalette: NotesPalette {
        get { self[NotesPaletteKey.self] }
        set { self[NotesPaletteKey.self] = newValue }
    }
}

private struct NotesThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let palette = NotesPalette(colorScheme: colorScheme)
        content
            .environment(\.notesPalette, palette)
            .tint(palette.tint)
    }
}

extension View {
    func notesTheme() -> some View {
        modifier(NotesThemeModifier())
    }
}
