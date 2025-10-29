//
//  SVGConverter.swift
//  SVG Paint
//
//  Core image to SVG conversion with gradient flattening
//  Created: 2025-10-29 09:28 CDT
//

import UIKit
import CoreImage

@MainActor
class SVGConverter {
    
    func convert(image: UIImage, numberOfColors: Int, colorTolerance: Double) async -> String {
        let quantizedImage = await quantizeColors(image: image, numberOfColors: numberOfColors, tolerance: colorTolerance)
        let svgContent = await generateSimpleSVG(from: quantizedImage)
        return svgContent
    }
    
    nonisolated private func quantizeColors(image: UIImage, numberOfColors: Int, tolerance: Double) async -> UIImage {
        return await Task.detached {
            guard let cgImage = image.cgImage else { return image }
            
            let width = cgImage.width
            let height = cgImage.height
            
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
            
            var colorMap: [String: (color: UIColor, count: Int)] = [:]
            
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * 4
                    let r = CGFloat(pixelBuffer[offset]) / 255.0
                    let g = CGFloat(pixelBuffer[offset + 1]) / 255.0
                    let b = CGFloat(pixelBuffer[offset + 2]) / 255.0
                    let a = CGFloat(pixelBuffer[offset + 3]) / 255.0
                    
                    let color = UIColor(red: r, green: g, blue: b, alpha: a)
                    let key = SVGConverter.toHexStatic(color)
                    
                    if let existing = colorMap[key] {
                        colorMap[key] = (color: existing.color, count: existing.count + 1)
                    } else {
                        colorMap[key] = (color: color, count: 1)
                    }
                }
            }
            
            let allColors = colorMap.values.map { $0.color }
            let palette = SVGConverter.createPaletteStatic(from: allColors, count: numberOfColors)
            
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * 4
                    let r = CGFloat(pixelBuffer[offset]) / 255.0
                    let g = CGFloat(pixelBuffer[offset + 1]) / 255.0
                    let b = CGFloat(pixelBuffer[offset + 2]) / 255.0
                    let a = CGFloat(pixelBuffer[offset + 3]) / 255.0
                    
                    let originalColor = UIColor(red: r, green: g, blue: b, alpha: a)
                    let nearestColor = SVGConverter.findNearestColorStatic(originalColor, in: palette)
                    
                    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                    nearestColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                    
                    pixelBuffer[offset] = UInt8(red * 255)
                    pixelBuffer[offset + 1] = UInt8(green * 255)
                    pixelBuffer[offset + 2] = UInt8(blue * 255)
                    pixelBuffer[offset + 3] = UInt8(alpha * 255)
                }
            }
            
            guard let newCGImage = context.makeImage() else { return image }
            return UIImage(cgImage: newCGImage)
        }.value
    }
    
    nonisolated private static func createPaletteStatic(from colors: [UIColor], count: Int) -> [UIColor] {
        guard colors.count > count else { return colors }
        
        var centroids = stride(from: 0, to: colors.count, by: max(1, colors.count / count))
            .prefix(count)
            .map { colors[$0] }
        
        for _ in 0..<10 {
            var clusters: [[UIColor]] = Array(repeating: [], count: count)
            
            for color in colors {
                if let nearestIndex = centroids.enumerated().min(by: { a, b in
                    colorDistanceStatic(color, a.element) < colorDistanceStatic(color, b.element)
                })?.offset {
                    clusters[nearestIndex].append(color)
                }
            }
            
            centroids = clusters.enumerated().map { index, cluster in
                guard !cluster.isEmpty else { return centroids[index] }
                return averageColorStatic(of: cluster)
            }
        }
        
        return centroids
    }
    
    nonisolated private static func averageColorStatic(of colors: [UIColor]) -> UIColor {
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
    
    nonisolated private static func colorDistanceStatic(_ c1: UIColor, _ c2: UIColor) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))
    }
    
    nonisolated private static func findNearestColorStatic(_ color: UIColor, in palette: [UIColor]) -> UIColor {
        palette.min(by: { colorDistanceStatic(color, $0) < colorDistanceStatic(color, $1) }) ?? color
    }
    
    nonisolated private static func toHexStatic(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
    
    nonisolated private func generateSimpleSVG(from image: UIImage) async -> String {
        guard let pngData = image.pngData() else {
            return "<svg></svg>"
        }
        
        let base64 = pngData.base64EncodedString()
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        
        let svgString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" viewBox=\"0 0 \(width) \(height)\" width=\"\(width)\" height=\"\(height)\"><image width=\"\(width)\" height=\"\(height)\" xlink:href=\"data:image/png;base64,\(base64)\"/></svg>"
                
                return svgString
            }
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
