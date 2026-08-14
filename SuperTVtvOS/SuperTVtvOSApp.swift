//
//  SuperTVtvOSApp.swift
//  SuperTVtvOS
//
//  Created by Omar Regalado on 14/08/26.
//

import SwiftUI
import IPTVUITV

@main
struct SuperTVtvOSApp: App {
    var body: some Scene {
        WindowGroup {
            // App tvOS delgada: toda la lógica y las vistas viven en IPTVUITV.
            SuperTVTVRootView()
        }
    }
}
