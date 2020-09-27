//
//  LazyStackPolyfill.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2020.
//

// SRC: https://thomas-sivilay.github.io/morningswiftui.github.io/swiftui/2020/07/01/conditionally-use-vstack-in-ios-13-or-lazyvstack-in-ios-14.html

import SwiftUI

public struct LazyStackPolyfill<Content>: View where Content : View {

  let content: () -> Content
  let alignment: HorizontalAlignment
  let spacing: CGFloat?

  public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
    self.content = content
    self.alignment = alignment
    self.spacing = spacing
  }

  @ViewBuilder public var body: some View {
      if #available(iOS 14.0, *) {
          LazyVStack(alignment: alignment, spacing: spacing, content: self.content)
      } else {
          VStack(alignment: alignment, spacing: spacing, content: self.content)
      }
  }
}
