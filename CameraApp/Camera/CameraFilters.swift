import CoreImage
import CoreImage.CIFilterBuiltins

enum CameraFilters {
  static func applyPreview(to image: CIImage) -> CIImage {
    applyGrain(to: image)
  }

  static func applyCapture(to image: CIImage) -> CIImage {
    applyGrain(to: image)
  }

  private static func applyGrain(to image: CIImage) -> CIImage {
    var output = image

    if let noise = CIFilter(name: "CIRandomGenerator")?.outputImage {
      let noiseCrop = noise.cropped(to: output.extent)
      let noiseAlpha = noiseCrop.applyingFilter(
        "CIColorMatrix",
        parameters: [
          "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
          "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
          "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
          "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.06)
        ]
      )
      let blended = noiseAlpha.applyingFilter(
        "CIOverlayBlendMode",
        parameters: [kCIInputBackgroundImageKey: output]
      )
      output = blended
    }

    return output.cropped(to: image.extent)
  }
}
