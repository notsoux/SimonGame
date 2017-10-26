//
//  SimonGameViewControllerDelegate.swift
//  Pods
//
//  Created by William Pompei on 26/10/2017.
//

import Foundation

public protocol SimonGameViewControllerDelegate{
    func startNewGame()
    func update(tick: Int)
    func playerTurn()
    func playerCorrectMove(counter: Int)
    func playerWrongMove(counter: Int)
    func gameFinished(score: SimonGameViewModel.PlayerScore)
    
    func simonButtonToPress(item: SimonGameViewModel.Simoncolor)
}
