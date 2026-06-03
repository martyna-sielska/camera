import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewRepresentable {
  @ObservedObject var viewModel: CameraViewModel

  func makeUIView(context: Context) -> CameraPreviewContainerView {
    let view = CameraPreviewContainerView()
    view.previewLayer.session = viewModel.captureSession
    view.previewLayer.videoGravity = .resizeAspectFill
    view.updateVideoOrientation()
    return view
  }

  func updateUIView(_ uiView: CameraPreviewContainerView, context: Context) {
    uiView.previewLayer.session = viewModel.captureSession
    uiView.updateVideoOrientation()
  }
}

final class CameraPreviewContainerView: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  var previewLayer: AVCaptureVideoPreviewLayer {
    layer as! AVCaptureVideoPreviewLayer
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateVideoOrientation()
  }

  func updateVideoOrientation() {
    if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
      connection.videoOrientation = .landscapeRight
    }
  }
}
