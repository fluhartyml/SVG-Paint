//
//  SVGConverter.swift
//  SVG Paint
//
//  Handles image to SVG conversion and posterization
//

import UIKit

class SVGConverter {
    
    // MARK: - Public Methods
    
    /// Posterize an image by reducing it to a specific number of colors
    public func posterizeImage(_ image: UIImage, numberOfColors: Int, colorTolerance: Double) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Extract unique colors
        var colorCounts: [UIColor: Int] = [:]
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0
                let a = CGFloat(pixelData[offset + 3]) / 255.0
                
                let color = UIColor(red: r, green: g, blue: b, alpha: a)
                colorCounts[color, default: 0] += 1
            }
        }
        
        // Get the most common colors
        let sortedColors = colorCounts.sorted { $0.value > $1.value }
        let paletteColors = Array(sortedColors.prefix(numberOfColors).map { $0.key })
        
        // Map each pixel to nearest palette color
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0
                let a = CGFloat(pixelData[offset + 3]) / 255.0
                
                let originalColor = UIColor(red: r, green: g, blue: b, alpha: a)
                let nearestColor = findNearestColor(originalColor, in: paletteColors)
                
                var newR: CGFloat = 0, newG: CGFloat = 0, newB: CGFloat = 0, newA: CGFloat = 0
                nearestColor.getRed(&newR, green: &newG, blue: &newB, alpha: &newA)
                
                pixelData[offset] = UInt8(newR * 255)
                pixelData[offset + 1] = UInt8(newG * 255)
                pixelData[offset + 2] = UInt8(newB * 255)
                pixelData[offset + 3] = UInt8(newA * 255)
            }
        }
        
        // Create new image from modified pixel data
        guard let newContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let newCGImage = newContext.makeImage() else { return nil }
        
        return UIImage(cgImage: newCGImage)
    }
    
    /// Convert an image to SVG format
    public func convertToSVG(image: UIImage, numberOfColors: Int, colorTolerance: Double) -> String {
        guard let posterized = posterizeImage(image, numberOfColors: numberOfColors, colorTolerance: colorTolerance),
              let cgImage = posterized.cgImage else {
            return "<svg></svg>"
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="\(width)" height="\(height)" xmlns="http://www.w3.org/2000/svg">
        
        """
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return "<svg></svg>" }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Group pixels by color and create rectangles
        var colorGroups: [String: [(x: Int, y: Int)]] = [:]
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = pixelData[offset]
                let g = pixelData[offset + 1]
                let b = pixelData[offset + 2]
                
                let colorKey = String(format: "#%02X%02X%02X", r, g, b)
                colorGroups[colorKey, default: []].append((x, y))
            }
        }
        
        // Create rectangles for each color group
        for (color, pixels) in colorGroups {
            for pixel in pixels {
                svg += "  <rect x=\"\(pixel.x)\" y=\"\(pixel.y)\" width=\"1\" height=\"1\" fill=\"\(color)\"/>\n"
            }
        }
        
        svg += "</svg>"
        
        return svg
    }
    
    // MARK: - Private Helper Methods
    
    private func findNearestColor(_ color: UIColor, in palette: [UIColor]) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        
        var nearestColor = palette[0]
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for paletteColor in palette {
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            paletteColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            let distance = sqrt(
                pow(r1 - r2, 2) +
                pow(g1 - g2, 2) +
                pow(b1 - b2, 2)
            )
            
            if distance < minDistance {
                minDistance = distance
                nearestColor = paletteColor
            }
        }
        
        return nearestColor
    }
}
