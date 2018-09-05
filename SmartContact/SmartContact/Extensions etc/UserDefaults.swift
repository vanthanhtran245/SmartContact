//
//  UserDefaults.swift
//  SmartContact
//
//  Created by Thanh Tran Van on 9/5/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation

extension UserDefaults {
    struct Keys {
        fileprivate static let showFirstNameFirst = "ShowFirstNameFirst"
        fileprivate static let subtitleWithEmail = "SubtitleWithEmail"
        fileprivate static let smartContactThemeColor = "ThemeColor"
    }
    
    static var subtitleWithEmail: Bool {
        set {  UserDefaults.standard.set(newValue, forKey: Keys.subtitleWithEmail) }
        get { return UserDefaults.standard.bool(forKey: Keys.subtitleWithEmail) }
    }
    
    static var showFirstNameBeforeLast: Bool {
        set {  UserDefaults.standard.set(newValue, forKey: Keys.showFirstNameFirst) }
        get { return UserDefaults.standard.bool(forKey: Keys.showFirstNameFirst) }
    }
    
    static var smartContactThemeColor: String? {
        set {  UserDefaults.standard.set(newValue, forKey: Keys.smartContactThemeColor) }
        get { return UserDefaults.standard.string(forKey: Keys.smartContactThemeColor) }
    }
}
