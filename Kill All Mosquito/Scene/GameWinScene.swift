//
//  GameOverScene.swift
//  ZombieConga
//
//  Created by Banghua Zhao on 1/15/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import Foundation
import SpriteKit
import SwiftyButton

class GameWinScene: SKScene {
    var level: Int!

    let tapSound = SKAction.playSoundFileNamed("tap.mp3", waitForCompletion: true)

    override func didMove(to view: SKView) {
        #if !targetEnvironment(macCatalyst)
            bannerView.isHidden = true
        #endif
        playBackgroundMusic(filename: "victory.mp3", repeatForever: false)

        let levelComplete = SKSpriteNode(imageNamed: "level\(level!)-complete")
        levelComplete.zPosition = 1
        levelComplete.position = CGPoint(x: 0, y: 0)
        addChild(levelComplete)

        if level <= 7 {
            let nextButton = SKSpriteNode(imageNamed: "next-level-button")
            nextButton.zPosition = 2
            nextButton.position = CGPoint(x: 0, y: -440)
            nextButton.name = "nextButton"
            levelComplete.addChild(nextButton)

            let backButton = SKSpriteNode(imageNamed: "main-menu-button")
            backButton.zPosition = 2
            backButton.position = CGPoint(x: 0, y: -550)
            backButton.name = "backButton"
            levelComplete.addChild(backButton)
        } else {
            let backButton = SKSpriteNode(imageNamed: "main-menu-button")
            backButton.zPosition = 2
            backButton.position = CGPoint(x: 0, y: -500)
            backButton.name = "backButton"
            levelComplete.addChild(backButton)
        }
    }
}

// MARK: - touch

extension GameWinScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let vTouch = touches.first else { return }
        let touchLocation = vTouch.location(in: self)
        let nodesAtPoint = nodes(at: touchLocation)
        for node in nodesAtPoint {
            if node.name == "nextButton" {
                backgroundMusicPlayer.stop()
                run(tapSound)
                if let scene = SKScene(fileNamed: "LevelScene") as? LevelScene {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    scene.level = level + 1
                    // Present the scene
                    view?.presentScene(scene)
                }
            }

            if node.name == "backButton" {
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
}
