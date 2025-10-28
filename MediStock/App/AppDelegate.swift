//
//  AppDelegate.swift
//  MediStock
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import Foundation
import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || CommandLine.arguments.contains("-XCTest")
        if !isRunningTests {
            FirebaseApp.configure()
        }
        return true
    }
}
