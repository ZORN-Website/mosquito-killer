//
//  Constants.swift
//  Kill All Mosquito
//
//  Created by Banghua Zhao on 1/30/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import UIKit

struct Constants {
    static let appID = "1513712754"

    static let countdownDaysAppID = "1525084657"
    static let moneyTrackerAppID = "1534244892"
    static let financeGoAppID = "1519476344"
    static let financialRatiosGoAppID = "1481582303"
    static let finanicalRatiosGoMacOSAppID = "1486184864"
    static let BMIDiaryAppID = "1521281509"
    static let fourGreatClassicalNovelsAppID = "1526758926"
    static let novelsHubAppID = "1528820845"
    
    // banner ID
    static let bannerAdUnitID =  Bundle.main.object(forInfoDictionaryKey: "BannerAdUnitID") as? String ?? ""
    
    // Interstitial Ad ID
    static let interstitialAdID = Bundle.main.object(forInfoDictionaryKey: "InterstitialAdID") as? String ?? ""

    static var isIphoneFaceID: Bool {
        if let topInset = UIApplication.shared.delegate?.window??.safeAreaInsets.top, topInset <= 24 {
            return false
        } else {
            return true
        }
    }
    
    static var topSafeAreaHeight: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
    }

    struct UserDefaultsKeys {
        static let OPEN_COUNT = "OPEN_COUNT"
        static let BEST_SCORE = "BEST_SCORE"
    }
}
