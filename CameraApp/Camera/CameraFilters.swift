import CoreImage
import CoreImage.CIFilterBuiltins

enum CameraFilters {
  static func applyPreview(to image: CIImage) -> CIImage {
    let pixelated = applyPixelate(to: image, scale: 14)
    return applyFilmLook(to: pixelated)
  }

  static func applyCapture(to image: CIImage) -> CIImage {
    let pixelated = applyPixelate(to: image, scale: 18)
    return applyFilmLook(to: pixelated)
  }

  private static func applyPixelate(to image: CIImage, scale: Float) -> CIImage {
    guard let filter = CIFilter(name: "CIPixellate") else { return image }
    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(scale, forKey: kCIInputScaleKey)
    filter.setValue(CIVector(x: image.extent.midX, y: image.extent.midY), forKey: kCIInputCenterKey)
    let output = filter.outputImage ?? image
    return output.cropped(to: image.extent)
  }

  private static func applyFilmLook(to image: CIImage) -> CIImage {
    var output = image

    if let temp = CIFilter(name: "CITemperatureAndTint") {
      temp.setValue(output, forKey: kCIInputImageKey)
      temp.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
      temp.setValue(CIVector(x: 8000, y: 0), forKey: "inputTargetNeutral")
      output = temp.outputImage ?? output
    }

    if let sepia = CIFilter(name: "CISepiaTone") {
      sepia.setValue(output, forKey: kCIInputImageKey)
      sepia.setValue(0.18, forKey: kCIInputIntensityKey)
      output = sepia.outputImage ?? output
    }

    if let color = CIFilter(name: "CIColorControls") {
      color.setValue(output, forKey: kCIInputImageKey)
      color.setValue(1.05, forKey: kCIInputSaturationKey)
      color.setValue(1.08, forKey: kCIInputContrastKey)
      color.setValue(-0.02, forKey: kCIInputBrightnessKey)
      output = color.outputImage ?? output
    }

    if let noise = CIFilter(name: "CIRandomGenerator")?.outputImage {
      let noiseCrop = noise.cropped(to: output.extent)
      let noiseAlpha = noiseCrop.applyingFilter(
        "CIColorMatrix",
        parameters: [
          "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
          "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
          "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
          "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.08)
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
