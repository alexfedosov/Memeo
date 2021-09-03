//
//  TrackerTextEditor.swift
//  Memeo
//
//  Created by Alex on 30.8.2021.
//

import Foundation
import SwiftUI

struct TrackerTextEditor: View {
  @State var text: String
  @State var isTextFieldFocused = true
  let onFinishEditing: (String) -> Void
  let onDeleteTracker: () -> Void
  @State var showRemoveConfirmation = false
  
  var body: some View {
    ZStack {
      VisualEffectView(effect: UIBlurEffect(style: .regular)).ignoresSafeArea()
        .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
        .animation(SwiftUI.Animation.easeOut(duration: 0.5))
      VStack {
        HStack {
          Button(action: {
            withAnimation {
              showRemoveConfirmation = true
            }
          }, label: {
            HStack {
              Image(systemName: "trash")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: .infinity).fill(Color.red))
          }).padding()
        }
        Spacer()
        VStack {
          UIKitTextField(text: $text,
                         isFirstResponder: $isTextFieldFocused) { textField in
            textField.textAlignment = .center
            textField.font = .systemFont(ofSize: 16, weight: .bold)
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
          }
          .padding()
          .frame(height: 60)
        }.frame(maxHeight: .infinity, alignment: .center)
        HStack {
          Button(action: {
            let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            onFinishEditing(text)
          }, label: {
            Text("Done")
              .font(.system(size: 14, weight: .bold, design: .default))
              .foregroundColor(.white)
              .padding()
              .frame(maxWidth: .infinity)
              .background(Color.white.opacity(0.1))
              .cornerRadius(12)
          }).padding()
        }
        Text("Pro tip: after you have added text, double tap to come back to this screen")
          .font(.system(size: 10, weight: .bold))
          .multilineTextAlignment(.center)
          .opacity(0.6)
          .padding(.horizontal)
          .padding(.bottom)
      }
      .frame(maxHeight: .greatestFiniteMagnitude)
    }
    .transition(.opacity)
    .alert(isPresented: $showRemoveConfirmation, content: {
      Alert(title: Text("Delete \"\(text)\"?"),
            message: nil,
            primaryButton: .destructive(Text("Delete"), action: {
              onDeleteTracker()
            }),
            secondaryButton: .cancel())
    })
  }
}

struct TrackerTextEditor_Previews: PreviewProvider {
  static var previews: some View {
    TrackerTextEditor(text: "Tracker 1",
                      onFinishEditing: { _ in },
                      onDeleteTracker: { })
      .background(Color.black)
      .colorScheme(.dark)
  }
}
