//
//  CreditsView.swift
//  Flick
//
//  Created by Liam Lefohn on 1/30/26.
//

import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Flick 1.1")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Text("Created by Wyld-1")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Text("Built with 🧡 for adventure")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

#Preview {
    CreditsView()
        .environmentObject(AppStateManager())
}
