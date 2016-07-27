//
//  GameScene.swift
//  XBlaster
//
//  Created by altair21 on 15/6/4.
//  Copyright (c) 2015年 altair21. All rights reserved.
//

import SpriteKit

// The update method uses the GameState to work out what should be done during each update
// loop
enum GameState {
    case SplashScreen
    case GameRunning
    case GameOver
    case WaveComplete
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let playerLayerNode = SKNode()
    let hudLayerNode = SKNode()
    let bulletLayerNode = SKNode()
    var enemyLayerNode = SKNode()
    let particleLayerNode = SKNode()
    
    let gameOverLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")
    let levelLabel = SKLabelNode(fontNamed:  "Edit Undo Line BRK")
    let scoreLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")
    let playerHealthLabel = SKLabelNode(fontNamed: "Arial")
    let countdownLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")
    
    
    let playableRect: CGRect
    let screenBackgroundColor = SKColor.blackColor()
    let hudHeight: CGFloat = 90
    var scoreFlashAction: SKAction!
    let healthBarString: NSString = "===================="
    var playerShip: PlayerShip!
    var deltaPoint = CGPointZero
    var previousTouchLocation = CGPointZero
    var bulletInterval: NSTimeInterval = 0
    var bulletFireRateInterval: NSTimeInterval = 0.12
    var lastUpdateTime: NSTimeInterval = 0
    var bonusStartTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    var bonusTimeRemaining: Int = 0
    var lastBonusTimeRemaining: Int = 0
    var score = 0
    var gameState = GameState.GameRunning
    var bonusMode = false
    var endBonusMode = false
    var bonusTimeMaxRegenerationPercent = 0.5
    var bonusTime: Int = 30
    let maxFighters = 3
    let livesPerFighter = 2
    let levelsMinisGainsAdditionalLives = 10
    let levelMinisAppear = 5
    let levelBossAppear = 10
    let levelBoss2Appear = 15
    let maxLivesPerMini = 0
    var damageFromPlayerHit = 10
    let maxBosses = 5
    let maxMinis = 15
    var wave = 0
    
    
    let screenPulseAction = SKAction.repeatActionForever(SKAction.sequence([
        SKAction.fadeOutWithDuration(1),
        SKAction.fadeInWithDuration(1)
        ]))
    let tapScreenLabel = SKLabelNode(fontNamed: "Edit Undo Line BRK")
    
    let laserSound = SKAction.playSoundFileNamed("laser.wav", waitForCompletion: false)
    let explodeSound = SKAction.playSoundFileNamed("explode.wav", waitForCompletion: false)
    
    override init(size: CGSize) {
        // Calculate playable margin
        playableRect = CGRect(x: 20, y: 20, width: size.width-40, height: size.height - hudHeight-40)
        
        super.init(size: size)
        
        // Setup the initial game state
        gameState = .GameRunning
        
        setupSceneLayers()
        setUpUI()
        setupEntities()
        
        SKTAudio.sharedInstance().playBackgroundMusic("bgMusic.mp3")
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
    }
    
    func setupSceneLayers() {
        playerLayerNode.zPosition = 50
        hudLayerNode.zPosition = 100
        bulletLayerNode.zPosition = 25
        enemyLayerNode.zPosition = 35
        
        self.runAction(SKAction.sequence([
            SKAction.colorizeWithColor(screenBackgroundColor, colorBlendFactor: 1.0, duration: 0)]))
        addChild(playerLayerNode)
        addChild(hudLayerNode)
        addChild(bulletLayerNode)
        addChild(enemyLayerNode)
        
        let starfieldNode = SKNode()
        starfieldNode.name = "starfieldNode"
        starfieldNode.addChild(starfieldEmitterNode(speed: -48, lifetime: size.height / 23, scale: 0.2, birthRate: 1, color: SKColor.lightGrayColor()))
        addChild(starfieldNode)
        var emitterNode = starfieldEmitterNode(speed: -32, lifetime: size.height / 10, scale: 0.14, birthRate: 2, color: SKColor.grayColor())
        emitterNode.zPosition = -10
        starfieldNode.addChild(emitterNode)
        emitterNode = starfieldEmitterNode(speed: -20, lifetime: size.height / 5, scale: 0.1, birthRate: 5, color: SKColor.darkGrayColor())
        starfieldNode.addChild(emitterNode)
        
        particleLayerNode.zPosition = 10
        addChild(particleLayerNode)
    
    }
    
    func setUpUI() {
        let backgroundSize =
        CGSize(width: size.width, height:hudHeight)
        let hudBarBackground =
        SKSpriteNode(color: screenBackgroundColor, size: backgroundSize)
        hudBarBackground.position =
            CGPoint(x:0, y: size.height - hudHeight)
        hudBarBackground.anchorPoint = CGPointZero
        hudLayerNode.addChild(hudBarBackground)
        
        // 1
        scoreLabel.fontSize = 50
        scoreLabel.text = "Score: 0"
        scoreLabel.name = "scoreLabel"
        // 2
        scoreLabel.verticalAlignmentMode = .Center
        // 3
        scoreLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height - scoreLabel.frame.size.height + 3)
        // 4
        hudLayerNode.addChild(scoreLabel)
        
        scoreFlashAction = SKAction.sequence([
            SKAction.scaleTo(1.5, duration: 0.1),
            SKAction.scaleTo(1.0, duration: 0.1)])
        scoreLabel.runAction(
            SKAction.repeatAction(scoreFlashAction, count: 20))
        
        // 1
        let playerHealthBackgroundLabel =
        SKLabelNode(fontNamed: "Arial")
        playerHealthBackgroundLabel.name = "playerHealthBackground"
        playerHealthBackgroundLabel.fontColor = SKColor.darkGrayColor()
        playerHealthBackgroundLabel.fontSize = 50
        playerHealthBackgroundLabel.text = healthBarString as String
        playerHealthBackgroundLabel.zPosition = 0
        // 2
        playerHealthBackgroundLabel.horizontalAlignmentMode = .Left
        playerHealthBackgroundLabel.verticalAlignmentMode = .Top
        playerHealthBackgroundLabel.position = CGPoint(x: CGRectGetMinX(playableRect), y: size.height - CGFloat(hudHeight) + playerHealthBackgroundLabel.frame.size.height)
        hudLayerNode.addChild(playerHealthBackgroundLabel)
        // 3
        playerHealthLabel.name = "playerHealthLabel"
        playerHealthLabel.fontColor = SKColor.greenColor()
        playerHealthLabel.fontSize = 50
        playerHealthLabel.text = healthBarString.substringToIndex(20*75/100)
        playerHealthLabel.zPosition = 1
        playerHealthLabel.horizontalAlignmentMode = .Left
        playerHealthLabel.verticalAlignmentMode = .Top
        playerHealthLabel.position = CGPoint(x: CGRectGetMinX(playableRect), y: size.height - CGFloat(hudHeight) +
        playerHealthLabel.frame.size.height)
        hudLayerNode.addChild(playerHealthLabel)
        
        gameOverLabel.name = "gameOverLabel"
        gameOverLabel.fontSize = 100
        gameOverLabel.fontColor = SKColor.whiteColor()
        gameOverLabel.horizontalAlignmentMode = .Center
        gameOverLabel.verticalAlignmentMode = .Center
        gameOverLabel.position = CGPointMake(size.width / 2, size.height / 2)
        gameOverLabel.text = "GAME OVER";
        
        countdownLabel.name = "countdownLabel"
        countdownLabel.fontSize = 100
        countdownLabel.fontColor = SKColor.whiteColor()
        countdownLabel.horizontalAlignmentMode = .Center
        countdownLabel.verticalAlignmentMode = .Center
        countdownLabel.position = CGPointMake(size.width / 2, size.height / 2)
        
        levelLabel.name = "levelLabel"
        levelLabel.fontSize = 50
        levelLabel.fontColor = SKColor.whiteColor()
        levelLabel.horizontalAlignmentMode = .Center
        levelLabel.verticalAlignmentMode = .Center
        levelLabel.position = CGPointMake(size.width / 2, size.height / 2)
        levelLabel.text = "WAVE COMPLETE";
        
        tapScreenLabel.name = "tapScreen"
        tapScreenLabel.fontSize = 22;
        tapScreenLabel.fontColor = SKColor.whiteColor()
        tapScreenLabel.horizontalAlignmentMode = .Center
        tapScreenLabel.verticalAlignmentMode = .Center
        tapScreenLabel.position = CGPointMake(size.width / 2,
            size.height / 2 - 100)
        tapScreenLabel.text = "Tap Screen To Start Attack Wave"
        
    }
    
    func setupEntities() {
        playerShip = PlayerShip(entityPosition: CGPoint(x: size.width / 2, y: 100))
        
        if (playerShip.parent == nil) {
            playerLayerNode.addChild(playerShip)
            playerShip.createEngine()
        }

        // Add the initial enemies
        setupEnemies()
    }
    
    func setupEnemies() {
        if (wave+1)%5 == 0 {
            bonusMode = true
            addBonusEnemies()
        } else {
            addFighters()
            addMinis()
            addBosses()
            addBosses2()
        }
    }
    
    // Fighter add method:  Fighters are added up to the maximum number at a rate of 1 ever 3 levels.
    func addFighters() {
        var number: Int = (wave/3) + 1
        if (number > maxFighters) {
            number = maxFighters
        }
        
        for _ in 0..<number {
            let enemy = EnemyA(entityPosition: CGPointMake(
                CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                playableRect.size.height+100), playableRect: playableRect)
            
            // Set the initialWaypoint for the enemy to a random position within the playableRect
            let initialWaypoint = CGPointMake(CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width), CGFloat.random(min: 0, max: playableRect.size.height))
            enemy.aiSteering.updateWaypoint(initialWaypoint)
            enemy.lives = livesPerFighter
            enemy.speed = CGFloat(0.55)
            enemyLayerNode.addChild(enemy)
        }
        // Add some EnemyB entities to the scene
        for _ in 0..<number {
            let enemy = EnemyB(entityPosition: CGPointMake(
                CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                playableRect.size.height+100), playableRect: playableRect)
            let initialWaypoint = CGPointMake(CGFloat.random(min: playableRect.origin.x, max: playableRect.width), CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
            enemy.aiSteering.updateWaypoint(initialWaypoint)
            enemy.lives = livesPerFighter
            enemy.speed = CGFloat(0.65)
            enemyLayerNode.addChild(enemy)
        }
    }
    
    // Bonus Levels
    func addBonusEnemies() {
        var number: Int = 15 + ((wave+1)/5) * 5
        if (number > maxFighters * 10) {
            number = maxFighters * 10
        }
        let miniLives = 0
        for _ in 0..<number {
            let enemy = EnemyMini(entityPosition: CGPointMake(
                CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                playableRect.size.height+100), playableRect: playableRect)
            let initialWaypoint = CGPointMake(CGFloat.random(min: playableRect.origin.x, max: playableRect.width), CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
            enemy.aiSteering.updateWaypoint(initialWaypoint)
            enemy.health = 25
            enemy.maxHealth = 25
            enemy.speed = CGFloat(1.0)
            enemy.lives = miniLives
            enemy.attackDamage = 0  // No damage from these enemies
            enemyLayerNode.addChild(enemy)
        }

    }
    
    // Mini Bosses add method:  Mini bosses are added starting in wave 5 with additional mini bosses added each level up to the maximum number.  Every 10 levels mini bosses gain an addition life.
    func addMinis() {
        var number: Int = (wave/3) + 1
        if (number > maxMinis) {
            number = maxMinis
        }
        var miniLives = ((wave + 1)/levelsMinisGainsAdditionalLives)
        if (maxLivesPerMini != 0) {
            miniLives = (miniLives > maxLivesPerMini ? maxLivesPerMini : miniLives)
        }
        
        // Add mini boss enemies starting at wave 5
        if (wave >= levelMinisAppear) {
            for _ in 0..<number {
                let enemy = EnemyMini(entityPosition: CGPointMake(
                    CGFloat.random(min: playableRect.origin.x, max: playableRect.size.width),
                    playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPointMake(CGFloat.random(min: playableRect.origin.x, max: playableRect.width), CGFloat.random(min: playableRect.height / 2, max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = 25
                enemy.maxHealth = 25
                enemy.speed = CGFloat(1.0)
                if (wave >= levelsMinisGainsAdditionalLives) {
                    enemy.lives = miniLives
                }
                enemyLayerNode.addChild(enemy)
            }
        }
    }
    
    // Bosses add method:  Bosses are added starting in wave 10 with additional bosses added each level up to the maximum number.  Every 10 levels mini bosses gain an addition life.
    func addBosses() {
        if (wave + 1 < levelBossAppear) {
            return
        }
        
        var number: Int = ((wave + 1 - levelBossAppear)/5) + 1
        if (number > maxBosses) {
            number = maxBosses
        }
        
        // If we are on at least wave 10 and the wave is evenly divisble by 5, add a boss
        if (wave >= levelBossAppear-1) {
            // Add boss enemies
            for _ in 0..<number {
                let enemy = EnemyBoss(entityPosition: CGPointMake(
                    CGFloat.random(min: playableRect.origin.x, max:
                        playableRect.size.width),
                    playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPointMake(CGFloat.random(min: playableRect.origin.x, max: playableRect.width), CGFloat.random(min: playableRect.height / 2,   max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = Double((wave+1)/5) * 100.0
                enemy.maxHealth = Double((wave+1)/5) * 100.0
                enemy.lives = (wave+1)/levelBossAppear
                enemy.speed = CGFloat(0.25)
                enemyLayerNode.addChild(enemy)
            }
        }
    }
    
    // Bosses add method:  Bosses are added starting in wave 10 with additional bosses added each level up to the maximum number.  Every 10 levels mini bosses gain an addition life.
    func addBosses2() {
        if (wave + 1 < levelBoss2Appear) {
            return
        }
        
        var number: Int = ((wave + 1 - levelBoss2Appear)/5) + 1
        if (number > maxBosses) {
            number = maxBosses
        }
        
        // If we are on at least wave 10 and the wave is evenly divisble by 5, add a boss
        if (wave >= levelBoss2Appear-1) {
            // Add boss enemies
            for _ in 0..<number {
                let enemy = EnemyBoss2(entityPosition: CGPointMake(
                    CGFloat.random(min: playableRect.origin.x, max:
                        playableRect.size.width),
                    playableRect.size.height+100), playableRect: playableRect)
                let initialWaypoint = CGPointMake(CGFloat.random(min: playableRect.origin.x, max: playableRect.width), CGFloat.random(min: playableRect.height / 2,   max: playableRect.height))
                enemy.aiSteering.updateWaypoint(initialWaypoint)
                enemy.health = Double((wave+1)/5) * 100.0
                enemy.maxHealth = Double((wave+1)/5) * 100.0
                enemy.lives = (wave+1)/levelBossAppear
                enemy.speed = CGFloat(0.25)
                enemyLayerNode.addChild(enemy)
            }
        }
    }
    
    // Increase the score
    func increaseScoreBy(increment: Int) {
        score += increment
        scoreLabel.text = "Score: \(score)"
        scoreLabel.removeAllActions()
        scoreLabel.runAction(scoreFlashAction)
    }
    
    func showSplashScreen() {
        gameState = .GameRunning
        
    }
    
    func restartGame() {
        // Reset the state of the game
        gameState = .GameRunning
        
        reportMemory()
        
        // Setup the entities and reset the score
        setupEntities()
        score = 0
        wave = 0
        bonusTimeRemaining = 0
        lastBonusTimeRemaining = 0
        bonusStartTime = 0
        scoreLabel.text = "Score: 0"
        
        // Reset the players health and position
        playerShip.health = playerShip.maxHealth
        playerShip.position = CGPointMake(size.width / 2, 100)
        
        // Remove the game over HUD labels
        countdownLabel.removeFromParent()
        gameOverLabel.removeFromParent()
        tapScreenLabel.removeAllActions()
        tapScreenLabel.removeFromParent()
        levelLabel.removeFromParent()
    }
 
    func continueGame() {
        // Reset the state of the game
        gameState = .GameRunning
        
        bonusTimeRemaining = 0
        lastBonusTimeRemaining = 0
        bonusStartTime = 0
        
        // Setup the entities and reset the score
        setupEnemies()
        
        // Reset the players health and position
        playerShip.position = CGPointMake(size.width / 2, 100)
        
        // Remove the game over HUD labels
        countdownLabel.removeFromParent()
        gameOverLabel.removeFromParent()
        tapScreenLabel.removeAllActions()
        tapScreenLabel.removeFromParent()
        levelLabel.removeFromParent()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if gameState == .GameOver {
            restartGame()
        }
        if gameState == .WaveComplete {
            continueGame()
        }
        if gameState == .SplashScreen {
            restartGame()
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = (touches as NSSet).anyObject() as! UITouch
        let currentPoint = touch.locationInNode(self)
        previousTouchLocation = touch.previousLocationInNode(self)
        deltaPoint = currentPoint - previousTouchLocation
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        deltaPoint = CGPointZero
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        deltaPoint = CGPointZero
    }
    
    override func update(currentTime: NSTimeInterval) {
        var newPoint:CGPoint = playerShip.position + deltaPoint
        
        // If we are in bonus mode, and we don't have a bonusStartTime, get the current time
        if bonusMode && bonusStartTime == 0 {
            bonusStartTime = currentTime
            lastBonusTimeRemaining = bonusTime
        }
        if bonusStartTime > 0 {
            bonusTimeRemaining = bonusTime - Int(currentTime - bonusStartTime)
            if bonusTimeRemaining < 0 {
                bonusTimeRemaining = 0
            }
            // Add the health regeneration for the number of seconds that we
            // stayed alive since the last check
            let healthPerTick: Double = ((playerShip.maxHealth*bonusTimeMaxRegenerationPercent)/Double(bonusTime))
            // Calcuate the amount of health to regenerate
            playerShip.health += Double(lastBonusTimeRemaining - bonusTimeRemaining)*healthPerTick
            
            if (playerShip.health > playerShip.maxHealth) {
                playerShip.health = playerShip.maxHealth
            }
            lastBonusTimeRemaining = bonusTimeRemaining
        }
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        switch gameState {
        case (.SplashScreen):
            break
        case (.GameRunning):
            // Move the player's ship
            newPoint.x.clamp(CGRectGetMinX(playableRect), CGRectGetMaxX(playableRect))
            newPoint.y.clamp(CGRectGetMinY(playableRect),CGRectGetMaxY(playableRect))
            
            if (bonusMode && endBonusMode) {
                endBonusMode = false
                bonusTimeRemaining = 0
            }
            
            if (bonusMode) {
                if (countdownLabel.parent == nil) {
                    hudLayerNode.addChild(countdownLabel)
                }
                countdownLabel.text = "\(bonusTimeRemaining)"
                countdownLabel.fontSize = bonusTimeRemaining > 10 ? CGFloat(36) : CGFloat(144)
                countdownLabel.fontColor = SKColor(red: CGFloat(drand48()),
                                                  green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
                if (bonusTimeRemaining == 0) {
                    gameState = .WaveComplete
                    // Remove enemies from wave
                    for node in enemyLayerNode.children {
                        node.removeFromParent()
                    }
                }
            }
            
            playerShip.position = newPoint
            deltaPoint = CGPointZero
            
            // Fire the bullets
            fireBullets()
            
            // Loop through all enemy nodes and run their update method.
            // This causes them to update their position based on their currentWaypoint and position
            var nodeCounter = 0
            for node in enemyLayerNode.children {
                nodeCounter += 1
                let enemy = node as! Enemy
                enemy.update(self.dt)
            }
            // If all of the enemies are gone, wave is complete
            if (nodeCounter == 0) {
                gameState = .WaveComplete
                wave += 1
            }
            
            // Update the players health label to be the right length based on the players health and also
            // update the color so that the closer to 0 it gets the more red it becomes
            playerHealthLabel.fontColor = SKColor(red: CGFloat(2.0 * (1 - playerShip.health / 100)),
                green: CGFloat(2.0 * playerShip.health / 100),
                blue: 0,
                alpha: 1)
            
            // Calculate the length of the players health bar.
            let healthBarLength = Double(healthBarString.length) * playerShip.health / 100.0
            playerHealthLabel.text = healthBarString.substringToIndex(Int(healthBarLength))
            
            // If the player health reaches 0 then change the game state.
            if playerShip.health <= 0 {
                gameState = .GameOver
            }
        case (.WaveComplete):
            // Reset the players health and position
            playerShip.position = CGPointMake(size.width / 2, 100)
            bonusMode = false
            // If we don't have a levelLabel, then we just changed to this games status
            if (levelLabel.parent == nil) {
                bulletLayerNode.removeAllChildren()
                enemyLayerNode.removeAllChildren()
                levelLabel.removeFromParent()
                tapScreenLabel.removeFromParent()
                countdownLabel.removeFromParent()
                
                //print("<Node Debug>")
                //displayNodes(playerLayerNode, nodename: "Player Ship Layer")
                //displayNodes(enemyLayerNode, nodename: "Enemy Layer")
                //displayNodes(hudLayerNode, nodename: "HUD Layer")
                //displayNodes(bulletLayerNode, nodename: "Bullet Layer")
                
                levelLabel.text = "WAVE \(wave+1)"
                if ((wave+1)%5 == 0) {
                    levelLabel.text = "WAVE \(wave+1): BONUS WAVE"
                }
                levelLabel.removeAllActions()
                hudLayerNode.addChild(tapScreenLabel)
                hudLayerNode.addChild(levelLabel)
                tapScreenLabel.runAction(screenPulseAction)
                levelLabel.runAction(screenPulseAction)
            }
            
        case (.GameOver):
            
            // When the game is over remove all the entities from the scene and add the game over labels
            if (gameOverLabel.parent == nil) {
                bulletLayerNode.removeAllChildren()
                enemyLayerNode.removeAllChildren()
                playerShip.removeFromParent()
                countdownLabel.removeFromParent()
                hudLayerNode.addChild(gameOverLabel)
                hudLayerNode.addChild(tapScreenLabel)
                tapScreenLabel.runAction(screenPulseAction)
            }
            
            // Set a random color for the game over label
            gameOverLabel.fontColor = SKColor(red: CGFloat(drand48()),
                green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
            
        default:
            print("UNKNOWN GAME STATE")
        }
        
    }
    
    func fireBullets() {
        // Current method of firing bullets are based upon the level
        bulletInterval += dt
        if bulletInterval > bulletFireRateInterval {
            bulletInterval = 0

            // Single or double barrel
            if (wave+1 < 10) {
                bulletSingleForward()
            } else if (wave + 1 < 20) {
                bulletDoubleForward()
            } else if (wave + 1 < 30) {
                bulletDoubleForward()
                bulletSingleBackward()
            } else if (wave + 1 < 40) {
                bulletSingleForward()
                bulletDoubleForward()
                bulletSingleBackward()
            } else {
                bulletSingleForward()
                bulletDoubleForward()
                bulletDoubleBackward()
            }
            
            playLaserSound()
        }
    }
    
    func bulletSingleForward() {
        // Single bullet
        let bullet = Bullet(entityPosition: playerShip.position)
        bulletLayerNode.addChild(bullet)
        bullet.runAction(SKAction.sequence([
            SKAction.moveByX(1, y: size.height+20, duration: 1),
            SKAction.removeFromParent()
            ]))
    }
    
    func bulletDoubleForward() {
        // Double bullet
        let bullet1 = Bullet(entityPosition: CGPoint(x: playerShip.position.x-20, y: playerShip.position.y))
        let bullet2 = Bullet(entityPosition: CGPoint(x: playerShip.position.x+20, y: playerShip.position.y))
        bulletLayerNode.addChild(bullet1)
        bulletLayerNode.addChild(bullet2)
        bullet1.runAction(SKAction.sequence([
            SKAction.moveByX(1, y: size.height, duration: 1),
            SKAction.removeFromParent()
            ]))
        bullet2.runAction(SKAction.sequence([
            SKAction.moveByX(1, y: size.height, duration: 1),
            SKAction.removeFromParent()
            ]))
    }
    
    func bulletSingleBackward() {
        // Single bullet
        let bullet = Bullet(entityPosition: playerShip.position)
        bulletLayerNode.addChild(bullet)
        bullet.runAction(SKAction.sequence([
            SKAction.moveByX(-1, y: -size.height, duration: 1),
            SKAction.removeFromParent()
            ]))

    }
    
    func bulletDoubleBackward() {
        // Double bullet
        let bullet1 = Bullet(entityPosition: CGPoint(x: playerShip.position.x-10, y: playerShip.position.y))
        let bullet2 = Bullet(entityPosition: CGPoint(x: playerShip.position.x+10, y: playerShip.position.y))
        bulletLayerNode.addChild(bullet1)
        bulletLayerNode.addChild(bullet2)
        bullet1.runAction(SKAction.sequence([
            SKAction.moveByX(-1, y: -size.height, duration: 1),
            SKAction.removeFromParent()
            ]))
        bullet2.runAction(SKAction.sequence([
            SKAction.moveByX(-1, y: -size.height, duration: 1),
            SKAction.removeFromParent()
            ]))
    }
    
    func displayNodes(node : SKNode, nodename : String?) {
    
        print((nodename != nil) ? nodename : node.name)
    
        var nodeCounter = 0
        for subnode in node.children {
            nodeCounter += 1
            print("Node: \((subnode.name != nil) ? subnode.name! : "Nil")")
            for node1 in subnode.children {
                print("  [\((node1.name != nil) ? node1.name : "Nil")]")
            }
        }
    }
    
    // This method is called by the physics engine when two physics body collide
    func didBeginContact(contact: SKPhysicsContact) {
        
        var enemyDamage = 5
        
        // Check to see if Body A is an enamy ship and if so call collided with
        if let enemyNode = contact.bodyA.node {
            if enemyNode.name == "enemy" {
                let enemy = enemyNode as! Entity
                enemyDamage = enemy.attackDamage
                enemy.collidedWith(contact.bodyA, contact: contact, damage: damageFromPlayerHit)
            }
        }
        
        // ...and now check to see if Body B is the player ship/bullet
        if let playerNode = contact.bodyB.node {
            if playerNode.name == "playerShip" || playerNode.name == "bullet" {
                let player = playerNode as! Entity
                player.collidedWith(contact.bodyA, contact: contact, damage: enemyDamage)
                if (playerNode.name == "playerShip") {
                    // Flash the screen when we take damage
                    flashScreenBasedOnDamage(enemyDamage)
                    
                    if (bonusMode) {
                        endBonusMode = true
                    }
                }
            }
        }
    }
    
    // Flash the screen red based upon the damage taken
    func flashScreenBasedOnDamage(damage: Int) {
        var duration: NSTimeInterval = 0.25
        if damage <= 1 {
            duration = 0.05
        } else if damage <= 2 {
            duration = 0.1
        } else if damage <= 3 {
            duration = 0.15
        } else if damage <= 4 {
            duration = 0.2
        }
        
        // Flash the screen red
        self.runAction(SKAction.sequence([
            SKAction.colorizeWithColor(SKColor.redColor(), colorBlendFactor: 1.0,
                duration: duration),
            SKAction.colorizeWithColor(screenBackgroundColor, colorBlendFactor: 1.0,
                duration: duration)
            ]))
    }
    
    func starfieldEmitterNode(speed speed: CGFloat, lifetime: CGFloat, scale: CGFloat, birthRate: CGFloat, color: SKColor) -> SKEmitterNode {
        let star = SKLabelNode(fontNamed: "Helvetica")
        star.fontSize = 80.0
        star.text = "✦"
        let textureView = SKView()
        let texture = textureView.textureFromNode(star)
        texture!.filteringMode = .Nearest
        
        let emitterNode = SKEmitterNode()
        emitterNode.particleTexture = texture
        emitterNode.particleBirthRate = birthRate
        emitterNode.particleColor = color
        emitterNode.particleLifetime = lifetime
        emitterNode.particleSpeed = speed
        emitterNode.particleScale = scale
        emitterNode.particleColorBlendFactor = 1
        emitterNode.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMaxY(frame))
        emitterNode.particlePositionRange = CGVector(dx: CGRectGetMaxX(frame), dy: 0)
        
        emitterNode.particleAction = SKAction.repeatActionForever(SKAction.sequence([
            SKAction.rotateByAngle(CGFloat(-M_PI_4), duration: 1),
            SKAction.rotateByAngle(CGFloat(M_PI_4), duration: 1)
        ]))
        emitterNode.particleSpeedRange = 16.0

        let twinkles = 20
        let colorSequence = SKKeyframeSequence(capacity: twinkles * 2)
        let twinkleTime = 1.0 / CGFloat(twinkles)
        for i in 0..<twinkles {
            colorSequence.addKeyframeValue(SKColor.whiteColor(), time: CGFloat(i) * 2 * twinkleTime / 2)
            switch i%4 {
            case 0:
                colorSequence.addKeyframeValue(SKColor.yellowColor(), time: (CGFloat(i) * 2 + 1) * twinkleTime / 2)
            case 1:
                colorSequence.addKeyframeValue(SKColor.blueColor(), time: (CGFloat(i) * 2 + 1) * twinkleTime / 2)
            case 2:
                colorSequence.addKeyframeValue(SKColor.orangeColor(), time: (CGFloat(i) * 2 + 1) * twinkleTime / 2)
            default:
                colorSequence.addKeyframeValue(SKColor.redColor(), time: (CGFloat(i) * 2 + 1) * twinkleTime / 2)
                
            }
        }
        emitterNode.particleColorSequence = colorSequence
        emitterNode.advanceSimulationTime(NSTimeInterval(lifetime))
        
        return emitterNode
    }
    
    func playExplodeSound() {
        runAction(explodeSound)
    }
    
    func playLaserSound() {
        runAction(laserSound)
    }
    
    func reportMemory() {
        // constant
        let MACH_TASK_BASIC_INFO_COUNT = (sizeof(mach_task_basic_info_data_t) / sizeof(natural_t))
        
        // prepare parameters
        let name   = mach_task_self_
        let flavor = task_flavor_t(MACH_TASK_BASIC_INFO)
        var size   = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)
        
        // allocate pointer to mach_task_basic_info
        let infoPointer = UnsafeMutablePointer<mach_task_basic_info>.alloc(1)
        
        // call task_info - note extra UnsafeMutablePointer(...) call
        let kerr = task_info(name, flavor, UnsafeMutablePointer(infoPointer), &size)
        
        // get mach_task_basic_info struct out of pointer
        let info = infoPointer.move()
        
        // deallocate pointer
        infoPointer.dealloc(1)
        
        // check return value for success / failure
        if kerr == KERN_SUCCESS {
            print("Memory in use (in MB): \(info.resident_size/1000000)")
        } else {
            let errorString = String(CString: mach_error_string(kerr), encoding: NSASCIIStringEncoding)
            print(errorString ?? "Error: couldn't parse error string")
        }    
    }

    
}