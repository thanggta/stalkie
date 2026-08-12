// Sources/CarveUI/Views/ImageDetailView.swift
import SwiftUI
import CoreGraphics
import ImageIO
import CarveCore
import CarveDamage
import CarveShell

struct ImageDetailView: View {
  @EnvironmentObject private var session: GameSession
  @Environment(\.carveTheme) private var theme
  let fragment: Fragment
  @State private var cgImage: CGImage?
  @State private var errorText: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.md) {
        if let cgImage {
          Image(decorative: cgImage, scale: 1, orientation: .up)
            .resizable()
            .scaledToFit()
            .clipShape(
              RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
            )
        } else if let errorText {
          Text(errorText)
            .font(theme.fonts.bodyFont)
            .foregroundStyle(theme.palette.destructive.color)
        } else {
          Text(PlayerFacingCopy.imageRecovering)
            .font(theme.fonts.bodyFont)
            .foregroundStyle(theme.palette.secondaryText.color)
        }

        if let content = try? FragmentContent.image(fragment) {
          if let captured = content.capturedAt {
            Text(captured)
              .font(theme.fonts.captionFont)
              .foregroundStyle(theme.palette.secondaryText.color)
          }

        }
      }
      .padding(theme.spacing.md)
    }
    .background(theme.palette.screenBackground.color)
    .task(id: fragment.id) {
      await renderDamage()
    }
  }

  @MainActor
  private func renderDamage() async {
    guard let content = try? FragmentContent.image(fragment) else {
      errorText = PlayerFacingCopy.imageMissing
      return
    }
    guard let caseDir = CaseBundleLoader.resolveCaseDirectory(id: session.caseFile.id) else {
      errorText = PlayerFacingCopy.imageMissing
      return
    }
    let mediaURL = CaseBundleLoader.mediaURL(caseDirectory: caseDir, source: content.source)
    guard let sourceCG = loadCGImage(url: mediaURL) else {
      errorText = PlayerFacingCopy.imageMissing
      return
    }

    let width = sourceCG.width
    let height = sourceCG.height
    guard let sourceBytes = rgbaBytes(from: sourceCG) else {
      errorText = PlayerFacingCopy.imageMissing
      return
    }

    do {
      let renderer = try DamageRenderer()
      let damaged = try renderer.render(
        spec: fragment.damage,
        sourceBytes: sourceBytes,
        width: width,
        height: height)
      cgImage = cgImageFromRGBA(damaged, width: width, height: height)
    } catch {
      errorText = PlayerFacingCopy.imageMissing
    }
  }
}

private func loadCGImage(url: URL) -> CGImage? {
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
  return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

private func rgbaBytes(from image: CGImage) -> [UInt8]? {
  let width = image.width
  let height = image.height
  var bytes = [UInt8](repeating: 0, count: width * height * 4)
  guard let ctx = CGContext(
    data: &bytes,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  ) else { return nil }
  ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  return bytes
}

private func cgImageFromRGBA(_ bytes: [UInt8], width: Int, height: Int) -> CGImage? {
  let data = Data(bytes)
  guard let provider = CGDataProvider(data: data as CFData) else { return nil }
  return CGImage(
    width: width,
    height: height,
    bitsPerComponent: 8,
    bitsPerPixel: 32,
    bytesPerRow: width * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
    provider: provider,
    decode: nil,
    shouldInterpolate: false,
    intent: .defaultIntent)
}
