import CoreGraphics

struct FrameLayout {
  let origin: CGPoint
  let size: CGSize
  let scale: CGFloat

  static func aspectFit(imageSize: CGSize, in viewSize: CGSize) -> FrameLayout {
    let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
    let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    let origin = CGPoint(
      x: (viewSize.width - size.width) / 2,
      y: (viewSize.height - size.height) / 2
    )
    return FrameLayout(origin: origin, size: size, scale: scale)
  }

  func map(rect: CGRect) -> CGRect {
    CGRect(
      x: origin.x + rect.origin.x * scale,
      y: origin.y + rect.origin.y * scale,
      width: rect.size.width * scale,
      height: rect.size.height * scale
    )
  }
}
