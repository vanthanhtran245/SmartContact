//
//  DetailContactVC.swift
//  SmartContact
//
//  Created by Thanh Tran Van on 8/30/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation
import UIKit
import SunflowerSDK

class DetailContactVC: UIViewController {
    var header : StretchHeader!
    var tableView : UITableView!
}

extension DetailContactVC {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil;
    }
    
    func setupHeaderView() {
        
        let options = StretchHeaderOptions()
        options.position = .fullScreenTop
        
        header = StretchHeader()
        header.stretchHeaderSize(headerSize: CGSize(width: view.frame.size.width, height: 160),
                                 imageSize: CGSize(width: view.frame.size.width, height: 120),
                                 controller: self,
                                 options: options)
        header.imageView.image = UIImage(named: "photo_sample_05")
        
        // custom
        let avatarImage = UIImageView()
        avatarImage.frame = CGRect(x: 10, y: header.imageView.frame.height - 20, width: 60, height: 60)
        avatarImage.image = UIImage(named: "photo_sample_03")
        avatarImage.layer.cornerRadius = 5.0
        avatarImage.layer.borderColor = UIColor.white.cgColor
        avatarImage.layer.borderWidth = 3.0
        avatarImage.clipsToBounds = true
        avatarImage.contentMode = .scaleAspectFill
        header.addSubview(avatarImage)
        
        let button = UIButton(type: .roundedRect)
        button.frame = CGRect(x: header.imageView.frame.width - 100 - 10, y: header.imageView.frame.height + 10, width: 100, height: 30)
        button.setTitle("Edit Profile", for: UIControlState())
        button.setTitleColor(UIColor.lightGray, for: UIControlState())
        button.layer.cornerRadius = 5.0
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1.0
        header.addSubview(button)
        
        tableView.tableHeaderView = header
    }
}
