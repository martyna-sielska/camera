import SwiftUI
import MediaPlayer
import UIKit

struct ContentView: View {
  @StateObject private var camera = CameraViewModel()
  @State private var overlayLayout: OverlayLayout?

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .topLeading) {
        if let overlayLayout {
          let fit = FrameLayout.aspectFit(imageSize: overlayLayout.image.size, in: geo.size)
          let cutout = fit.map(rect: overlayLayout.cutoutRect)

          CameraPreviewView(viewModel: camera)
            .frame(width: cutout.width, height: cutout.height)
            .position(x: cutout.midX, y: cutout.midY)

          PixelDateView(date: camera.currentDate)
            .frame(width: cutout.width, height: cutout.height)
            .position(x: cutout.midX, y: cutout.midY)
            .allowsHitTesting(false)

          Image(uiImage: overlayLayout.image)
            .resizable()
            .frame(width: fit.size.width, height: fit.size.height)
            .position(x: fit.origin.x + fit.size.width / 2, y: fit.origin.y + fit.size.height / 2)
            .allowsHitTesting(false)
        } else {
          CameraPreviewView(viewModel: camera)
            .ignoresSafeArea()

          PixelDateView(date: camera.currentDate)
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)
        }

        ShutterButton {
          camera.capturePhoto()
        }
        .frame(
          width: min(geo.size.width, geo.size.height) * 0.12,
          height: min(geo.size.width, geo.size.height) * 0.12
        )
        .position(x: geo.size.width * 0.83, y: geo.size.height * 0.80)

        VolumeButtonView(listener: camera.volumeListener)
          .frame(width: 1, height: 1)
          .opacity(0.01)

        if camera.cameraPermission == .denied {
          PermissionOverlayView(text: "Brak dostepu do kamery. Wlacz uprawnienia w Ustawieniach.")
        } else if camera.photoPermission == .denied {
          PermissionOverlayView(text: "Brak dostepu do galerii. Wlacz uprawnienia w Ustawieniach.")
        }
      }
      .onAppear {
        camera.startSession()
        overlayLayout = OverlayProcessor.loadOverlayLayout()
      }
      .onDisappear {
        camera.stopSession()
      }
    }
  }
}

struct ShutterButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack {
        Circle()
          .fill(Color.white.opacity(0.9))
        Circle()
          .stroke(Color.black.opacity(0.6), lineWidth: 2)
      }
    }
    .buttonStyle(.plain)
  }
}

struct PermissionOverlayView: View {
  let text: String

  var body: some View {
    ZStack {
      Color.black.opacity(0.6)
      Text(text)
        .foregroundColor(.white)
        .multilineTextAlignment(.center)
        .padding(24)
    }
    .ignoresSafeArea()
  }
}

struct VolumeButtonView: UIViewRepresentable {
  let listener: VolumeButtonListener

  func makeUIView(context: Context) -> UIView {
    let container = UIView(frame: .zero)
    let volumeView = MPVolumeView(frame: .zero)
    volumeView.alpha = 0.01
    container.addSubview(volumeView)
    listener.attach(volumeView: volumeView)
    return container
  }

  func updateUIView(_ uiView: UIView, context: Context) {}
}
