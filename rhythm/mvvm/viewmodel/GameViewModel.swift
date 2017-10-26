//
//  GameViewModel.swift
//  rhythm
//
//  Created by William Pompei on 23/10/2017.
//  Copyright © 2017 William Pompei. All rights reserved.
//

import Foundation

public class GameViewModel{
    
    //MARK: - Game structure data
    public  enum Simoncolor: Int{
        case red
        case green
        case blue
        case yellow
        
        /*
         Get random Simoncolor
         */
        static func random() -> Simoncolor {
            let index = Int(arc4random_uniform(4))
            let simonColor = Simoncolor(rawValue: index % 4)!
            return simonColor
        }
    }
    
    /*
     Game item: it represents a color at specific time
     */
    struct SimonSequenceItem: Equatable{
        let simonColor: Simoncolor
        let time: TimeInterval
        
        static func ==(lhs: SimonSequenceItem, rhs: SimonSequenceItem) -> Bool {
            return lhs.simonColor == rhs.simonColor && lhs.time == rhs.time
        }
    }
    
    enum GamesState {
        case waitingToStart
        case playback // playback phase
        case waitForUserPlay // wait for player to star repeating sequence
        case userPlay // player acting
        case lastTick // waiting for last player action
        case gameEnded // game ended
    }
    
    enum GameAction {
        case none
        case startGame
        case playbackAction(tick: Double) // tick during playback phase
        case confirmPlayerStart
        case playTapAction(item: Simoncolor)
    }
    
    var gameState = GamesState.waitingToStart
    
    //MARK: - view model property
    
    //view controller callback
    var delegate: TapViewControllerDelegate?
    
    //play sequence
    var simonSequence = [SimonSequenceItem]()
    
    //game timer
    var timer: Timer?
    
    var playerPlay: PlayerPlay!
    
    //tick duration (eg. lower value increase game speed)
    private(set) var tickDurationSeconds: TimeInterval
    private let sequenceLenght: Int
    private let lastMoveDuration: Int
    
    //MARK: -
    init(tickDurationSeconds: Double, sequenceLenght: Int = 4, lastMoveDuration: Int = 4){
        self.tickDurationSeconds = tickDurationSeconds
        self.sequenceLenght = sequenceLenght
        self.lastMoveDuration = lastMoveDuration
    }
}

//MARK: - state machine
private extension GameViewModel {
    
    func selectNextValidItem(for timerTick: TimeInterval) {
        if let item = simonSequence.filter({ $0.time == timerTick}).first {
            playerPlay.turnCurrentItem = item
            print("next item for player")
            if let lastSequenceItem = simonSequence.last,
                lastSequenceItem == item {
                playerPlay.waitForLastMove = true
                playerPlay.lastTick = timerTick
            }
        }
    }
    
    func updatePlayerPlaybackState(for timerTick: TimeInterval) {
        selectNextValidItem(for: timerTick)
        delegate?.update(tick: Int(timerTick))
        if playerPlay.waitForLastMove && Int(timerTick - playerPlay.lastTick) == lastMoveDuration {
            finishGame()
        }
    }
    
    private func evolveGameState(using action: GameAction){
        switch gameState {
        case .waitingToStart :
            switch action {
            case .startGame:
                // clear player data
                playerPlay = PlayerPlay()
                
                var tick = 0
                setupSequence()
                delegate?.startNewGame()
                
                gameState = .playback
                timer = Timer.scheduledTimer(withTimeInterval: tickDurationSeconds, repeats: true, block: {
                    [weak self](timer) in
                    
                    self?.evolveGameState(using: .playbackAction(tick: Double(tick)))
                    tick += 1
                })
            default: break
            }
        case .playback :
            switch action {
            case let .playbackAction(tick):
                var lastItem = false
                print("checkTimer -> \(tick)")
                if let item = simonSequence.filter({ $0.time == tick}).first {
                    print("found item")
                    self.delegate?.simonButtonToPress(item: item.simonColor)
                    if let lastSequenceItem = simonSequence.last,
                        lastSequenceItem == item {
                        lastItem = true
                    }
                }
                delegate?.update(tick: Int(tick))
                if lastItem {
                    gameState = .waitForUserPlay
                    timer?.invalidate()
                    timer = nil
                    self.delegate?.playerTurn()
                }
            default: break
            }
        case .waitForUserPlay:
            switch action{
            case .confirmPlayerStart:
                var timerTick: Double = 0
                gameState = .userPlay
                timer = Timer.scheduledTimer(withTimeInterval: tickDurationSeconds, repeats: true, block: { [weak self](timer) in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.updatePlayerPlaybackState(for: timerTick)
                    timerTick += 1
                })
            default: break
            }
        case .userPlay:
            switch action {
            case let .playTapAction( item):
                func internalCheckFinishGame() -> Bool{
                    if playerPlay.waitForLastMove {
                        gameState = .gameEnded
                        evolveGameState(using: .none)
                        return true
                    }
                    return false
                }
                
                guard let correctMove = playerPlay.turnCurrentItem,
                    item == correctMove.simonColor else {
                        playerPlay.score.errors += 1
                        self.delegate?.playerWrongMove(counter: playerPlay.score.errors)
                        let _ = internalCheckFinishGame()
                        return
                }
                
                //if current player move is correct and it's expected
                //last one, let's finish game
                if !internalCheckFinishGame() {
                    playerPlay.score.correct += 1
                    self.delegate?.playerCorrectMove(counter: playerPlay.score.correct)
                }
                break
            default: break
            }
        case .gameEnded : finishGame()
        default: break
        }
    }
    
    private func finishGame(){
        timer?.invalidate()
        timer = nil
        self.delegate?.gameFinished(score: playerPlay.score)
        gameState = .waitingToStart
    }
}

extension GameViewModel {
    
    struct PlayerPlay{
        var score: PlayerScore = PlayerScore()
        
        var waitForLastMove = false
        var lastTick: Double = 0
        var turnCurrentItem: SimonSequenceItem?
    }
}

//MARK: public interface 
public extension GameViewModel {
    
    struct PlayerScore{
        var correct: Int = 0
        var errors: Int = 0
    }
    
    //MARK: - setup game (phase 1)
    public func setupSequence() {
        var timeSoFar:Double = 0
        simonSequence = []
        (0..<sequenceLenght).forEach { (_) in
            //each sequence has interval greater from predecessor
            timeSoFar += Double(arc4random_uniform(2)) + 1
            let item = SimonSequenceItem(simonColor: Simoncolor.random(), time: timeSoFar)
            simonSequence.append( item)
            print(" item interval -> \(timeSoFar) - rawValue -> \(item.simonColor.rawValue)")
        }
    }
    
    //MARK: - Start new game
    public func startNewGame(){
        evolveGameState(using: .startGame)
    }
    
    public func playerReady(){
        evolveGameState(using: .confirmPlayerStart)
    }
    
    public func playerMove(item: Simoncolor){
        evolveGameState(using: .playTapAction(item: item))
    }
}
