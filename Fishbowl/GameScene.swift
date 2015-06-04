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
    static let Fish: UInt32 = 0b1       // 1
    static let FishAware: UInt32 = 0b10 // 2
    static let Food: UInt32 = 0b100 // 4
}



//implement this
public extension SKNode {
    func DEFAULT_MAX_RECURSIVE_DEPTH() -> Int {
        return 10
    }

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
    
    func findActionInNodeHierarchy(key: String, var maxDepth: Int? = nil) -> SKAction? {
        // try to find action within this node...
        if let actionHere: SKAction = self.actionForKey(key) {
            // ...if we find it, we're good!
            return actionHere
        }

        // set and handle maxDepth
        if (maxDepth == nil) {
            maxDepth = DEFAULT_MAX_RECURSIVE_DEPTH()
        }
        if (maxDepth == nil || maxDepth <= 0) {
            return nil
        }

        // recursively search child nodes for action
        for child in self.children {
            let childNode = child as? SKNode
            if let childResult: SKAction = childNode?.findActionInNodeHierarchy(key, maxDepth: maxDepth! - 1) {
                return childResult
            }
        }
        return nil
    }
}


class GameScene: SKScene, SKPhysicsContactDelegate {
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

        physicsWorld.gravity = CGVectorMake(0, -2)
        physicsWorld.contactDelegate = self

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
            selectNodeForTouch(locationInScene!)
            if (selectedNode == nil) { // no draggable node found under touch
                createFoodAt(locationInScene!)
            } else {
                let patrolActionFromKey: SKAction? = selectedNode?.findActionInNodeHierarchy("patrol")
                patrolActionFromKey?.speed = 0.0
            }
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
        let patrolActionFromKey: SKAction? = selectedNode?.findActionInNodeHierarchy("patrol")
        patrolActionFromKey?.speed = 1.0
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
    
    func createFoodAt(location: CGPoint) {
        let foodNode = SKSpriteNode(texture: SKTexture(imageNamed: "food0001"))
        foodNode.position = location
        addChild(foodNode)
        foodNode.physicsBody = SKPhysicsBody(rectangleOfSize: foodNode.size) // 1
        foodNode.physicsBody?.dynamic = true // 2
        foodNode.physicsBody?.categoryBitMask = PhysicsCategory.Food // 3
        foodNode.physicsBody?.contactTestBitMask = PhysicsCategory.FishAware // 4
        foodNode.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        

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
        fish.name = "fish"
        let fishFloat = SKNode()
        fishFloat.name = "float"
        let fishPatrol = SKNode()
        fishPatrol.name = "patrol"
        fish.position = location
  
        let fishSheetNode = SKSpriteNode(texture: fishImages.first)
        fishSheetNode.name = "sheet"
        let sheetAction: SKAction = SKAction.repeatActionForever(SKAction.animateWithTextures(fishImages, timePerFrame: 0.1))
        
        let fishAwareNode = SKSpriteNode()
        fishAwareNode.name = "awareNode"
        fishAwareNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: fishSheetNode.size.width * 2, height: fishSheetNode.size.height)) // 1
        fishAwareNode.physicsBody?.dynamic = false // 2
        fishAwareNode.physicsBody?.categoryBitMask = PhysicsCategory.FishAware // 3
        fishAwareNode.physicsBody?.contactTestBitMask = PhysicsCategory.Food // 4
        fishAwareNode.physicsBody?.collisionBitMask = PhysicsCategory.None // 5

        
        addChild(fish)
        fish.addChild(fishFloat)
        fishFloat.addChild(fishPatrol)
        fishPatrol.addChild(fishAwareNode)
        fishAwareNode.addChild(fishSheetNode)
        
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
        fish.userData!["type"] = Int(PhysicsCategory.Fish)
        
        fishSheetNode.runAction(sheetAction, withKey: "sheet")
        fish.runAction(patrolAction, withKey: "patrol")
        fish.runAction(floatAction, withKey: "float")
        
        NSLog("patrolAction address %p should equal actionforkey %p", patrolAction, fish.actionForKey("patrol")!)

    }
    
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.FishAware != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Food != 0)) {
                foodDidCollideWithFishAware(secondBody.node as! SKSpriteNode, fishAwareNode: firstBody.node as! SKSpriteNode)
        }
        
    }

    func foodDidCollideWithFishAware(foodNode: SKSpriteNode, fishAwareNode: SKSpriteNode) {
        let fishNode: SKNode? = fishAwareNode.parentNodeWithName("fish")
        if (fishNode != nil) {
            // fish now wants to eat this food!
            // stop patrol
            let patrolActionFromKey: SKAction? = fishNode!.findActionInNodeHierarchy("patrol")
            patrolActionFromKey?.speed = 0.0
            // start pursuit
            let distPerS: CGFloat = 200.0
            let iterationPortionSize: CGFloat = 1.0
            var durationToFood: NSTimeInterval = 0.0
            var effectiveFoodPos: CGPoint = CGPoint(x: 0.0, y: 0.0)

            // NOTE: problem here is that we don't have access to variables for duration outside of blocks. probably should change approach to constant 1s actions, and work out direction and distance in block? then we can stop it any time.
            let pursuitAction =
            SKAction.repeatActionForever(
                SKAction.sequence([
                    SKAction.runBlock({
                        NSLog("running custom block. fishNode position is (%f, %f)", fishNode!.position.x, fishNode!.position.y)

                        let vectorToFood: CGPoint = foodNode.position - fishNode!.position
                        let vectorForIteration: CGPoint = vectorToFood * iterationPortionSize
                        effectiveFoodPos = fishAwareNode.position + vectorForIteration
                        let distToFood: CGFloat = vectorForIteration.length()
                        durationToFood = NSTimeInterval(distToFood/distPerS)
                        
                        // invoked asynchronously
                        fishAwareNode.runAction(
                            SKAction.sequence([
                                SKAction.waitForDuration(NSTimeInterval(1.0)),
                                SKAction.runBlock({
                                    NSLog("running inner block")
                                }),
                                SKAction.moveTo(effectiveFoodPos, duration: durationToFood),
                                SKAction.waitForDuration(NSTimeInterval(1.0))
                            ])
                        )
                        NSLog("done running custom block")
                        return ()
                    }),
                    SKAction.waitForDuration(NSTimeInterval(5.0))
                ])
            )
            fishAwareNode.runAction(pursuitAction, withKey: "pursuit")


        }
        
    }

}
