//
//  MuseWidgetsBundle.swift
//  MuseWidgets
//
//  Created by Davis on 12/12/25.
//

import WidgetKit
import SwiftUI

@main
struct MuseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Static widgets (simple, no configuration)
        QuoteWidget()
        AffirmationWidget()
    }
}
