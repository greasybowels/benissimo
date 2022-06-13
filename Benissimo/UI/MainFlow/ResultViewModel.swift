//
//  ResultViewModel.swift
//  Benissimo
//
//  Created by Igor Chertenkov on 12/6/22.
//

import Foundation

protocol ResultViewModelActionDelegate: AnyObject {
    
}

protocol ResultViewModelDisplayDelegate: AnyObject {
    
}

class ResultViewModel {
    weak var actionDelegate: ResultViewModelActionDelegate?
    weak var displayDelegate: ResultViewModelDisplayDelegate?

}
