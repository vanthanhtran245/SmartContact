//
//  SwipeHelper.swift
//  SmartContact
//
//  Created by Thanh Tran Van on 9/4/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation
import UIKit

class IndicatorView: UIView {
    var color = UIColor.clear {
        didSet { setNeedsDisplay() }
    }
    
    override func draw(_ rect: CGRect) {
        color.set()
        UIBezierPath(ovalIn: rect).fill()
    }
}

enum ActionDescriptor {
    case call, notfavorite, favorite, trash, message
    
    func title(forDisplayMode displayMode: ButtonDisplayMode) -> String? {
        guard displayMode != .imageOnly else { return nil }
        
        switch self {
        case .call: return "Call"
        case .notfavorite: return "Favorite"
        case .favorite: return "UnFavorite"
        case .trash: return "Delete"
        case .message: return "Message"
        }
    }
    
    func image(forStyle style: ButtonStyle, displayMode: ButtonDisplayMode) -> UIImage? {
        guard displayMode != .titleOnly else { return nil }
        let name: String
        switch self {
        case .call: name = "Call"
        case .notfavorite: name = "NotFavorite"
        case .favorite: name = "Favorited"
        case .trash: name = "Trash"
        case .message: name = "Message"
        }
        
        return UIImage(named: style == .backgroundColor ? name : name + "-circle")
    }
    
    var color: UIColor {
        switch self {
        case .call: return #colorLiteral(red: 0, green: 0.4577052593, blue: 1, alpha: 1)
        case .notfavorite, .message: return #colorLiteral(red: 1, green: 0.5803921569, blue: 0, alpha: 1)
        case .favorite: return #colorLiteral(red: 0.9467939734, green: 0.9468161464, blue: 0.9468042254, alpha: 1)
        case .trash: return #colorLiteral(red: 1, green: 0.2352941176, blue: 0.1882352941, alpha: 1)
        }
    }
}
enum ButtonDisplayMode {
    case titleAndImage, titleOnly, imageOnly
}

enum ButtonStyle {
    case backgroundColor, circular
}

