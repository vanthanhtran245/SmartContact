//
//  NotificationCenter.swift
//  SmartContact
//
//  Created by Thanh Tran Van on 9/5/18.
//  Copyright © 2018 Thanh Tran Van. All rights reserved.
//

import Foundation

public let SmartContactThemeColorChanged = "SmartContactThemeColorChanged"

// MARK: Notifications
///
public extension Notification.Name {
    /// Fired when debug mode change
    public static let colorThemeChanged   = Notification.Name(SmartContactThemeColorChanged)
}
