//
//  GameViewController.swift
//  Fishbowl
//
//  Created by Benjamin Wheeler on 6/1/15.
//  Copyright (c) 2015 wheeler. All rights reserved.
//

import UIKit
import SpriteKit



class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = GameScene(size: view.bounds.size)
        let skView = view as! SKView
        skView.showsFPS = true
        skView.showsPhysics = true
        skView.showsFields = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .ResizeFill
        skView.presentScene(scene)
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
