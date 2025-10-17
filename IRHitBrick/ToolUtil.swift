//
//  ToolUtil.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/17.
//

import SpriteKit
import Foundation

final class ToolUtil: SKSpriteNode {

    // MARK: - Public properties
    var isStartDownTool: Bool = false
    weak var ball: BallUtil?

    // MARK: - Private state
    private weak var ballView: MyScene?
    private var saveStickLong: CGFloat = 0
    private var toolBitmap: SKTexture?
    private var timerThread: TimerThread?
    private var whichToolType: ToolType = .ballSpeedUp

    private var toolObjLeft: CGFloat = 0
    private var toolObjTop: CGFloat = 0
    private var toolRect: CGRect = .zero

    // MARK: - Types
    private enum ToolType: Int, CaseIterable {
        case ballSpeedUp, ballSpeedDown, stickLongUp, stickLongDown,
             ballCountUpToThree, lifeUp, ballReset, stickLongMax,
             ballRadiusUp, ballRadiusDown, blackHole, ballLevelUpTwice, ballLevelDownOnce
    }

    // MARK: - Inits
    convenience init(ballView: MyScene, brickUtil: BrickUtil) {
        self.init(texture: nil, color: .clear, size: .zero)
        self.ballView = ballView
        setToolObjectXY(BrickLeft: brickUtil.left, BrickTop: brickUtil.top, BrickRight: brickUtil.right, BrickBottom: brickUtil.bottom)
        setRandomEffectType()
        setToolBitmap()
        isStartDownTool = false
    }

    /// ObjC 兼容：+ (instancetype)initWithBallView:BrickUtil:
    @objc class func initWithBallView(_ ballView: MyScene, BrickUtil brickUtil: BrickUtil) -> ToolUtil {
        return ToolUtil(ballView: ballView, brickUtil: brickUtil)
    }

    // MARK: - Setup
    private func setRandomEffectType() {
        let idx = Int.random(in: 0..<ToolType.allCases.count)
        whichToolType = ToolType(rawValue: idx) ?? .ballSpeedUp

        if whichToolType == .blackHole {
            // 若要隨機黑洞位置，可在此依場景尺寸調整 toolRect / position
        }
    }

    private func setToolObjectXY(BrickLeft: CGFloat, BrickTop: CGFloat, BrickRight: CGFloat, BrickBottom: CGFloat) {
        let height = (BrickTop - BrickBottom) * 3 / 4
        let width = height
        toolObjTop = BrickTop
        toolObjLeft = (BrickLeft + BrickRight - width) / 2
        toolRect = CGRect(x: toolObjLeft, y: toolObjTop, width: width, height: height)

        // SKSpriteNode 的 position 預設以中心錨點；原 ObjC 直接用 left/top。
        // 為保持視覺一致，這裡同樣賦值，必要時可調整 anchorPoint = (0,1)
        self.position = CGPoint(x: CGFloat(toolObjLeft), y: CGFloat(toolObjTop))
        self.size = CGSize(width: width, height: height)
    }

    private func setToolBitmap() {
        let bmp = BitmapUtil.sharedInstance
        switch whichToolType {
        case .ballSpeedUp:        toolBitmap = bmp.tool_BallSpeedUp_bmp
        case .ballSpeedDown:      toolBitmap = bmp.tool_BallSpeedDown_bmp
        case .stickLongUp:        toolBitmap = bmp.tool_StickLongUp_bmp
        case .stickLongDown:      toolBitmap = bmp.tool_StickLongDown_bmp
        case .ballCountUpToThree: toolBitmap = bmp.tool_BallCountUpToThree_bmp
        case .lifeUp:             toolBitmap = bmp.tool_LifeUp_bmp
        case .ballReset:          toolBitmap = bmp.tool_BallReset_bmp
        case .stickLongMax:       toolBitmap = bmp.tool_StickLongMax_bmp
        case .ballRadiusUp:       toolBitmap = bmp.tool_BallRadiusUp_bmp
        case .ballRadiusDown:     toolBitmap = bmp.tool_BallRadiusDown_bmp
        case .blackHole:          toolBitmap = bmp.tool_BlackHole_bmp
        case .ballLevelUpTwice:   toolBitmap = bmp.tool_BallLevelUpTwice_bmp
        case .ballLevelDownOnce:  toolBitmap = bmp.tool_BallLevelDownOnce_bmp
        }
        self.texture = toolBitmap
    }

    // MARK: - Public API
    func moveDownToolObj() {
        if whichToolType != .blackHole {
            position = CGPoint(x: position.x, y: position.y - 2)
        }
    }

    
    @discardableResult
    func doTool(_ ballUtils: inout [BallUtil], ball: BallUtil) -> ToolUtil? {
        guard let ballView = ballView else { return nil }
        self.ball = ball

        switch whichToolType {
        case .ballSpeedUp:
            ball.setSpeedX(ball.getSpeedX() * 2)
            ball.setSpeedY(ball.getSpeedY() * 2)
            if let body = ball.physicsBody {
                ball.physicsBody?.velocity = CGVector(dx: body.velocity.dx * 2, dy: body.velocity.dy * 2)
            }
            timerThread = TimerThread(time: 10)
            timerThread?.start()
            return self

        case .ballSpeedDown:
            ball.setSpeedX(ball.getSpeedX() / 2)
            ball.setSpeedY(ball.getSpeedY() / 2)
            if let body = ball.physicsBody {
                ball.physicsBody?.velocity = CGVector(dx: body.velocity.dx / 2, dy: body.velocity.dy / 2)
            }
            timerThread = TimerThread(time: 10)
            timerThread?.start()
            return self

        case .stickLongUp:
            ballView.setStickLong(ballView.getStickLong() * 1.5)
            timerThread = TimerThread(time: 10)
            timerThread?.start()
            return self

        case .stickLongDown:
            ballView.setStickLong(ballView.getStickLong() * 0.5)
            timerThread = TimerThread(time: 10)
            timerThread?.start()
            return self

        case .ballCountUpToThree:
            for _ in ballUtils.count..<3 {
                let newBall = BallUtil.initBallUtil(0, speedX: 0, speedY: 0, imageX: 0, imageY: 0, fAngle: 0, RADIUS: 10)
                ballUtils.append(newBall)
                newBall.name = ball.name
                newBall.position = ball.position
                ballView.addChild(newBall)

                newBall.physicsBody = SKPhysicsBody(circleOfRadius: newBall.frame.size.width / 2)
                newBall.physicsBody?.friction = 0.0
                newBall.physicsBody?.restitution = 1.0
                newBall.physicsBody?.linearDamping = 0.0
                newBall.physicsBody?.allowsRotation = false
                newBall.physicsBody?.applyImpulse(CGVector(dx: 10, dy: -10))
                newBall.physicsBody?.categoryBitMask = ball.physicsBody?.categoryBitMask ?? 0
                newBall.physicsBody?.contactTestBitMask = ball.physicsBody?.contactTestBitMask ?? 0
            }
            return nil

        case .lifeUp:
            ballView.setBallLife(ballView.getBallLife() + 1)
            return nil

        case .ballReset:
            DispatchQueue.main.async { [weak ballView] in ballView?.resetBall() }
            return nil

        case .stickLongMax:
            saveStickLong = ballView.getStickLong()
            ballView.setStickLong(ballView.size.width)
            timerThread = TimerThread(time: 10)
            timerThread?.start()
            return self

        case .ballRadiusUp:
            ball.xScale = 1.5
            ball.yScale = 1.5
            timerThread = TimerThread(time: 10)
            timerThread?.start()
            return self

        case .ballRadiusDown:
            ball.xScale = 0.5
            ball.yScale = 0.5
            timerThread = TimerThread(time: 10)
            timerThread?.start()
            return self

        case .blackHole:
            ball.setBallLevel(-5)
            return nil

        case .ballLevelUpTwice:
            let next = (ball.getBallLevel() > 0) ? -1 : (ball.getBallLevel() + 2)
            ball.setBallLevel(next)
            return nil

        case .ballLevelDownOnce:
            ball.setBallLevel(ball.getBallLevel() - 1)
            return nil
        }
    }


    func doToolFinish() {
        guard let ballView = ballView, let ball = ball else { return }

        switch whichToolType {
        case .ballSpeedUp:
            ball.setSpeedX(ball.getSpeedX() / 2)
            ball.setSpeedY(ball.getSpeedY() / 2)
            if let body = ball.physicsBody {
                ball.physicsBody?.velocity = CGVector(dx: body.velocity.dx / 2, dy: body.velocity.dy / 2)
            }

        case .ballSpeedDown:
            ball.setSpeedX(ball.getSpeedX() * 2)
            ball.setSpeedY(ball.getSpeedY() * 2)
            if let body = ball.physicsBody {
                ball.physicsBody?.velocity = CGVector(dx: body.velocity.dx * 2, dy: body.velocity.dy * 2)
            }

        case .stickLongUp:
            ballView.setStickLong(ballView.getStickLong() * 0.67)

        case .stickLongDown:
            ballView.setStickLong(ballView.getStickLong() * 2)

        case .stickLongMax:
            if saveStickLong > ballView.size.width - 10 {
                ballView.setStickLong(ballView.size.width / 2)
            } else {
                ballView.setStickLong(saveStickLong)
            }

        case .ballRadiusUp, .ballRadiusDown:
            ball.xScale = 1.0
            ball.yScale = 1.0

        default:
            break
        }
        return

    }

    func getToolTimerThread() -> TimerThread? {
        return timerThread
    }

    func getToolBitmap() -> SKTexture {
        return toolBitmap ?? SKTexture()
    }

    //（可選）若需要和 ObjC 一樣拿 rect：
    func getToolRect() -> CGRect { toolRect }
}
