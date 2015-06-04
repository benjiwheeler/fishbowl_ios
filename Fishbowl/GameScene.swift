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



//implement this
public extension SKNode {
    func parentNodeWithName(name: String?) -> SKNode? {
        if (name == nil) {
            return nil;
        }
        var curNode: SKNode? = self
        let MAX_GENERATIONS = 10
        for (var i = 0; i < MAX_GENERATIONS; ++i) {
            if (curNode == nil) {
                return nil
            }
            if (curNode?.name == name) {
                return curNode
            }
            curNode = curNode?.parent
        }
        // if we got here, we failed to find a match
        return nil
    }

    // flawed idea... children inherit parent's speed, so if you pause parent, you would have to multiply children speed by infinity!
    func setSpeedWithoutAffectingChildren(newSpeed: CGFloat) -> Void {
        var childSpeeds = [SKNode: Double]()
        for child in self.children {
            childSpeeds[child as! SKNode] = Double(child.speed)
        }
        self.speed = newSpeed
        for child in self.children {
            var childDoubleSpeed: Double? = childSpeeds[(child as! SKNode)]
            childDoubleSpeed? /= Double(newSpeed) // overcorrect!
            if (childDoubleSpeed != nil) {
                (child as! SKNode).speed = CGFloat(childDoubleSpeed!)
            }
        }
    }
}


class GameScene: SKScene {
    var selectedNode: SKNode? = nil
    
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
        let touch = touches.first as? UITouch
        let locationInScene = touch?.locationInNode(self)
        if (locationInScene != nil) {
            selectNodeForTouch(locationInScene!) // NOTE: next thing to do is select patrol node, not patrol action, and pause that!
            let nodeData = selectedNode?.userData as NSMutableDictionary?
            let patrolActionFromNodeData: SKAction? = nodeData?["patrolAction"] as? SKAction
            let patrolActionFromKey: SKAction? = selectedNode?.actionForKey("patrol")
            //selectedNode?.removeActionForKey("patrol")
            patrolActionFromNodeData?.speed = 0.25
            patrolActionFromKey?.speed = 0.25
        }
    }
   
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as? UITouch
        let positionInScene = touch?.locationInNode(self)
        let previousPosition = touch?.previousLocationInNode(self)
        if (positionInScene != nil && previousPosition != nil) {
            let translation = positionInScene! - previousPosition!
            panForTranslation(translation)
        }
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        let nodeData = selectedNode?.userData as NSMutableDictionary?
        let patrolAction: SKAction? = nodeData?["patrolAction"] as? SKAction
        patrolAction?.speed = 4.0
        selectedNode = nil
        return
    }

    /*
    func boundLayerPos(newPos: CGPoint) {
        var retVal = newPos
        retVal.x = min(retVal.x, 0)
        retVal.y =
        CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -[_background size].width+ winSize.width);
    retval.y = [self position].y;
    return retval;
    }
    */
    func panForTranslation(translation: CGPoint?) {
        let nodePos = selectedNode?.position
        if (matchesNodeType(selectedNode, category: PhysicsCategory.Fish)) {
            if (nodePos != nil && translation != nil) {
                let newPos = nodePos! + translation!
                selectedNode?.position = newPos;
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }

    func matchesNodeType(node: SKNode?, category: UInt32) -> Bool {
        let nodeData = node?.userData as NSMutableDictionary?
        let nodeType: Int? = nodeData?["type"] as? Int
        return ((nodeType != nil) && (nodeType == Int(category)))
    }
    
    func selectNodeForTouch(touchLocation: CGPoint) {
        //1
        let touchedNodes: [SKNode] = nodesAtPoint(touchLocation) as! [SKNode]
        for touchedNode in touchedNodes {
            if (matchesNodeType(touchedNode, category: PhysicsCategory.Fish)) {
                // nodes must not already be equal
                if (selectedNode == nil || !selectedNode!.isEqualToNode(touchedNode)) {
                    selectedNode?.removeAllActions()
                    //selectedNode?.runAction(SKAction.rotateToAngle(0.0, duration: 0.1))
                    selectedNode = touchedNode;
                    //3
                    if (matchesNodeType(selectedNode, category: PhysicsCategory.Fish)) {
/*
                        selectedNode!.runAction(
                            SKAction.repeatActionForever(
                                SKAction.sequence([
                                    SKAction.rotateByAngle(CGFloat(-4.0).degreesToRadians(), duration: 0.1),
                                    SKAction.rotateByAngle(0.0, duration: 0.1),
                                    SKAction.rotateByAngle(CGFloat(4.0).degreesToRadians(), duration: 0.1)
                                ])
                            )
                        )
                    )
  */
                    }
                }
            }
        }
        
        //2
    }
    
    
    func addFish() {
        var fishImages: [SKTexture] = []
        for (var i = 1; i <= 65; ++i) {
            let celName = NSString(format: "Angler300%02d.png", i)
            let cel = SKTexture(imageNamed: celName as! String);
            fishImages.append(cel)
        }
        let location = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        let fish = SKNode()
        let fishFloat = SKNode()
        fishFloat.name = "float"
        let fishPatrol = SKNode()
        fishPatrol.name = "patrol"
        fish.position = location
  
        let fishSheetNode = SKSpriteNode(texture: fishImages.first)
        fishSheetNode.name = "sheet"
        let sheetAction: SKAction = SKAction.repeatActionForever(SKAction.animateWithTextures(fishImages, timePerFrame: 0.1))

        addChild(fish)
        fish.addChild(fishFloat)
        fishFloat.addChild(fishPatrol)
        fishPatrol.addChild(fishSheetNode)
        
        // SKUtils will help us ease!
        let floatUpVector = CGPoint(x: 0, y: 30)
        let floatDownVector = CGPoint(x: 0, y: -30)
        let floatLeftVector = CGPoint(x: -800, y: 0)
        let floatRightVector = CGPoint(x: 800, y: 0)
        
        let upEffect = SKTMoveEffect(node: fishFloat, duration: 1.0, delta: floatUpVector)
        let downEffect = SKTMoveEffect(node: fishFloat, duration: 1.0, delta: floatDownVector)
        let leftEffect = SKTMoveEffect(node: fishPatrol, duration: 5.0, delta: floatLeftVector)
        let rightEffect = SKTMoveEffect(node: fishPatrol, duration: 5.0, delta: floatRightVector)

        upEffect.timingFunction = SKTTimingFunctionQuadraticEaseInOut
        downEffect.timingFunction = SKTTimingFunctionQuadraticEaseInOut
        leftEffect.timingFunction = SKTTimingFunctionQuadraticEaseInOut
        rightEffect.timingFunction = SKTTimingFunctionQuadraticEaseInOut

        let floatAction: SKAction =
            SKAction.repeatActionForever(
                SKAction.sequence([
                    SKAction.actionWithEffect(upEffect),
                    SKAction.actionWithEffect(downEffect)
                ])
            )
        let patrolAction =
            SKAction.repeatActionForever(
                SKAction.sequence([
                    SKAction.actionWithEffect(rightEffect),
                    SKAction.runBlock({fishSheetNode.xScale = fishSheetNode.xScale * -1}),
                    SKAction.actionWithEffect(leftEffect),
                    SKAction.runBlock({fishSheetNode.xScale = fishSheetNode.xScale * -1})
                ])
            )
        
        fish.userData = NSMutableDictionary()
        fish.userData!["floatAction"] = floatAction
        fish.userData!["patrolAction"] = patrolAction
        fish.userData!["sheetAction"] = sheetAction
        fish.userData!["type"] = Int(PhysicsCategory.Fish)
        
        fishSheetNode.runAction(sheetAction, withKey: "sheet")
        fishPatrol.runAction(patrolAction, withKey: "patrol")
        fishFloat.runAction(floatAction, withKey: "float")
        
        NSLog("patrolAction address %p should equal userdata value %p, and actionforkey %p", patrolAction, fish.userData!["patrolAction"] as! SKAction, fishPatrol.actionForKey("patrol")!)

    }
}
