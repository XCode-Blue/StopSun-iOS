//
//  IdentifiableURL.swift
//  StopSun
//
//  Created by taeni on 2/24/26.
//

import Foundation

///
/// ```swift
/// @State private var selectedURL: IdentifiableURL?
///
/// .sheet(item: $selectedURL) { item in
///     SafariView(url: item.url)
/// }
/// ```
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}
