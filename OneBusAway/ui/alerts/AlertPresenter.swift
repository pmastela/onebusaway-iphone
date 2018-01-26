//
//  AlertPresenter.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

import OBAKit
import UIKit
import SwiftMessages
import SafariServices

@objc open class AlertPresenter: NSObject {

    /// Displays an alert on screen at the status bar level indicating a successful operation.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    @objc open class func showSuccess(_ title: String, body: String) {
        self.showMessage(withTheme: .success, title: title, body: body)
    }

    /// Displays an alert on screen at the status bar level indicating an unsuccessful operation.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    @objc open class func showWarning(_ title: String, body: String) {
        self.showMessage(withTheme: .warning, title: title, body: body)
    }

    /// Displays an alert on screen at the status bar level indicating an error.
    ///
    /// - parameter title: The title of the alert
    /// - parameter body:  The body of the alert
    @objc open class func showError(_ title: String, body: String) {
        self.showMessage(withTheme: .error, title: title, body: body)
    }

    /// Displays an error alert on screen generated from an error object.
    ///
    /// - Parameters:
    ///   - error: The error object from which the alert is generated.
    ///   - presentingController: The view controller from which a modal view controller should be presented if this error requires action on the user's part.
    @objc open class func showError(_ error: NSError, presentingController: UIViewController?) {
        guard
            let presentingController = presentingController,
            shouldDisplayErrorUrlInController(error),
            let urlString = error.userInfo[NSURLErrorFailingURLStringErrorKey] as? String,
            let url = URL.init(string: urlString)
        else {
            showMessage(from: error)
            return
        }

        let safari = SFSafariViewController.init(url: url)
        presentingController.present(safari, animated: true, completion: nil)
    }

    private class func showMessage(from error: NSError) {
        var userInfo: [String: Any] = [:]
        var referenceID: String? = nil
        if let url = error.userInfo[NSURLErrorFailingURLStringErrorKey] as? NSString,
            let substr = url.oba_SHA1?.prefix(10) {
            referenceID = String(describing: substr)
            userInfo["reference"] = referenceID
        }
        Crashlytics.sharedInstance().recordError(error, withAdditionalUserInfo: userInfo)
        self.showError(OBAStrings.error, body: errorMessage(from: error, referenceID: referenceID))
    }

    open class func showMessage(withTheme theme: Theme, title: String, body: String) {
        var config = SwiftMessages.Config()
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = theme == .error ? .forever : .seconds(seconds: 5)
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true
        config.preferredStatusBarStyle = .lightContent

        let view = AlertPresenterView.init()
        view.configureContent(title: title, body: body, iconImage: nil, iconText: nil, buttonImage: nil, buttonTitle: NSLocalizedString("msg_close", comment: "close"), buttonTapHandler: { _ in
            SwiftMessages.hide()
        })
        view.configureTheme(theme)

        // Show the message.
        SwiftMessages.show(config: config, view: view)
    }

    private class func errorMessage(from error: NSError, referenceID: String?) -> String {
        let wifiName = OBAReachability.wifiNetworkName
        
        var message: String

        if (errorPotentiallyFromWifiCaptivePortal(error) && wifiName != nil) {
            message = NSLocalizedString("alert_presenter.captive_wifi_portal_error_message", comment: "Error message displayed when the user is connecting to a Wi-Fi captive portal landing page.")
        }
        else {
            message = error.localizedDescription
        }
        
        // If the error includes an URL, append the SHA-1 hash
        // value of that URL to the error for legibility's sake.
        if let referenceID = referenceID {
            let formatString = NSLocalizedString("alerts.reference_format", comment: "ID: {Reference ID Number}")
            let referenceLine = String.init(format: formatString, referenceID)
            message = "\(message)\r\n\r\n\(referenceLine)"
        }
        
        return message
    }

    /// Returns true if the value of error.userInfo[NSURLErrorFailingURLStringErrorKey] should be displayed in a
    /// modal safari view controller, and false if it shouldn't be. Currently only looks for cases where the user
    /// is on what appears to be a captive portal wifi network.
    ///
    /// - Parameter error: The error in question
    /// - Returns: true if a modal safari controller should be displayed and false otherwise.
    private class func shouldDisplayErrorUrlInController(_ error: NSError) -> Bool {
        if error.domain != NSURLErrorDomain && error.domain != (kCFErrorDomainCFNetwork as String) {
            return false
        }

        if error.code != NSURLErrorAppTransportSecurityRequiresSecureConnection {
            return false
        }

        return error.userInfo[NSURLErrorFailingURLStringErrorKey] != nil
    }

    private class func errorPotentiallyFromWifiCaptivePortal(_ error: NSError) -> Bool {
        if error.domain == NSCocoaErrorDomain && error.code == 3840 {
            return true
        }

        if error.domain == (kCFErrorDomainCFNetwork as String) && error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
            return true
        }

        return false
    }
}
