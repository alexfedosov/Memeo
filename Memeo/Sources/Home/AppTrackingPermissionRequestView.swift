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
        Text("You're on iOS \(UIDevice.current.systemVersion)").font(.title2).bold()
          .padding()
        Text("This version of ios requires us to ask permissions to track activity received from apps and websites that you visit on this phone to improve your ads. If you give us requested permissions, you can:")
          .font(.system(size: 16)).lineSpacing(6)
          .multilineTextAlignment(.center)
        VStack(alignment: .leading) {
          HStack {
            Image(systemName: "person")
            Text("Get ads that are more personalised")
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
              .multilineTextAlignment(.leading)
              .font(.system(size: 13).bold()).lineSpacing(6)
          }
          .frame(maxHeight: 64)
          .padding(.bottom, 4)
          HStack {
            Image(systemName: "heart")
            Text("Help keep Memeo free of charge")
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
              .multilineTextAlignment(.leading)
              .font(.system(size: 13).bold()).lineSpacing(6)
            
          }
        }.padding(24)
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

extension View {
  public func presentAppTrackingRequestView(isPresented: Binding<Bool>) -> some View {
    self.modifier(FullscreenModifier(presenting: AppTrackingPermissionRequestView(isPresented: isPresented), canCancelByBackgroundTap: false, isPresented: isPresented))
  }
}

struct AppTrackingPermissionRequestView_Previews: PreviewProvider {
  static var previews: some View {
    AppTrackingPermissionRequestView(isPresented: .constant(true))
    AppTrackingPermissionRequestView(isPresented: .constant(true)).previewDevice("iPhone 12 Pro Max")

  }
}
