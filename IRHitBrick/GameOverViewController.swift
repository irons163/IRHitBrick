//
//  GameOverViewController.swift
//  IRHitBrick
//
//  Created by Phil on 2025/10/12.
//

import UIKit

final class GameOverViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Dependencies
    weak var gameDelegate: GameDelegate?      // 使用你專案內的 GameDelegate
    weak var delegateRef: AnyObject?          // 原 ObjC 的 `id delegate`

    // MARK: - Outlets
    @IBOutlet weak var gameOverTitleLabel: UILabel!
    @IBOutlet weak var gameScoreLabel: UILabel!
    @IBOutlet weak var nameEditView: UITextField!
    @IBOutlet weak var submitButton: UIButton!

    // MARK: - State
    private var gameScore: Int = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        gameScoreLabel.text = "\(gameScore)"
        gameScoreLabel.sizeToFit()
        nameEditView.delegate = self
    }

    // MARK: - Public API
    func setScore(_ score: Int) {
        gameScore = score
        // 若畫面已載入，同步更新
        if isViewLoaded {
            gameScoreLabel.text = "\(gameScore)"
            gameScoreLabel.sizeToFit()
        }
    }

    // MARK: - Actions
    @IBAction func goToMenu(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            self?.gameDelegate?.goToMenu()
        }
    }

    @IBAction func sendScore(_ sender: Any) {
        let rawName = nameEditView.text ?? ""
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            showAlert(title: "", message: NSLocalizedString("CannotNull", comment: ""))
            return
        }

        DatabaseManager.sharedInstance().insert(withName: name, withScore: Int32(gameScore))

        // 成功提示並隱藏輸入區塊
        gameOverTitleLabel.isHidden = true
        gameScoreLabel.isHidden = true
        nameEditView.isHidden = true
        submitButton.isHidden = true

        showAlert(title: "", message: "success")
    }

    @IBAction func restartClick(_ sender: Any) {
        dismiss(animated: true) { [weak self] in
            self?.gameDelegate?.restart()
        }
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "ok", style: .default))
        present(ac, animated: true)
    }
}
