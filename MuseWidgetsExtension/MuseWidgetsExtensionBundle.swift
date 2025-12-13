//
//  MuseWidgetsExtensionBundle.swift
//  MuseWidgetsExtension
//
//  Created by Davis on 12/13/25.
//

import WidgetKit
import SwiftUI

@main
struct MuseWidgetsExtensionBundle: WidgetBundle {
    var body: some Widget {
        MuseWidgetsExtension()
        MuseWidgetsExtensionControl()
        MuseWidgetsExtensionLiveActivity()
    }
}
