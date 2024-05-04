//
//  InfoView.swift
//  Memeo
//
//  Created by Alex on 10.9.2021.
//

import SwiftUI
import RevenueCat

struct InfoView: View {
    @Binding var isPresented: Bool
    @State var restoringSubscriptions = false
    @State var showRestoredPurchasesDialog: Bool = false

    var body: some View {
        VStack {
            VStack {
                VStack {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 50)
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("App version: \(version)").font(.system(size: 10, weight: .black))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
                Text(
                    "memeo is a fun passion project that allows you to easily attach text to objects in any video and create funny memes"
                )
                .font(.system(size: 14)).lineSpacing(6)
                .multilineTextAlignment(.center)
                VStack {
                    Image("giphy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 30)
                }.padding(24)

                DialogGradientButton(text: restoringSubscriptions ? "Restoring, just a second..." : "Restore purchases") {
                    Task {
                        restoringSubscriptions = true
                        _ = try await Purchases.shared.restorePurchases()
                        showRestoredPurchasesDialog = true
                        restoringSubscriptions = false
                    }
                }

                DialogGradientButton(
                    text: "Close",
                    action: {
                        withAnimation {
                            isPresented = false
                        }
                    })
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(VisualEffectView(effect: UIBlurEffect(style: .dark)))
            .cornerRadius(16)
            .padding()
            .alert("Done!", isPresented: $showRestoredPurchasesDialog) {
                Button("Close") {
                    showRestoredPurchasesDialog = false
                }
            } message: {
                Text("We have checked and restored all in-app purchases and active subscriptions")
            }

        }
    }
}

extension View {
    public func presentInfoView(isPresented: Binding<Bool>) -> some View {
        self.modifier(
            FullscreenModifier(
                presenting: InfoView(isPresented: isPresented), canCancelByBackgroundTap: true, isPresented: isPresented
            ))
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView(isPresented: .constant(true))
    }
}
