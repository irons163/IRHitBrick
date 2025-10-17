//
//  WinDialogViewController.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/12.
//

import UIKit

final class WinDialogViewController: UIViewController {

    weak var gameDelegate: GameDelegate?
    var level: Int = 0

    @IBOutlet weak var goToMenuBtn: UIButton!
    @IBOutlet weak var goToNextLevel: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func goToMenuClick(_ sender: Any) {
        gameDelegate?.goToMenu()
    }

    @IBAction func goToNextLevelClick(_ sender: Any) {
        gameDelegate?.goToNextLevel()
    }
}
