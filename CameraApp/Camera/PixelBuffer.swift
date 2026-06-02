import UIKit

struct PixelBuffer {
  let width: Int
  let height: Int
  let bytesPerRow: Int
  var data: [UInt8]

  init?(image: UIImage, downscale: Int) {
    guard let cgImage = image.cgImage else { return nil }
    let scale = max(1, downscale)
    let targetWidth = max(1, cgImage.width / scale)
    let targetHeight = max(1, cgImage.height / scale)
    let bytesPerRow = targetWidth * 4

    var data = [UInt8](repeating: 0, count: targetHeight * bytesPerRow)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

    let success = data.withUnsafeMutableBytes { buffer -> Bool in
      guard let context = CGContext(
        data: buffer.baseAddress,
        width: targetWidth,
        height: targetHeight,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo
      ) else { return false }
      context.interpolationQuality = .low
      context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
      return true
    }

    if !success { return nil }

    self.width = targetWidth
    self.height = targetHeight
    self.bytesPerRow = bytesPerRow
    self.data = data
  }

  func isNearWhite(x: Int, y: Int, threshold: UInt8) -> Bool {
    let offset = (y * width + x) * 4
    let r = data[offset]
    let g = data[offset + 1]
    let b = data[offset + 2]
    return r > threshold && g > threshold && b > threshold
  }

  mutating func setAlpha(x: Int, y: Int, value: UInt8) {
    let offset = (y * width + x) * 4 + 3
    guard offset < data.count else { return }
    data[offset] = value
  }

  func makeImage(scale: CGFloat, orientation: UIImage.Orientation) -> UIImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

    let cfData = data.withUnsafeBytes { buffer -> CFData? in
      guard let baseAddress = buffer.bindMemory(to: UInt8.self).baseAddress else { return nil }
      return CFDataCreate(nil, baseAddress, data.count)
    }
    guard let cfData, let provider = CGDataProvider(data: cfData) else { return nil }
    guard let cgImage = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    ) else { return nil }

    return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
  }
}
