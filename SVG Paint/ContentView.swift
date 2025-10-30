//
//  ContentView.swift
//  SVG Paint
//
//  Main view with PIP animation and shutter sound
//  Updated: 2025-10-30 09:13
//

import SwiftUI
import PhotosUI
import AVFoundation

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var pipPreviewImage: UIImage?
    @State private var finalImage: UIImage?
    @State private var showingImagePicker = false
    @State private var numberOfColors: Double = 6
    @State private var colorTolerance: Double = 30
    @State private var svgSize: CGFloat = 0
    @State private var isProcessing: Bool = false
    @State private var showingFinal: Bool = false
    @State private var updateTimer: Timer?
    @State private var animatingShutter: Bool = false
    @State private var pipScale: CGFloat = 1.0
    @State private var pipOffset: CGSize = .zero
    
    let converter = SVGConverter()
    let maxPreviewDimension: CGFloat = 400
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main background - always shows original image
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                        .opacity(showingFinal || animatingShutter ? 0 : 1)
                } else {
                    Color.gray.opacity(0.1)
                        .ignoresSafeArea()
                        .overlay(
                            Text("Select an image to start")
                                .foregroundColor(.secondary)
                        )
                }
                
                // Final full-screen preview (after animation completes)
                if showingFinal, let final = finalImage {
                    Image(uiImage: final)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .ignoresSafeArea()
                }
                
                // Picture-in-Picture with animation
                if !showingFinal, selectedImage != nil, let preview = pipPreviewImage {
                    GeometryReader { geo in
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: animatingShutter ? geometry.size.width : geometry.size.width / 3,
                                height: animatingShutter ? geometry.size.height : geometry.size.height / 3
                            )
                            .cornerRadius(animatingShutter ? 0 : 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: animatingShutter ? 0 : 12)
                                    .stroke(Color.white, lineWidth: animatingShutter ? 0 : 3)
                            )
                            .shadow(color: .black.opacity(animatingShutter ? 0 : 0.5), radius: 10)
                            .position(
                                x: animatingShutter ? geometry.size.width / 2 : (geometry.size.width / 6) + 20,
                                y: animatingShutter ? geometry.size.height / 2 : geometry.size.height - (geometry.size.height / 6) - 200
                            )
                    }
                } else if !showingFinal, selectedImage != nil {
                    // Loading indicator in PIP location
                    VStack {
                        Spacer()
                        HStack {
                            ZStack {
                                Rectangle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(
                                        width: geometry.size.width / 3,
                                        height: geometry.size.height / 3
                                    )
                                    .cornerRadius(12)
                                
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.2)
                                    Text("Generating preview...")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(radius: 10)
                            .padding(20)
                            
                            Spacer()
                        }
                        .padding(.bottom, 180)
                    }
                }
                
                // Processing overlay (shows AFTER animation)
                if isProcessing && !animatingShutter {
                    ZStack {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(2.0)
                                .tint(.white)
                            
                            Text("Processing final image...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                }
                
                // Control panel overlay
                if !showingFinal && !animatingShutter {
                    VStack(spacing: 0) {
                        // Top navigation bar
                        HStack {
                            Text("SVG Paint")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Select Image") {
                                showingImagePicker = true
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        
                        Spacer()
                        
                        // Sliders panel at bottom
                        VStack(spacing: 20) {
                            // Number of Colors Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Number of Colors:")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(numberOfColors))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(minWidth: 40)
                                }
                                
                                Slider(value: $numberOfColors, in: 2...16, step: 1)
                                    .tint(.blue)
                                    .onChange(of: numberOfColors) { oldValue, newValue in
                                        schedulePIPPreview()
                                    }
                                    .disabled(selectedImage == nil)
                            }
                            
                            // Color Tolerance Slider
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Color Tolerance:")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(colorTolerance))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(minWidth: 40)
                                }
                                
                                Slider(value: $colorTolerance, in: 10...100, step: 5)
                                    .tint(.blue)
                                    .onChange(of: colorTolerance) { oldValue, newValue in
                                        schedulePIPPreview()
                                    }
                                    .disabled(selectedImage == nil)
                            }
                            
                            // Shutter button
                            Button(action: {
                                captureWithAnimation()
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 70, height: 70)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                }
                            }
                            .disabled(selectedImage == nil || pipPreviewImage == nil)
                            .padding(.top, 12)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.8))
                    }
                }
                
                // Final image controls
                if showingFinal {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                withAnimation {
                                    showingFinal = false
                                    finalImage = nil
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Adjust")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                            }
                            
                            Button("Convert to SVG") {
                                convertToSVG()
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                            .disabled(isProcessing)
                            
                            Button("Save to Photos") {
                                saveToPhotos()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isProcessing)
                            
                            if svgSize > 0 {
                                Button("Export SVG") {
                                    exportSVG()
                                }
                                .buttonStyle(.bordered)
                                .tint(.white)
                                .disabled(isProcessing)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        
                        if svgSize > 0 {
                            Text("SVG Ready! (\(String(format: "%.2f", svgSize)) bytes)")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
                .onDisappear {
                    if selectedImage != nil {
                        resetState()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            updatePIPPreview()
                        }
                    }
                }
        }
    }
    
    private func resetState() {
        pipPreviewImage = nil
        finalImage = nil
        showingFinal = false
        animatingShutter = false
        svgSize = 0
        pipScale = 1.0
        pipOffset = .zero
    }
    
    private func schedulePIPPreview() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            updatePIPPreview()
        }
    }
    
    private func updatePIPPreview() {
        guard let image = selectedImage else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let orientedImage = image.fixedOrientation()
            let previewImage = self.downscaleImage(orientedImage, maxDimension: self.maxPreviewDimension)
            
            let result = self.converter.posterizeImage(
                previewImage,
                numberOfColors: Int(self.numberOfColors),
                colorTolerance: self.colorTolerance
            )
            
            DispatchQueue.main.async {
                self.pipPreviewImage = result
            }
        }
    }
    
    private func captureWithAnimation() {
        // Play camera shutter sound
        AudioServicesPlaySystemSound(1108)
        
        // Start animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            animatingShutter = true
        }
        
        // Process full resolution after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            processFinalImage()
        }
    }
    
    private func processFinalImage() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let orientedImage = image.fixedOrientation()
            
            let result = self.converter.posterizeImage(
                orientedImage,
                numberOfColors: Int(self.numberOfColors),
                colorTolerance: self.colorTolerance
            )
            
            DispatchQueue.main.async {
                self.finalImage = result
                self.isProcessing = false
                self.showingFinal = true
                self.animatingShutter = false
            }
        }
    }
    
    private func convertToSVG() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let orientedImage = image.fixedOrientation()
            let svgString = self.converter.convertToSVG(
                image: orientedImage,
                numberOfColors: Int(self.numberOfColors),
                colorTolerance: self.colorTolerance
            )
            
            DispatchQueue.main.async {
                self.svgSize = CGFloat(svgString.count)
                self.isProcessing = false
            }
        }
    }
    
    private func saveToPhotos() {
        guard let final = finalImage else { return }
        UIImageWriteToSavedPhotosAlbum(final, nil, nil, nil)
    }
    
    private func exportSVG() {
        guard let image = selectedImage else { return }
        let orientedImage = image.fixedOrientation()
        let svgString = converter.convertToSVG(
            image: orientedImage,
            numberOfColors: Int(numberOfColors),
            colorTolerance: colorTolerance
        )
        
        let av = UIActivityViewController(activityItems: [svgString], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
    
    private func downscaleImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxDim = max(size.width, size.height)
        
        if maxDim <= maxDimension {
            return image
        }
        
        let scale = maxDimension / maxDim
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage ?? image
    }
}

extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
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
