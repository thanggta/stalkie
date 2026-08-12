// Apps/Carve/Views/NoteDetailView.swift
import SwiftUI
import CarveCore
import CarveShell

struct NoteDetailView: View {
  @Environment(\.carveTheme) private var theme
  let fragment: Fragment

  var body: some View {
    if let content = try? FragmentContent.note(fragment) {
      ScrollView {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
          Text(content.title)
            .font(theme.fonts.titleFont)
            .foregroundStyle(theme.palette.primaryText.color)
          if let modified = content.modifiedAt {
            Text(modified)
              .font(theme.fonts.captionFont)
              .foregroundStyle(theme.palette.secondaryText.color)
          }
          CorruptBodyText(text: content.body)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(theme.palette.screenBackground.color)
    } else {
      Text("Unreadable note")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
    }
  }
}

struct CorruptBodyText: View {
  @Environment(\.carveTheme) private var theme
  let text: String

  var body: some View {
    Text(attributed)
      .font(theme.fonts.bodyFont)
  }

  private var attributed: AttributedString {
    var result = AttributedString()
    for ch in text {
      var piece = AttributedString(String(ch))
      if ch == "█" || ch == "▆" || ch == "▇" {
        piece.foregroundColor = theme.palette.corruptGlyph.color
      } else {
        piece.foregroundColor = theme.palette.primaryText.color
      }
      result.append(piece)
    }
    return result
  }
}
