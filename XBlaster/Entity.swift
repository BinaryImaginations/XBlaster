//
//  Entity.swift
//  XBlaster
//
//  Created by altair21 on 15/6/4.
//  Copyright (c) 2015年 altair21. All rights reserved.
//

import SpriteKit

class Entity: SKSpriteNode {
    
    struct ColliderType {
        static var Player: UInt32 = 1
        static var Enemy: UInt32 = 2
        static var Bullet: UInt32 = 4
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var direction = CGPointZero
    var health = 100.0
    var maxHealth = 100.0
    var score = 0
    var lives = 1  // Number of times to respawn
    var attackDamage = 1
    var velocity = CGVector(dx: 1.0, dy: 1.0)

    init(position: CGPoint, texture: SKTexture) {
        super.init(texture: texture, color: SKColor.whiteColor(),
            size: texture.size())
        self.position = position
    }

    class func generateTexture() -> SKTexture? {
        // Overridden by subclasses
        return nil
    }

    func update(delta: NSTimeInterval) {
        // Overridden by subclasses
    }
    
    func collidedWith(body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int) {
        // Overridden by subsclasses to implement actions to be carried out when an entity
        // collides with another entity e.g. PlayerShip or Bullet
    }  
    
}
