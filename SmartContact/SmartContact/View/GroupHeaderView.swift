//
//  GroupHeaderView.swift
//  SmartContact
//
//  Created by Sunflower on 9/6/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import UIKit

class GroupHeaderView: UITableViewHeaderFooterView {
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var actionButton: UIButton!
    var section: Int?
    var buttonTappedAction: ((Int?) -> Void)?
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    @IBAction func didTapAction() {
        buttonTappedAction?(section)
    }
    
}
