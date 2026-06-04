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
          let lw = max(geo.size.width, geo.size.height)
          let lh = min(geo.size.width, geo.size.height)
          let scaleX = lw / overlayLayout.image.size.width
          let scaleY = lh / overlayLayout.image.size.height
          let scale = max(scaleX, scaleY)
          let scaledW = overlayLayout.image.size.width * scale
          let scaledH = overlayLayout.image.size.height * scale
          let imgOffsetX = (lw - scaledW) / 2
          let imgOffsetY = (lh - scaledH) / 2
          let cutout = CGRect(
            x: imgOffsetX + overlayLayout.cutoutRect.origin.x * scale,
            y: imgOffsetY + overlayLayout.cutoutRect.origin.y * scale,
            width: overlayLayout.cutoutRect.width * scale,
            height: overlayLayout.cutoutRect.height * scale
          )

          CameraPreviewView(viewModel: camera)
            .frame(width: cutout.width, height: cutout.height)
            .position(x: cutout.midX, y: cutout.midY)

          PixelDateView(date: camera.currentDate)
            .frame(width: cutout.width, height: cutout.height)
            .position(x: cutout.midX, y: cutout.midY)
            .allowsHitTesting(false)

          Image(uiImage: overlayLayout.image)
            .resizable()
            .scaledToFill()
            .frame(width: lw, height: lh)
            .clipped()
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
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
            width: min(geo.size.width, geo.size.height) * 0.10,
            height: min(geo.size.width, geo.size.height) * 0.10
          )
          .position(x: geo.size.width * 0.88, y: geo.size.height * 0.78)
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

