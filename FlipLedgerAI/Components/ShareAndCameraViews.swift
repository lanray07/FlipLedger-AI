import PhotosUI
import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onImage: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        controller.allowsEditing = false
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct PhotoImportControls: View {
    @Binding var selectedItems: [PhotosPickerItem]
    var onCamera: () -> Void

    var body: some View {
        HStack {
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 8, matching: .images) {
                Label("Photos", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)

            Button(action: onCamera) {
                Label("Camera", systemImage: "camera")
            }
            .buttonStyle(.bordered)
        }
    }
}

struct PhotoDataGrid: View {
    var photos: [Data]

    var body: some View {
        if !photos.isEmpty {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
                ForEach(Array(photos.enumerated()), id: \.offset) { _, data in
                    PhotoTile(data: data, systemImage: "photo")
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }
}
