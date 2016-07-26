//
//  Bullet.swift
//  XBlaster
//
//  Created by altair21 on 15/6/5.
//  Copyright (c) 2015年 altair21. All rights reserved.
//

import SpriteKit

class Bullet: Entity {
    
    init(entityPosition: CGPoint) {
        let entityTexture = Bullet.generateTexture()!
        
        super.init(position: entityPosition, texture: entityTexture)
        
        name = "bullet"
        
        configureCollisionBody()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override class func generateTexture() -> SKTexture? {
        struct SharedTexture {
            static var texture = SKTexture()
            static var onceToken: dispatch_once_t = 0
        }
        
        dispatch_once(&SharedTexture.onceToken, {
            let bullet = SKLabelNode(fontNamed: "Arial")
            bullet.name = "bullet"
            bullet.fontSize = 30
            bullet.fontColor = SKColor.whiteColor()
            bullet.text = "•"
            
            let textureView = SKView()
            SharedTexture.texture =
                textureView.textureFromNode(bullet)!
            SharedTexture.texture.filteringMode = .Nearest
        })
        
        return SharedTexture.texture
    }
    
    func configureCollisionBody() {
        // Set the PlayerShip class for details of how the physics body configuration is used.
        // More details are provided in Chapter 9 "Beginner Physics" in the book also
        physicsBody = SKPhysicsBody(circleOfRadius:5)
        physicsBody!.affectedByGravity = false
        physicsBody!.categoryBitMask = ColliderType.Bullet
        physicsBody!.collisionBitMask = 0
        physicsBody!.contactTestBitMask = ColliderType.Enemy
    }
    
    override func collidedWith(body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int) {
        removeFromParent()
    }
    
}