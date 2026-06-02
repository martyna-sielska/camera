import SwiftUI
import UIKit

struct PixelDateView: View {
  let date: Date

  var body: some View {
    Canvas { context, size in
      let formatter = DateFormatter()
      formatter.dateFormat = "dd.MM.yy HH:mm"
      let text = formatter.string(from: date)

      let pixelSize: CGFloat = 3
      let spacing: CGFloat = 2
      let textSize = PixelFont.textSize(text, pixelSize: pixelSize, spacing: spacing)
      let origin = CGPoint(
        x: size.width - textSize.width - pixelSize * 4,
        y: size.height - textSize.height - pixelSize * 4
      )
      let color = UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 0.9)

      context.withCGContext { cgContext in
        PixelFont.draw(
          text: text,
          in: cgContext,
          origin: origin,
          pixelSize: pixelSize,
          spacing: spacing,
          color: color
        )
      }
    }
  }
}
