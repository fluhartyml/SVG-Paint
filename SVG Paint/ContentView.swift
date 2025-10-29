//
//  ContentView.swift
//  SVG Paint
//
//  Created by Michael Fluharty on 10/29/25.
//


//
//  ContentView.swift
//  SVG Paint
//
//  Main UI for image import and SVG conversion
//  Created: 2025-10-29 09:28 CDT
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var convertedSVG: String?
    @State private var isConverting = false
    
    // Color quantization settings
    @State private var numberOfColors: Int = 6
    @State private var colorTolerance: Double = 30.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Image preview
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .border(Color.gray, width: 1)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            Text("No image selected")
                                .foregroundColor(.gray)
                        )
                }
                
                // Controls
                VStack(spacing: 15) {
                    // Color count slider
                    VStack(alignment: .leading) {
                        Text("Number of Colors: \(numberOfColors)")
                            .font(.caption)
                        Slider(value: Binding(
                            get: { Double(numberOfColors) },
                            set: { numberOfColors = Int($0) }
                        ), in: 3...12, step: 1)
                    }
                    
                    // Color tolerance slider
                    VStack(alignment: .leading) {
                        Text("Color Tolerance: \(Int(colorTolerance))")
                            .font(.caption)
                        Slider(value: $colorTolerance, in: 10...50, step: 5)
                    }
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        Button("Select Image") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Convert to SVG") {
                            convertImage()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedImage == nil || isConverting)
                        
                        if convertedSVG != nil {
                            Button("Export SVG") {
                                exportSVG()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                
                // Status
                if isConverting {
                    ProgressView("Converting...")
                }
                
                if let svg = convertedSVG {
                    Text("SVG Ready (\(svg.count) bytes)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            .navigationTitle("SVG Paint")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
    
    private func convertImage() {
        guard let image = selectedImage else { return }
        
        isConverting = true
        
        Task {
            let converter = SVGConverter()
            convertedSVG = await converter.convert(
                image: image,
                numberOfColors: numberOfColors,
                colorTolerance: colorTolerance
            )
            
            await MainActor.run {
                isConverting = false
            }
        }
    }
    
    private func exportSVG() {
        guard let svgString = convertedSVG else { return }
        
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("converted_image.svg")
        
        do {
            try svgString.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Share the file
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting SVG: \(error)")
        }
    }
}

// Simple image picker wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ContentView()
}