//
//  GroupContactViewController.swift
//  SmartContact
//
//  Created by Sunflower on 9/4/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation
import UIKit
import SwiftyContacts

class GroupContactViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchGroups { groups in
            print("Group \(groups)")
        }
    }
}
