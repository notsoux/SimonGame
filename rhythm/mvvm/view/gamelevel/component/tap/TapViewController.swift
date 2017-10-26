//
//  TapViewController.swift
//  rhythm
//
//  Created by William Pompei on 22/10/2017.
//  Copyright © 2017 William Pompei. All rights reserved.
//

import UIKit

protocol TapViewControllerDelegate{
    func startNewGame()
    func update(tick: Int)
    func playerTurn()
    func playerCorrectMove(counter: Int)
    func playerWrongMove(counter: Int)
    func gameFinished(score: GameViewModel.PlayerScore)
    
    func simonButtonToPress(item: GameViewModel.Simoncolor)
}

class TapViewController: UIViewController{
    
    @IBOutlet weak var redLight: UIView!
    @IBOutlet weak var greenLight: UIView!
    @IBOutlet weak var blueLight: UIView!
    @IBOutlet weak var yellowLight: UIView!
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    var viewModel: GameViewModel!
    var colorLightMapper: [GameViewModel.Simoncolor: UIView]!
    var tickDuration: Double!
    
    //MARK: - Setup from coordinator
    func setup(viewModel: GameViewModel){
        self.viewModel?.delegate = self
        self.viewModel = viewModel
        self.tickDuration = viewModel.tickDurationSeconds
    }
    
    //MARK - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        colorLightMapper = [.red: redLight,
                            .green: greenLight,
                            .blue: blueLight,
                            .yellow: yellowLight]
        clearLabels()
        setupGesture()
        viewModel?.startNewGame()
    }
    
    func setupGesture(){
        addTapGesture(to: redLight)
        addTapGesture(to: greenLight)
        addTapGesture(to: blueLight)
        addTapGesture(to: yellowLight)
    }
    
    func addTapGesture(to lightView: UIView){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pressedAction(_:)))
        lightView.addGestureRecognizer(tapGesture)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - actions
    @IBAction func pressedAction(_ sender: Any) {
        guard let sender = sender as? UITapGestureRecognizer,
            let senderView = sender.view else {
                return
        }
        print("tapAction...")
        if let colorSelected = colorLightMapper.filter({
            return $0.value == senderView
        }).first {
            self.viewModel.playerMove(item: colorSelected.key)
            animateTap(for: senderView)
        }
    }

    //MARK: - GUI utils
    fileprivate func clearLabels() {
        self.timerLabel.text = ""
        self.scoreLabel.text = ""
        self.errorLabel.text = ""
    }
}

extension TapViewController: TapViewControllerDelegate {
    
    func gameFinished(score: GameViewModel.PlayerScore) {
        let scoreMessage = "correct: \(score.correct)\n\nerrors: \(score.errors)"
        let alert = UIAlertController(title: "Game finished", message: scoreMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Restart!", style: .default, handler: { [weak self](_) in
            self?.viewModel.startNewGame()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func playerCorrectMove(counter: Int) {
        self.scoreLabel.text = "Score: \(counter)"
    }
    
    func playerWrongMove(counter: Int) {
        self.errorLabel.text = "Errors: \(counter)"
    }
    
    func setupPlayerStart(){
        clearLabels()
        
        // enable interaction on player's turn
        colorLightMapper.values.forEach { (view) in
            view.isUserInteractionEnabled = true
        }
    }
    
    func startNewGame() {
        clearLabels()
        // disable interaction until it's player's turn
        colorLightMapper.values.forEach { (view) in
            view.isUserInteractionEnabled = false
        }
    }
    
    func simonButtonToPress(item: GameViewModel.Simoncolor) {
        guard let lightView = colorLightMapper?[item] else {
            return
        }
        animateTap(for: lightView)
    }
    
    func update(tick: Int) {
        self.timerLabel.text = "Time: \(tick)"
    }
    
    func playerTurn() {
        self.timerLabel.text = nil
        let alert = UIAlertController(title: "Repeat the sequence", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Start!", style: .default, handler: { [weak self](_) in
            self?.setupPlayerStart()
            self?.viewModel.playerReady()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}

//MARK: - tap animation
extension TapViewController {
    fileprivate func pressedAnimationValues(for light: UIView){
        light.alpha = 0.5
    }
    
    fileprivate func notPressedAnimationValues(for light: UIView){
        light.alpha = 1.0
    }
    
    private func animateTap(for light: UIView){
        UIView.animate(withDuration: tickDuration / 2.0, delay: 0.0, options: .autoreverse,animations: { [weak self] in
            self?.pressedAnimationValues(for: light)
        }){ [weak self] _ in
            self?.notPressedAnimationValues(for: light)
        }
    }
}
