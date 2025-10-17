//
//  BallUtil.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/17.
//

import SpriteKit
import Foundation

final class BallUtil: SKSpriteNode {

    // MARK: - Stored state (對應 ObjC 成員)
    private var ballLevel: Int = 0
    private var speedXValue: CGFloat = 0
    private var speedYValue: CGFloat = 0
    private var imageXValue: CGFloat = 0
    private var imageYValue: CGFloat = 0
    private var angleValue: CGFloat = 0
    private var radiusValue: Int = 0
    private var isErrorLeftWallDoubleHitFlagValue: Bool = false
    private var isErrorRightWallDoubleHitFlagValue: Bool = false

    // MARK: - Factory (對應 +initBallUtil:... )
    @objc
    class func initBallUtil(_ ballLevel: Int,
                            speedX: CGFloat,
                            speedY: CGFloat,
                            imageX: CGFloat,
                            imageY: CGFloat,
                            fAngle: CGFloat,
                            RADIUS: Int) -> BallUtil {
        let bm = BitmapUtil.sharedInstance
        let idx = max(0, min(ballLevel, bm.ballTextures.count - 1))
        let tex = bm.ballTextures[idx]
        let node = BallUtil(texture: tex)
        node.ballLevel = ballLevel
        node.speedXValue = speedX
        node.speedYValue = speedY
        node.imageXValue = imageX
        node.imageYValue = imageY
        node.angleValue = fAngle
        node.radiusValue = RADIUS
        return node
    }

    // MARK: - Initializers (與 ObjC 其他 init 對應，若你需要)
    convenience init(speedX: CGFloat, speedY: CGFloat) {
        self.init(texture: nil, color: .clear, size: .zero)
        self.speedXValue = speedX
        self.speedYValue = speedY
    }

    convenience init(ballLevel: Int,
                     speedX: CGFloat,
                     speedY: CGFloat,
                     imageX: CGFloat,
                     imageY: CGFloat,
                     angle: CGFloat,
                     radius: Int) {
        self.init(texture: nil, color: .clear, size: .zero)
        self.ballLevel = ballLevel
        self.speedXValue = speedX
        self.speedYValue = speedY
        self.imageXValue = imageX
        self.imageYValue = imageY
        self.angleValue = angle
        self.radiusValue = radius
        // 若想在此即設定貼圖，可解除註解：
        // setBallLevel(ballLevel)
    }

    // MARK: - Public API (ObjC 風格對應)

    @objc func getBallLevel() -> Int { ballLevel }

    @objc func setBallLevel(_ level: Int) {
        ballLevel = level
        // 僅在 0...2 範圍內切換貼圖（沿用原始碼邏輯）
        if level >= 0 && level <= 2 {
            let bm = BitmapUtil.sharedInstance
            if level < bm.ballTextures.count {
                self.texture = bm.ballTextures[level]
            }
        }
    }

    @objc func getSpeedX() -> CGFloat { speedXValue }
    @objc func setSpeedX(_ v: CGFloat) { speedXValue = v }

    @objc func getSpeedY() -> CGFloat { speedYValue }
    @objc func setSpeedY(_ v: CGFloat) { speedYValue = v }

    @objc func getImageX() -> CGFloat { imageXValue }
    @objc func setImageX(_ v: CGFloat) { imageXValue = v }

    @objc func getImageY() -> CGFloat { imageYValue }
    @objc func setImageY(_ v: CGFloat) { imageYValue = v }

    @objc func getAngle() -> CGFloat { angleValue }
    @objc func setAngle(_ v: CGFloat) { angleValue = v }

    @objc func getRadius() -> Int { radiusValue }
    @objc func setRadius(_ v: Int) { radiusValue = v }

    @objc func getIsErrorLeftWallDoubleHitFlag() -> Bool { isErrorLeftWallDoubleHitFlagValue }
    @objc func setIsErrorLeftWallDoubleHitFlag(_ v: Bool) { isErrorLeftWallDoubleHitFlagValue = v }

    @objc func getIsErrorRightWallDoubleHitFlag() -> Bool { isErrorRightWallDoubleHitFlagValue }
    @objc func setIsErrorRightWallDoubleHitFlag(_ v: Bool) { isErrorRightWallDoubleHitFlagValue = v }
}
