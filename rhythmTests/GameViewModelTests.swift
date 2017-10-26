//
//  rhythmTests.swift
//  rhythmTests
//
//  Created by William Pompei on 21/10/2017.
//  Copyright © 2017 William Pompei. All rights reserved.
//

import XCTest
@testable import rhythm

class GameViewModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSimonSequenceItem_Equatable() {
        let itemOne = GameViewModel.SimonSequenceItem(simonColor: .red, time: 1)
        let itemTwo = GameViewModel.SimonSequenceItem(simonColor: .red, time: 1)
        XCTAssertEqual(itemOne, itemTwo)
    }
    
    func testPlayerReady_confirm(){
        let vm = GameViewModel(tickDurationSeconds: 1)
        vm.gameState = .waitForUserPlay
        vm.playerReady()
        XCTAssertEqual(vm.gameState, .userPlay)
    }
    
    func testStartNewGame_sequenceCreation(){
        let sequenceLenght = 10
        let vm = GameViewModel(tickDurationSeconds: 1, sequenceLenght: sequenceLenght)
        let delegate = GameTestDelegate()
        vm.delegate = delegate
        vm.startNewGame()
        
        //check sequece size
        XCTAssertEqual(vm.simonSequence.count, sequenceLenght)
        
        //check all items are different
        var duplicatesInSequence = false
        var dictDuplicates = [Double: Double]()
        vm.simonSequence.forEach { (item) in
            guard dictDuplicates[item.time] == nil else {
                duplicatesInSequence = true
                return
            }
            dictDuplicates[item.time] = item.time
        }
        XCTAssertFalse(duplicatesInSequence)
        XCTAssertTrue(delegate.startNewGameCalled)
    }
    
    func testCheckPlayer(){
        let sequenceLenght = 4
        let lastMoveDuration = 2
        let vm = GameViewModel(tickDurationSeconds: 1, sequenceLenght: sequenceLenght, lastMoveDuration: lastMoveDuration)
        let delegate = GameTestDelegate()
        vm.delegate = delegate
        
        vm.startNewGame()
        vm.gameState = .userPlay
        let totalTickToTest = Int(vm.simonSequence.last!.time) + lastMoveDuration
        (0...totalTickToTest).forEach{ tick in
            vm.updatePlayerPlaybackState(for: Double(tick))
            //select correct move or let time go to next tick
            guard let itemToSelect = vm.simonSequence.filter({ item -> Bool in
                item.time == Double(tick)
            }).first else {
                return
            }
            
            //player make move
            vm.playerMove(item: itemToSelect.simonColor)
            XCTAssertFalse(delegate.playerWrongMoveCalled)
            switch vm.gameState {
            case .userPlay :
                XCTAssertFalse(vm.playerPlay.waitForLastMove)
                XCTAssertEqual(vm.playerPlay.lastTick, 0)
                XCTAssertFalse(delegate.gameFinishedCalled)
            case .lastTick :
                XCTAssertTrue(vm.playerPlay.waitForLastMove)
                XCTAssertEqual(vm.playerPlay.lastTick, Double(totalTickToTest - lastMoveDuration))
            case .gameEnded:
                XCTAssertEqual(delegate.gameFinishedCalledCounter, 1)
                XCTAssertTrue(delegate.gameFinishedCalled)
            case .waitingToStart: break
            default: XCTFail()
            }
        }
        XCTAssertEqual(vm.gameState, .waitingToStart)
    }
    
    func testCheckPlayback(){
        let sequenceLenght = 4
        let lastMoveDuration = 2
        let vm = GameViewModel(tickDurationSeconds: 1, sequenceLenght: sequenceLenght, lastMoveDuration: lastMoveDuration)
        let delegate = GameTestDelegate()
        vm.delegate = delegate
        vm.startNewGame()
        let totalTickToTest = Int(vm.simonSequence.last!.time)
        (0...totalTickToTest).forEach{ tick in
            vm.evolveGameState(using: .playbackAction(tick: Double(tick)))
            switch vm.gameState {
            case .playback:
                XCTAssertEqual(delegate.updateCalledCounter, Int(tick + 1))
            case .waitForUserPlay:
                XCTAssertEqual(delegate.updateCalledCounter, Int(tick + 1))
                XCTAssertTrue(delegate.playerTurnCalled)
                XCTAssertEqual(delegate.playerTurnCalledCounter,1)
            default: XCTFail()
            }
        }
    }
    
    func testCheckWrongMove(){
    }
}


/**
 Delegate used to collect test data about delegate invocation
 */
class GameTestDelegate: TapViewControllerDelegate {
    
    var startNewGameCalled = false
    var updateCalled = false
    var playerTurnCalled = false
    var playerCorrectMoveCalled = false
    var playerWrongMoveCalled = false
    var gameFinishedCalled = false
    
    var updateCalledCounter: Int = 0
    var simonButtonToPressCalled = false
    var simonButtonToPressCounter: Int = 0
    var gameFinishedCalledCounter: Int = 0
    var playerTurnCalledCounter: Int = 0
    
    func startNewGame() {
        startNewGameCalled = true
    }
    
    func update(tick: Int) {
        updateCalled = true
        updateCalledCounter += 1
    }
    
    func playerTurn() {
        playerTurnCalled = true
        playerTurnCalledCounter += 1
    }
    
    func playerCorrectMove(counter: Int) {
        playerCorrectMoveCalled = true
    }
    
    func playerWrongMove(counter: Int) {
        playerWrongMoveCalled = true
    }
    
    func gameFinished(score: GameViewModel.PlayerScore) {
        gameFinishedCalled = true
        gameFinishedCalledCounter += 1
    }
    
    func simonButtonToPress(item: GameViewModel.Simoncolor) {
        simonButtonToPressCalled = true
    }
}
