//
//  InfoView.swift
//  Memeo
//
//  Created by Alex on 10.9.2021.
//  Moved to Features/Home structure
//

import SwiftUI
import RevenueCat

struct InfoView: View {
    @Binding var isPresented: Bool
    @State var restoringSubscriptions = false
    @State var showRestoredPurchasesDialog: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header section
                VStack {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 50)
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("App version: \(version)")
                            .font(.system(size: 10, weight: .black))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding()
                
                // Use Form for better structure and semantics
                Form {
                    // About section
                    Section(header: Text("About Memeo").font(.headline)) {
                        Text("Memeo is a fun passion project that allows you to easily attach text to objects in any video and create funny memes")
                            .font(.system(size: 14))
                            .lineSpacing(6)
                            .listRowBackground(Color.clear)
                    }
                    
                    // Attribution section
                    Section(header: Text("Powered By").font(.headline)) {
                        HStack {
                            Spacer()
                            Image("giphy")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150, height: 30)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    // Purchases section
                    Section {
                        Button(action: {
                            Task {
                                restoringSubscriptions = true
                                _ = try await Purchases.shared.restorePurchases()
                                showRestoredPurchasesDialog = true
                                restoringSubscriptions = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text(restoringSubscriptions ? "Restoring, just a second..." : "Restore purchases")
                            }
                        }
                        .disabled(restoringSubscriptions)
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                
                // Close button
                DialogGradientButton(
                    text: "Close",
                    action: {
                        withAnimation {
                            isPresented = false
                        }
                    })
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
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
