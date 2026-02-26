//
//  SafariView.swift
//  StopSun
//
//  Created by taeni on 2/24/26.
//

import SwiftUI
import SafariServices

/// SFSafariViewController의 SwiftUI 래퍼
///
/// ```swift
/// .sheet(item: $webURL) { url in
///     SafariView(url: url)
/// }
/// ```
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
