//
//  GameScene.swift
//  Fishbowl
//
//  Created by Benjamin Wheeler on 6/1/15.
//  Copyright (c) 2015 wheeler. All rights reserved.
//

import SpriteKit

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Fish   : UInt32 = 0b1       // 1
    static let Projectile: UInt32 = 0b10      // 2
}

class GameScene: SKScene {
    var selectedNode: SKSpriteNode? = nil
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        /*
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        */
        backgroundColor = SKColor.whiteColor()

        let bg: SKSpriteNode = SKSpriteNode(imageNamed:"aquarium.png")
        bg.position = CGPoint(x:size.width/2.0, y:size.height/2.0);
//        bg.frame = self.frame
        addChild(bg)
        addFish()

        
//        addChild(myLabel)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        let touch: UITouch = (touches as! Set<UITouch>).first!;
        let locationInScene = touch.locationInNode(self)
        selectNodeForTouch(locationInScene)
        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    func selectNodeForTouch(touchLocation: CGPoint) {
        //1
        let touchedNode: SKSpriteNode? = nodeAtPoint(touchLocation) as? SKSpriteNode
        
        //2
        if (selectedNode != nil && selectedNode!.isEqualToNode(touchedNode)) { // not same type of node!
            selectedNode!.removeAllActions()
            selectedNode!.runAction(SKAction.rotateToAngle(0.0, duration: 0.1))
            selectedNode = touchedNode;
            //3
            let nodeData = touchedNode!.userData as NSMutableDictionary?
            let nodeType: UInt32? = nodeData?["type"] as? UInt32
            if (nodeType == PhysicsCategory.Fish) {
                selectedNode!.runAction(
                    SKAction.repeatActionForever(
                        SKAction.sequence([
                            SKAction.rotateByAngle((-4.0 as CGFloat).degreesToRadians(), duration: 0.1),
                            SKAction.rotateByAngle(0.0, duration: 0.1),
                            SKAction.rotateByAngle((4.0 as CGFloat).degreesToRadians(), duration: 0.1)
                        ])
                    )
                )
            }
        }
    }
    
    
    func addFish() {
        var fishImages: [SKTexture] = []
        for (var i = 1; i <= 65; ++i) {
            let celName = NSString(format: "Angler300%02d.png", i)
            let cel = SKTexture(imageNamed: celName as! String);
            fishImages.append(cel)
        }
        let location = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let fish = SKSpriteNode(texture: fishImages.first)
        fish.position = location
        fish.userData = ["type": Int(PhysicsCategory.Fish)] as NSMutableDictionary?
        addChild(fish)
        fish.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(fishImages, timePerFrame: 0.1)))
  
        // SKUtils will help us ease!
        let lowPoint = location
        let highPoint = location + CGPoint(x: 0, y: 50)
        
        let upEffect = SKTMoveEffect(node: fish, duration: 3.0, startPosition: lowPoint, endPosition: highPoint)
        let downEffect = SKTMoveEffect(node: fish, duration: 3.0, startPosition: highPoint, endPosition: lowPoint)
        upEffect.timingFunction = SKTTimingFunctionQuadraticEaseInOut
        downEffect.timingFunction = SKTTimingFunctionQuadraticEaseInOut
        fish.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.actionWithEffect(upEffect),SKAction.actionWithEffect(downEffect)])))

    }
}
