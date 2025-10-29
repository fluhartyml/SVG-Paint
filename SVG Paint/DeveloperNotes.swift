//
//  DeveloperNotes.swift
//  SVG Paint
//
//  Project memory and decision log
//  Created: 2025-10-29 09:28 CDT
//

/*

# SVG Paint — Developer Notes

Purpose
- Image to SVG converter with gradient flattening
- Secondary: Paint tool for pixel art creation (future)
- Universal posterizer: works on icons, logos, photos

Project Details
- Bundle ID: com.mlf.SVGPaint
- Platform: iOS/iPadOS (Designed for iPad, runs on Mac)
- Storage: None - simple import/convert/export workflow
- Created: 2025-10-29 09:28 CDT

Key Design Decisions

[2025 OCT 29 0928] (MLF) Primary purpose is converting "bitchin icon images" to SVG
[2025 OCT 29 0928] (MLF) Gradient flattening: average gradient colors into single solid color
[2025 OCT 29 0928] (MLF) Universal posterizer: works on ANY image (icon, logo, photo, human, dog)
[2025 OCT 29 0928] (MLF) Output: simplified SVG illustration with flat color regions
[2025 OCT 29 0928] (MLF) Processing: color quantization → gradient averaging → vectorization
[2025 OCT 29 0928] (Claude) No storage/database - simple file-based workflow
[2025 OCT 29 0928] (Claude) User controls: number of colors (3-12), color tolerance (10-50)

Technical Approach

[2025 OCT 29 0928] (Claude) K-means clustering for color quantization
[2025 OCT 29 0928] (Claude) Gradient flattening via color averaging within tolerance
[2025 OCT 29 0928] (Claude) Region extraction via flood fill (to be implemented)
[2025 OCT 29 0928] (Claude) SVG path generation from color regions

Current Status

[2025 OCT 29 0928] (Claude) Xcode project created with GitHub remote
[2025 OCT 29 0928] (Claude) Core files generated: ContentView, SVGConverter, DeveloperNotes
[2025 OCT 29 0928] (Claude) Color quantization algorithm complete
[2025 OCT 29 0928] (Claude) TODO: Implement region extraction (flood fill)
[2025 OCT 29 0928] (Claude) TODO: Implement SVG path tracing from regions
[2025 OCT 29 0928] (Claude) TODO: Add paint tool (future v2)

*/
