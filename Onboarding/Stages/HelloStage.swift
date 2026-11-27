// Licensed under GPL-3.0. See LICENSE.
//
//  HelloStage.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 19/02/2026.
//

import SwiftUI

struct HelloStage: View {

    var body: some View {
        VStack(spacing: 24){
            Text("Say Hi to Lelele Browser")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
            Image("lelele-logo-1024")
                .resizable()
                .scaledToFit()
                .frame(width: 128 ,height: 128)
            Text("Your new open-source browser.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
