//
//  LevelScene.swift
//  Kill All Mosquito
//
//  Created by Banghua Zhao on 1/29/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import Localize_Swift
import SpriteKit
import Then

enum GameState {
    case play, pause
}

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Cell: UInt32 = 0b1
    static let Virus: UInt32 = 0b10
    static let Mask: UInt32 = 0b100
    static let Pill: UInt32 = 0b1000
}

class LevelScene: SKScene {
    var gameState: GameState = .play
    var isResume = false

    var gameLayerNode = SKNode()

    // music
    let sprinkleSound: SKAction = SKAction.playSoundFileNamed(
        "sprinkle.mp3", waitForCompletion: true)
    let warningSound: SKAction = SKAction.playSoundFileNamed(
        "warning.mp3", waitForCompletion: false)
    let killVirusSound: SKAction = SKAction.playSoundFileNamed(
        "kill-virus.mp3", waitForCompletion: false)
    let tapSound = SKAction.playSoundFileNamed("tap.mp3", waitForCompletion: true)

    // particle
    let dummyNode = SKSpriteNode()

    var gameEnded = false

    var rightLimit: CGFloat!
    var leftLimit: CGFloat!

    // TouchPoints
    var activeSlicePoints = [CGPoint]()

    // level labels

    var maxLevel = 8

    var level: Int = 1 {
        didSet {
            levelLabel.text = "\("Level".localized()): \(level) / \(maxLevel)"
        }
    }

    lazy var levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
        node.text = "\("Level".localized()): \(level) / \(maxLevel)"
        node.fontColor = SKColor.black
        node.fontSize = 54
        node.zPosition = 100
        node.horizontalAlignmentMode = .left
        node.verticalAlignmentMode = .top
    }

    // Time Label

    var lastUpdateTime: TimeInterval = 0.0
    var dt: TimeInterval = 0.0

    var maxTime: TimeInterval = 60.0

    var timeRemind: TimeInterval = 60.0 {
        didSet {
            timeLabel.text = "\("Time".localized()): \(String(format: "%.1f", timeRemind)) / \(maxTime)"
        }
    }

    lazy var timeLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
        node.text = "\("Time".localized()): \(String(format: "%.1f", timeRemind)) / \(maxTime)"
        node.fontColor = SKColor.black
        node.fontSize = 54
        node.zPosition = 100
        node.horizontalAlignmentMode = .right
        node.verticalAlignmentMode = .top
    }

    // Live label

    var maxLive = 20

    var livesRemaining = 20 {
        didSet {
            livesLabel.text = "\("Lives".localized()): \(livesRemaining) / \(maxLive)"
        }
    }

    lazy var livesLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
        node.text = "\("Lives".localized()): \(maxLive) / \(maxLive)"
        node.fontColor = SKColor.black
        node.fontSize = 54
        node.zPosition = 100
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .center
    }

    // wave

    var createWave1 = true
    var createWave2 = true
    var createMoreWave1 = true
    var createMoreWave2 = true
    var createMoreWave3 = true

    // MARK: - didMove

    override func didMove(to view: SKView) {
        addObservers()
        #if !targetEnvironment(macCatalyst)
            bannerView.isHidden = true
        #endif
        gameState = .play
        playBackgroundMusic(filename: "BGM.mp3", repeatForever: true)
        createWorld()
        createLabels()
        createCell()
        spawnVirus()

        if level >= 2 {
            spawnMask()
        }

        if level >= 5 {
            spawnPill()
        }
    }

    // MARK: - update

    override func update(_ currentTime: TimeInterval) {
        if gameState == .pause {
            if !gameLayerNode.isPaused {
                gameState = .pause
                gameLayerNode.isPaused = true
                physicsWorld.speed = 0

                print("pauseButton Tapped")
                let pauseGame = SKSpriteNode(imageNamed: "pause-menu")
                pauseGame.zPosition = 200
                pauseGame.position = CGPoint(x: 0, y: 0)
                pauseGame.name = "pauseMenu"
                addChild(pauseGame)

                let resumeButton = SKSpriteNode(imageNamed: "resume-button")
                resumeButton.zPosition = 201
                resumeButton.position = CGPoint(x: 0, y: -440)
                resumeButton.name = "resumeButton"
                pauseGame.addChild(resumeButton)

                let backButton = SKSpriteNode(imageNamed: "main-menu-button")
                backButton.zPosition = 202
                backButton.position = CGPoint(x: 0, y: -550)
                backButton.name = "backButton"
                pauseGame.addChild(backButton)
            }
            return
        }

        if isResume {
            lastUpdateTime = currentTime
            isResume = false
        }

        // Called before each frame is rendered
        dt = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        timeRemind -= dt
        lastUpdateTime = currentTime

        if timeRemind <= 0.0 {
            gameWin()
        }

        if timeRemind <= 41.0 && createWave1 {
            createWave1 = false
            spawnWave1()
        }

        if timeRemind <= 11.0 && createWave2 {
            createWave2 = false
            spawnWave2()
        }

        if level == 7 {
            if timeRemind <= 51.0 && createMoreWave1 {
                createMoreWave1 = false
                spawnWave2()
            }

            if timeRemind <= 31.0 && createMoreWave2 {
                createMoreWave2 = false
                spawnWave2()
            }

            if timeRemind <= 21.0 && createMoreWave3 {
                createMoreWave3 = false
                spawnWave1()
            }
        }
    }
}

// MARK: - touch related

extension LevelScene {
    // MARK: - touchesBegan

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSlicePoints.removeAll(keepingCapacity: true)

        guard let vTouch = touches.first else { return }
        let touchLocation = vTouch.location(in: self)
        activeSlicePoints.append(touchLocation)

        let sprinkleParticle = SKEmitterNode(fileNamed: "sprinkle.sks")!
        sprinkleParticle.name = "sprinkle"
        dummyNode.position = touchLocation
        dummyNode.addChild(sprinkleParticle)
        sprinkleParticle.targetNode = self

        let nodesAtPoint = nodes(at: touchLocation)

        for node in nodesAtPoint {
            if node.name == "pauseButton" {
                if !gameLayerNode.isPaused {
                    gameState = .pause
                    gameLayerNode.isPaused = true
                    physicsWorld.speed = 0
                    run(tapSound)
                    print("pauseButton Tapped")
                    let pauseGame = SKSpriteNode(imageNamed: "pause-menu")
                    pauseGame.zPosition = 200
                    pauseGame.position = CGPoint(x: 0, y: 0)
                    pauseGame.name = "pauseMenu"
                    addChild(pauseGame)

                    let resumeButton = SKSpriteNode(imageNamed: "resume-button")
                    resumeButton.zPosition = 201
                    resumeButton.position = CGPoint(x: 0, y: -440)
                    resumeButton.name = "resumeButton"
                    pauseGame.addChild(resumeButton)

                    let backButton = SKSpriteNode(imageNamed: "main-menu-button")
                    backButton.zPosition = 202
                    backButton.position = CGPoint(x: 0, y: -550)
                    backButton.name = "backButton"
                    pauseGame.addChild(backButton)
                    #if !targetEnvironment(macCatalyst)
                        bannerView.isHidden = false
                    #endif
                }
            } else if node.name == "resumeButton" {
                isResume = true
                run(tapSound)
                enumerateChildNodes(withName: "pauseMenu") { node, _ in
                    node.removeFromParent()
                }
                gameState = .play
                gameLayerNode.isPaused = false
                physicsWorld.speed = 1
                #if !targetEnvironment(macCatalyst)
                    bannerView.isHidden = true
                #endif

            } else if node.name == "backButton" {
                isResume = true
                backgroundMusicPlayer.stop()
                run(tapSound)
                if let scene = SKScene(fileNamed: "MainMenuScene") {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    // Present the scene
                    view?.presentScene(scene)
                }
            }
        }
    }

    // MARK: - touchesMoved

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameEnded else { return }

        guard let vTouch = touches.first else { return }
        let touchLocation = vTouch.location(in: self)
        activeSlicePoints.append(touchLocation)

        dummyNode.position = touchLocation

        let nodesAtPoint = nodes(at: touchLocation)

        for node in nodesAtPoint {
            if node.name == "virus" {
                // Particles
                let emitter = SKEmitterNode(fileNamed: "sliceHitEnemy")!
                emitter.position = node.position
                gameLayerNode.addChild(emitter)

                // Prevent multiple swipes
                node.name = ""

                // Death Animation
                let scaleOutAction = SKAction.scale(by: 0.001, duration: 0.2)
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.2)
                let deathAction = SKAction.sequence([
                    SKAction.group([scaleOutAction, fadeOutAction]),
                    SKAction.removeFromParent(),
                ])
                node.run(deathAction)
                run(killVirusSound)
            } else if node.name == "mask" {
                // Prevent multiple swipes
                node.name = ""

                // Death Animation
                let scaleOutAction = SKAction.scale(by: 0.001, duration: 0.6)
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.6)
                let rotateAction = SKAction.rotate(byAngle: CGFloat(2 * Double.pi), duration: 0.6)
                let action = SKAction.sequence([
                    SKAction.group([scaleOutAction, fadeOutAction, rotateAction]),
                    SKAction.removeFromParent(),
                ])
                node.run(action)

                gameLayerNode.enumerateChildNodes(withName: "virus") { node, _ in
                    // Particles
                    let emitter = SKEmitterNode(fileNamed: "sliceHitEnemy")!
                    emitter.position = node.position
                    self.gameLayerNode.addChild(emitter)

                    // Prevent multiple swipes
                    node.name = ""

                    // Death Animation
                    let scaleOutAction = SKAction.scale(by: 0.001, duration: 0.2)
                    let fadeOutAction = SKAction.fadeOut(withDuration: 0.2)
                    let deathAction = SKAction.sequence([
                        SKAction.group([scaleOutAction, fadeOutAction]),
                        SKAction.removeFromParent(),
                    ])
                    node.run(deathAction)
                    self.run(self.killVirusSound)
                }
            } else if node.name == "pill" {
                // Prevent multiple swipes
                node.name = ""

                // Death Animation
                let scaleOutAction = SKAction.scale(by: 0.001, duration: 0.6)
                let fadeOutAction = SKAction.fadeOut(withDuration: 0.6)
                let rotateAction = SKAction.rotate(byAngle: CGFloat(2 * Double.pi), duration: 0.6)
                let action = SKAction.sequence([
                    SKAction.group([scaleOutAction, fadeOutAction, rotateAction]),
                    SKAction.removeFromParent(),
                ])
                node.run(action)
            }
        }
    }

    // MARK: - touchesEnded

    override func touchesEnded(_ touches: Set<UITouch>?, with event: UIEvent?) {
        dummyNode.enumerateChildNodes(withName: "sprinkle") { node, _ in
            node.run(SKAction.sequence(
                [SKAction.wait(forDuration: 1.0),
                 SKAction.removeFromParent()])
            )
        }
    }

    // MARK: - touchesCancelled

    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        guard let vTouches = touches else { return }
        touchesEnded(vTouches, with: event)
    }
}

// MARK: - helper

extension LevelScene {
    func sceneCropAmount() -> CGFloat {
        guard let view = view else { return 0 }
        let scale = view.bounds.size.height / size.height
        let scaledWidth = size.width * scale
        let scaledOverlap = scaledWidth - view.bounds.size.width
        return scaledOverlap / scale
    }

    // MARK: - createWorld

    func createWorld() {
        addChild(gameLayerNode)
        rightLimit = size.width / 2 - sceneCropAmount() / 2
        leftLimit = -rightLimit
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: leftLimit, y: -frame.height / 2, width: rightLimit * 2, height: frame.height))
        physicsWorld.gravity = CGVector(dx: 0, dy: -1.0)
        physicsWorld.contactDelegate = self
        gameLayerNode.addChild(dummyNode)

        let pauseButton = SKSpriteNode(imageNamed: "pause-button")
        pauseButton.zPosition = 2
        if Constants.isIphoneFaceID {
            pauseButton.position = CGPoint(
                x: 0,
                y: -frame.height / 2 + CGFloat(90 + 100))
        } else {
            pauseButton.position = CGPoint(
                x: 0,
                y: -frame.height / 2 + CGFloat(70 + 100))
        }
        pauseButton.name = "pauseButton"
        addChild(pauseButton)
    }

    // MARK: - createLabels

    func createLabels() {
        #if !targetEnvironment(macCatalyst)
            if Constants.isIphoneFaceID {
                levelLabel.position = CGPoint(
                    x: leftLimit + CGFloat(30),
                    y: frame.height / 2 - Constants.topSafeAreaHeight - 60)
            } else {
                levelLabel.position = CGPoint(
                    x: leftLimit + CGFloat(30),
                    y: frame.height / 2 - CGFloat(40))
            }

            if Constants.isIphoneFaceID {
                timeLabel.position = CGPoint(
                    x: rightLimit - CGFloat(30),
                    y: frame.height / 2 - Constants.topSafeAreaHeight - 60)
            } else {
                timeLabel.position = CGPoint(
                    x: rightLimit - CGFloat(30),
                    y: frame.height / 2 - CGFloat(40))
            }

            if Constants.isIphoneFaceID {
                livesLabel.position = CGPoint(
                    x: 0,
                    y: -frame.height / 2 + CGFloat(90))
            } else {
                livesLabel.position = CGPoint(
                    x: 0,
                    y: -frame.height / 2 + CGFloat(70))
            }
        #else
            levelLabel.position = CGPoint(
                x: leftLimit + CGFloat(30),
                y: frame.height / 2 - CGFloat(110))
            timeLabel.position = CGPoint(
                x: rightLimit - CGFloat(30),
                y: frame.height / 2 - CGFloat(110))
            livesLabel.position = CGPoint(
                x: 0,
                y: -frame.height / 2 + CGFloat(90))
        #endif

        addChild(levelLabel)
        addChild(timeLabel)
        addChild(livesLabel)
    }

    // MARK: - createCell

    func createCell() {
        let cell = scene!.childNode(withName: "cell")
        cell?.physicsBody?.categoryBitMask = PhysicsCategory.Cell
        cell?.physicsBody?.contactTestBitMask = PhysicsCategory.Virus
        let scaleUpGrounp = SKAction.group(
            [SKAction.scale(by: 1.02, duration: 1.0),
             SKAction.fadeAlpha(to: 0.9, duration: 1.0)]
        )

        let scaleDownGrounp = SKAction.group(
            [SKAction.scale(by: 0.98, duration: 1.0),
             SKAction.fadeAlpha(to: 1.0, duration: 1.0)]
        )

        cell?.run(SKAction.repeatForever(
            SKAction.sequence([
                scaleUpGrounp,
                scaleDownGrounp,
            ])))
    }

    // MARK: - spawnVirus

    func spawnVirus() {
        var waitDuration: TimeInterval
        switch level {
        case 1:
            waitDuration = 0.5
        case 2:
            waitDuration = 0.2
        case 3, 4, 5, 6, 7:
            waitDuration = 0.4
        case 8:
            waitDuration = 0.15
        default:
            waitDuration = 0.5
        }
        delay(seconds: 1.0) {
            self.gameLayerNode.run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run(self.createTopVirus),
                        SKAction.wait(forDuration: waitDuration),
                    ]))
            )
        }
    }

    // MARK: - spawnWave1

    func spawnWave1() {
        let waveWarning = SKSpriteNode(imageNamed: "wave1-warning")
        waveWarning.position = CGPoint(x: 0, y: 100)
        waveWarning.zPosition = 2
        addChild(waveWarning)

        waveWarning.setScale(0.6)
        waveWarning.run(SKAction.sequence(
            [SKAction.group([SKAction.scale(to: 1.0, duration: 0.3), warningSound]),
             SKAction.scale(to: 0.8, duration: 0.3),
             SKAction.group([SKAction.scale(to: 1.0, duration: 0.3), warningSound]),
             SKAction.wait(forDuration: 1.1),
             SKAction.removeFromParent(),
            ]))

        delay(seconds: 2.0) {
            self.gameLayerNode.run(
                SKAction.repeat(
                    SKAction.group([
                        SKAction.run(self.createLeftVirus),
                        SKAction.run(self.createRightVirus),
                    ]),
                    count: 12)
            )
        }
    }

    // MARK: - spawnWave2

    func spawnWave2() {
        let waveWarning = SKSpriteNode(imageNamed: "wave2-warning")
        waveWarning.position = CGPoint(x: 0, y: 100)
        waveWarning.zPosition = 2
        addChild(waveWarning)

        waveWarning.setScale(0.6)
        waveWarning.run(SKAction.sequence(
            [SKAction.group([SKAction.scale(to: 1.0, duration: 0.3), warningSound]),
             SKAction.scale(to: 0.8, duration: 0.3),
             SKAction.group([SKAction.scale(to: 1.0, duration: 0.3), warningSound]),
             SKAction.wait(forDuration: 1.1),
             SKAction.removeFromParent(),
            ]))

        delay(seconds: 2.0) {
            self.gameLayerNode.run(
                SKAction.repeat(
                    SKAction.group([
                        SKAction.run(self.createLeftVirus),
                        SKAction.run(self.createRightVirus),
                    ]),
                    count: 16)
            )
        }
    }

    // MARK: - spawn mask

    func spawnMask() {
        var waitDuration: TimeInterval
        switch level {
        case 1:
            waitDuration = 60
        case 2:
            waitDuration = 5
        case 3, 4, 5, 6:
            waitDuration = 19
        default:
            waitDuration = 19
        }

        delay(seconds: 2.0) {
            self.gameLayerNode.run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run(self.createTopMask),
                        SKAction.wait(forDuration: waitDuration),
                    ]))
            )
        }

        let possibility = 0.3
        if possibility >= Double(random(min: 0.0, max: 1.0)) && level >= 3 {
            delay(seconds: 15) {
                if 0.5 >= Double(random(min: 0.0, max: 1.0)) {
                    self.gameLayerNode.run(SKAction.run(self.createLeftMask))
                } else {
                    self.gameLayerNode.run(SKAction.run(self.createRightMask))
                }
            }
        }

        if possibility >= Double(random(min: 0.0, max: 1.0)) && level >= 3 {
            delay(seconds: 45) {
                if 0.5 >= Double(random(min: 0.0, max: 1.0)) {
                    self.gameLayerNode.run(SKAction.run(self.createLeftMask))
                } else {
                    self.gameLayerNode.run(SKAction.run(self.createRightMask))
                }
            }
        }
    }

    func spawnPill() {
        var waitDuration: TimeInterval
        switch level {
        case 1, 2, 3, 4:
            waitDuration = 60
        case 5, 6:
            waitDuration = 5
        default:
            waitDuration = 5
        }

        delay(seconds: 3.0) {
            self.gameLayerNode.run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run(self.createTopPill),
                        SKAction.wait(forDuration: waitDuration),
                    ]))
            )
        }
    }
}

// MARK: - create virus related

extension LevelScene {
    // MARK: - virus related

    func createTopVirus() {
        let virus = SKSpriteNode(imageNamed: "virus")

        virus.position = CGPoint(
            x: random(min: leftLimit + virus.size.width, max: rightLimit - virus.size.width),
            y: size.height / 2 - virus.size.height)

        virus.zPosition = 2
        virus.physicsBody?.categoryBitMask = PhysicsCategory.Virus
        virus.physicsBody?.contactTestBitMask = PhysicsCategory.Cell

        virus.physicsBody = SKPhysicsBody(circleOfRadius:
            virus.size.width / 2)

        virus.name = "virus"
        gameLayerNode.addChild(virus)

        virus.physicsBody?.applyImpulse(
            CGVector(dx: random(min: -50, max: 50),
                     dy: random(min: -100, max: 10))
        )

        if level >= 3 {
            virus.setScale(random(min: 0.6, max: 1.2))
        }

        if CGFloat(Float(arc4random()) / Float(UINT32_MAX)) > 0.5 {
            virus.xScale = virus.xScale * -1
        }

        if level >= 4 {
            virus.physicsBody?.velocity.dx = random(min: 1.0, max: 2.0) * virus.physicsBody!.velocity.dx
            virus.physicsBody?.velocity.dy = random(min: 1.0, max: 4.0) * virus.physicsBody!.velocity.dy
        }

        if level >= 6 {
            let possibility = 0.3
            if possibility >= Double(random(min: 0.0, max: 1.0)) {
                virus.run(
                    SKAction.repeatForever(
                        SKAction.sequence(
                            [SKAction.fadeAlpha(to: CGFloat(random(min: 0.0, max: 0.5)), duration: 1.0),
                             SKAction.fadeAlpha(to: 1.0, duration: 0.5)])
                    )
                )
            }
        }
    }

    func createLeftVirus() {
        let virus = SKSpriteNode(imageNamed: "virus")

        virus.position = CGPoint(
            x: leftLimit + virus.size.width,
            y: random(min: 0, max: size.height / 2 - virus.size.height)
        )

        virus.zPosition = 2
        virus.physicsBody?.categoryBitMask = PhysicsCategory.Virus
        virus.physicsBody?.contactTestBitMask = PhysicsCategory.Cell

        virus.physicsBody = SKPhysicsBody(circleOfRadius:
            virus.size.width / 2)

        virus.name = "virus"
        gameLayerNode.addChild(virus)

        virus.physicsBody?.applyImpulse(
            CGVector(dx: random(min: 40, max: 120),
                     dy: random(min: -100, max: 100))
        )

        if level >= 3 {
            virus.setScale(random(min: 0.6, max: 1.2))
        }

        if level >= 4 {
            virus.physicsBody?.velocity.dx = random(min: 1.0, max: 2.0) * virus.physicsBody!.velocity.dx
            virus.physicsBody?.velocity.dy = random(min: 1.0, max: 4.0) * virus.physicsBody!.velocity.dy
        }

        if level >= 6 {
            let possibility = 0.3
            if possibility >= Double(random(min: 0.0, max: 1.0)) {
                virus.run(
                    SKAction.repeatForever(
                        SKAction.sequence(
                            [SKAction.fadeAlpha(to: CGFloat(random(min: 0.0, max: 0.5)), duration: 1.0),
                             SKAction.fadeAlpha(to: 1.0, duration: 0.5)])
                    )
                )
            }
        }
    }

    func createRightVirus() {
        let virus = SKSpriteNode(imageNamed: "virus")

        virus.position = CGPoint(
            x: rightLimit - virus.size.width,
            y: random(min: 0, max: size.height / 2 - virus.size.height)
        )

        virus.zPosition = 2
        virus.physicsBody?.categoryBitMask = PhysicsCategory.Virus
        virus.physicsBody?.contactTestBitMask = PhysicsCategory.Cell

        virus.physicsBody = SKPhysicsBody(circleOfRadius:
            virus.size.width / 2)

        virus.name = "virus"
        gameLayerNode.addChild(virus)

        virus.physicsBody?.applyImpulse(
            CGVector(dx: random(min: -40, max: -120),
                     dy: random(min: -100, max: 100))
        )

        if level >= 3 {
            virus.setScale(random(min: 0.6, max: 1.2))
        }

        virus.xScale = virus.xScale * -1

        if level >= 4 {
            virus.physicsBody?.velocity.dx = random(min: 1.0, max: 2.0) * virus.physicsBody!.velocity.dx
            virus.physicsBody?.velocity.dy = random(min: 1.0, max: 4.0) * virus.physicsBody!.velocity.dy
        }

        if level >= 6 {
            let possibility = 0.3
            if possibility >= Double(random(min: 0.0, max: 1.0)) {
                virus.run(
                    SKAction.repeatForever(
                        SKAction.sequence(
                            [SKAction.fadeAlpha(to: CGFloat(random(min: 0.0, max: 0.5)), duration: 1.0),
                             SKAction.fadeAlpha(to: 1.0, duration: 0.5)])
                    )
                )
            }
        }
    }

    // MARK: - mask related

    func createTopMask() {
        let mask = SKSpriteNode(imageNamed: "mask")

        mask.position = CGPoint(
            x: random(min: leftLimit + mask.size.width, max: rightLimit - mask.size.width),
            y: size.height / 2 - mask.size.height)

        mask.zPosition = 2
        mask.physicsBody?.categoryBitMask = PhysicsCategory.Mask
        mask.physicsBody?.contactTestBitMask = PhysicsCategory.Cell

        mask.physicsBody = SKPhysicsBody(rectangleOf: mask.size)
        mask.name = "mask"

        gameLayerNode.addChild(mask)

        mask.physicsBody?.applyImpulse(
            CGVector(dx: random(min: -40, max: 40),
                     dy: random(min: -100, max: 20))
        )
    }

    func createLeftMask() {
        let mask = SKSpriteNode(imageNamed: "mask")

        mask.position = CGPoint(
            x: leftLimit + mask.size.width,
            y: random(min: 0, max: size.height / 2 - mask.size.height)
        )

        mask.zPosition = 2
        mask.physicsBody?.categoryBitMask = PhysicsCategory.Mask
        mask.physicsBody?.contactTestBitMask = PhysicsCategory.Cell

        mask.physicsBody = SKPhysicsBody(rectangleOf: mask.size)

        mask.name = "mask"
        gameLayerNode.addChild(mask)

        mask.physicsBody?.applyImpulse(
            CGVector(dx: random(min: 40, max: 120),
                     dy: random(min: -100, max: 100))
        )
    }

    func createRightMask() {
        let mask = SKSpriteNode(imageNamed: "mask")

        mask.position = CGPoint(
            x: rightLimit - mask.size.width,
            y: random(min: 0, max: size.height / 2 - mask.size.height)
        )

        mask.zPosition = 2
        mask.physicsBody?.categoryBitMask = PhysicsCategory.Mask
        mask.physicsBody?.contactTestBitMask = PhysicsCategory.Cell

        mask.physicsBody = SKPhysicsBody(rectangleOf: mask.size)

        mask.name = "mask"
        gameLayerNode.addChild(mask)

        mask.physicsBody?.applyImpulse(
            CGVector(dx: random(min: -40, max: -120),
                     dy: random(min: -100, max: 100))
        )
    }

    // MARK: - pill related

    func createTopPill() {
        let pill = SKSpriteNode(imageNamed: "pill")

        pill.position = CGPoint(
            x: random(min: leftLimit + pill.size.width, max: rightLimit - pill.size.width),
            y: size.height / 2 - pill.size.height)

        pill.zPosition = 2
        pill.physicsBody?.categoryBitMask = PhysicsCategory.Pill
        pill.physicsBody?.contactTestBitMask = PhysicsCategory.Cell

        pill.physicsBody = SKPhysicsBody(rectangleOf: pill.size)
        pill.name = "pill"

        gameLayerNode.addChild(pill)

        pill.physicsBody?.applyImpulse(
            CGVector(dx: random(min: -40, max: 40),
                     dy: random(min: -100, max: 20))
        )
    }
}

// MARK: - game play related

extension LevelScene {
    func gameOver() {
        backgroundMusicPlayer.stop()
        gameEnded = true
        if let scene = SKScene(fileNamed: "GameOverScene") as? GameOverScene {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            scene.level = level
            // Present the scene
            view?.presentScene(scene)
        }
    }

    func gameWin() {
        backgroundMusicPlayer.stop()
        gameEnded = true
        if let scene = SKScene(fileNamed: "GameWinScene") as? GameWinScene {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            scene.level = level
            // Present the scene
            view?.presentScene(scene)
        }
    }
}

// MARK: - SKPhysicsContactDelegate

extension LevelScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let cellBody = contact.bodyA.categoryBitMask == PhysicsCategory.Cell ? contact.bodyA : contact.bodyB
        let otherBody = contact.bodyA.categoryBitMask == PhysicsCategory.Cell ? contact.bodyB : contact.bodyA
        if let other = otherBody.node as? SKSpriteNode {
            other.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            other.run(SKAction.sequence([
                SKAction.group(
                    [SKAction.scale(by: 0.1, duration: 0.5),
                     SKAction.fadeAlpha(to: 0.1, duration: 0.5),
                    ]),
                SKAction.removeFromParent(),
            ]))
            if other.name == "virus" {
                if let cell = cellBody.node as? SKSpriteNode {
                    cell.run(SKAction.sequence(
                        [SKAction.colorize(with: .red, colorBlendFactor: 0.5, duration: 0.2),
                         SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)]
                    ))
                }
                livesRemaining -= 1
                if livesRemaining <= 0 {
                    gameOver()
                }
            } else if other.name == "pill" {
                if let cell = cellBody.node as? SKSpriteNode {
                    cell.run(SKAction.sequence(
                        [SKAction.colorize(with: .green, colorBlendFactor: 0.5, duration: 0.2),
                         SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)]
                    ))
                }
                if livesRemaining < 20 {
                    livesRemaining += 1
                }
            }
        }
    }
}

// MARK: - Notifications

extension LevelScene {
    func addObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationDidBecomeActive()
        }
        notificationCenter.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationWillResignActive()
        }
        notificationCenter.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationDidEnterBackground()
        }
    }

    func applicationDidBecomeActive() {
        print("* applicationDidBecomeActive")
    }

    func applicationWillResignActive() {
        print("* applicationWillResignActive")
        gameState = .pause
    }

    func applicationDidEnterBackground() {
        print("* applicationDidEnterBackground")
        gameState = .pause
    }
}
