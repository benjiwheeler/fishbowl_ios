//
//  GameScene.swift
//  Fishbowl
//
//  Created by Benjamin Wheeler on 6/1/15.
//  Copyright (c) 2015 wheeler. All rights reserved.
//

import SpriteKit
//import UIControl+Sound

struct PhysicsCategory {
    static let kNone      : UInt32 = 0
    static let kAll       : UInt32 = UInt32.max
    static let kSceneBoundary: UInt32 = 0b1       // 1
    static let kFish: UInt32 = 0b10       // 2
    static let kFishAware: UInt32 = 0b100 // 4
    static let kFood: UInt32 = 0b1000 // 8
}

func randomInt(min: Int, max:Int) -> Int {
    return min + Int(arc4random_uniform(UInt32(max - min + 1)))
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
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
    
    func childNodeWithNameRecursive(name: String, var maxDepth: Int? = nil) -> SKNode? {
        // try to find node within this node...
        if let nodeHere: SKNode = self.childNodeWithName(name) {
            // ...if we find it, we're good!
            return nodeHere
        }
        
        if (maxDepth == nil) {
            maxDepth = DEFAULT_MAX_RECURSIVE_DEPTH()
        }
        if (maxDepth == nil || maxDepth <= 0) {
            return nil
        }
        
        // recursively search child nodes for action
        for child in self.children {
            let childNode = child as? SKNode
            if let childResult: SKNode = childNode?.childNodeWithNameRecursive(name, maxDepth: maxDepth! - 1) {
                return childResult
            }
        }
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
    var fishes: [Fish] = []
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        /*
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        */
        backgroundColor = SKColor.whiteColor()

        physicsWorld.gravity = CGVectorMake(0, -0.5)
        physicsWorld.contactDelegate = self
        self.name = "gamescene"
        
        let bg: SKSpriteNode = SKSpriteNode(imageNamed:"aquarium.png")
        bg.position = CGPoint(x:size.width/2.0, y:size.height/2.0);
//        bg.frame = self.frame
        addChild(bg)

        let minX: Int = 100
        let maxX: Int = 500
        let minY = 100
        let maxY = 500
        for var i = 0; i < 5; ++i {
            let newFish = Fish()
            fishes.append(newFish)
            let startingX = Int(arc4random_uniform(UInt32(maxX - minX))) + minX
            let startingY = Int(arc4random_uniform(UInt32(maxY - minY))) + minY

            newFish.position = CGPoint(x: startingX, y: startingY)
            addChild(newFish)
        }
        
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRect(x: self.frame.minX + 80, y: self.frame.minY + 70, width: self.frame.width - 200, height: self.frame.height - 250))
        self.physicsBody!.categoryBitMask = PhysicsCategory.kSceneBoundary;

        SKTAudio.sharedInstance().playBackgroundMusic("bubbling_short_quiet.aiff")

       // SoundPlayer.sharedInstance.addSound("bubble_plink")
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
                if let selectedFish: Fish = selectedNode! as? Fish {
                    selectedFish.stopActions()
                }
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
        if let selectedFish: Fish = selectedNode as? Fish {
            selectedFish.restartActions()
        }
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
        if (matchesNodeType(selectedNode, category: PhysicsCategory.kFish)) {
            if (nodePos != nil && translation != nil) {
                let newPos = nodePos! + translation!
                selectedNode?.position = newPos;
                NSLog("panForTranslation: fish node position is (%f, %f)", selectedNode!.position.x, selectedNode!.position.y)
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
            if (matchesNodeType(touchedNode, category: PhysicsCategory.kFish)) {
                // nodes must not already be equal
                if (selectedNode == nil || !selectedNode!.isEqualToNode(touchedNode)) {
//                    selectedNode?.removeAllActions()
                    //selectedNode?.runAction(SKAction.rotateToAngle(0.0, duration: 0.1))
                    selectedNode = touchedNode;
                    //3
                    if (matchesNodeType(selectedNode, category: PhysicsCategory.kFish)) {
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
        foodNode.physicsBody?.categoryBitMask = PhysicsCategory.kFood // 3
        foodNode.physicsBody?.contactTestBitMask = PhysicsCategory.kFishAware // 4
        foodNode.physicsBody?.collisionBitMask = PhysicsCategory.kSceneBoundary // 5
        SKTAudio.sharedInstance().playSoundEffect("bubble_plink.aiff")
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
        if ((firstBody.categoryBitMask & PhysicsCategory.kFishAware != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.kFood != 0)) {
                if let fishAwareNode: SKSpriteNode = firstBody.node as? SKSpriteNode {
                    if let fish: Fish = fishAwareNode.parentNodeWithName("fish") as? Fish {
                        fish.foodDidCollideWithFishAware(secondBody.node as! SKSpriteNode, fishAwareNode: fishAwareNode)
                    }
                }
        }
        if ((firstBody.categoryBitMask & PhysicsCategory.kFish != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.kFood != 0)) {
                if let fish: Fish = firstBody.node as? Fish {
                    fish.foodDidCollideWithFish(secondBody.node as! SKSpriteNode)
                }
        }
    }

    // hugely important: need to manually reset the relative coordinates of fishAware child node, or else it simply doesn't follow its parent node at all, but just keeps doing its own thing!
    override func didSimulatePhysics() {
        for fish in fishes {
            let fishAware = fish.childNodeWithNameRecursive("awareNode")
            fishAware?.position = CGPoint(x: 0.0, y: 0.0)
        }
    }

}

class Fish: SKNode {
    var targetedNode: SKNode?
    var doPursuit = true
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init() {
        super.init()
        
        var fishImages: [SKTexture] = []
        for (var i = 1; i <= 65; ++i) {
            let celName = NSString(format: "Angler300%02d.png", i)
            let cel = SKTexture(imageNamed: celName as! String);
            fishImages.append(cel)
        }
        self.name = "fish"
        self.position = CGPoint(x: 100.0, y: 100.0)
        
        let fishSheetNode = SKSpriteNode(texture: fishImages.first)
        fishSheetNode.name = "sheet"
        let sheetAction: SKAction = SKAction.repeatActionForever(SKAction.animateWithTextures(fishImages, timePerFrame: 0.1))
        
        
        let fishAwareNode = SKSpriteNode()
        fishAwareNode.name = "awareNode"
        fishAwareNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: fishSheetNode.size.width * 2, height: fishSheetNode.size.height)) // 1
        fishAwareNode.physicsBody?.dynamic = false // do be affected by forces
        fishAwareNode.physicsBody?.affectedByGravity = false
        fishAwareNode.physicsBody?.categoryBitMask = PhysicsCategory.kFishAware // 3
        fishAwareNode.physicsBody?.contactTestBitMask = PhysicsCategory.kFood // 4
        fishAwareNode.physicsBody?.collisionBitMask = PhysicsCategory.kNone // 5
        
        self.addChild(fishAwareNode)
        fishAwareNode.addChild(fishSheetNode)
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: fishSheetNode.size.width * 0.25) // 1
        self.physicsBody?.dynamic = true // do be affected by forces
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.categoryBitMask = PhysicsCategory.kFish // 3
        self.physicsBody?.contactTestBitMask = PhysicsCategory.kFood // 4
        self.physicsBody?.collisionBitMask = PhysicsCategory.kSceneBoundary + PhysicsCategory.kFish // 5

        // note that the placement order of this command matters!
        self.setScale(0.5)

        // SKUtils will help us ease!
        let patrolX = randomInt(600, 900)
        let patrolDuration: CGFloat = CGFloat(Double(randomInt(300, 700)) / 100.0)
        let floatUpVector = CGPoint(x: 0, y: 30)
        let floatDownVector = CGPoint(x: 0, y: -30)
        let floatLeftVector = CGPoint(x: -patrolX, y: 0)
        let floatRightVector = CGPoint(x: patrolX, y: 0)
        
        let upEffect = SKTMoveEffect(node: self, duration: 1.0, delta: floatUpVector)
        let downEffect = SKTMoveEffect(node: self, duration: 1.0, delta: floatDownVector)
        let leftEffect = SKTMoveEffect(node: self, duration: Double(patrolDuration), delta: floatLeftVector)
        let rightEffect = SKTMoveEffect(node: self, duration: Double(patrolDuration), delta: floatRightVector)
        
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
                SKAction.runBlock({
                }),
                SKAction.runBlock({fishSheetNode.xScale = fishSheetNode.xScale * -1}),
                SKAction.actionWithEffect(leftEffect),
                SKAction.runBlock({
//                    let tempFish: SKNode? = self.childNodeWithName("fish")
                    //                        NSLog("patrolAction: after left, fish node position is (%f, %f)", tempFish!.position.x, tempFish!.position.y)
                }),
                SKAction.runBlock({fishSheetNode.xScale = fishSheetNode.xScale * -1})
                ])
        )
        
        self.userData = NSMutableDictionary()
        self.userData!["type"] = Int(PhysicsCategory.kFish)
        
        fishSheetNode.runAction(sheetAction, withKey: "sheet")
        self.runAction(patrolAction, withKey: "patrol")
        self.runAction(floatAction, withKey: "float")
        
        NSLog("patrolAction address %p should equal actionforkey %p", patrolAction, self.actionForKey("patrol")!)
    }
    
    func pursuitAction(targetNode: SKNode, distPerSec: CGFloat, segmentDuration: NSTimeInterval) -> SKAction? {
        let awareNode: SKNode? = self.childNodeWithNameRecursive("awareNode")
//        NSLog("pursuitAction: targetNode.pos: (%f, %f);  self.pos: (%f, %f); awareNode.pos: (%f, %f)", targetNode.position.x, targetNode.position.y, self.position.x, self.position.y, awareNode!.position.x, awareNode!.position.y)
        var curSegmentDuration = segmentDuration
        var segmentDist: CGFloat = CGFloat(segmentDuration) * distPerSec
        let vectorToTarget: CGPoint = targetNode.position - self.position

        // adjust duration and distance if target is very close
        let targetDist: CGFloat = vectorToTarget.length()
        if (targetDist < 25.0) {
            return nil
        }
        if (targetDist < segmentDist) {
            curSegmentDuration = NSTimeInterval(Double(CGFloat(curSegmentDuration) * targetDist / segmentDist))
            segmentDist = targetDist
        }

        // figure out where we're going
        let vectorForSegment: CGPoint = vectorToTarget.normalized() * segmentDist * 10.0
        let segmentTargetPos: CGPoint = self.position + vectorForSegment
  
        return SKAction.sequence([
            SKAction.runBlock({
                if let body: SKPhysicsBody = self.physicsBody {
//                    NSLog("applying force (%f, %f)", vectorForSegment.x, vectorForSegment.y)
                    body.applyForce(CGVector(point: vectorForSegment))
                }
            }),
            SKAction.waitForDuration(0.1) // important: without slight wait, instantaneous force action just never stops hogging cpu
        ])
//        return SKAction.moveTo(segmentTargetPos, duration: curSegmentDuration)
    }
    
    func runPursuitAction(targetNode: SKNode, distPerSec: CGFloat, segmentDuration: NSTimeInterval) -> Void {
        if let thisPursuitAction: SKAction = pursuitAction(targetNode, distPerSec: distPerSec, segmentDuration: segmentDuration) {
            self.runAction(thisPursuitAction,
                completion: {
                    if (self.doPursuit && targetNode == self.targetedNode && self.targetedNode != nil) { // stop pursuing if targetted node is gone!
                        self.runPursuitAction(targetNode, distPerSec: distPerSec, segmentDuration: segmentDuration)
                    }
                }
            )
        }
        return
    }

    func patrolAction() -> SKAction? {
        let patrolActionFromKey: SKAction? = self.findActionInNodeHierarchy("patrol")
        return patrolActionFromKey
    }
    func foodDidCollideWithFish(foodNode: SKSpriteNode) {
//        SoundPlayer.sharedInstance.playSound("bubble_plink")
        //        runAction(SKAction.playSoundFileNamed("bubble_plink.aiff", waitForCompletion: false))
        SKTAudio.sharedInstance().playSoundEffect("comicbite_med_quiet.aiff")

        let sparkEmmiter = SKEmitterNode(fileNamed: "sparks.sks")
        sparkEmmiter.physicsBody?.collisionBitMask = 0
        sparkEmmiter.position = foodNode.position
        sparkEmmiter.name = "sparkEmmitter"
        sparkEmmiter.zPosition = 1
        sparkEmmiter.targetNode = self
//        sparkEmmiter.particleLifetime = 1
        self.parent?.addChild(sparkEmmiter)

        foodNode.removeFromParent()
        targetedNode = nil
        patrolAction()?.speed = 1.0
    }
    
    func foodDidCollideWithFishAware(foodNode: SKSpriteNode, fishAwareNode: SKSpriteNode) {
        // fish now wants to eat this food!
        // stop patrol
        patrolAction()?.speed = 0.5
        targetedNode = foodNode
        // start pursuit
        self.runPursuitAction(targetedNode!, distPerSec: CGFloat(500.0), segmentDuration: NSTimeInterval(0.1))
    }

    func restartActions() -> Void {
        patrolAction()?.speed = 1.0
        doPursuit = true
    }
    
    func stopActions() -> Void {
        patrolAction()?.speed = 0.0
        doPursuit = false // forget about the food you're pursuing
        self.physicsBody?.velocity = CGVector(dx: 0.0, dy: 0.0)
        return
    }
}
