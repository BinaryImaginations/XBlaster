//
//  EnemyC.swift
//  XBlaster
//
//  Created by George McMullen on 7/22/16.
//  Copyright © 2016 altair21. All rights reserved.
//

import SpriteKit

class EnemyBoss2: Enemy, SKPhysicsContactDelegate {
    
    override class func generateTexture() -> SKTexture? {
        
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken: dispatch_once_t = 0
        }
        
        dispatch_once(&SharedTexture.onceToken, {
            let mainShip:SKLabelNode = SKLabelNode(fontNamed: "Arial")
            mainShip.name = "mainship"
            mainShip.fontSize = 38
            mainShip.fontColor = SKColor.greenColor()     
            mainShip.text = "(-oo-⚉-oo-)"
            
            let textureView = SKView()
            SharedTexture.texture = textureView.textureFromNode(mainShip)!
            SharedTexture.texture.filteringMode = .Nearest
        })
        
        return SharedTexture.texture
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(entityPosition: CGPoint, playableRect: CGRect) {
        
        let entityTexture = EnemyBoss2.generateTexture()!
        super.init(entityPosition: entityPosition, texture: entityTexture, playableRect: playableRect)
        
        name = "enemy"
        score = 750
        attackDamage = 5
        enemyClass = EnemyClass.Boss
        
        Enemy.loadSharedAssets()
        configureCollisionBody()
        
        scoreLabel.name = "scoreLabel"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = SKColor(red: 0.5, green: 1, blue: 1, alpha: 1)
        scoreLabel.text = String(score)
        
        // Set a default waypoint. The actual waypoint will be called by whoever created this instance
        aiSteering = AISteering(entity: self, waypoint: CGPointZero)
        
        // Changing the maxVelicity and maxSteeringForce will change how an entity moves towards its waypoint.
        // Changing these values can generate some interesting movement effects
        aiSteering.maxVelocity = 10.0
        aiSteering.maxSteeringForce = 0.1
    }
    
}
