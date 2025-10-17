//
//  BitmapUtil.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/16.
//

import SpriteKit

class BitmapUtil {
    static let sharedInstance = BitmapUtil()

    let bar: SKTexture

    let brick_once_bmp: SKTexture
    let brick_twice_bmp: SKTexture
    let brick_three_bmp: SKTexture
    let brick_iron_bmp: SKTexture
    let brick_time_bmp: SKTexture
    let brick_tool_bmp: SKTexture
    let brick_ball_level_up_bmp: SKTexture
    let brick_iron_break_bmp: SKTexture

    let tool_BallSpeedUp_bmp: SKTexture
    let tool_BallSpeedDown_bmp: SKTexture
    let tool_StickLongUp_bmp: SKTexture
    let tool_StickLongDown_bmp: SKTexture
    let tool_BallCountUpToThree_bmp: SKTexture
    let tool_LifeUp_bmp: SKTexture
    let tool_Weapen_bmp: SKTexture
    let tool_BallReset_bmp: SKTexture
    let tool_StickLongMax_bmp: SKTexture
    let tool_BallRadiusUp_bmp: SKTexture
    let tool_BallRadiusDown_bmp: SKTexture
    let tool_BlackHole_bmp: SKTexture
    let tool_BallLevelUpTwice_bmp: SKTexture
    let tool_BallLevelDownOnce_bmp: SKTexture

    let ball_Show_bmp: SKTexture

    let ballTextures: [SKTexture]

    /// 對應時間數字材質（索引 0~9 對應 0~9；最後一個是「dot / s」等符號）
    let timeTextures: [SKTexture]

    // MARK: - Init
    private init() {
        // bar
        bar = SKTexture(imageNamed: "bar")

        // bricks
        brick_once_bmp            = SKTexture(imageNamed: "brick01")
        brick_twice_bmp           = SKTexture(imageNamed: "brick02")
        brick_three_bmp           = SKTexture(imageNamed: "brick03")
        brick_iron_bmp            = SKTexture(imageNamed: "brick04")
        brick_time_bmp            = SKTexture(imageNamed: "brick05")
        brick_tool_bmp            = SKTexture(imageNamed: "brick06")
        brick_ball_level_up_bmp   = SKTexture(imageNamed: "brick07")
        brick_iron_break_bmp      = SKTexture(imageNamed: "brick04_1")

        // tools
        tool_BallSpeedUp_bmp         = SKTexture(imageNamed: "tool01")
        tool_BallSpeedDown_bmp       = SKTexture(imageNamed: "tool02")
        tool_StickLongUp_bmp         = SKTexture(imageNamed: "tool03")
        tool_StickLongDown_bmp       = SKTexture(imageNamed: "tool04")
        tool_BallCountUpToThree_bmp  = SKTexture(imageNamed: "tool05")
        tool_LifeUp_bmp              = SKTexture(imageNamed: "tool06")
        tool_Weapen_bmp              = SKTexture(imageNamed: "tool07")
        tool_BallReset_bmp           = SKTexture(imageNamed: "tool08")
        tool_StickLongMax_bmp        = SKTexture(imageNamed: "tool09")
        tool_BallRadiusUp_bmp        = SKTexture(imageNamed: "tool10")
        tool_BallRadiusDown_bmp      = SKTexture(imageNamed: "tool11")
        tool_BlackHole_bmp           = SKTexture(imageNamed: "tool12")
        tool_BallLevelUpTwice_bmp    = SKTexture(imageNamed: "tool13")
        tool_BallLevelDownOnce_bmp   = SKTexture(imageNamed: "tool14")

        // ball show
        ball_Show_bmp = SKTexture(imageNamed: "ball2")

        // time digits/textures (維持 ObjC 的順序：0,1,2,...,9, dot)
        let time01 = SKTexture(imageNamed: "s1")
        let time02 = SKTexture(imageNamed: "s2")
        let time03 = SKTexture(imageNamed: "s3")
        let time04 = SKTexture(imageNamed: "s4")
        let time05 = SKTexture(imageNamed: "s5")
        let time06 = SKTexture(imageNamed: "s6")
        let time07 = SKTexture(imageNamed: "s7")
        let time08 = SKTexture(imageNamed: "s8")
        let time09 = SKTexture(imageNamed: "s9")
        let time00 = SKTexture(imageNamed: "s0")
        let timeQ  = SKTexture(imageNamed: "dot")

        timeTextures = [time00, time01, time02, time03, time04, time05, time06, time07, time08, time09, timeQ]

        // ball animation frames
        ballTextures = [
            SKTexture(imageNamed: "ball"),
            SKTexture(imageNamed: "ball1"),
            SKTexture(imageNamed: "ball2")
        ]
    }

    // 若你想保留 ObjC 的方法型介面，可用這個：
    func timeTexturesArray() -> [SKTexture] {
        return timeTextures
    }
}
