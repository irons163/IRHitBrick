//
//  EffectUtil.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/16.
//

import Foundation
import SpriteKit

//class EffectUtil: NSObject {
//    func isHasTool() -> Bool { false }
//    func getToolObj() -> ToolUtil { ToolUtil() }
//    func getToolTimerThread() -> TimerThread { TimerThread() }
//    func doEffectFinish(_ balls: [BallUtil]) {}
//}

final class EffectUtil: NSObject {

    // MARK: - Public properties
    @objc var ironsCombo: Bool = false

    // MARK: - Private state
    private weak var brickUtil: BrickUtil?
    private weak var ball: BallUtil?

    private var timerThread: TimerThread?
    private var toolEffectTwinkingAlpha: Int = 255
    private var toolEffectFinishAlpha: Int = 255

    private var whichEffectType: EffectType = .once
    private var toolUtil: ToolUtil?
    private var needHitCount: Int = 0

    // MARK: - Constants
    private let TIME_EFFECT_COUNT: Int = 60

    // ObjC 版的 enum
    private enum EffectType: Int {
        case once = 0, twice, three, iron, time, tool, ballLevelUP
    }

    // MARK: - Inits (保留 ObjC 介面)
    convenience init(brickUtil: BrickUtil) {
        self.init()
        self.brickUtil = brickUtil
        self.ironsCombo = false
        initEffectUtilValue()
    }

    /// 對應 ObjC: + (instancetype)initWithBallView:withBrickUtil:
    @objc class func initWithBallView(withBrickUtil brickUtil: BrickUtil) -> EffectUtil {
        return EffectUtil(brickUtil: brickUtil)
    }

    private func initEffectUtilValue() {
        toolEffectTwinkingAlpha = 255
        toolEffectFinishAlpha = 255
    }

    // MARK: - Effect setup
    /// 對應 ObjC: - (void)setEffect:(int)whichType;
    @objc func setEffect(_ whichType: Int) {
        setEffectInternal(whichType)
    }
    // 兼容 Int32 呼叫（先前轉換的 BrickUtil 使用 Int32）
    func setEffect(_ whichType: Int32) {
        setEffectInternal(Int(whichType))
    }

    private func setEffectInternal(_ whichType: Int) {
        let mapped = EffectType(rawValue: whichType) ?? .once
        whichEffectType = mapped
        switch mapped {
        case .once:        needHitCount = 1
        case .twice:       needHitCount = 2
        case .three:       needHitCount = 3
        case .iron:        needHitCount = -2
        case .time:        needHitCount = 1
        case .tool:        needHitCount = 1
        case .ballLevelUP: needHitCount = 1
        }
    }

    // MARK: - Effect application
    /// 對應 ObjC: - (void)doEffect:(BallUtil*) ball show:(NSMutableArray*)showTimeBrickEffectTime;
    func doEffect(_ ball: BallUtil, show showTimeBrickEffectTime: inout [EffectUtil]) {
        self.ball = ball
        switch whichEffectType {
        case .once, .twice, .three:
            doHitDetermine()
        case .iron:
            doHitIronDetermine()
        case .time:
            doHitDetermine()
            doTimeCountEffect(&showTimeBrickEffectTime)
        case .tool:
            doHitDetermine()
            setToolEffect()
            startDownTool()
        case .ballLevelUP:
            doHitDetermine()
            doBallLevelUPEffect(ball)
        }
    }

    private func doHitDetermine() {
        guard let ballView = ViewController.scene else { return }
        if needHitCount > 0 {
            let hit = (ballView.getBallLevel() > 1) ? 2 : (ballView.getBallLevel() + 1)
            if needHitCount == 2 {
                ballView.hitBrickLevelDownCount += 1
            } else if needHitCount == 3 {
                ballView.hitBrickLevelDownCount += hit
            }
            needHitCount = max(0, needHitCount - hit)
        }
    }

    private func doHitIronDetermine() {
        guard let ballView = ViewController.scene else { return }
        if ballView.getBallLevel() == 2 {
            if needHitCount == -2 {
                ballView.hitIronBrickLevelDownCount += 1
            }
            needHitCount += 1
            ironsCombo = true
        } else {
            ironsCombo = false
        }
    }

    private func doTimeCountEffect(_ showTimeBrickEffectTime: inout [EffectUtil]) {
        // 若已有一個生效中的 time effect，縮短其時間，否則新建一個
        if let first = showTimeBrickEffectTime.first,
           let t = first.getToolTimerThread() {
            let current = t.getCurrentTime()
            if current != 0 {
                let newTime = max(0, current - TIME_EFFECT_COUNT / 2)
                t.setCurrentTime(newTime)
                return
            }
        }
        let t = TimerThread(time: TIME_EFFECT_COUNT)
        t.start()
        self.timerThread = t
        showTimeBrickEffectTime.append(self)
    }

    // MARK: - Timer thread access
    /// 對應 ObjC: - (TimerThread*)getToolTimerThread;
    @objc func getToolTimerThread() -> TimerThread? {
        return timerThread
    }

    // MARK: - Alpha getters/setters (保持 API)
    @objc func getFinishAlpha() -> Int { toolEffectFinishAlpha }
    @objc func setFinishAlpha(_ alpha: Int) { toolEffectFinishAlpha = alpha }

    @objc func getTwinklingAlpha() -> Int { toolEffectTwinkingAlpha }
    @objc func setTwinklingAlpha(_ alpha: Int) { toolEffectTwinkingAlpha = alpha }

    // MARK: - Tool effects
    private func setToolEffect() {
        guard let ballView = ViewController.scene, let brickUtil = brickUtil else { return }
        let tool = ToolUtil(ballView: ballView, brickUtil: brickUtil)
        ballView.addChild(tool)
        toolUtil = tool
    }

    /// 對應 ObjC: - (void)startDownTool;
    @objc func startDownTool() {
        // 需要 ToolUtil 具備 `isStartDownTool` 屬性
        toolUtil?.isStartDownTool = true
    }

    // MARK: - Finish / cleanup effects
    /// 對應 ObjC: - (void)doEffectFinish:(NSMutableArray*) ballUtils;
    func doEffectFinish(_ ballUtils: inout [BallUtil]) {
        for b in ballUtils {
            b.setBallLevel(-5)
        }
    }

    // MARK: - Ball Level Up
    private func doBallLevelUPEffect(_ ball: BallUtil) {
        // 若 >1 則設為 -1，否則 +1
        let current = ball.getBallLevel()
        let next = current > 1 ? -1 : (current + 1)
        ball.setBallLevel(next)
    }

    // MARK: - Public getters
    /// 對應 ObjC: - (int)getNeedHitCount;
    @objc func getNeedHitCount() -> Int {
        return needHitCount
    }

    /// 對應 ObjC: - (bool)isHasTool;
    @objc func isHasTool() -> Bool {
        return toolUtil != nil
    }

    /// 對應 ObjC: - (ToolUtil*)getToolObj;
    @objc func getToolObj() -> ToolUtil? {
        return toolUtil
    }
}
