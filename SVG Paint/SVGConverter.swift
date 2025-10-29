//
//  SVGConverter.swift
//  SVG Paint
//
//  Core image to SVG conversion with gradient flattening
//  Created: 2025-10-29 09:28 CDT
//

import UIKit
import CoreImage

actor SVGConverter {
    
    func convert(image: UIImage, numberOfColors: Int, colorTolerance: Double) async -> String {
        // Step 1: Quantize colors (flatten gradients)
        let quantizedImage = quantizeColors(image: image, numberOfColors: numberOfColors, tolerance: colorTolerance)
        
        // Step 2: Extract color regions
        let colorRegions = extractColorRegions(from: quantizedImage)
        
        // Step 3: Convert to SVG paths
        let svgContent = generateSVG(from: colorRegions, imageSize: image.size)
        
        return svgContent
    }
    
    private func quantizeColors(image: UIImage, numberOfColors: Int, tolerance: Double) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // Create bitmap context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return image }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return image }
        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        // Extract all unique colors
        var colorCounts: [UIColor: Int] = [:]
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = CGFloat(pixelBuffer[offset]) / 255.0
                let g = CGFloat(pixelBuffer[offset + 1]) / 255.0
                let b = CGFloat(pixelBuffer[offset + 2]) / 255.0
                let a = CGFloat(pixelBuffer[offset + 3]) / 255.0
                
                let color = UIColor(red: r, green: g, blue: b, alpha: a)
                colorCounts[color, default: 0] += 1
            }
        }
        
        // Get dominant colors using k-means-like clustering
        let palette = createPalette(from: Array(colorCounts.keys), count: numberOfColors)
        
        // Map each pixel to nearest palette color
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = CGFloat(pixelBuffer[offset]) / 255.0
                let g = CGFloat(pixelBuffer[offset + 1]) / 255.0
                let b = CGFloat(pixelBuffer[offset + 2]) / 255.0
                let a = CGFloat(pixelBuffer[offset + 3]) / 255.0
                
                let originalColor = UIColor(red: r, green: g, blue: b, alpha: a)
                let nearestColor = findNearestColor(originalColor, in: palette)
                
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                nearestColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                pixelBuffer[offset] = UInt8(red * 255)
                pixelBuffer[offset + 1] = UInt8(green * 255)
                pixelBuffer[offset + 2] = UInt8(blue * 255)
                pixelBuffer[offset + 3] = UInt8(alpha * 255)
            }
        }
        
        // Create new image from modified data
        guard let newCGImage = context.makeImage() else { return image }
        return UIImage(cgImage: newCGImage)
    }
    
    private func createPalette(from colors: [UIColor], count: Int) -> [UIColor] {
        // Simple k-means clustering to find dominant colors
        guard colors.count > count else { return colors }
        
        // Start with evenly distributed colors
        var centroids = stride(from: 0, to: colors.count, by: colors.count / count)
            .prefix(count)
            .map { colors[$0] }
        
        // Iterate to refine centroids
        for _ in 0..<10 {
            var clusters: [[UIColor]] = Array(repeating: [], count: count)
            
            for color in colors {
                let nearestIndex = centroids.enumerated().min(by: { a, b in
                    colorDistance(color, a.element) < colorDistance(color, b.element)
                })!.offset
                clusters[nearestIndex].append(color)
            }
            
            centroids = clusters.map { cluster in
                guard !cluster.isEmpty else { return centroids[0] }
                return averageColor(of: cluster)
            }
        }
        
        return centroids
    }
    
    private func averageColor(of colors: [UIColor]) -> UIColor {
        var totalR: CGFloat = 0, totalG: CGFloat = 0, totalB: CGFloat = 0, totalA: CGFloat = 0
        
        for color in colors {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            totalR += r
            totalG += g
            totalB += b
            totalA += a
        }
        
        let count = CGFloat(colors.count)
        return UIColor(
            red: totalR / count,
            green: totalG / count,
            blue: totalB / count,
            alpha: totalA / count
        )
    }
    
    private func colorDistance(_ c1: UIColor, _ c2: UIColor) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))
    }
    
    private func findNearestColor(_ color: UIColor, in palette: [UIColor]) -> UIColor {
        palette.min(by: { colorDistance(color, $0) < colorDistance(color, $1) }) ?? color
    }
    
    private func extractColorRegions(from image: UIImage) -> [ColorRegion] {
        guard let cgImage = image.cgImage else { return [] }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // For now, return simplified regions (will be enhanced)
        var regions: [ColorRegion] = []
        
        // This is a placeholder - real implementation would use flood fill or similar
        // to find connected regions of same color
        
        return regions
    }
    
    private func generateSVG(from regions: [ColorRegion], imageSize: CGSize) -> String {
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" 
             viewBox="0 0 \(Int(imageSize.width)) \(Int(imageSize.height))" 
             width="\(Int(imageSize.width))" 
             height="\(Int(imageSize.height))">
        
        """
        
        // Add regions as paths (placeholder)
        for region in regions {
            svg += """
                <path d="\(region.pathData)" fill="\(region.color.toHex())" />
            
            """
        }
        
        svg += "</svg>"
        
        return svg
    }
}

// Helper structures
struct ColorRegion {
    let color: UIColor
    let pathData: String
    let bounds: CGRect
}

extension UIColor {
    func toHex() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}