//
//  TennisBallWithParticles.swift
//  Versus
//
//  Created by Anitej Srivastava on 05/01/26.
//


import SwiftUI
import RealityKit

extension TennisBallRealityView {
    
    // MARK: - Add Particle Effects
    
    static func addImpactParticles(to anchor: AnchorEntity, at position: SIMD3<Float>) {
        // Create particle emitter for impact effect
        let particleEmitter = Entity()
        particleEmitter.position = position
        
        // Configure particle system
        var particles = ParticleEmitterComponent()
        
        // Emitter shape and behavior
        particles.emitterShape = .sphere
        particles.emitterShapeSize = [0.1, 0.01, 0.1]
        particles.mainEmitter.birthRate = 100
        particles.burstCount = 20
        particles.mainEmitter.lifeSpan = 0.5
        particles.speed = 0.3
        
        // Visual properties
        let particleColor = UIColor(red: 0.0, green: 0.9, blue: 0.46, alpha: 0.8)
        particles.mainEmitter.color = .evolving(
            start: .single(particleColor),
            end: .single(particleColor.withAlphaComponent(0))
        )
        particles.mainEmitter.size = 0.005
        particles.mainEmitter.blendMode = .additive
        
        // Animation
        particles.isEmitting = true
        
        particleEmitter.components.set(particles)
        anchor.addChild(particleEmitter)
        
        // Remove after burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            particleEmitter.removeFromParent()
        }
    }
    
    static func addTrailParticles(to ball: ModelEntity) {
        // Create motion trail effect
        var particles = ParticleEmitterComponent()
        
        particles.emitterShape = .point
        particles.mainEmitter.birthRate = 50
        particles.mainEmitter.lifeSpan = 0.3
        particles.speed = 0.1
        
        // Trail color (tennis ball yellow)
        let trailColor = UIColor(red: 0.8, green: 0.95, blue: 0.2, alpha: 0.6)
        particles.mainEmitter.color = .evolving(
            start: .single(trailColor),
            end: .single(trailColor.withAlphaComponent(0))
        )
        particles.mainEmitter.size = 0.003
        particles.mainEmitter.blendMode = .additive
        
        particles.isEmitting = true
        
        ball.components.set(particles)
    }
    
    // MARK: - Enhanced Coordinator with Particles
    
    class EnhancedCoordinator {
        private var hasPlayedImpact = false
        private var previousPosition: SIMD3<Float> = .zero
        private var velocityCheckTimer: Timer?
        
        func startAnimationWithParticles(
            ball: ModelEntity,
            anchor: AnchorEntity,
            arView: ARView,
            onComplete: @escaping () -> Void
        ) {
            // Add motion trail
            TennisBallRealityView.addTrailParticles(to: ball)
            
            // Initial setup
            ball.position = [-0.3, 2.5, -1.5]
            previousPosition = ball.position
            
            // Apply impulse instead of setting velocity
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                ball.applyLinearImpulse([0.03, -0.15, 0], relativeTo: nil)
                ball.applyAngularImpulse([0.2, 0, 0.3], relativeTo: nil)
            }
            
            // Monitor for impacts and settling
            velocityCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                
                let currentPosition = ball.position
                let displacement = currentPosition - self.previousPosition
                let speed = sqrt(displacement.x * displacement.x +
                               displacement.y * displacement.y +
                               displacement.z * displacement.z)
                
                // Detect impact (ball hitting ground)
                if !self.hasPlayedImpact && currentPosition.y < 0.0 && self.previousPosition.y > 0.0 {
                    self.hasPlayedImpact = true
                    TennisBallRealityView.addImpactParticles(to: anchor, at: currentPosition)
                    
                    // Haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
                
                self.previousPosition = currentPosition
                
                // Check if ball has settled
                if speed < 0.005 && currentPosition.y < 0.3 {
                    timer.invalidate()
                    self.velocityCheckTimer = nil
                    
                    // Stop trail particles
                    if var particles = ball.components[ParticleEmitterComponent.self] {
                        particles.isEmitting = false
                        ball.components.set(particles)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.settleBallWithEffect(ball: ball) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onComplete()
                            }
                        }
                    }
                }
                
                // Safety timeout
                if timer.fireDate.timeIntervalSinceNow < -5.0 {
                    timer.invalidate()
                    self.velocityCheckTimer = nil
                    self.settleBallWithEffect(ball: ball, completion: onComplete)
                }
            }
        }
        
        private func settleBallWithEffect(ball: ModelEntity, completion: @escaping () -> Void) {
            let finalPosition: SIMD3<Float> = [0, 0.1, -1.5]
            
            // Switch to kinematic mode
            if var physics = ball.components[PhysicsBodyComponent.self] {
                physics.mode = .kinematic
                ball.components.set(physics)
            }
            
            // Smooth settle animation
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
            
            // Squash and stretch with haptics
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                // Squash
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                
                ball.move(
                    to: Transform(
                        scale: [1.1, 0.9, 1.1],
                        rotation: ball.orientation,
                        translation: finalPosition
                    ),
                    relativeTo: ball.parent,
                    duration: 0.1
                )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Stretch back
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

// MARK: - Integration Guide
/*
 To integrate particles into your existing TennisBallTransitionView:
 
 1. In TennisBallRealityView's makeUIView method, replace the Coordinator usage:
    
    // Replace:
    context.coordinator.startAnimation(...)
    
    // With:
    let enhancedCoordinator = TennisBallRealityView.EnhancedCoordinator()
    enhancedCoordinator.startAnimationWithParticles(
        ball: ball,
        anchor: anchor,
        arView: arView,
        onComplete: onComplete
    )
 
 2. This adds:
    - Motion trail particles while ball is moving
    - Impact burst particles on ground contact
    - Haptic feedback for immersive experience
    - Enhanced settling animation
 
 3. For best results, combine with the enhanced texture:
    let ball = TennisBallRealityView.createEnhancedTennisBall()
 */
