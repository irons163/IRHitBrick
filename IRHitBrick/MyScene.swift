//
//  MyScene.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/12.
//

import SpriteKit
import Foundation

class BallViewConfig {
    static let sharedInstance = BallViewConfig()
    var gameFlag: Bool = true
    var waitGameSuccessProcessing: Bool = false
    var GAME_PAUSE_FLAG: Bool = false
}

// MARK: - Bit masks & constants
let N: Int = 4

private let BRICK_LEVEL_DOWN_SCORE = 300
private let BRICK_IRON_LEVEL_DOWN_SCORE = 500
private let BRICK_CLEAR_SCORE = 1000
private let BRICK_COMBO_SCORE = 100
private let BRICK_IRON_CLEAR_SCORE = 1500

private let MAX_LEVEL = 10
private let GAME_TIME = 60
private let CHANGE_MUSIC_TIME = 30
private let InitRadius: Int = 20
private let Init_THICK_OF_STICK: Int = 100
private let ballInitLife = 2 // 剩餘兩顆
private let BALL_LIFE_UP = 1
private let BALL_LIFE_DOWN = -1
private let BALL_LIFE_SHOW_COUNT = 100

// MARK: - Helper MyRect (Objective‑C macro -> Swift helper)
struct MyRect {
    var left: Int
    var top: Int
    var right: Int
    var bottom: Int
    static func make(left: Int, top: Int, right: Int, bottom: Int) -> MyRect { .init(left: left, top: top, right: right, bottom: bottom) }
    var cgRect: CGRect { CGRect(x: left, y: top, width: right - left, height: bottom - top) }
}

final class MyScene: SKScene, SKPhysicsContactDelegate {

    enum Constants {
        static let ballCategory: UInt32   = 0x1 << 0
        static let bottomCategory: UInt32 = 0x1 << 1
        static let blockCategory: UInt32  = 0x1 << 2
        static let paddleCategory: UInt32 = 0x1 << 3
        static let toolCategory: UInt32   = 0x1 << 4

        static let ballCategoryName = "ball"
        static let paddleCategoryName = "paddle"
        static let blockCategoryName = "block"
        static let blockNodeCategoryName = "blockNode"
    }

    // MARK: Public API (translated from @property and methods)
    var hitBrickLevelDownCount: Int = 0
    var hitIronBrickLevelDownCount: Int = 0
    weak var gameDelegate: GameDelegate?

    class func blockCategory() -> UInt32 { Constants.blockCategory }
    class func blockCategoryName() -> String { Constants.blockCategoryName }

    class func make(size: CGSize, playGameLevel: Int, with viewController: ViewController) -> MyScene {
        let scene = MyScene(size: size)
        scene.physicsWorld.contactDelegate = scene
        scene.playGameLevel = playGameLevel
        scene.iNumBricks = N * N
        scene.widthScreen = size.width
        scene.heightScreen = size.height
        BrickMaxConfig.sharedInstance.setBrickMaxConfigEnable(true, PlayGameLevel: playGameLevel)
        //磚塊初始化
        for i in 0..<N {
            for j in 0..<N {
                scene.bRbOn[i][j] = true
                let brick = BrickUtil()
                scene.rBrick[i][j] = brick
                scene.addChild(brick)
                let top = scene.heightScreen - scene.heightScreen * CGFloat(i) / CGFloat(N) / 3
                let bottom = scene.heightScreen - scene.heightScreen * CGFloat(i + 1) / CGFloat(N) / 3
                brick.setPlayGameLevel(playGameLevel,
                                       left: scene.widthScreen * CGFloat(j) / CGFloat(N),
                                       top: top,
                                       right: scene.widthScreen * CGFloat(j + 1) / CGFloat(N),
                                       bottom: bottom)
            }
        }
        scene.ballViewConfig = BallViewConfig.sharedInstance
        scene.ballViewConfig.waitGameSuccessProcessing = false
        return scene
    }

    func getBallLevel() -> Int { ballLevel }
    func setStickLong(_ stickLong: CGFloat) {
        guard let paddle = childNode(withName: Constants.paddleCategoryName) as? SKSpriteNode else { return }
        paddle.size = CGSize(width: stickLong, height: paddle.size.height)
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.frame.size)
        paddle.physicsBody?.restitution = 1.0
        paddle.physicsBody?.friction = 0.0
        paddle.physicsBody?.isDynamic = false
        paddle.physicsBody?.categoryBitMask = Constants.paddleCategory
    }
    func getStickLong() -> CGFloat { (childNode(withName: Constants.paddleCategoryName) as? SKSpriteNode)?.size.width ?? 0 }
    func setBallLife(_ life: Int) { setBallLifeInternal(life) }
    func getBallLife() -> Int { ballLife }
    func resetBall() { resetBallInternal() }

    // MARK: Private state
    private var isFingerOnPaddle = false

    private var rBrick: [[BrickUtil?]] = Array(repeating: Array(repeating: nil, count: N), count: N)
    private var iNumBricks: Int = 0
    private var bRbOn: [[Bool]] = Array(repeating: Array(repeating: false, count: N), count: N)
    private var playGameLevel: Int = 0
    private var widthScreen: CGFloat = 0
    private var heightScreen: CGFloat = 0
    private var ballViewConfig: BallViewConfig = .sharedInstance

    private var toolUtils: [ToolUtil] = []
    private var ballUtils: [BallUtil] = []
    private var showToolEffectTime: [ToolUtil] = []
    private var showTimeBrickEffectTime: [EffectUtil] = []
    private var showToolEffectTimeNodes: [[SKSpriteNode]] = [] // [icon, ten, single, s]
    private var showTimeBrickEffectTimeNodes: [[SKSpriteNode]] = [] // [icon, ten, single, s]

    private var bitmapUtil: BitmapUtil = .sharedInstance

    private var clearBrickCount = 0
    private var comboCount = 0
    private var comboScoreCount = 0
    private var clearIronBrickCount = 0

    private var score = 0
    private var lastTimeCount = 0
    private var increaseScroe = 0

    private var scroeTextView = SKLabelNode(text: "0")
    private var increaseScroeTextView = SKLabelNode(text: "0")
    private var gameTimeHundredsCountNode = SKSpriteNode()
    private var gameTimeTensCountNode = SKSpriteNode()
    private var gameTimeSingleDigitsCountNode = SKSpriteNode()
    private var gameTimeNode = SKSpriteNode()

    private var isFirstDoGameFinish = false

    private var ballIconNode = SKSpriteNode()
    private var ballCHangeLabelNode = SKLabelNode(text: "")

    private var isBallLifeChange = false
    private var ballLifeChange = 0
    private var ballLifeShowBmpCount = 0
    private var ballLifeNode = SKLabelNode(text: "0")
    private var gameSuccessFlag = false

    private var timer: Timer?
    private var ballLevel: Int = 0
    private var readyFlag = false
    private var readyAlertBox = SKSpriteNode()
    private var paddle = SKSpriteNode()
    private var paddleOriginalSize = CGSize.zero

    private var ballLife: Int = 0

    private var ball_isRun = false
    private var RADIUS: Int = InitRadius
    private var THICK_OF_STICK: Int = Init_THICK_OF_STICK

    private var imageX: CGFloat = -50
    private var imageY: CGFloat = -50
    private var fAngle: CGFloat = 0
    private var speedY: CGFloat = -15
    private var speedX: CGFloat = -15

    private var waitGameSuccessProcessing = false
    private var gameFlag = true

    private var ball: BallUtil!

    // MARK: - Scene life cycle
    override init(size: CGSize) {
        super.init(size: size)
        initGame()

        let background = SKSpriteNode(imageNamed: "bg")
        background.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        addChild(background)

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        let borderBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: frame.origin.x, y: frame.origin.y - 50, width: frame.size.width, height: frame.size.height + 50))
        physicsBody = borderBody
        physicsBody?.friction = 0.0

        paddle = SKSpriteNode(imageNamed: "paddle")
        paddle.name = Constants.paddleCategoryName
        paddleOriginalSize = paddle.size
        paddle.position = CGPoint(x: frame.midX, y: paddle.frame.size.height * 0.6)
        addChild(paddle)

        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.frame.size)
        paddle.physicsBody?.restitution = 1.0
        paddle.physicsBody?.friction = 0.0
        paddle.physicsBody?.isDynamic = false

        resetBallInternal()

        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y - (ball?.size.height ?? 20), width: frame.size.width, height: 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        addChild(bottom)

        bottom.physicsBody?.categoryBitMask = Constants.bottomCategory
        paddle.physicsBody?.categoryBitMask = Constants.paddleCategory

        physicsWorld.contactDelegate = self
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        if readyFlag { shootBall(touchLocation) }
        if let body = physicsWorld.body(at: touchLocation),
           body.node?.name == Constants.paddleCategoryName {
            isFingerOnPaddle = true
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isFingerOnPaddle, let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let previousLocation = touch.previousLocation(in: self)
        guard let paddle = childNode(withName: Constants.paddleCategoryName) as? SKSpriteNode else { return }
        var paddleX = paddle.position.x + (touchLocation.x - previousLocation.x)
        paddleX = max(paddleX, paddle.size.width/2)
        paddleX = min(paddleX, size.width - paddle.size.width/2)
        paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
        if readyFlag {
            ball.position = CGPoint(x: paddle.position.x, y: paddle.position.y + paddle.size.height)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFingerOnPaddle = false
    }

    // MARK: - Physics Contact
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody: SKPhysicsBody
        let secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA; secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB; secondBody = contact.bodyA
        }

        // ball vs bottom
        if firstBody.categoryBitMask == Constants.ballCategory && secondBody.categoryBitMask == Constants.bottomCategory {
            if !gameFlag { return }
            if !gameSuccessFlag {
                let maxLevel = UserDefaults.standard.integer(forKey: "level")
                if maxLevel < MAX_LEVEL && playGameLevel >= maxLevel {
                    UserDefaults.standard.set(maxLevel + 1, forKey: "level")
                }
                if ballUtils.count <= 1,
                   let ballNode = firstBody.node as? BallUtil,
                   ballUtils.contains(where: { $0 === ballNode }) {
                    if ballLife <= 0 {
                        gameOver()
                    } else {
                        ballLife -= 1
                        setBallLifeInternal(ballLife)
                        resetBall()
                    }
                } else {
                    if let ballNode = firstBody.node as? BallUtil, let idx = ballUtils.firstIndex(where: { $0 === ballNode }) {
                        ballUtils.remove(at: idx)
                    }
                    firstBody.node?.removeFromParent()
                }
                return
            }
//            gameDelegate?.showLoseDialog(score: score)
        }

        // ball vs block
        if firstBody.categoryBitMask == Constants.ballCategory && secondBody.categoryBitMask == Constants.blockCategory {
            if let brick = secondBody.node as? BrickUtil, let ballNode = firstBody.node as? BallUtil {
                brick.doHitEffect(ballNode, showTimeBrickEffectTime: &showTimeBrickEffectTime)
                if !brick.isBrickExist() {
                    brick.removeFromParent()
                    if brick.isHitIronBrick { clearIronBrickCount += 1 } else { clearBrickCount += 1 }
                }
                if !brick.isIronsBrick || brick.isHitIronBrick { comboCount += 1 }
                let effect = brick.getEffect()
                if effect.isHasTool() { toolUtils.append(effect.getToolObj()!) }
                if isGameWon() { gameSuccess() }
            }
        }

        // ball vs tool
        if firstBody.categoryBitMask == Constants.ballCategory && secondBody.categoryBitMask == Constants.toolCategory {
            scene?.isPaused = true
        }

        // ball vs paddle
        if firstBody.categoryBitMask == Constants.ballCategory && secondBody.categoryBitMask == Constants.paddleCategory {
            comboCount = -1
            comboScoreCount = 0
        }
    }

    private func isGameWon() -> Bool {
        var numberOfBricks = 0
        for node in children where node.name == Constants.blockCategoryName { numberOfBricks += 1 }
        return numberOfBricks <= 0
    }

    // MARK: - Frame update
    override func update(_ currentTime: TimeInterval) {
        if let ball = childNode(withName: Constants.ballCategoryName) as? SKSpriteNode {
            let maxSpeed: CGFloat = 1000
            let v = ball.physicsBody?.velocity ?? .zero
            let speed = sqrt(v.dx * v.dx + v.dy * v.dy)
            ball.physicsBody?.linearDamping = speed > maxSpeed ? 0.4 : 0.0
        }
        checkGameTime()
        if !gameFlag { return }

        // move tools
        var i = 0
        while i < toolUtils.count {
            let tool = toolUtils[i]
            tool.moveDownToolObj()
            if tool.position.y < 0 {
                toolUtils.remove(at: i)
                tool.removeFromParent()
            } else {
                i += 1
            }
        }
        checkHitTool()
        drawToolEffectTime()
        drawTimeBrickEffectTime()
        checkGameEnd()
    }

    // MARK: - Tools collisions & UI
    private func checkHitTool() {
        var hit = false
        var i = 0
        while i < toolUtils.count {
            let tool = toolUtils[i]
            for ball in ballUtils {
                if ball.calculateAccumulatedFrame().intersects(tool.calculateAccumulatedFrame()) {
                    if let eff = tool.doTool(&ballUtils, ball: ball) { showToolEffectTime.append(eff) }
                    tool.removeFromParent()
                    toolUtils.remove(at: i)
                    hit = true
                    break
                }
            }
            if hit { break }
            i += 1
        }
    }

    private func drawToolEffectTime() {
        let effectItemWidth = 20
        let effectItemHeight = 20
        var i = 0
        while i < showToolEffectTime.count {
            let tool = showToolEffectTime[i]
            let time = tool.getToolTimerThread()!.getCurrentTime()
            let icon = tool.getToolBitmap()
            let tens = getTimeTexture(time / 10)
            let ones = getTimeTexture(time % 10)
            let sTex = SKTexture(imageNamed: "second_s")

            let nodes: [SKSpriteNode] = {
                if i < showToolEffectTimeNodes.count { return showToolEffectTimeNodes[i] }
                let a = [SKSpriteNode(), SKSpriteNode(), SKSpriteNode(), SKSpriteNode()]
                a.forEach(addChild(_:))
                showToolEffectTimeNodes.append(a)
                return a
            }()
            let iconNode = nodes[0]
            let tensNode = nodes[1]
            let onesNode = nodes[2]
            let sNode = nodes[3]

            // layout rects
            var temp = MyRect.make(left: Int(widthScreen) - effectItemWidth * 4 - 10,
                                   top: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * (i + 1) - 50 + 10,
                                   right: Int(widthScreen) - effectItemWidth * 3 - 10,
                                   bottom: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * i - 50)
            let rectIcon = temp.cgRect

            temp = MyRect.make(left: Int(widthScreen) - effectItemWidth * 3 - 10,
                               top: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * (i + 1) - 50 + 10,
                               right: Int(widthScreen) - effectItemWidth * 2 - 10,
                               bottom: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * i - 50)
            let rectTens = temp.cgRect

            temp = MyRect.make(left: Int(widthScreen) - effectItemWidth * 2 - 10,
                               top: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * (i + 1) - 50 + 10,
                               right: Int(widthScreen) - effectItemWidth - 10,
                               bottom: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * i - 50)
            let rectOnes = temp.cgRect

            temp = MyRect.make(left: Int(widthScreen) - effectItemWidth - 10,
                               top: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * (i + 1) - 50 + 10,
                               right: Int(widthScreen) - 10,
                               bottom: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * i - 50)
            let rectS = temp.cgRect

            iconNode.texture = icon
            tensNode.texture = tens
            onesNode.texture = ones
            sNode.texture = sTex

            iconNode.position = rectIcon.origin
            tensNode.position = rectTens.origin
            onesNode.position = rectOnes.origin
            sNode.position = rectS.origin

            iconNode.size = rectIcon.size
            tensNode.size = rectTens.size
            onesNode.size = rectTens.size
            sNode.size = rectS.size

            if time != 0 {
                // same layout/textures (kept for parity with ObjC)
            } else {
                let alpha = max(0, sNode.alpha - 0.05)
                [iconNode, tensNode, onesNode, sNode].forEach { $0.alpha = alpha }
                if alpha <= 0 {
                    tool.doToolFinish()
                    showToolEffectTime.remove(at: i)
                    showToolEffectTimeNodes.remove(at: i)
                    [iconNode, tensNode, onesNode, sNode].forEach { $0.removeFromParent() }
                    i -= 1
                }
            }
            i += 1
        }
    }

    private func drawTimeBrickEffectTime() {
        let effectItemWidth = 20
        let effectItemHeight = 20
        var i = 0
        while i < showTimeBrickEffectTime.count {
            let eff = showTimeBrickEffectTime[i]
            let time = eff.getToolTimerThread()!.getCurrentTime()
            let icon = bitmapUtil.brick_time_bmp
            let tens = getTimeTexture(time / 10)
            let ones = getTimeTexture(time % 10)
            let sTex = SKTexture(imageNamed: "second_s")

            let nodes: [SKSpriteNode] = {
                if i < showTimeBrickEffectTimeNodes.count { return showTimeBrickEffectTimeNodes[i] }
                let a = [SKSpriteNode(), SKSpriteNode(), SKSpriteNode(), SKSpriteNode()]
                a.forEach(addChild(_:))
                showTimeBrickEffectTimeNodes.append(a)
                return a
            }()
            let iconNode = nodes[0]
            let tensNode = nodes[1]
            let onesNode = nodes[2]
            let sNode = nodes[3]

            var temp = MyRect.make(left: 0 + effectItemWidth/2 + 10,
                                   top: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * (i + 1) - 50 + 10,
                                   right: 0 + effectItemWidth * 2 + 10,
                                   bottom: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * i - 50)
            let rectIcon = temp.cgRect

            temp = MyRect.make(left: 0 + effectItemWidth * 2 + 10,
                               top: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * (i + 1) - 50 + 10,
                               right: 0 + effectItemWidth * 3 + 10,
                               bottom: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * i - 50)
            let rectTens = temp.cgRect

            temp = MyRect.make(left: 0 + effectItemWidth * 3 + 10,
                               top: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * (i + 1) - 50 + 10,
                               right: 0 + effectItemWidth * 4 + 10,
                               bottom: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * i - 50)
            let rectOnes = temp.cgRect

            temp = MyRect.make(left: 0 + effectItemWidth * 4 + 10,
                               top: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * (i + 1) - 50 + 10,
                               right: 0 + effectItemWidth * 5 + 10,
                               bottom: Int(heightScreen/1.5) - THICK_OF_STICK - (effectItemHeight + 10) * i - 50)
            let rectS = temp.cgRect

            iconNode.texture = icon
            tensNode.texture = tens
            onesNode.texture = ones
            sNode.texture = sTex

            iconNode.position = rectIcon.origin
            tensNode.position = rectTens.origin
            onesNode.position = rectOnes.origin
            sNode.position = rectS.origin

            iconNode.size = rectIcon.size
            tensNode.size = rectTens.size
            onesNode.size = rectTens.size
            sNode.size = rectS.size

            if time != 0 {
                // same layout/textures
            } else {
                let alpha = max(0, sNode.alpha - 0.05)
                [iconNode, tensNode, onesNode, sNode].forEach { $0.alpha = alpha }
                if alpha <= 0 {
                    eff.doEffectFinish(&ballUtils)
                    showTimeBrickEffectTime.remove(at: i)
                    showTimeBrickEffectTimeNodes.remove(at: i)
                    [iconNode, tensNode, onesNode, sNode].forEach { $0.removeFromParent() }
                    i -= 1
                }
            }
            i += 1
        }
    }

    private func initBallLifeNode() {
        ballLifeNode = SKLabelNode(text: "\(ballLife)")
        ballLifeNode.position = CGPoint(x: 280, y: 0)
        addChild(ballLifeNode)
    }

    private func initBallLifeChangeNodes() {
        ballIconNode = SKSpriteNode(texture: nil)
        ballCHangeLabelNode = SKLabelNode(text: "011")
        ballIconNode.position = CGPoint(x: ballLifeNode.position.x - 25, y: ballLifeNode.position.y)
        ballCHangeLabelNode.position = ballLifeNode.position
        ballIconNode.zPosition = 1
        ballCHangeLabelNode.zPosition = 1
        ballIconNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        ballIconNode.alpha = 0
        ballCHangeLabelNode.alpha = 0
        ballCHangeLabelNode.fontColor = .red
        addChild(ballIconNode)
        addChild(ballCHangeLabelNode)
    }

    private func initGameTimeNode() {
        [gameTimeHundredsCountNode, gameTimeTensCountNode, gameTimeSingleDigitsCountNode, gameTimeNode].forEach { addChild($0) }
    }

    // MARK: - Time & Scoring
    private var count: Int = 0

    private func checkGameTime() {
        let timeTextureSize = CGSize(width: 30, height: 30)
        var temp = MyRect.make(left: 0, top: 60, right: Int(timeTextureSize.width), bottom: Int(timeTextureSize.height) + 60)
        let rectHundreds = temp.cgRect
        temp = MyRect.make(left: Int(timeTextureSize.width), top: 60, right: Int(timeTextureSize.width) * 2, bottom: Int(timeTextureSize.height) + 60)
        let rectTens = temp.cgRect
        temp = MyRect.make(left: Int(timeTextureSize.width) * 2, top: 60, right: Int(timeTextureSize.width) * 3, bottom: Int(timeTextureSize.height) + 60)
        let rectOnes = temp.cgRect
        temp = MyRect.make(left: Int(timeTextureSize.width) * 3, top: 60, right: Int(timeTextureSize.width) * 4, bottom: Int(timeTextureSize.height) + 60)
        let rectS = temp.cgRect

        countScore()

        let hundredsTex = getTimeTexture((count / 100) % 10)
        let tensTex = getTimeTexture((count / 10) % 10)
        let onesTex = getTimeTexture(count % 10)
        let sTex = SKTexture(imageNamed: "second_s")

        gameTimeHundredsCountNode.texture = hundredsTex
        gameTimeTensCountNode.texture = tensTex
        gameTimeSingleDigitsCountNode.texture = onesTex
        gameTimeNode.texture = sTex

        gameTimeHundredsCountNode.position = rectHundreds.origin
        gameTimeTensCountNode.position = rectTens.origin
        gameTimeSingleDigitsCountNode.position = rectOnes.origin
        gameTimeNode.position = rectS.origin

        gameTimeHundredsCountNode.size = rectHundreds.size
        gameTimeTensCountNode.size = rectTens.size
        gameTimeSingleDigitsCountNode.size = rectOnes.size
        gameTimeNode.size = rectS.size

        if count == CHANGE_MUSIC_TIME && !waitGameSuccessProcessing {
            // swap music here if needed
        }

        if count <= 0 && isFirstDoGameFinish {
            isFirstDoGameFinish = false
            if waitGameSuccessProcessing {
                waitGameSuccessProcessing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showWinView()
                }
            }
        }
    }

    private func gameSuccess() {
        gameFlag = false
        waitGameSuccessProcessing = true
        lastTimeCount = count
        paddle.isUserInteractionEnabled = false
        gameDelegate?.showWinDialog()
        gameSuccessFlag = true
    }

    private func showWinView() {
        gameDelegate?.showWinDialog()
    }

    private func gameOver() {
        gameFlag = false
        gameDelegate?.showLoseDialog(score: score)
        isPaused = true
    }

    private func checkGameEnd() {
        var ballNum = 0
        while ballNum < ballUtils.count {
            let b = ballUtils[ballNum]
            ballLevel = b.getBallLevel()
            RADIUS = Int(b.size.width / 2)
            if ballLevel <= -1 {
                ballUtils.remove(at: ballNum)
                b.removeFromParent()
                if ballUtils.isEmpty {
                    setBallLifeInternal(ballLife - 1)
                    if ballLife < 0 { gameOver() } else { resetBallInternal(); setReadyAlertBox(true) }
                    return
                }
            }
            if iNumBricks == 0 { gameSuccess(); return }
            else if ballLife < 0 { gameOver(); return }
            ballNum += 1
        }
    }

    private func countScore() {
        if !waitGameSuccessProcessing {
            increaseScroe += hitIronBrickLevelDownCount * BRICK_IRON_LEVEL_DOWN_SCORE
            increaseScroe += hitBrickLevelDownCount * BRICK_LEVEL_DOWN_SCORE
            increaseScroe += clearBrickCount * BRICK_CLEAR_SCORE
            increaseScroe += clearIronBrickCount * BRICK_IRON_CLEAR_SCORE
            let deltaCombo = (comboCount - comboScoreCount) * BRICK_COMBO_SCORE
            increaseScroe += max(0, deltaCombo)
            score += increaseScroe
        } else {
            Thread.sleep(forTimeInterval: 0.2)
            count -= 1
            increaseScroe += ((lastTimeCount - count) * 100)
            score += 100
        }

        scroeTextView.text = "\(score)"
        if increaseScroe != 0 {
            if increaseScroeTextView.hasActions() {
                increaseScroeTextView.removeAllActions()
                increaseScroeTextView.alpha = 1
                increaseScroeTextView.position = CGPoint(x: scroeTextView.position.x, y: scroeTextView.position.y + 30)
            } else {
                increaseScroeTextView.position = scroeTextView.position
                increaseScroeTextView.alpha = 0
                increaseScroeTextView.text = "\(increaseScroe)"
                increaseScroe = 0
                let move = SKAction.moveBy(x: 0, y: 3, duration: 0.1)
                let alpha = SKAction.run { self.increaseScroeTextView.alpha += 0.1 }
                let increaseScoreAction = SKAction.repeat(SKAction.sequence([alpha, move]), count: 10)
                let end = SKAction.run {
                    self.increaseScroeTextView.alpha = 0
                    self.increaseScroeTextView.position = self.scroeTextView.position
                }
                increaseScroeTextView.run(.sequence([increaseScoreAction, end]))
            }
        }

        hitIronBrickLevelDownCount = 0
        hitBrickLevelDownCount = 0
        clearBrickCount = 0
        clearIronBrickCount = 0
        if comboCount > 0 { comboScoreCount = comboCount }
    }

    // MARK: - Init & Timer
    private func initGame() {
        comboCount = -1
        count = GAME_TIME
        ballLife = ballInitLife
        isFirstDoGameFinish = true
        isBallLifeChange = false
        ballLifeShowBmpCount = BALL_LIFE_SHOW_COUNT
        ball_isRun = true
        gameFlag = true

        bitmapUtil = .sharedInstance
        ballViewConfig = .sharedInstance
        ballViewConfig.gameFlag = true
        ballViewConfig.waitGameSuccessProcessing = false
        ballViewConfig.GAME_PAUSE_FLAG = false

        toolUtils = []
        ballUtils = []
        showToolEffectTime = []
        showTimeBrickEffectTime = []
        showToolEffectTimeNodes = []
        showTimeBrickEffectTimeNodes = []

        scroeTextView = SKLabelNode(text: "\(score)")
        scroeTextView.position = CGPoint(x: 100, y: 10)
        addChild(scroeTextView)

        increaseScroeTextView = SKLabelNode(text: "\(increaseScroe)")
        increaseScroeTextView.position = scroeTextView.position
        addChild(increaseScroeTextView)
        increaseScroeTextView.alpha = 0
        increaseScroeTextView.fontColor = .red

        initBallLifeNode()
        initBallLifeChangeNodes()
        initGameTimeNode()
    }

    private func initTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }

    private func tick() {
        if !gameFlag { timer?.invalidate(); timer = nil }
        if isPaused { return }
        if count < 0 { gameOver(); return }
        if gameFlag && !waitGameSuccessProcessing { count -= 1 }
        else if waitGameSuccessProcessing {
            ball_isRun = false
            gameOver()
        }
    }

    // MARK: - Ready/Reset/Shoot
    private func onSizeChanged() {
        widthScreen = frame.size.width
        heightScreen = frame.size.height
    }

    private func initReadyAlertBox() {
        readyFlag = true
        readyAlertBox = SKSpriteNode(texture: SKTexture(imageNamed: "TapToStart"), size: CGSize(width: 80, height: 50))
        readyAlertBox.position = CGPoint(x: frame.size.width/2, y: 100)
        readyAlertBox.anchorPoint = CGPoint(x: 0.5, y: 0)
        readyAlertBox.zPosition = 1
        addChild(readyAlertBox)
    }

    private func setReadyAlertBox(_ willChangeToReady: Bool) {
        readyFlag = willChangeToReady
        readyAlertBox.isHidden = !readyFlag
    }

    private func shootBall(_ touchPoint: CGPoint) {
        let length: CGFloat = sqrt(10*10 + 10*10)
        let radians = pointPairToBearingRadians(ball.position, secondPoint: touchPoint)
        let vX = cos(radians) * length
        let vY = sin(radians) * length
        ball.physicsBody?.applyImpulse(CGVector(dx: vX, dy: vY))
        setReadyAlertBox(false)
        initTimer()
    }

    private func resetBallInternal() {
        // 1) 清掉 tool/time 效果節點與清單
        clearEffectLists()

        // 2) 重設球的位置基準
        imageX = widthScreen / 2
        imageY = heightScreen - CGFloat(THICK_OF_STICK + RADIUS) - 1

        // 3) 移除舊球並建立新球
        ballUtils.forEach { $0.removeFromParent() }
        ballUtils.removeAll(keepingCapacity: true)

        ball = makeBall(level: 0,
                        speedX: speedX,
                        speedY: speedY,
                        at: CGPoint(x: paddle.position.x,
                                    y: paddle.position.y + paddle.size.height))

        ballUtils.append(ball)

        // 4) 重置計分/組合狀態與板子尺寸
        hitIronBrickLevelDownCount = 0
        hitBrickLevelDownCount = 0
        clearBrickCount = 0
        clearIronBrickCount = 0
        comboCount = -1
        comboScoreCount = 0

        paddle.size = paddleOriginalSize

        initReadyAlertBox()
    }

    // 安全清空兩組效果：倒序刪除，並把對應節點從場景移除
    private func clearEffectLists() {
        precondition(Thread.isMainThread)
        // ---- Tool effects: 成對彈出，確保同步 ----
        while let nodes = showToolEffectTimeNodes.popLast(),
              let tool  = showToolEffectTime.popLast() {

            // 收尾：取消計時、還原狀態
            tool.getToolTimerThread()?.cancel()
            tool.doToolFinish()

            // 移除對應 UI 節點與 tool 節點
            nodes.forEach { $0.removeFromParent() }
            tool.removeFromParent()
        }

        // 若長度不同，清掉剩餘孤兒（保險）
        while let nodes = showToolEffectTimeNodes.popLast() {
            nodes.forEach { $0.removeFromParent() }
        }
        while let leftover = showToolEffectTime.popLast() {
            leftover.getToolTimerThread()?.cancel()
            leftover.removeFromParent()
        }

        // ---- Time-brick effects（若成對陣列，一樣可用成對彈出）----
        while let nodes = showTimeBrickEffectTimeNodes.popLast() {
            nodes.forEach { $0.removeFromParent() }
        }
        // 如果有對應效果物件陣列，也一起清：
        while let effect = showTimeBrickEffectTime.popLast() {
            // 視你的 EffectUtil 需求：例如取消計時/收尾
            effect.getToolTimerThread()?.cancel()
            effect.doEffectFinish(&ballUtils) // 若需要還原球狀態；沒有就移除下一行即可
            //（沒有節點可移，略）
        }
    }

    // 建立並配置一顆球
    @discardableResult
    private func makeBall(level: Int,
                          speedX: CGFloat,
                          speedY: CGFloat,
                          at position: CGPoint) -> BallUtil {
        let b = BallUtil.initBallUtil(level,
                                      speedX: speedX,
                                      speedY: speedY,
                                      imageX: imageX,
                                      imageY: imageY,
                                      fAngle: fAngle,
                                      RADIUS: RADIUS)
        b.name = Constants.ballCategoryName
        b.position = position
        addChild(b)

        let pb = SKPhysicsBody(circleOfRadius: b.frame.size.width / 2)
        pb.friction = 0
        pb.restitution = 1
        pb.linearDamping = 0
        pb.allowsRotation = false
        pb.categoryBitMask = Constants.ballCategory
        pb.contactTestBitMask = Constants.bottomCategory | Constants.blockCategory | Constants.paddleCategory
        b.physicsBody = pb

        return b
    }

    // MARK: - Geometry helpers
    private func pointPairToBearingRadians(_ startingPoint: CGPoint, secondPoint endingPoint: CGPoint) -> CGFloat {
        let originPoint = CGPoint(x: endingPoint.x - startingPoint.x, y: endingPoint.y - startingPoint.y)
        return atan2(originPoint.y, originPoint.x)
    }

    private func pointPairToBearingDegrees(_ startingPoint: CGPoint, secondPoint endingPoint: CGPoint) -> CGFloat {
        let radians = pointPairToBearingRadians(startingPoint, secondPoint: endingPoint)
        var degrees = radians * (180.0 / .pi)
        degrees = (degrees > 0.0 ? degrees : (360.0 + degrees))
        return degrees
    }

    private func getTimeTexture(_ time: Int) -> SKTexture {
        let idx = max(0, min(9, time))
        return bitmapUtil.timeTextures[idx]
    }

    // MARK: - Ball life UI/logic
    private func setBallLifeInternal(_ life: Int) {
        let prev = ballLife
        ballLife = life
        if ballLife > prev {
            ballLifeShowBmpCount = BALL_LIFE_SHOW_COUNT
            isBallLifeChange = true
            ballLifeChange = BALL_LIFE_UP
        } else if ballLife < prev {
            ballLifeShowBmpCount = BALL_LIFE_SHOW_COUNT
            isBallLifeChange = true
            ballLifeChange = BALL_LIFE_DOWN
        } else {
            ballLifeChange = 0
        }
        let changeString = ballLifeChange >= 0 ? " +\(ballLifeChange)" : " \(ballLifeChange)"
        ballCHangeLabelNode.text = changeString

        let move = SKAction.moveBy(x: 0, y: 3, duration: 0.1)
        let alpha = SKAction.run { self.ballCHangeLabelNode.alpha += 0.1 }
        let increaseAction = SKAction.repeat(SKAction.sequence([alpha, move]), count: 10)
        let end = SKAction.run {
            self.ballCHangeLabelNode.alpha = 0
            self.ballCHangeLabelNode.position = self.ballLifeNode.position
        }
        ballCHangeLabelNode.run(.sequence([increaseAction, end]))
        ballIconNodeAnimation()
        ballLifeNode.text = "\(ballLife)"
    }

    private func ballIconNodeAnimation() {
        let move = SKAction.moveBy(x: 0, y: 3, duration: 0.1)
        let alpha = SKAction.run { self.ballIconNode.alpha += 0.1 }
        let increaseAction = SKAction.repeat(SKAction.sequence([alpha, move]), count: 10)
        let end = SKAction.run {
            self.ballIconNode.alpha = 0
            self.ballIconNode.position = CGPoint(x: self.ballLifeNode.position.x - 20, y: self.ballLifeNode.position.y)
        }
        ballIconNode.run(.sequence([increaseAction, end]))
    }
}
