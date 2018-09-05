//
//  BaseViewController.swift
//  SmartContact
//
//  Created by Thanh Tran Van on 9/5/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation

class BaseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupThemeColor()
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(forName: .colorThemeChanged, object: nil, queue: nil, using: { _ in
            self.setupThemeColor()
        })
    }
    
    func setupThemeColor() {
        guard let hexColor = UserDefaults.smartContactThemeColor else { return }
        let color = UIColor(hexString: hexColor)
        self.navigationController?.navigationBar.barTintColor = color
        self.tabBarController?.tabBar.tintColor = color
    }
}

class BaseTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupThemeColor()
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(forName: .colorThemeChanged, object: nil, queue: nil, using: { _ in
            self.setupThemeColor()
        })
    }
    
    func setupThemeColor() {
        guard let hexColor = UserDefaults.smartContactThemeColor else { return }
        let color = UIColor(hexString: hexColor)
        self.navigationController?.navigationBar.barTintColor = color
        self.tabBarController?.tabBar.tintColor = color
    }
}
