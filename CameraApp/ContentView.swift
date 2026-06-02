import SwiftUI

struct ContentView: View {
  @StateObject private var camera = CameraViewModel()
  @State private var isCameraStarted = false
  @State private var didCheckCameraPermission = false

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
        } else {
          CameraPreviewView(viewModel: camera)
            .ignoresSafeArea()

          PixelDateView(date: camera.currentDate)
            .frame(width: geo.size.width, height: geo.size.height)
            .allowsHitTesting(false)
        }

        if isCameraStarted {
          ShutterButton {
            camera.capturePhoto()
          }
          .frame(
            width: min(geo.size.width, geo.size.height) * 0.12,
            height: min(geo.size.width, geo.size.height) * 0.12
          )
          .position(x: geo.size.width * 0.83, y: geo.size.height * 0.80)
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

