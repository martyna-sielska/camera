import UIKit

struct OverlayLayout {
  let image: UIImage
  let cutoutRect: CGRect
}

enum OverlayProcessor {
  static func loadOverlayLayout() -> OverlayLayout? {
    guard let image = loadTemplateImage() else { return nil }
    let cutoutPixels = detectCutoutRectPixels(in: image, threshold: 245)
    let cutoutPoints = convertToPoints(rect: cutoutPixels, scale: image.scale)
    let cleaned = removeBorderWhite(from: image, threshold: 245)
    let punched = punchHole(in: cleaned, rect: cutoutPoints.insetBy(dx: 2, dy: 2))
    return OverlayLayout(image: punched, cutoutRect: cutoutPoints)
  }

  static func loadTemplateImage() -> UIImage? {
    if let image = UIImage(named: "frame") {
      return image
    }

    let directUrls = [
      Bundle.main.url(forResource: "frame", withExtension: "jpg"),
      Bundle.main.url(forResource: "frame", withExtension: "jpg", subdirectory: "assets")
    ]

    for url in directUrls {
      if let url, let image = UIImage(contentsOfFile: url.path) {
        return image
      }
    }

    if let resourcePath = Bundle.main.resourcePath,
       let enumerator = FileManager.default.enumerator(atPath: resourcePath) {
      for case let path as String in enumerator where path.hasSuffix("frame.jpg") {
        let fullPath = (resourcePath as NSString).appendingPathComponent(path)
        if let image = UIImage(contentsOfFile: fullPath) {
          return image
        }
      }
    }

    return nil
  }

  private static func convertToPoints(rect: CGRect, scale: CGFloat) -> CGRect {
    guard scale > 0 else { return rect }
    return CGRect(
      x: rect.origin.x / scale,
      y: rect.origin.y / scale,
      width: rect.size.width / scale,
      height: rect.size.height / scale
    )
  }

  private static func detectCutoutRectPixels(in image: UIImage, threshold: UInt8) -> CGRect {
    guard let buffer = PixelBuffer(image: image, downscale: 4) else {
      return fallbackRectPixels(for: image)
    }

    let width = buffer.width
    let height = buffer.height
    var visited = [Bool](repeating: false, count: width * height)
    var bestArea = 0
    var bestRect = CGRect.zero

    for y in 0..<height {
      for x in 0..<width {
        let idx = y * width + x
        if visited[idx] || !buffer.isNearWhite(x: x, y: y, threshold: threshold) {
          continue
        }

        visited[idx] = true
        var queueX: [Int] = [x]
        var queueY: [Int] = [y]
        var head = 0
        var minX = x
        var maxX = x
        var minY = y
        var maxY = y
        var area = 0
        var touchesBorder = false

        while head < queueX.count {
          let currentX = queueX[head]
          let currentY = queueY[head]
          head += 1

          if !buffer.isNearWhite(x: currentX, y: currentY, threshold: threshold) {
            continue
          }

          area += 1
          minX = min(minX, currentX)
          maxX = max(maxX, currentX)
          minY = min(minY, currentY)
          maxY = max(maxY, currentY)

          if currentX == 0 || currentY == 0 || currentX == width - 1 || currentY == height - 1 {
            touchesBorder = true
          }

          let neighbors = [
            (currentX + 1, currentY),
            (currentX - 1, currentY),
            (currentX, currentY + 1),
            (currentX, currentY - 1)
          ]

          for (nx, ny) in neighbors where nx >= 0 && ny >= 0 && nx < width && ny < height {
            let nIdx = ny * width + nx
            if visited[nIdx] { continue }
            visited[nIdx] = true
            if buffer.isNearWhite(x: nx, y: ny, threshold: threshold) {
              queueX.append(nx)
              queueY.append(ny)
            }
          }
        }

        if !touchesBorder && area > bestArea {
          bestArea = area
          bestRect = CGRect(
            x: CGFloat(minX),
            y: CGFloat(minY),
            width: CGFloat(maxX - minX + 1),
            height: CGFloat(maxY - minY + 1)
          )
        }
      }
    }

    if bestArea == 0 {
      return fallbackRectPixels(for: image)
    }

    let scale = CGFloat(4)
    return CGRect(
      x: bestRect.origin.x * scale,
      y: bestRect.origin.y * scale,
      width: bestRect.size.width * scale,
      height: bestRect.size.height * scale
    )
  }

  private static func fallbackRectPixels(for image: UIImage) -> CGRect {
    let width = CGFloat(image.cgImage?.width ?? Int(image.size.width))
    let height = CGFloat(image.cgImage?.height ?? Int(image.size.height))
    return CGRect(
      x: width * 0.12,
      y: height * 0.22,
      width: width * 0.53,
      height: height * 0.47
    )
  }

  private static func removeBorderWhite(from image: UIImage, threshold: UInt8) -> UIImage {
    guard var buffer = PixelBuffer(image: image, downscale: 1) else { return image }
    let width = buffer.width
    let height = buffer.height
    var visited = [Bool](repeating: false, count: width * height)
    var queueX: [Int] = []
    var queueY: [Int] = []

    func enqueue(_ x: Int, _ y: Int) {
      let idx = y * width + x
      if visited[idx] { return }
      visited[idx] = true
      if buffer.isNearWhite(x: x, y: y, threshold: threshold) {
        queueX.append(x)
        queueY.append(y)
      }
    }

    for x in 0..<width {
      enqueue(x, 0)
      enqueue(x, height - 1)
    }
    if height > 1 {
      for y in 0..<height {
        enqueue(0, y)
        enqueue(width - 1, y)
      }
    }

    var head = 0
    while head < queueX.count {
      let x = queueX[head]
      let y = queueY[head]
      head += 1

      buffer.setAlpha(x: x, y: y, value: 0)

      let neighbors = [
        (x + 1, y),
        (x - 1, y),
        (x, y + 1),
        (x, y - 1)
      ]

      for (nx, ny) in neighbors where nx >= 0 && ny >= 0 && nx < width && ny < height {
        let idx = ny * width + nx
        if visited[idx] { continue }
        visited[idx] = true
        if buffer.isNearWhite(x: nx, y: ny, threshold: threshold) {
          queueX.append(nx)
          queueY.append(ny)
        }
      }
    }

    return buffer.makeImage(scale: image.scale, orientation: image.imageOrientation) ?? image
  }

  private static func punchHole(in image: UIImage, rect: CGRect) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: image.size)
    return renderer.image { context in
      image.draw(at: .zero)
      context.cgContext.setBlendMode(.clear)
      context.cgContext.fill(rect)
    }
  }
}
