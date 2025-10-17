//
//  BrickUtil.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/16.
//

import SpriteKit

class BrickUtil: SKSpriteNode {

    private enum BrickType: Int {
        case once = 0
        case twice = 1
        case three = 2
        case iron = 3
        case time = 4
        case tool = 5
        case ballLevelUp = 6
    }
    private var whichBrickType: BrickType = .once
    private var rect: CGRect = .zero
    var left: CGFloat = 0
    var top: CGFloat = 0
    var right: CGFloat = 0
    var bottom: CGFloat = 0
    var bitmap: SKTexture?
    var effectUtil: EffectUtil = EffectUtil()

    private let bitmapUtil: BitmapUtil = .sharedInstance
    var isHitIronBrick: Bool = false
    var isIronsBrick: Bool = false

    convenience init() {
        let tex = SKTexture(imageNamed: "block")
        self.init(texture: tex, color: .clear, size: tex.size())

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.allowsRotation = false
        physicsBody?.friction = 0.0
        physicsBody?.density = 0.0
        name = MyScene.blockCategoryName()
        physicsBody?.categoryBitMask = MyScene.blockCategory()
        physicsBody?.isDynamic = false
    }

    func isBrickExist() -> Bool {
        return effectUtil.getNeedHitCount() != 0
    }

    func doHitEffect(_ ball: BallUtil, showTimeBrickEffectTime: inout [EffectUtil]) {
        var effects = showTimeBrickEffectTime.compactMap { $0 }
        effectUtil.doEffect(ball, show: &effects)
        showTimeBrickEffectTime.removeAll()
        effects.forEach { showTimeBrickEffectTime.append($0) }

        if let newBrickBmp = getNewBrickBmpAfterHit(effectUtil.getNeedHitCount()) {
            bitmap = newBrickBmp
            self.texture = bitmap
        }
    }

    func setPlayGameLevel(_ level: Int, left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat) {
        let brickMaxConfig = BrickMaxConfig.sharedInstance

        // 保存邊界與 rect
        rect = CGRect(x: left, y: bottom, width: right - left, height: top - bottom)

        // 調整節點尺寸與位置（左上定位）
        self.size = CGSize(width: right - left, height: top - bottom)
        self.position = CGPoint(x: CGFloat(left) + size.width / 2.0,
                                y: CGFloat(top) - size.height)

        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom

        // 依關卡隨機挑選磚塊類型（並尊重 BrickMaxConfig 上限規則）
        repeat {
            whichBrickType = pickBrickType(for: level)
        } while brickMaxConfig.isBrickMaxConfigEnable() &&
                brickMaxConfig.isBrickOverMax(Int32(whichBrickType.rawValue))

        // 設定位圖與效果
        bitmap = SKTexture(imageNamed: "block")
        self.texture = bitmap
        setBitmapByBrickType(whichBrickType)
        setEffect(whichBrickType)
    }
    func getEffect() -> EffectUtil { effectUtil }
}

extension BrickUtil {

    // MARK: - Private helpers
    private func pickBrickType(for level: Int) -> BrickType {
        switch level {
        case 0:
            return .once
        case 1:
            switch Int.random(in: 0..<3) {
            case 0: return .twice
            case 1: return .tool
            default: return .ballLevelUp
            }
        case 2:
            switch Int.random(in: 0..<4) {
            case 0: return .three
            case 1: return .iron
            case 2: return .tool
            default: return .ballLevelUp
            }
        case 3:
            switch Int.random(in: 0..<5) {
            case 0: return .twice
            case 1: return .three
            case 2: return .time
            case 3: return .tool
            default: return .ballLevelUp
            }
        case 4:
            switch Int.random(in: 0..<6) {
            case 0: return .twice
            case 1: return .three
            case 2: return .iron
            case 3: return .time
            case 4: return .tool
            default: return .ballLevelUp
            }
        default:
            return .once
        }
    }

    private func setBitmapByBrickType(_ type: BrickType) {
        switch type {
        case .once:        bitmap = bitmapUtil.brick_once_bmp
        case .twice:       bitmap = bitmapUtil.brick_twice_bmp
        case .three:       bitmap = bitmapUtil.brick_three_bmp
        case .iron:        bitmap = bitmapUtil.brick_iron_bmp
        case .time:        bitmap = bitmapUtil.brick_time_bmp
        case .tool:        bitmap = bitmapUtil.brick_tool_bmp
        case .ballLevelUp: bitmap = bitmapUtil.brick_ball_level_up_bmp
        }
        self.texture = bitmap
    }

    private func setEffect(_ type: BrickType) {
        effectUtil = EffectUtil(brickUtil: self)
        effectUtil.setEffect(Int32(type.rawValue))
    }

    private func getNewBrickBmpAfterHit(_ needHitCount: Int) -> SKTexture? {
        switch needHitCount {
        case 1:  return bitmapUtil.brick_once_bmp
        case 2:  return bitmapUtil.brick_twice_bmp
        case -1: return bitmapUtil.brick_iron_break_bmp
        default: return nil
        }
    }
}
