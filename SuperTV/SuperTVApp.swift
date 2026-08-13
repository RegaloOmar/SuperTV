//
//  SuperTVApp.swift
//  SuperTV
//
//  Created by Omar Regalado on 12/08/26.
//

import SwiftUI
import IPTVFeatures

@main
struct SuperTVApp: App {
    var body: some Scene {
        WindowGroup {
            // App target delgado: toda la lógica y navegación vive en IPTVFeatures.
            SuperTVRootView()
        }
    }
}
