import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewRepresentable {
  @ObservedObject var viewModel: CameraViewModel

  func makeUIView(context: Context) -> CameraPreviewContainerView {
    let view = CameraPreviewContainerView()
    view.previewLayer.session = viewModel.captureSession
    view.previewLayer.videoGravity = .resizeAspectFill
    return view
  }

  func updateUIView(_ uiView: CameraPreviewContainerView, context: Context) {
    uiView.previewLayer.session = viewModel.captureSession
  }
}

final class CameraPreviewContainerView: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  var previewLayer: AVCaptureVideoPreviewLayer {
    layer as! AVCaptureVideoPreviewLayer
  }
}
