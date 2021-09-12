//
//  AppTrackingPermissionRequestView.swift
//  Memeo
//
//  Created by Alex on 10.9.2021.
//

import SwiftUI
import AppTrackingTransparency
import AdSupport

struct AppTrackingPermissionRequestView: View {
  @Binding var isPresented: Bool
  
  var body: some View {
    VStack {
      VStack {
        Text("You're on iOS \(UIDevice.current.systemVersion)").font(.title2).bold()
          .padding()
        Text("This version of ios requires us to ask permissions to track activity received from apps and websites that you visit on this phone to improve your ads. If you give us requested permissions, you can:")
          .font(.system(size: 16)).lineSpacing(6)
          .multilineTextAlignment(.center)
        VStack(alignment: .leading) {
          HStack {
            Image(systemName: "person")
            Text("Get ads that are more personalised")
              .font(.system(size: 14).bold()).lineSpacing(6)
          }.padding(.bottom, 4)
          HStack {
            Image(systemName: "heart")
            Text("Help keep Memeo free of charge")
              .font(.system(size: 14).bold()).lineSpacing(6)
          }
        }.padding(36)
        DialogGradientButton(text: "Continue", action: {
          ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
            DispatchQueue.main.async {
              withAnimation {
                isPresented = false
              }
            }
          })
        })
      }
      .padding(24)
      .frame(maxWidth: .infinity)
      .background(VisualEffectView(effect: UIBlurEffect(style: .dark)))
      .cornerRadius(16)
      .padding()
    }
  }
}

extension View {
  public func presentAppTrackingRequestView(isPresented: Binding<Bool>) -> some View {
    self.modifier(FullscreenModifier(presenting: AppTrackingPermissionRequestView(isPresented: isPresented), canCancelByBackgroundTap: false, isPresented: isPresented))
  }
}

struct AppTrackingPermissionRequestView_Previews: PreviewProvider {
  static var previews: some View {
    AppTrackingPermissionRequestView(isPresented: .constant(true))
  }
}
