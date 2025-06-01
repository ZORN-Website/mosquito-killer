//
//  GameOverScene.swift
//  ZombieConga
//
//  Created by Banghua Zhao on 1/15/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import Foundation
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif
import SpriteKit
import SwiftyButton

class GameOverScene: SKScene {
    var level: Int!

    var levelMode = true
    var score: Int!

    let tapSound = SKAction.playSoundFileNamed("tap.mp3", waitForCompletion: true)

    var nextScene: SKScene = SKScene()

    override func didMove(to view: SKView) {
        #if !targetEnvironment(macCatalyst)
            bannerView.isHidden = false
        #endif
        playBackgroundMusic(filename: "fail.mp3", repeatForever: false)

        restartCount += 1
        print("restartCount: \(restartCount)")
        if restartCount >= 2 {
            #if !targetEnvironment(macCatalyst)
                GADInterstitialAd.load(withAdUnitID: Constants.interstitialAdID, request: GADRequest()) { ad, error in
                    if let error = error {
                        print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                        return
                    }
                    if let ad = ad {
                        if let rootViewController = self.view?.window?.rootViewController {
                            ad.present(fromRootViewController: rootViewController)
                        }
                        restartCount = 0
                    } else {
                        print("interstitial Ad wasn't ready")
                    }
                }
            #else
                let moreAppsViewController = MoreAppsViewController()
                if let rootViewController = view.window?.rootViewController { rootViewController.present(moreAppsViewController, animated: true)
                }
            #endif
        }

        if levelMode {
            let gameOver = SKSpriteNode(imageNamed: "game-over")
            gameOver.zPosition = 1
            gameOver.position = CGPoint(x: 0, y: 0 + 200)
            addChild(gameOver)

            let againButton = SKSpriteNode(imageNamed: "try-again-button")
            againButton.zPosition = 2
            againButton.position = CGPoint(x: 0, y: -440)
            againButton.name = "againButton"
            gameOver.addChild(againButton)

            let backButton = SKSpriteNode(imageNamed: "main-menu-button")
            backButton.zPosition = 2
            backButton.position = CGPoint(x: 0, y: -550)
            backButton.name = "backButton"
            gameOver.addChild(backButton)
        } else {
            let gameOver = SKSpriteNode(imageNamed: "challenge-end")
            gameOver.zPosition = 1
            gameOver.position = CGPoint(x: 0, y: 0 + 120)
            addChild(gameOver)

            let scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
                node.text = "\(score!) \("mosquitoes".localized())"
                node.fontColor = SKColor.black
                node.fontSize = 50
                node.zPosition = 100
                node.horizontalAlignmentMode = .center
                node.verticalAlignmentMode = .center
            }
            scoreLabel.position = CGPoint(x: 0, y: 26)
            scoreLabel.name = "scoreLabel"
            gameOver.addChild(scoreLabel)

            let againButton = SKSpriteNode(imageNamed: "try-again-button")
            againButton.zPosition = 2
            againButton.position = CGPoint(x: 0, y: -180)
            againButton.name = "againButton"
            gameOver.addChild(againButton)

            let shareButton = SKSpriteNode(imageNamed: "share-button")
            shareButton.zPosition = 2
            shareButton.position = CGPoint(x: 0, y: -290)
            shareButton.name = "shareButton"
            gameOver.addChild(shareButton)

            let backButton = SKSpriteNode(imageNamed: "main-menu-button")
            backButton.zPosition = 2
            backButton.position = CGPoint(x: 0, y: -400)
            backButton.name = "backButton"
            gameOver.addChild(backButton)
        }
    }
}

// MARK: - touch

extension GameOverScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let vTouch = touches.first else { return }
        let touchLocation = vTouch.location(in: self)
        let nodesAtPoint = nodes(at: touchLocation)
        for node in nodesAtPoint {
            if node.name == "againButton" {
                if levelMode {
                    backgroundMusicPlayer.stop()
                    run(tapSound)
                    if let scene = SKScene(fileNamed: "LevelScene") as? LevelScene {
                        // Set the scale mode to scale to fit the window
                        scene.scaleMode = .aspectFill
                        scene.level = level
                        nextScene = scene
                        view?.presentScene(scene)
                    }
                } else {
                    backgroundMusicPlayer.stop()
                    run(tapSound)
                    if let scene = SKScene(fileNamed: "SurvivalScene") as? SurvivalScene {
                        // Set the scale mode to scale to fit the window
                        scene.scaleMode = .aspectFill
                        nextScene = scene
                        view?.presentScene(scene)
                    }
                }
            }

            if node.name == "backButton" {
                backgroundMusicPlayer.stop()
                run(tapSound)
                if let scene = SKScene(fileNamed: "MainMenuScene") {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    nextScene = scene
                    // Present the scene
                    view?.presentScene(scene)
                }
            }

            if node.name == "shareButton" {
                run(tapSound)
                let textToShare = "\("Kill All Mosquito: Congratulations! You have killed".localized()) \(score!) \("mosquitoes".localized())"

                let image = UIImage(named: "appIcon144")!

                if let myWebsite = URL(string: "http://itunes.apple.com/app/id\(Constants.appID)") {
                    // Enter link to your app here
                    let objectsToShare = [textToShare, myWebsite, image] as [Any]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

                    if let popoverController = activityVC.popoverPresentationController {
                        popoverController.sourceRect = CGRect(x: view?.center.x ?? 0, y: view?.center.y ?? 0, width: 0, height: 0)
                        popoverController.sourceView = view
                    }

                    view?.window?.rootViewController?.present(activityVC, animated: true, completion: nil)
                }
            }
        }
    }
}
