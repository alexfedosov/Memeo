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
        ContinueButton(text: "Continue", action: {
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

fileprivate struct ContinueButton: View {
  let text: String
  let action: () -> ()
  
  let gradientColors = [
    Color(red: 50 / 255, green: 197 / 255, blue: 1),
    Color(red: 182 / 255, green: 32 / 255, blue: 224 / 255),
    Color(red: 247 / 255, green: 181 / 255, blue: 0),
  ]
  
  var body: some View {
    Button(action: action, label: {
      Text(text)
        .foregroundColor(.white)
        .font(Font.system(size: 14, weight: .bold))
        .padding(EdgeInsets(top: 16, leading: 48, bottom: 16, trailing: 48))
        .cornerRadius(7)
        .frame(maxWidth: .infinity)
    }).background(
      RoundedRectangle(cornerRadius: 7)
        .fill(LinearGradient(gradient: Gradient(colors: gradientColors.reversed()),
                               startPoint: .bottomLeading,
                               endPoint: .topTrailing))
    )
  }
}

struct FullscreenModifier<T: View>: ViewModifier {
  let presenting: T
  @Binding var isPresented: Bool
  
  func body(content: Content) -> some View {
    ZStack {
      content
      if isPresented {
        ZStack {
          VisualEffectView(effect: UIBlurEffect(style: .prominent)).opacity(0.6).ignoresSafeArea()
          Rectangle().fill(Color.black.opacity(0.6)).ignoresSafeArea()
          presenting
        }.transition(.opacity)
      }
    }
  }
}

extension View {
  public func presentAppTrackingRequestView(isPresented: Binding<Bool>) -> some View {
    self.modifier(FullscreenModifier(presenting: AppTrackingPermissionRequestView(isPresented: isPresented), isPresented: isPresented))
  }
}

struct AppTrackingPermissionRequestView_Previews: PreviewProvider {
  static var previews: some View {
    AppTrackingPermissionRequestView(isPresented: .constant(true))
  }
}
