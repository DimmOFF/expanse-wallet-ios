//
//  UserActivityService.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 27.04.2023.
//

import Foundation
import AlphaWalletFoundation
import AlphaWalletLogger

protocol UserActivityHandler: AnyObject {
    func handle(_ userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
}

class UserActivityService: UserActivityHandler {
    private let handlers: [UserActivityHandler]

    init(handlers: [UserActivityHandler]) {
        self.handlers = handlers
    }

    func handle(_ userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        var result: Bool = false
        for each in handlers where each.handle(userActivity, restorationHandler: restorationHandler) {
            result = true
            break
        }

        return result
    }
}

protocol DonationUserActivityHandlerDelegate: AnyObject {
    func launchUniversalScanner(fromSource source: Analytics.ScanQRCodeSource)
    func showQrCode()
}

class DonationUserActivityHandler: UserActivityHandler {
    weak var delegate: DonationUserActivityHandlerDelegate?
    private let analytics: AnalyticsLogger

    init(analytics: AnalyticsLogger) {
        self.analytics = analytics
    }

    func handle(_ userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let type = userActivity.userInfo?[Donations.typeKey] as? String {
            infoLog("[Shortcuts] handleIntent type: \(type)")
            if type == CameraDonation.userInfoTypeValue {
                analytics.log(navigation: Analytics.Navigation.openShortcut, properties: [
                    Analytics.Properties.type.rawValue: Analytics.ShortcutType.camera.rawValue
                ])

                delegate?.launchUniversalScanner(fromSource: .siriShortcut)
                return true
            }
            if type == WalletQrCodeDonation.userInfoTypeValue {
                analytics.log(navigation: Analytics.Navigation.openShortcut, properties: [
                    Analytics.Properties.type.rawValue: Analytics.ShortcutType.walletQrCode.rawValue
                ])
                delegate?.showQrCode()
                return true
            }
        }
        return false
    }
}
