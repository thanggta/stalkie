// Apps/Carve/Views/RecordDetailView.swift
import SwiftUI
import CarveCore
import CarveShell

struct RecordDetailView: View {
  @Environment(\.carveTheme) private var theme
  let fragment: Fragment

  var body: some View {
    if let content = try? FragmentContent.record(fragment) {
      List {
        ForEach(Array(content.rows.enumerated()), id: \.offset) { _, row in
          VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            ForEach(Array(content.columns.enumerated()), id: \.offset) { index, column in
              HStack(alignment: .firstTextBaseline) {
                Text(column)
                  .font(theme.fonts.captionFont)
                  .foregroundStyle(theme.palette.secondaryText.color)
                  .frame(width: 100, alignment: .leading)
                Text(cellText(row, index: index))
                  .font(theme.fonts.bodyFont)
                  .foregroundStyle(
                    isNull(row, index: index)
                      ? theme.palette.corruptGlyph.color
                      : theme.palette.primaryText.color
                  )
              }
            }
          }
          .padding(.vertical, theme.spacing.xs)
          .listRowBackground(theme.palette.elevatedBackground.color)
        }
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .background(theme.palette.groupedBackground.color)
    } else {
      Text("Unreadable record")
        .font(theme.fonts.bodyFont)
        .foregroundStyle(theme.palette.secondaryText.color)
    }
  }

  private func isNull(_ row: [JSONValue], index: Int) -> Bool {
    guard index < row.count else { return true }
    if case .null = row[index] { return true }
    return false
  }

  private func cellText(_ row: [JSONValue], index: Int) -> String {
    guard index < row.count else { return "█" }
    switch row[index] {
    case .null: return "█ unrecovered"
    case .string(let s): return s
    case .number(let n):
      if n == Double(Int(n)) { return String(Int(n)) }
      return String(n)
    case .bool(let b): return b ? "true" : "false"
    case .array, .object: return "…"
    }
  }
}
