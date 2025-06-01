//
//  MainMenuScene.swift
//  Kill All Mosquito
//
//  Created by Banghua Zhao on 1/15/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import SnapKit
import SpriteKit
import SwiftyButton
import Then

class MainMenuScene: SKScene {
    let tapSound = SKAction.playSoundFileNamed("tap.mp3", waitForCompletion: true)
    override func didMove(to view: SKView) {
        #if !targetEnvironment(macCatalyst)
            bannerView.isHidden = false
        #endif
        playBackgroundMusic(filename: "BGM.mp3", repeatForever: true)

        let mainOver = SKSpriteNode(imageNamed: "main-menu")
        mainOver.zPosition = 1
        mainOver.position = CGPoint(x: 0, y: 0)
        addChild(mainOver)

        let levelButton = SKSpriteNode(imageNamed: "level-mode-button")
        levelButton.zPosition = 2
        levelButton.position = CGPoint(x: 0, y: -400)
        levelButton.name = "levelButton"
        mainOver.addChild(levelButton)

        let survivalButton = SKSpriteNode(imageNamed: "survival-mode-button")
        survivalButton.zPosition = 2
        survivalButton.position = CGPoint(x: 0, y: -500)
        survivalButton.name = "survivalButton"
        mainOver.addChild(survivalButton)

        let moreAppsButton = SKSpriteNode(imageNamed: "more-apps-button")
        moreAppsButton.zPosition = 2
        moreAppsButton.position = CGPoint(x: 0, y: -600)
        moreAppsButton.name = "moreAppsButton"
        mainOver.addChild(moreAppsButton)
    }
}

// MARK: - touch

extension MainMenuScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let vTouch = touches.first else { return }
        let touchLocation = vTouch.location(in: self)
        let nodesAtPoint = nodes(at: touchLocation)
        for node in nodesAtPoint {
            if node.name == "levelButton" {
                backgroundMusicPlayer.stop()
                run(tapSound)
                if let scene = SKScene(fileNamed: "LevelScene") as? LevelScene {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    scene.level = 1
                    // Present the scene
                    view?.presentScene(scene)
                }
            }

            if node.name == "survivalButton" {
                backgroundMusicPlayer.stop()
                run(tapSound)
                if let scene = SKScene(fileNamed: "SurvivalScene") as? SurvivalScene {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    // Present the scene
                    view?.presentScene(scene)
                }
            }

            if node.name == "moreAppsButton" {
                run(tapSound)
                let moreAppsViewController = MoreAppsViewController()
                if let rootViewController = view?.window?.rootViewController { rootViewController.present(moreAppsViewController, animated: true)
                }
            }
        }
    }
}
