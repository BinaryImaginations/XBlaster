//
//  EnemyBoss.swift
//  XBlaster
//
//  Created by George McMullen on 7/22/16.
//  Copyright © 2016 altair21. All rights reserved.
//

import SpriteKit

class EnemyBoss: Enemy, SKPhysicsContactDelegate {
    
    override class func generateTexture() -> SKTexture? {
        
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken = "EnemyBoss"
        }
        
        // See extension in Entity.swift
        DispatchQueue.once(token: SharedTexture.onceToken) {
            let mainShip:SKLabelNode = SKLabelNode(fontNamed: "Arial")
            mainShip.name = "mainship"
            mainShip.fontSize = 38
            mainShip.fontColor = SKColor.yellow
            mainShip.text = "(-x=⚉=x-)"
            
            let textureView = SKView()
            SharedTexture.texture = textureView.texture(from: mainShip)!
            SharedTexture.texture.filteringMode = .nearest
        }
        
        return SharedTexture.texture
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(entityPosition: CGPoint, playableRect: CGRect) {
        
        let entityTexture = EnemyBoss.generateTexture()!
        super.init(entityPosition: entityPosition, texture: entityTexture, playableRect: playableRect)
        
        name = "enemy"
        score = 500
        lives = 1
        attackDamage = 5
        enemyClass = EnemyClass.boss
        
        Enemy.loadSharedAssets()
        configureCollisionBody()
        
        scoreLabel.name = "scoreLabel"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = SKColor(red:0.5, green:1, blue:1, alpha:1)
        scoreLabel.text = String(score)
        
        // Set a default waypoint. The actual waypoint will be called by whoever created this instance
        aiSteering = AISteering(entity:self, waypoint:CGPoint.zero)
        
        // Changing the maxVelicity and maxSteeringForce will change how an entity moves towards its waypoint.
        // Changing these values can generate some interesting movement effects
        aiSteering.maxVelocity = 9.0
        aiSteering.maxSteeringForce = 0.15
    }
}
