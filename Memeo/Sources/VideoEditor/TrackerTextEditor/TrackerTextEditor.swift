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
  let onFinishEditing: (String) -> Void
  
  var body: some View {
    ZStack {
      VisualEffectView(effect: UIBlurEffect(style: .regular)).ignoresSafeArea()
        .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
        .animation(SwiftUI.Animation.easeOut(duration: 0.5))
      VStack {
        HStack {
          Spacer()
          Button(action: {
            finishEditing()
          }, label: {
            HStack {
              Text("Done")
                .font(.system(size: 14, weight: .bold, design: .default))
                .foregroundColor(.black)
              Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold, design: .default))
                .accentColor(.black)
            }
            .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 12))
            .background(Color.white)
            .cornerRadius(100)
          }).padding()
        }
        Spacer()
        HStack(alignment: .center) {
          UIKitTextField(text: $text,
                         isFirstResponder: .constant(true)) { textField in
            textField.textAlignment = .center
            textField.font = .systemFont(ofSize: 16, weight: .bold)
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
          }
        }.padding()
        Spacer()
      }
      .frame(maxHeight: .greatestFiniteMagnitude)
      .onTapGesture {
        finishEditing()
      }
    }.transition(.opacity)
  }
  
  func finishEditing() {
    onFinishEditing(text)
  }
}

