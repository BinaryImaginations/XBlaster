//
//  PlayerShip.swift
//  XBlaster
//
//  Created by altair21 on 15/6/4.
//  Copyright (c) 2015年 altair21. All rights reserved.
//

import SpriteKit

class PlayerShip: Entity {

    init(entityPosition: CGPoint) {
        let entityTexture = PlayerShip.generateTexture()!
        
        super.init(position: entityPosition, texture: entityTexture)
        
        name = "playerShip"
        
        // Details on how the Sprite Kit physics engine works can be found in the book in
        // Chapter 9, "Beginner Physics"
        configureCollisionBody()
        ventingPlasma.isHidden = true
        //        damageEmitter.hidden = true
        self.addChild(ventingPlasma)
        //        self.addChild(damageEmitter)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    let ventingPlasma:SKEmitterNode = SKEmitterNode(fileNamed: "ventingPlasma.sks")!
//    let damageEmitter:SKEmitterNode = SKEmitterNode(fileNamed: "ventingPlasma.sks")!
    
    override class func generateTexture() -> SKTexture? {
        // 1
        struct SharedTexture {
          static var texture = SKTexture()
            static var onceToken = "playerShip"
        }
        
        DispatchQueue.once(token: SharedTexture.onceToken) {
            // 2
            let mainShip = SKLabelNode(fontNamed: "Arial")
            mainShip.name = "mainship"
            mainShip.fontSize = 40
            mainShip.fontColor = SKColor.white
            mainShip.text = "▲"
            // 3
            let wings = SKLabelNode(fontNamed: "PF TempestaSeven")
            wings.name = "wings"
            wings.fontSize = 40
            wings.text = "< >"
            wings.fontColor = SKColor.white
            wings.position = CGPoint(x: 1, y: 7)
            // 4
            wings.zRotation = CGFloat(180).degreesToRadians()
            
            mainShip.addChild(wings)
            // 5
            let textureView = SKView()
            SharedTexture.texture = textureView.texture(from: mainShip)!
            SharedTexture.texture.filteringMode = .nearest
        }
        
        return SharedTexture.texture
    }
    
    func configureCollisionBody() {
        // Set up the physics body for this entity using a circle around the ship
        physicsBody = SKPhysicsBody(circleOfRadius: 15)
        
        // There is no gravity in the game so it shoud be switched off for this physics body
        physicsBody!.affectedByGravity = false
        
        // Specify the type of physics body this is using the ColliderType defined in the Entity
        // class. This tells the physics engine that this entity is the player
        physicsBody!.categoryBitMask = ColliderType.Player
        
        // We don't want the physics engine applying it's own effects when physics body collide so
        // we switch it off
        physicsBody!.collisionBitMask = 0
        
        // Specify physics bodies we want this entity to be able to collide with. Specifying Enemy
        // means that the physics collision method inside GameScene will be called when this entity
        // collides with an Entity that is marked as ColliderType.Enemy
        physicsBody!.contactTestBitMask = ColliderType.Enemy
    }
    
    override func collidedWith(_ body: SKPhysicsBody, contact: SKPhysicsContact, damage: Int = 5) {
        // This method is called from GameScene didBeginContact(contact:) when the player entity
        // hits an enemy entity. When that happens the players health is reduced by 5 and a check
        // makes sure that the health cannot drop below zero
        let mainScene = scene as! GameScene
        mainScene.playExplodeSound()

        health -= Double(damage)
        if health < 0 {
            health = 0
        }
        
        ventingPlasma.isHidden = health > 30
        
//        damageEmitter.setScale(CGFloat(1.5))
//        damageEmitter.hidden = false
//        damageEmitter.alpha = 1.0
//        damageEmitter.runAction(SKAction.sequence([SKAction.fadeOutWithDuration(1.0),SKAction.hide()]))
//        damageEmitter.resetSimulation()

        mainScene.playExplodeSound()
    }
    
    func createEngine() {
        let engineEmitter = SKEmitterNode(fileNamed: "engine.sks")
        engineEmitter!.position = CGPoint(x: 1, y: -4)
        engineEmitter!.name = "engineEmitter"
        addChild(engineEmitter!)
        
        let mainScene = scene as! GameScene
        engineEmitter!.targetNode = mainScene.particleLayerNode
    }
    
}
