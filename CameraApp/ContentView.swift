import SwiftUI
import UIKit

struct ContentView: View {
  @StateObject private var camera = CameraViewModel()
  @State private var overlayLayout: OverlayLayout?
  @State private var isCameraStarted = false
  @State private var didCheckCameraPermission = false
  @State private var didTryLoadingOverlay = false

  var body: some View {
    GeometryReader { geo in
      let screenBounds = UIScreen.main.bounds
      let fullSize = CGSize(
        width: max(screenBounds.width, screenBounds.height),
        height: min(screenBounds.width, screenBounds.height)
      )
      let offsetX = (fullSize.width - geo.size.width) / 2
      let offsetY = (fullSize.height - geo.size.height) / 2

      ZStack(alignment: .topLeading) {
        if !isCameraStarted {
          Color.black
            .ignoresSafeArea()

          VStack(spacing: 16) {
            Text("CameraApp")
              .font(.title)
              .foregroundColor(.white)

            Button("Sprawdz dostep do aparatu") {
              didCheckCameraPermission = true
              camera.requestCameraOnly()
            }
            .buttonStyle(.borderedProminent)

            if camera.cameraPermission == .authorized {
              Button("Uruchom kamere") {
                overlayLayout = OverlayProcessor.loadOverlayLayout()
                didTryLoadingOverlay = true
                isCameraStarted = true
                camera.startSession()
              }
              .buttonStyle(.bordered)
            }

            if camera.cameraPermission == .authorized {
              Text("Dostep do aparatu OK")
                .foregroundColor(.white)
            } else if camera.cameraPermission == .denied {
              Text("Brak dostepu do aparatu")
                .foregroundColor(.white)
            } else if didCheckCameraPermission {
              Text("Czekam na zgode aparatu")
                .foregroundColor(.white)
            }
          }
          .frame(width: geo.size.width, height: geo.size.height)
        } else if let overlayLayout {
          let scaleX = fullSize.width / overlayLayout.image.size.width
          let scaleY = fullSize.height / overlayLayout.image.size.height
          let cutout = CGRect(
            x: overlayLayout.cutoutRect.origin.x * scaleX,
            y: overlayLayout.cutoutRect.origin.y * scaleY,
            width: overlayLayout.cutoutRect.width * scaleX,
            height: overlayLayout.cutoutRect.height * scaleY
          )

          CameraPreviewView(viewModel: camera)
            .frame(width: cutout.width, height: cutout.height)
            .position(x: cutout.midX - offsetX, y: cutout.midY - offsetY)

          PixelDateView(date: camera.currentDate)
            .frame(width: cutout.width, height: cutout.height)
            .position(x: cutout.midX - offsetX, y: cutout.midY - offsetY)
            .allowsHitTesting(false)

          Image(uiImage: overlayLayout.image)
            .resizable()
            .frame(width: fullSize.width, height: fullSize.height)
            .position(x: fullSize.width / 2 - offsetX, y: fullSize.height / 2 - offsetY)
            .allowsHitTesting(false)
        } else {
          CameraPreviewView(viewModel: camera)
            .ignoresSafeArea()

          PixelDateView(date: camera.currentDate)
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)

          if didTryLoadingOverlay {
            Text("Nie znaleziono ramki frame.jpg")
              .font(.footnote)
              .foregroundColor(.white)
              .padding(10)
              .background(Color.black.opacity(0.7))
              .position(x: geo.size.width / 2, y: 40)
          }
        }

        if isCameraStarted {
          ShutterButton {
            camera.capturePhoto()
          }
          .frame(
            width: min(fullSize.width, fullSize.height) * 0.10,
            height: min(fullSize.width, fullSize.height) * 0.10
          )
          .position(x: fullSize.width * 0.88 - offsetX, y: fullSize.height * 0.78 - offsetY)
        }

        if camera.cameraPermission == .denied {
          PermissionOverlayView(text: "Brak dostepu do kamery. Wlacz uprawnienia w Ustawieniach.")
        } else if camera.photoPermission == .denied {
          PermissionOverlayView(text: "Brak dostepu do galerii. Wlacz uprawnienia w Ustawieniach.")
        }
      }
      .onDisappear {
        camera.stopSession()
      }
    }
    .ignoresSafeArea(.all)
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

