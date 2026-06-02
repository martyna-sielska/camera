import UIKit

enum PixelDateRenderer {
  static func stamp(date: Date, onto image: UIImage) -> UIImage {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yy HH:mm"
    let text = formatter.string(from: date)
    return stamp(text: text, onto: image)
  }

  static func stamp(text: String, onto image: UIImage) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: image.size)
    return renderer.image { context in
      image.draw(at: .zero)

      let pixelSize = max(2, Int(image.size.width / 220))
      let spacing = max(1, pixelSize / 2)
      let size = PixelFont.textSize(
        text,
        pixelSize: CGFloat(pixelSize),
        spacing: CGFloat(spacing)
      )
      let margin = CGFloat(pixelSize) * 4
      let origin = CGPoint(
        x: image.size.width - size.width - margin,
        y: image.size.height - size.height - margin
      )
      let color = UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 0.9)

      PixelFont.draw(
        text: text,
        in: context.cgContext,
        origin: origin,
        pixelSize: CGFloat(pixelSize),
        spacing: CGFloat(spacing),
        color: color
      )
    }
  }
}
