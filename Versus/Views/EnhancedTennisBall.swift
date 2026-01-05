//
//  EnhancedTennisBall.swift
//  Versus
//
//  Created by Anitej Srivastava on 05/01/26.
//

import SwiftUI
import RealityKit
import CoreGraphics

extension TennisBallRealityView {
    
    // MARK: - Enhanced Tennis Ball with Custom Texture
    
    static func createEnhancedTennisBall() -> ModelEntity {
        let sphere = MeshResource.generateSphere(radius: 0.067)
        
        // Create custom tennis ball texture
        let texture = createTennisBallTexture()
        
        var material = PhysicallyBasedMaterial()
        
        // Use custom texture - CORRECTED
        if let cgImage = texture.cgImage {
            do {
                let textureResource = try TextureResource.generate(
                    from: cgImage,
                    options: .init(semantic: .color)
                )
                material.baseColor = .init(texture: .init(textureResource))
            } catch {
                print("Failed to generate texture: \(error)")
                // Fallback to solid color
                material.baseColor = .init(tint: UIColor(red: 0.8, green: 0.95, blue: 0.2, alpha: 1.0))
            }
        }
        
        // Material properties for realism
        material.roughness = .init(floatLiteral: 0.85)
        material.metallic = .init(floatLiteral: 0.0)
        
        let ball = ModelEntity(mesh: sphere, materials: [material])
        
        // Physics setup - CORRECTED
        let physicsMaterial = PhysicsMaterialResource.generate(
            staticFriction: 0.6,
            dynamicFriction: 0.4,
            restitution: 0.75
        )
        
        let physicsBody = PhysicsBodyComponent(
            massProperties: .init(mass: 0.058),
            material: physicsMaterial,
            mode: .dynamic
        )
        ball.components.set(physicsBody)
        
        let collision = CollisionComponent(shapes: [.generateSphere(radius: 0.067)])
        ball.components.set(collision)
        
        return ball
    }
    
    // MARK: - Custom Tennis Ball Texture Generator
    
    static func createTennisBallTexture() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Base yellow-green color
            let baseColor = UIColor(red: 0.8, green: 0.95, blue: 0.2, alpha: 1.0)
            baseColor.setFill()
            context.fill(rect)
            
            // Add fuzzy texture noise
            addFuzzyTexture(to: context, in: rect)
            
            // Draw characteristic curved white lines
            drawTennisBallLines(to: context, in: rect)
            
            // Add subtle shading gradient
            addShading(to: context, in: rect)
        }
        
        return image
    }
    
    private static func addFuzzyTexture(to context: UIGraphicsRendererContext, in rect: CGRect) {
        let cgContext = context.cgContext
        
        // Create fuzzy texture with random dots
        for _ in 0..<3000 {
            let x = CGFloat.random(in: 0...rect.width)
            let y = CGFloat.random(in: 0...rect.height)
            let size = CGFloat.random(in: 0.5...2.0)
            let opacity = CGFloat.random(in: 0.1...0.3)
            
            let color = UIColor(white: 1.0, alpha: opacity)
            color.setFill()
            
            let dotRect = CGRect(x: x, y: y, width: size, height: size)
            cgContext.fillEllipse(in: dotRect)
        }
    }
    
    private static func drawTennisBallLines(to context: UIGraphicsRendererContext, in rect: CGRect) {
        let cgContext = context.cgContext
        
        // White color for lines
        UIColor.white.setStroke()
        cgContext.setLineWidth(8)
        cgContext.setLineCap(.round)
        
        // Draw characteristic curved lines (simplified version)
        // Top curve
        let topPath = UIBezierPath()
        topPath.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.3))
        topPath.addQuadCurve(
            to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.3),
            controlPoint: CGPoint(x: rect.width * 0.5, y: rect.height * 0.1)
        )
        cgContext.addPath(topPath.cgPath)
        cgContext.strokePath()
        
        // Bottom curve (mirrored)
        let bottomPath = UIBezierPath()
        bottomPath.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.7))
        bottomPath.addQuadCurve(
            to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.7),
            controlPoint: CGPoint(x: rect.width * 0.5, y: rect.height * 0.9)
        )
        cgContext.addPath(bottomPath.cgPath)
        cgContext.strokePath()
        
        // Add side curves for wrapping effect
        cgContext.setLineWidth(6)
        
        // Left curve
        let leftPath = UIBezierPath()
        leftPath.move(to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.25))
        leftPath.addQuadCurve(
            to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.75),
            controlPoint: CGPoint(x: rect.width * 0.05, y: rect.height * 0.5)
        )
        cgContext.addPath(leftPath.cgPath)
        cgContext.strokePath()
        
        // Right curve
        let rightPath = UIBezierPath()
        rightPath.move(to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.25))
        rightPath.addQuadCurve(
            to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.75),
            controlPoint: CGPoint(x: rect.width * 0.95, y: rect.height * 0.5)
        )
        cgContext.addPath(rightPath.cgPath)
        cgContext.strokePath()
    }
    
    private static func addShading(to context: UIGraphicsRendererContext, in rect: CGRect) {
        let cgContext = context.cgContext
        
        // Create radial gradient for subtle 3D effect
        let colors = [
            UIColor(white: 1.0, alpha: 0.2).cgColor,
            UIColor(white: 0.0, alpha: 0.1).cgColor
        ]
        
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0.0, 1.0]
        )!
        
        cgContext.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: rect.midX - rect.width * 0.2, y: rect.midY - rect.height * 0.2),
            startRadius: 0,
            endCenter: CGPoint(x: rect.midX, y: rect.midY),
            endRadius: rect.width * 0.6,
            options: []
        )
    }
}

// MARK: - Usage Instructions
/*
 To use the enhanced tennis ball with custom texture, in TennisBallRealityView's makeUIView,
 replace:
 
 let ball = createTennisBall()
 
 with:
 
 let ball = TennisBallRealityView.createEnhancedTennisBall()
 
 This will give you a tennis ball with:
 - Custom procedurally generated texture
 - Characteristic curved white lines
 - Fuzzy surface appearance
 - Subtle 3D shading
 */
