//
//  GameScene.swift
//  fatcat
//
//  Created by Shannon Jin on 6/2/20.
//  Copyright © 2020 Shannon Jin. All rights reserved.
//

import SpriteKit
import GameplayKit
import UIKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    private var background = SKSpriteNode(imageNamed:"background.jpg")
    private var fox =  SKSpriteNode()
    private var foxRunFrames: [SKTexture] = []
   
    var motionManager = CMMotionManager()
    var destX:CGFloat  = 0.0
    
    
    struct PhysicsCategory {
      static let none: UInt32 = 0
      static let all : UInt32 = UInt32.max
      static let star: UInt32 = 0b1       // 1
      static let edge: UInt32 = 0b10      // 2
    }
    
    override func sceneDidLoad() {

        self.lastUpdateTime = 0
        
        background.position = CGPoint(x:0 , y: 0)
        background.size = self.size
        self.addChild(background)
    }
    
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        makeFox()

        let edge = SKShapeNode()
        let pathToDraw = CGMutablePath()

        pathToDraw.move(to: CGPoint(x: (size.width * -1), y: (size.height * -1)))
        pathToDraw.addLine(to: CGPoint(x:size.width, y:  (size.height * -1)))
        edge.path = pathToDraw
        edge.strokeColor = SKColor.red
        
        if let path = edge.path{
            edge.physicsBody = SKPhysicsBody(edgeChainFrom: path)
        }
        
        edge.physicsBody?.categoryBitMask = PhysicsCategory.edge
        edge.physicsBody?.contactTestBitMask = PhysicsCategory.star
        edge.physicsBody?.collisionBitMask = PhysicsCategory.star
        addChild(edge)
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addStar),
                SKAction.wait(forDuration: 1.0)
            ])
      ))
      
    //  let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
    //  backgroundMusic.autoplayLooped = true
    //  addChild(backgroundMusic)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
      
      print("didBegin called")
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
      
      if((firstBody.categoryBitMask & PhysicsCategory.star != 0) &&
          (secondBody.categoryBitMask & PhysicsCategory.edge != 0)){
          
          print("call destroyStar")
          if let star = firstBody.node as? SKSpriteNode {
              destroyStar(star: star)
          }
      }
    }
    
    func addStar(){
          
          let star = SKSpriteNode(imageNamed: "star")
          
          let scale = CGFloat.random(in: 0.1 ... 0.5)
          star.xScale = scale
          star.yScale = scale
          star.zPosition = 1.0
          
          star.physicsBody = SKPhysicsBody(rectangleOf: star.size)
          star.physicsBody?.linearDamping = 1.0
          star.physicsBody?.friction = 1.0
          
          star.physicsBody?.isDynamic = true // 2
          star.physicsBody?.categoryBitMask = PhysicsCategory.star // 3
          star.physicsBody?.contactTestBitMask = PhysicsCategory.edge // 4
          star.physicsBody?.collisionBitMask = PhysicsCategory.edge
          
          let actualX = CGFloat.random(in: (-1*size.width/2)+50 ... (size.width/2)-50)
         
          star.position = CGPoint(x: actualX, y: self.size.height)
          addChild(star)
      }
    
    func makeFox(){
        let foxAnimatedAtlas = SKTextureAtlas(named: "fox")
        var runFrames: [SKTexture] = []
        
        let numImages = foxAnimatedAtlas.textureNames.count
        
        for i in 1...numImages{
            let foxTextureName = "fox\(i)"
            runFrames.append(foxAnimatedAtlas.textureNamed(foxTextureName))
        }
        foxRunFrames = runFrames
        
        let firstFrameTexture = foxRunFrames[0]
        fox = SKSpriteNode(texture: firstFrameTexture)
        let actualY = CGFloat((size.height/2) * -1 * 0.6)
        fox.position = CGPoint(x: frame.midX, y:actualY)
        fox.xScale = 2.5
        fox.yScale = 2.5
        fox.zPosition = 1.0
        addChild(fox)
        
        if motionManager.isAccelerometerAvailable {
        motionManager.accelerometerUpdateInterval = 0.01
        motionManager.startAccelerometerUpdates(to: .main) {
            (data, error) in
            guard let data = data, error == nil else {
                return
            }
            let currentX = self.fox.position.x
            self.destX = currentX + CGFloat(data.acceleration.x * 500)
            }
        }
    }
    
    func animateFox() {
      fox.run(SKAction.repeatForever(
        SKAction.animate(with: foxRunFrames,
                         timePerFrame: 0.1,
                         resize: false,
                         restore: true)),
               withKey:"runningInPlaceFox")
    }
    
    func moveFox() {
        
        var multiplierForDirection: CGFloat = 1.0
        
        if let accelerometerData = motionManager.accelerometerData {
            if(accelerometerData.acceleration.x < 0){
                multiplierForDirection = -1.0
            }
        }
        
        fox.xScale = abs(fox.xScale) * multiplierForDirection
        
        if fox.action(forKey: "runningInPlaceFox") == nil {
            // if legs are not moving, start them
            animateFox()
            
        }

        let moveAction = SKAction.moveTo(x: destX, duration: 1)
        
        let doneAction = SKAction.run({ [weak self] in
             self?.foxMoveEnded()
           })
        
      let moveActionWithDone = SKAction.sequence([moveAction, doneAction])
      fox.run(moveActionWithDone, withKey:"foxMoving")
    }
    
    func foxMoveEnded() {
      fox.removeAllActions()
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        let action = SKAction.run({ [weak self] in
          self?.moveFox()
        })
        
        fox.run(action)
    }
    
    func destroyStar(star: SKSpriteNode){
        
        print("star destroyed")
        star.removeFromParent()
    
    }
}


