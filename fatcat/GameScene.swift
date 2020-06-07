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

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    var background = SKSpriteNode(imageNamed:"background.jpg")
    var fox =  SKSpriteNode(imageNamed: "fox_start.png")
    
    
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
        
        let actualY = CGFloat((size.height/2) * -1 * 0.6)
        fox.xScale = 2.5
        fox.yScale = 2.5
        fox.position = CGPoint(x:0, y: actualY)
        fox.zPosition = 1.0
        addChild(fox)
        
        let edge = SKShapeNode()
        let pathToDraw = CGMutablePath()

        pathToDraw.move(to: CGPoint(x: (size.width/2 * -1), y: (size.height * -1)))
        pathToDraw.addLine(to: CGPoint(x:size.width/2, y:  (size.height * -1)))
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

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
    
    func destroyStar(star: SKSpriteNode){
        
        print("star destroyed")
        star.removeFromParent()
    
    }
}


