//
//  SessionPagingView.swift
//  Wearable Sensor Watch App
//
//  Created by akhanafer on 2023-08-29.
//

import SwiftUI
import WatchKit

struct SessionPagingView: View {
    @State private var selection: Tab = .metrics
    
    enum Tab {
        case controls, metrics, nowPlaying
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ControlsView().tag(Tab.controls)
            MetricsView().tag(Tab.metrics)
            NowPlayingView().tag(Tab.nowPlaying)
        }
    }
}

struct SessionPagingView_Previews: PreviewProvider {
    static var previews: some View {
        SessionPagingView()
    }
}
