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
    @State private var previewImage: UIImage?
    @State private var convertedSVG: String?
    @State private var isConverting = false
    @State private var showingImagePicker = false
    @State private var showingShareSheet = false
    
    // Color quantization settings
    @State private var numberOfColors: Int = 6
    @State private var colorTolerance: Double = 30.0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Original image preview
                    if let image = selectedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original Image")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 250)
                                .border(Color.gray, width: 1)
                        }
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
                                set: {
                                    numberOfColors = Int($0)
                                    updatePreview()
                                }
                            ), in: 3...12, step: 1)
                        }
                        
                        // Color tolerance slider
                        VStack(alignment: .leading) {
                            Text("Color Tolerance: \(Int(colorTolerance))")
                                .font(.caption)
                            Slider(value: $colorTolerance, in: 10...50, step: 5)
                                .onChange(of: colorTolerance) { _, _ in
                                    updatePreview()
                                }
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
                                    showingShareSheet = true
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
                    
                    // Preview of posterized image
                    if let preview = previewImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Posterized Preview")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(uiImage: preview)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 250)
                                .border(Color.blue, width: 2)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("SVG Paint")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
                    .onChange(of: selectedImage) { _, _ in
                        updatePreview()
                    }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let svgString = convertedSVG {
                    ShareSheet(items: [createSVGFile(svgString)])
                }
            }
        }
    }
    
    private func updatePreview() {
        guard let image = selectedImage else {
            previewImage = nil
            return
        }
        
        Task {
            let converter = SVGConverter()
            let quantized = await converter.quantizeColorsPublic(
                image: image,
                numberOfColors: numberOfColors,
                tolerance: colorTolerance
            )
            
            await MainActor.run {
                previewImage = quantized
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
    
    private func createSVGFile(_ svgString: String) -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("converted_image.svg")
        
        do {
            try svgString.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating SVG file: \(error)")
        }
        
        return tempURL
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

// Share sheet for iPad compatibility
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
