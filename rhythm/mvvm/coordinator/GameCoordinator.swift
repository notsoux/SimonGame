//
//  GameCoordinator.swift
//  rhythm
//
//  Created by William Pompei on 21/10/2017.
//  Copyright © 2017 William Pompei. All rights reserved.
//

import Foundation
import UIKit
import SimonGamePod

class GameCoordinator {
    
    func start() -> UIViewController {
        let tapViewController = TapViewController()
        let gameViewModel = SimonGameViewModel(tickDurationSeconds: 1.0)
        gameViewModel.delegate = tapViewController
        tapViewController.setup(viewModel: gameViewModel)
        return tapViewController
    }

    deinit {
        print("deinit -> \(self)")
    }
}
