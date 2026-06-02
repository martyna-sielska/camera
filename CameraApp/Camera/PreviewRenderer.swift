import MetalKit
import CoreImage

final class PreviewRenderer: NSObject, MTKViewDelegate {
  private let ciContext: CIContext
  private let commandQueue: MTLCommandQueue
  private let colorSpace = CGColorSpaceCreateDeviceRGB()
  private weak var view: MTKView?

  var currentImage: CIImage?

  init?(mtkView: MTKView) {
    guard let device = mtkView.device,
          let queue = device.makeCommandQueue() else { return nil }
    self.commandQueue = queue
    self.ciContext = CIContext(mtlDevice: device)
    self.view = mtkView
    super.init()
  }

  func requestRedraw() {
    DispatchQueue.main.async { [weak self] in
      self?.view?.setNeedsDisplay()
    }
  }

  func draw(in view: MTKView) {
    guard let image = currentImage,
          let drawable = view.currentDrawable,
          let commandBuffer = commandQueue.makeCommandBuffer() else { return }

    let targetSize = CGSize(width: view.drawableSize.width, height: view.drawableSize.height)
    let scale = max(targetSize.width / image.extent.width, targetSize.height / image.extent.height)
    let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    let x = (targetSize.width - scaled.extent.width) / 2
    let y = (targetSize.height - scaled.extent.height) / 2
    let translated = scaled.transformed(by: CGAffineTransform(translationX: x, y: y))

    ciContext.render(
      translated,
      to: drawable.texture,
      commandBuffer: commandBuffer,
      bounds: CGRect(origin: .zero, size: targetSize),
      colorSpace: colorSpace
    )
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
