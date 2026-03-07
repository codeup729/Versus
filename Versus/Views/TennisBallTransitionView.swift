//
//  TennisBallTransitionView.swift
//  Versus
//
//  Created by Anitej Srivastava on 05/01/26.
//


import SwiftUI
import RealityKit
import Combine

struct TennisBallTransitionView: View {
    var showAuthBackground: Bool
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent black overlay if auth is showing
            if showAuthBackground {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            TennisBallRealityView(onComplete: onComplete)
                .ignoresSafeArea()
        }
    }
}

// MARK: - RealityKit View

struct TennisBallRealityView: UIViewRepresentable {
    var onComplete: () -> Void
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.backgroundColor = .clear
        
        // Create anchor
        let anchor = AnchorEntity()
        arView.scene.addAnchor(anchor)
        
        // Create tennis ball with seams
        let ball = createTennisBallWithSeams()
        anchor.addChild(ball)
        
        // Position ball at starting point
        ball.position = [-0.3, 2.5, -1.5]
        
        // Add lighting
        addLighting(to: anchor)
        
        // Add ground plane for collisions
        let ground = createGroundPlane()
        anchor.addChild(ground)
        
        // Start animation
        context.coordinator.startAnimation(ball: ball, anchor: anchor, arView: arView, onComplete: onComplete)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Tennis Ball Creation with Seams
    
    private func createTennisBallWithSeams() -> ModelEntity {
        let sphere = MeshResource.generateSphere(radius: 0.067)
        
        // Create tennis ball material
        var material = PhysicallyBasedMaterial()
        
        // Tennis ball yellow color
        material.baseColor = .init(tint: UIColor(red: 0.85, green: 0.95, blue: 0.25, alpha: 1.0))
        material.roughness = .init(floatLiteral: 0.85)
        material.metallic = .init(floatLiteral: 0.0)
        
        let ball = ModelEntity(mesh: sphere, materials: [material])
        
        // Add the seam lines as child entities
        addSeams(to: ball)
        
        // Add physics
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
        
        // Add collision
        let collision = CollisionComponent(shapes: [.generateSphere(radius: 0.067)])
        ball.components.set(collision)
        
        return ball
    }
    
    // MARK: - Seam Creation
    
    private func addSeams(to ball: ModelEntity) {
        // Create two curved seam lines that wrap around the ball
        // Tennis ball seams form a curved line pattern
        
        // Seam material (white)
        let seamMaterial = UnlitMaterial(color: .white)
        
        // Create first seam curve
        let seam1 = createSeamCurve(angle: 0)
        seam1.model?.materials = [seamMaterial]
        ball.addChild(seam1)
        
        // Create second seam curve (mirrored)
        let seam2 = createSeamCurve(angle: .pi)
        seam2.model?.materials = [seamMaterial]
        ball.addChild(seam2)
    }
    
    private func createSeamCurve(angle: Float) -> ModelEntity {
        // Create a curved seam line using multiple small cylinders
        let seamWidth: Float = 0.003
        let seamRadius: Float = 0.068 // Slightly larger than ball radius
        
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        // Generate vertices for the seam curve
        // Tennis ball seam follows a sinusoidal path around the ball
        let segments = 60
        for i in 0...segments {
            let t = Float(i) / Float(segments)
            let theta = t * 2 * .pi + angle
            
            // Sinusoidal curve for realistic seam pattern
            let phi = sin(theta * 2) * 0.6 + .pi / 2
            
            let x = seamRadius * sin(phi) * cos(theta)
            let y = seamRadius * cos(phi)
            let z = seamRadius * sin(phi) * sin(theta)
            
            vertices.append(SIMD3<Float>(x, y, z))
        }
        
        // Create mesh from vertices using boxes to form the seam line
        let seamEntity = ModelEntity()
        
        // Create small boxes along the curve
        for i in 0..<vertices.count - 1 {
            let box = MeshResource.generateBox(size: [seamWidth, seamWidth, seamWidth])
            let boxEntity = ModelEntity(mesh: box)
            
            // Position at vertex
            boxEntity.position = vertices[i]
            
            // Orient towards next vertex
            if i < vertices.count - 1 {
                var direction = normalize(vertices[i + 1] - vertices[i])
                boxEntity.look(at: vertices[i + 1], from: vertices[i], relativeTo: seamEntity)
            }
            
            seamEntity.addChild(boxEntity)
        }
        
        return seamEntity
    }
    
    // MARK: - Ground Plane
    
    private func createGroundPlane() -> ModelEntity {
        let plane = MeshResource.generatePlane(width: 5, depth: 5)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .clear)
        material.roughness = .init(floatLiteral: 0.8)
        
        let ground = ModelEntity(mesh: plane, materials: [material])
        ground.position = [0, -0.5, -1.5]
        
        // Add static physics
        let physicsMaterial = PhysicsMaterialResource.generate(
            staticFriction: 0.8,
            dynamicFriction: 0.6,
            restitution: 0.3
        )
        
        let physicsBody = PhysicsBodyComponent(
            massProperties: .init(mass: 1000),
            material: physicsMaterial,
            mode: .static
        )
        ground.components.set(physicsBody)
        
        let collision = CollisionComponent(shapes: [.generateBox(width: 5, height: 0.01, depth: 5)])
        ground.components.set(collision)
        
        return ground
    }
    
    // MARK: - Lighting
    
    private func addLighting(to anchor: AnchorEntity) {
        // Main directional light
        let mainLight = DirectionalLight()
        mainLight.light.color = .white
        mainLight.light.intensity = 3500
        mainLight.shadow = DirectionalLightComponent.Shadow(
            maximumDistance: 5,
            depthBias: 2
        )
        mainLight.position = [2, 3, -1]
        mainLight.look(at: [0, 0, -1.5], from: mainLight.position, relativeTo: nil)
        anchor.addChild(mainLight)
        
        // Fill light
        let fillLight = PointLight()
        fillLight.light.color = .white
        fillLight.light.intensity = 1200
        fillLight.light.attenuationRadius = 5
        fillLight.position = [-1, 1, -1]
        anchor.addChild(fillLight)
        
        // Ambient light
        let ambientLight = PointLight()
        ambientLight.light.color = .white
        ambientLight.light.intensity = 600
        ambientLight.light.attenuationRadius = 10
        ambientLight.position = [0, 2, -2]
        anchor.addChild(ambientLight)
    }
    
    // MARK: - Coordinator
    
    class Coordinator {
        private var cancellables = Set<AnyCancellable>()
        private var previousPosition: SIMD3<Float> = .zero
        private var velocityCheckTimer: Timer?
        
        func startAnimation(ball: ModelEntity, anchor: AnchorEntity, arView: ARView, onComplete: @escaping () -> Void) {
            // Apply initial impulse instead of setting velocity directly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Apply downward and sideways impulse
                ball.applyLinearImpulse([0.03, -0.15, 0], relativeTo: nil)
                
                // Apply angular impulse for spinning
                ball.applyAngularImpulse([0.2, 0, 0.3], relativeTo: nil)
            }
            
            // Store initial position
            previousPosition = ball.position
            
            // Monitor ball movement
            velocityCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                
                let currentPosition = ball.position
                let displacement = currentPosition - self.previousPosition
                let speed = sqrt(displacement.x * displacement.x +
                               displacement.y * displacement.y +
                               displacement.z * displacement.z)
                
                self.previousPosition = currentPosition
                
                // Check if ball has settled (very low speed and low position)
                if speed < 0.005 && currentPosition.y < 0.3 {
                    timer.invalidate()
                    self.velocityCheckTimer = nil
                    
                    // Wait a moment then settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.settleBall(ball: ball) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onComplete()
                            }
                        }
                    }
                }
                
                // Safety timeout after 5 seconds
                if timer.fireDate.timeIntervalSinceNow < -5.0 {
                    timer.invalidate()
                    self.velocityCheckTimer = nil
                    self.settleBall(ball: ball, completion: onComplete)
                }
            }
        }
        
        private func settleBall(ball: ModelEntity, completion: @escaping () -> Void) {
            let finalPosition: SIMD3<Float> = [0, 0.1, -1.5]
            
            // Switch to kinematic mode for smooth positioning
            if var physics = ball.components[PhysicsBodyComponent.self] {
                physics.mode = .kinematic
                ball.components.set(physics)
            }
            
            // Animate to final position
            ball.move(
                to: Transform(
                    scale: ball.scale,
                    rotation: ball.orientation,
                    translation: finalPosition
                ),
                relativeTo: ball.parent,
                duration: 0.8,
                timingFunction: .easeOut
            )
            
            // Add squash and stretch effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // Squash
                ball.move(
                    to: Transform(
                        scale: [1.1, 0.9, 1.1],
                        rotation: ball.orientation,
                        translation: finalPosition
                    ),
                    relativeTo: ball.parent,
                    duration: 0.1
                )
                
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Stretch back to normal
                    ball.move(
                        to: Transform(
                            scale: [1.0, 1.0, 1.0],
                            rotation: ball.orientation,
                            translation: finalPosition
                        ),
                        relativeTo: ball.parent,
                        duration: 0.15,
                        timingFunction: .easeOut
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        completion()
                    }
                }
            }
        }
        
        deinit {
            velocityCheckTimer?.invalidate()
        }
    }
}

// MARK: - Preview

#Preview {
    TennisBallTransitionView(showAuthBackground: true, onComplete: {})
}
