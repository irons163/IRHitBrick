//
//  ViewController.swift
//  IRHitBrick
//
//  Created by Phil on 2025/6/10.
//

import UIKit
import SpriteKit

protocol GameDelegate: AnyObject {
    func showWinDialog()
    func showLoseDialog(score: Int)
    func goToMenu()
    func goToNextLevel()
    func restart()
}

class ViewController: UIViewController, GameDelegate {

    static var scene: MyScene?
    private var winDialogViewController: WinDialogViewController?
    private var gameOverViewController: GameOverViewController?

    // Assuming MAX_LEVEL is defined elsewhere, for example:
    let MAX_LEVEL = 3
    
    // The 'level' variable from the Objective-C code seems to be a class-level or global variable.
    // In Swift, it's better to manage this as an instance property.
    var level: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        if let skView = self.view as? SKView {
            skView.showsFPS = true
            skView.showsNodeCount = true

            // Create and configure the scene.
            Self.scene = MyScene.make(size: skView.bounds.size, playGameLevel: 1, with: self)
            // let scene = BreakoutGameScene(size: skView.bounds.size)
            Self.scene?.scaleMode = .aspectFill
            Self.scene?.gameDelegate = self

            // Present the scene.
            skView.presentScene(Self.scene)
        }
    }

    func showWinDialog() {
        winDialogViewController = self.storyboard?.instantiateViewController(withIdentifier: "WinDialogViewController") as? WinDialogViewController
        guard let winDialogViewController = winDialogViewController else { return }
        
        winDialogViewController.gameDelegate = self
        
        self.navigationController?.providesPresentationContextTransitionStyle = true
        self.navigationController?.definesPresentationContext = true
        winDialogViewController.modalPresentationStyle = .overCurrentContext

        winDialogViewController.view.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)

        present(winDialogViewController, animated: true, completion: nil)
        
        if level == 2 {
            // winDialogViewController.goToNextLevel.rank_level; // This line in Objective-C is unclear and likely has a typo.
                                                              // It would need to be adapted to what it's supposed to do in Swift.
        }
    }

    func showLoseDialog(score: Int) {
        gameOverViewController = self.storyboard?.instantiateViewController(withIdentifier: "GameOverViewController") as? GameOverViewController
        guard let gameOverViewController = gameOverViewController else { return }

        gameOverViewController.gameDelegate = self
        gameOverViewController.setScore(score)
        
        self.providesPresentationContextTransitionStyle = true
        self.definesPresentationContext = true
        gameOverViewController.modalPresentationStyle = .overCurrentContext
        
        gameOverViewController.view.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)

        present(gameOverViewController, animated: true, completion: nil)
    }

    func goToMenu() {
        if let winDialog = winDialogViewController {
            winDialog.dismiss(animated: true) {
                self.winDialogViewController = nil
                self.dismiss(animated: true, completion: nil)
            }
        } else if let gameOverDialog = gameOverViewController {
            gameOverDialog.dismiss(animated: true) {
                self.gameOverViewController = nil
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func goToNextLevel() {
        if level + 1 < MAX_LEVEL {
            
        } else if level + 1 == MAX_LEVEL {

        }
        
        if let skView = self.view as? SKView {
            Self.scene = MyScene.make(size: skView.bounds.size, playGameLevel: level + 1, with: self)
            Self.scene?.scaleMode = .aspectFill
            Self.scene?.gameDelegate = self

            skView.showsFPS = false
            skView.showsNodeCount = false
            skView.presentScene(Self.scene)
        }
        
        if let winDialog = winDialogViewController {
            winDialog.dismiss(animated: true, completion: nil)
            self.winDialogViewController = nil
        } else if let gameOverDialog = gameOverViewController {
            gameOverDialog.dismiss(animated: true, completion: nil)
            self.gameOverViewController = nil
        }
        
        level += 1
    }

    func restart() {
        level -= 1
        goToNextLevel()
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}
