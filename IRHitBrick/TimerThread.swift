//
//  TimerThread.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/17.
//

import Foundation

final class TimerThread: NSObject {

    // MARK: - State
    private var timeLeft: Int
    private weak var tool: ToolUtil?
    private weak var effect: EffectUtil?
    private var isRunning = false
    private var shouldRun = true

    private let stateQueue = DispatchQueue(label: "TimerThread.state", attributes: .concurrent)
    private var timer: DispatchSourceTimer?

    // MARK: - Inits (對齊 ObjC)
    @objc class func initWithTime(_ time: Int) -> TimerThread {
        return TimerThread(time: time)
    }

    init(time: Int, tool: ToolUtil? = nil, effect: EffectUtil? = nil) {
        self.timeLeft = time
        self.tool = tool
        self.effect = effect
        super.init()
    }

    // MARK: - Public API
    @objc func start() {
        guard !isRunning else { return }
        isRunning = true
        shouldRun = true

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + 1, repeating: 1)

        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            if !self.shouldRun { self.stopTimer(); return }

            // 檢查遊戲狀態
            let cfg = BallViewConfig.sharedInstance
            if !(cfg.gameFlag) || cfg.waitGameSuccessProcessing {
                // 遊戲未進行或進入結算，不遞減
                return
            }
            if cfg.GAME_PAUSE_FLAG {
                // 暫停中，不遞減
                return
            }

            // 遞減
            var newValue = 0
            self.stateQueue.sync {
                newValue = self.timeLeft
            }
            if newValue > 0 {
                newValue -= 1
                self.stateQueue.async(flags: .barrier) { self.timeLeft = newValue }
            }

            if newValue <= 0 {
                self.stopTimer()
            }
        }

        self.timer = timer
        timer.resume()
    }

    @objc func cancel() {
        shouldRun = false
        stopTimer()
    }

    @objc func getCurrentTime() -> Int {
        var v = 0
        stateQueue.sync { v = timeLeft }
        return v
    }

    @objc func setCurrentTime(_ time: Int) {
        stateQueue.async(flags: .barrier) { self.timeLeft = time }
    }

    // MARK: - Helpers
    private func stopTimer() {
        stateQueue.async(flags: .barrier) { self.isRunning = false }
        timer?.cancel()
        timer = nil
    }
}
