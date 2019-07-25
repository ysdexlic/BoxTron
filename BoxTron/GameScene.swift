//
//  GameScene.swift
//  BoxTron
//
//  Created by David Thompson on 24/07/2019.
//  Copyright © 2019 The Beardy Developer. All rights reserved.
//

import SpriteKit
import GameplayKit


struct PhysicsCategory {
    static let Wall: UInt32 = 0x1 << 1
    static let OuterWall: UInt32 = 0x1 << 2
    static let Score: UInt32 = 0x1 << 3
    static let Border: UInt32 = 0x1 << 4
}


class GameScene: SKScene, SKPhysicsContactDelegate {

    // Sprites / Nodes
    private var border: SKShapeNode!
    private var box: SKSpriteNode!
    private var wall: SKSpriteNode!
    private var outerWall: SKShapeNode!
    private var scoreNode: SKShapeNode!
    private var barrier: SKNode!
    private var restartButton: SKSpriteNode!

    // Labels
    private var textLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!

    // Other
    private var touchPosition: CGPoint?
    private var highScore: Int = UserDefaults.standard.integer(forKey: "boxtron_highscore")
    private var score: Int = 0
    private var died: Bool = false
    private var gameStarted: Bool = false
    private var restartCount: Int = 0
    private var isFirstTouch: Bool = false

    private var initialWidth: CGFloat!
    private var scaleX: CGFloat!
    private var scaleY: CGFloat!


    override func didMove(to view: SKView) {
        createScene()
    }

    func createScene() {
        self.physicsWorld.contactDelegate = self
        initialWidth = (self.size.width + self.size.height) * 0.2

        box = SKSpriteNode.init(color: SKColor.red, size: CGSize(width: initialWidth, height: initialWidth))
        if let box = box {
            box.alpha = 0
            box.position = CGPoint(x: 0, y: 0)
            box.name = "box"
            self.addChild(box)
        }

        removeAndAddBorder()

        // Tap to start label
        textLabel = SKLabelNode()
        textLabel.fontSize = 50
        textLabel.position = CGPoint(x: 0, y: (self.frame.height / 2) - (self.frame.height / 4))
        textLabel.zPosition = 5
        textLabel.text = "Tap anywhere to start"

        // Score Label
        scoreLabel = SKLabelNode()
        scoreLabel.fontSize = 50
        scoreLabel.position = CGPoint(x: 0, y: (self.frame.height / 2) - (self.frame.height / 5))
        scoreLabel.zPosition = 5
        scoreLabel.text = gameStarted ? "\(score)" : "High Score: \(highScore)"
        self.addChild(scoreLabel)

        if restartCount > 0 {
            startGame()
        } else {
            self.addChild(textLabel)
        }
    }

    func restartScene() {
        self.removeAllChildren()
        self.removeAllActions()
        died = false
        gameStarted = true
        restartCount += 1
        score = 0
        isFirstTouch = false
        createScene()
    }

    func createRestartButton() {
        let restartText = SKLabelNode()
        restartText.text = "restart"
        restartText.fontSize = 60
        restartText.fontColor = UIColor.white
        restartButton = SKSpriteNode(color: UIColor.white, size: CGSize(width: 300, height: 200))
        restartButton.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        restartButton.zPosition = 6
        restartButton.setScale(0)
        restartButton.addChild(restartText)
        self.addChild(restartButton)
        restartButton.run(SKAction.scale(to: 1.0, duration: 0.25))

        textLabel.text = "High Score: \(highScore)"
        self.addChild(textLabel)
    }

    func startGame() {
        scoreLabel.text = "\(score)"
        let spawn = SKAction.run {
            () in
            self.createWalls()
        }
        let delay = SKAction.wait(forDuration: 5.0)
        let spawnDelay = SKAction.sequence([spawn, delay])
        let spawnDelayForever = SKAction.repeatForever(spawnDelay)
        self.run(spawnDelayForever)
    }

    func onDeath() {
        died = true

        if score > highScore {
            highScore = score
            UserDefaults.standard.set(score, forKey: "boxtron_highscore")
            UserDefaults.standard.synchronize()
        }

        createRestartButton()
    }

    func touchDown(atPoint pos : CGPoint) {
        touchPosition = pos
        scaleX = box.size.width
        scaleY = box.size.height

        if !gameStarted {
            isFirstTouch = true
            gameStarted = true
            if restartCount == 0 {
                textLabel.run(SKAction.removeFromParent())
                startGame()
                return
            }
        }
        if died || !gameStarted {
            return
        }
    }

    func removeAndAddBorder() {
        if let border = border {
            self.removeChildren(in: [border])
        }
        border = SKShapeNode.init(rect: box!.frame)
        border.strokeColor = SKColor.green
        border.lineWidth = 4
        border.physicsBody = SKPhysicsBody(edgeLoopFrom: box.frame)
        border.name = "border"
        border.physicsBody?.categoryBitMask = PhysicsCategory.Border
        border.physicsBody?.collisionBitMask = 0
        border.physicsBody?.contactTestBitMask = PhysicsCategory.Wall | PhysicsCategory.Score | PhysicsCategory.OuterWall
        border.zPosition = 1
        self.addChild(border)
    }

    func createWalls() {
        let gapSize = CGFloat(40)
        barrier = SKNode()

        wall = SKSpriteNode.init(color: SKColor.red, size: CGSize(width: 300, height: 500))
        wall.alpha = 0
        wall.position = CGPoint(x: 0, y: 0)
        wall.name = "wall"
        wall.physicsBody = SKPhysicsBody(rectangleOf: wall.size)
//        wall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
//        wall.physicsBody?.collisionBitMask = PhysicsCategory.Border
//        wall.physicsBody?.contactTestBitMask = PhysicsCategory.Border
        wall.physicsBody?.affectedByGravity = false
        wall.physicsBody?.isDynamic = false

        scoreNode = SKShapeNode.init(rect: wall.frame, cornerRadius: 10)
        scoreNode.lineWidth = gapSize
        scoreNode.physicsBody = SKPhysicsBody(edgeLoopFrom: scoreNode!.frame)
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.Score
        scoreNode.physicsBody?.collisionBitMask = 0
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.Border
        scoreNode.physicsBody?.affectedByGravity = false
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.zPosition = 1


        outerWall = SKShapeNode.init(rect: scoreNode.frame, cornerRadius: 10)
        outerWall.lineWidth = self.size.height
//        outerWall.strokeColor = SKColor.red
        outerWall.alpha = 0
        outerWall.name = "outerWall"
        outerWall.physicsBody = SKPhysicsBody(rectangleOf: outerWall!.frame.size)
//        outerWall.physicsBody?.categoryBitMask = PhysicsCategory.OuterWall
//        outerWall.physicsBody?.collisionBitMask = PhysicsCategory.Border
//        outerWall.physicsBody?.contactTestBitMask = PhysicsCategory.Border
//        outerWall.physicsBody?.affectedByGravity = false
        outerWall.physicsBody?.isDynamic = false
//        outerWall.zPosition = -1

        barrier.addChild(wall)
        barrier.addChild(scoreNode)
        barrier.addChild(outerWall)

        let wait = SKAction.wait(forDuration: 3.0)
        let updateZPosition = SKAction.run {
            () in
            print("DOIN IT")
//            self.scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.Score
//            self.scoreNode.physicsBody?.collisionBitMask = 0
//            self.scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.Border
        }
        let remove = SKAction.removeFromParent()
        let moveAndRemove = SKAction.sequence([wait, updateZPosition, remove])

        barrier.run(moveAndRemove)

        self.addChild(barrier)

//
//        let randomPosition = CGFloat.random(min: -200, max: 200)
//        wallPair.position.y = wallPair.position.y + randomPosition
//        wallPair.zPosition = 1
//        wallPair.run(moveAndRemove)
//
    }

    func touchMoved(toPoint pos : CGPoint) {
        let someThing = (initialWidth / 4)

        let diffX = pos.x - touchPosition!.x
        let diffY = pos.y - touchPosition!.y

        let newWidth = scaleX + (diffX * 2.5)
        let newHeight = scaleY + (diffY * 2.5)

        if newWidth >= someThing && newWidth <= self.size.width - someThing {
            box.size.width = newWidth
        } else if newWidth < someThing {
            box.size.width = someThing
        } else if newWidth > self.size.width - someThing {
            box.size.width = self.size.width - someThing
        }

        if newHeight >= someThing && newHeight <= self.size.height - someThing {
            box.size.height = newHeight
        } else if newHeight < someThing {
            box.size.height = someThing
        } else if newHeight > self.size.height - someThing {
            box.size.height = self.size.height - someThing
        }
    }

    func touchUp(atPoint pos : CGPoint) {
        if isFirstTouch && restartCount == 0 {
            isFirstTouch = false
            return
        }

        if died && restartButton.contains(pos) {
            restartScene()
        }

        if died || !gameStarted {
            return
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        print(firstBody)
        print(secondBody)

        // Player scored a point
        if !died && (firstBody.categoryBitMask == PhysicsCategory.Score && secondBody.categoryBitMask == PhysicsCategory.Border || firstBody.categoryBitMask == PhysicsCategory.Border && secondBody.categoryBitMask == PhysicsCategory.Score) {
            score += 1
            scoreLabel.text = "\(score)"
        }

        // Player hits wall
        if firstBody.categoryBitMask == PhysicsCategory.Border && secondBody.categoryBitMask == PhysicsCategory.Wall || firstBody.categoryBitMask == PhysicsCategory.Wall && secondBody.categoryBitMask == PhysicsCategory.Border {
            enumerateChildNodes(withName: "wall", using: { (node, error) in
                node.speed = 0
                self.removeAllActions()
            })
            if !died {
                onDeath()
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        removeAndAddBorder()
    }
}
