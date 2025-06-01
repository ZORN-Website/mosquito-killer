//
//  GameViewController.swift
//  Kill All Mosquito
//
//  Created by Banghua Zhao on 1/29/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import GameplayKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif
import SpriteKit
import UIKit

#if !targetEnvironment(macCatalyst)
    var bannerView: GADBannerView = {
        let bannerView = GADBannerView()
        bannerView.adUnitID = Constants.bannerAdUnitID
        bannerView.load(GADRequest())
        return bannerView
    }()
#endif

class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "MainMenuScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill

                // Present the scene
                view.presentScene(scene)
            }

            view.ignoresSiblingOrder = true

            #if DEBUG
//                view.showsPhysics = true
//                view.showsFPS = true
//                view.showsNodeCount = true
            #endif
        }
        #if !targetEnvironment(macCatalyst)
            view.addSubview(bannerView)
            bannerView.rootViewController = self
            bannerView.snp.makeConstraints { make in
                make.height.equalTo(50)
                make.width.equalToSuperview()
                make.bottom.equalTo(view.safeAreaLayoutGuide)
                make.centerX.equalToSuperview()
            }
        #endif
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
