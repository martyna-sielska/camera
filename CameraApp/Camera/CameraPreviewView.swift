import SwiftUI
import MetalKit

struct CameraPreviewView: UIViewRepresentable {
  @ObservedObject var viewModel: CameraViewModel

  func makeUIView(context: Context) -> MTKView {
    let view = MTKView(frame: .zero)
    view.device = MTLCreateSystemDefaultDevice()
    view.isPaused = true
    view.enableSetNeedsDisplay = true
    view.framebufferOnly = false
    view.clearColor = MTLClearColorMake(0, 0, 0, 1)
    viewModel.attachPreview(view)
    return view
  }

  func updateUIView(_ uiView: MTKView, context: Context) {}
}
