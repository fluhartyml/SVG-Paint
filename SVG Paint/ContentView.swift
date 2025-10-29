//
//  ContentView.swift
//  SVG Paint
//
//  Main view with image selection, conversion, and zoomable preview
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var posterizedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var numberOfColors: Double = 6
    @State private var colorTolerance: Double = 30
    @State private var svgSize: CGFloat = 0
    @State private var previewScale: CGFloat = 1.0
    
    let converter = SVGConverter()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Original Image
                    if let image = selectedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original Image")
                                .font(.headline)
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Posterized Preview with Zoom Controls
                    if let posterized = posterizedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Posterized Preview (\(Int(numberOfColors)) colors)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                // Zoom Controls
                                HStack(spacing: 16) {
                                    Button(action: {
                                        withAnimation {
                                            previewScale = max(0.5, previewScale - 0.25)
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "magnifyingglass")
                                            Image(systemName: "minus")
                                        }
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                    }
                                    
                                    Text("\(Int(previewScale * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        withAnimation {
                                            previewScale = min(3.0, previewScale + 0.25)
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "magnifyingglass")
                                            Image(systemName: "plus")
                                        }
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            ScrollView([.horizontal, .vertical]) {
                                Image(uiImage: posterized)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300 * previewScale)
                                    .cornerRadius(8)
                            }
                            .frame(maxHeight: 350)
                            .border(Color.green, width: 2)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Number of Colors Slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of Colors: \(Int(numberOfColors))")
                            .font(.subheadline)
                        
                        Slider(value: $numberOfColors, in: 2...16, step: 1)
                            .onChange(of: numberOfColors) { _, _ in
                                updatePosterization()
                            }
                    }
                    .padding()
                    
                    // Color Tolerance Slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color Tolerance: \(Int(colorTolerance))")
                            .font(.subheadline)
                        
                        Slider(value: $colorTolerance, in: 10...100, step: 5)
                            .onChange(of: colorTolerance) { _, _ in
                                updatePosterization()
                            }
                    }
                    .padding()
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button("Select Image") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        if selectedImage != nil {
                            Button("Convert to SVG") {
                                convertToSVG()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Export SVG") {
                                exportSVG()
                            }
                            .buttonStyle(.bordered)
                            .disabled(svgSize == 0)
                        }
                    }
                    .padding()
                    
                    // SVG Size Display
                    if svgSize > 0 {
                        Text("SVG Ready! (\(String(format: "%.2f", svgSize)) bytes)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
            }
            .navigationTitle("SVG Paint")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
                    .onDisappear {
                        updatePosterization()
                    }
            }
        }
    }
    
    private func updatePosterization() {
        guard let image = selectedImage else { return }
        posterizedImage = converter.posterizeImage(
            image,
            numberOfColors: Int(numberOfColors),
            colorTolerance: colorTolerance
        )
        previewScale = 1.0 // Reset zoom when updating
    }
    
    private func convertToSVG() {
        guard let image = selectedImage else { return }
        let svgString = converter.convertToSVG(
            image: image,
            numberOfColors: Int(numberOfColors),
            colorTolerance: colorTolerance
        )
        svgSize = CGFloat(svgString.count)
    }
    
    private func exportSVG() {
        guard let image = selectedImage else { return }
        let svgString = converter.convertToSVG(
            image: image,
            numberOfColors: Int(numberOfColors),
            colorTolerance: colorTolerance
        )
        
        // Create share sheet
        let av = UIActivityViewController(
            activityItems: [svgString],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
