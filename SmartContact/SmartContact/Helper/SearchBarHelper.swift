//
//  SearchBarHelper.swift
//  SmartContact
//
//  Created by Thanh Tran Van on 9/4/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation
import UIKit

struct SearchBarHelper {
    // MARK: - Helper Functions
    public static func defaultSearchBar(withRasterSize rasterSize: CGFloat, leftView: UIView?, rightView: UIView?, delegate: SHSearchBarDelegate) -> SHSearchBar {
        var config = defaultSearchBarConfig(rasterSize)
        config.leftView = leftView
        config.rightView = rightView
        config.useCancelButton = false
        if leftView != nil {
            config.leftViewMode = .always
        }
        if rightView != nil {
            config.rightViewMode = .unlessEditing
        }
        let bar = SHSearchBar(config: config)
        bar.textField.autocorrectionType = .no
        bar.delegate = delegate
        bar.updateBackgroundImage(withRadius: 6, corners: [.allCorners], color: UIColor.white)
        bar.layer.shadowColor = UIColor.black.cgColor
        bar.layer.shadowOffset = CGSize(width: 0, height: 3)
        bar.layer.shadowRadius = 5
        bar.layer.shadowOpacity = 0.25
        return bar
    }
    
    public static func defaultSearchBarConfig(_ rasterSize: CGFloat) -> SHSearchBarConfig {
        var config: SHSearchBarConfig = SHSearchBarConfig()
        config.rasterSize = rasterSize
        config.useCancelButton = false
        config.cancelButtonTextAttributes = [.foregroundColor : UIColor.darkGray]
        config.textContentType = UITextContentType.fullStreetAddress.rawValue
        config.textAttributes = [.foregroundColor : UIColor.gray]
        return config
    }
    
    public static func imageViewWithIcon(_ icon: UIImage, rasterSize: CGFloat) -> UIImageView {
        let imgView = UIImageView(image: icon)
        imgView.frame = CGRect(x: 0, y: 0, width: icon.size.width + rasterSize * 2.0, height: icon.size.height)
        imgView.contentMode = .center
        imgView.tintColor = UIColor(red: 0.75, green: 0, blue: 0, alpha: 1)
        return imgView
    }
}
