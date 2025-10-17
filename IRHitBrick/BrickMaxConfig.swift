//
//  BrickMaxConfig.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/16.
//

class BrickMaxConfig {
    static let sharedInstance = BrickMaxConfig()

    var LV2_Brick_Twice_MAX: Int = 6
    var LV2_Brick_Tool_MAX: Int = 7
    var LV2_Brick_BallLevelUP_MAX: Int = 5

    var LV3_Brick_Three_MAX: Int = 4
    var LV3_Brick_Iron_MAX: Int = 2
    var LV3_Brick_Tool_MAX: Int = 5
    var LV3_Brick_BallLevelUP_MAX: Int = 5

    var LV4_Brick_Twice_MAX: Int = 3
    var LV4_Brick_Three_MAX: Int = 3
    var LV4_Brick_Time_MAX: Int = 3
    var LV4_Brick_Tool_MAX: Int = 4
    var LV4_Brick_BallLevelUP_MAX: Int = 3

    var LV5_Brick_Twice_MAX: Int = 3
    var LV5_Brick_Three_MAX: Int = 3
    var LV5_Brick_Iron_MAX: Int = 2
    var LV5_Brick_Time_MAX: Int = 2
    var LV5_Brick_Tool_MAX: Int = 3
    var LV5_Brick_BallLevelUP_MAX: Int = 3

    private var brickOnceMax: Int = 0
    private var brickTwiceMax: Int = 0
    private var brickThreeMax: Int = 0
    private var brickIronMax: Int = 0
    private var brickTimeMax: Int = 0
    private var brickToolMax: Int = 0
    private var brickBallLevelUpMax: Int = 0

    private var bricksMax: [Int] = Array(repeating: 0, count: 7)

    // 是否啟用上限檢查
    private(set) var brickMaxConfigEnable: Bool = false

    private init() {
        brickMaxConfigEnable = false
    }

    func setBrickMaxConfigEnable(_ enable: Bool, PlayGameLevel level: Int) {
        brickMaxConfigEnable = enable
        if level == 0 { brickMaxConfigEnable = false }
        setBrickMaxBy(Int(level))
    }

    func setBrickMaxBy(_ playGameLevel: Int) {
        switch playGameLevel {
        case 1:
            brickTwiceMax = LV2_Brick_Twice_MAX
            brickToolMax = LV2_Brick_Tool_MAX
            brickBallLevelUpMax = LV2_Brick_BallLevelUP_MAX
        case 2:
            brickThreeMax = LV3_Brick_Three_MAX
            brickIronMax = LV3_Brick_Iron_MAX
            brickToolMax = LV3_Brick_Tool_MAX
            brickBallLevelUpMax = LV3_Brick_BallLevelUP_MAX
        case 3:
            brickTwiceMax = LV4_Brick_Twice_MAX
            brickThreeMax = LV4_Brick_Three_MAX
            brickTimeMax = LV4_Brick_Time_MAX
            brickToolMax = LV4_Brick_Tool_MAX
            brickBallLevelUpMax = LV4_Brick_BallLevelUP_MAX
        case 4:
            brickTwiceMax = LV5_Brick_Twice_MAX
            brickThreeMax = LV5_Brick_Three_MAX
            brickIronMax = LV5_Brick_Iron_MAX
            brickTimeMax = LV5_Brick_Time_MAX
            brickToolMax = LV5_Brick_Tool_MAX
            brickBallLevelUpMax = LV5_Brick_BallLevelUP_MAX
        default:
            break
        }

        // 依序填入陣列（與 ObjC 相同）
        bricksMax[0] = brickOnceMax
        bricksMax[1] = brickTwiceMax
        bricksMax[2] = brickThreeMax
        bricksMax[3] = brickIronMax
        bricksMax[4] = brickTimeMax
        bricksMax[5] = brickToolMax
        bricksMax[6] = brickBallLevelUpMax
    }

    // - (bool)isBrickOverMax:(int)whichBrickType;
    // whichBrickType: 0..6
    func isBrickOverMax(_ whichBrickType: Int32) -> Bool {
        let idx = Int(whichBrickType)
        guard idx >= 0 && idx < bricksMax.count else { return true }
        if bricksMax[idx] - 1 < 0 {
            return true
        } else {
            bricksMax[idx] -= 1
            return false
        }
    }

    // - (bool)isBrickMaxConfigEnable;
    func isBrickMaxConfigEnable() -> Bool {
        return brickMaxConfigEnable
    }
}
