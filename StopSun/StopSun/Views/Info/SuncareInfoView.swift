//
//  SuncareInfoView.swift
//  StopSun
//
//  Created by taeni on 3/2/26.
//

import SwiftUI

/// 정보 탭 메인 화면
///
/// 자외선/선크림 관련 정보 아티클을 카드 리스트로 표시합니다.
/// 카드 탭 시 상세 화면으로 NavigationLink(value:) 방식 이동.
///
struct SuncareInfoView: View {
    
    // MARK: - Dependencies
    
    @State private var viewModel: SuncareInfoViewModel
    
    // MARK: - Init
    
    init(viewModel: SuncareInfoViewModel? = nil) {
        self._viewModel = State(wrappedValue: viewModel ?? SuncareInfoViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.white01.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    content
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationDestination(for: SuncareInfoArticle.self) { article in
            SuncareInfoDetailView(article: article)
        }
        .task {
            viewModel.loadIfNeeded()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        Text(L10n.Info.title)
            .font(.ssFont(.B2))
            .foregroundStyle(Color.text00)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 16)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        if viewModel.hasError {
            errorView
        } else if viewModel.articles.isEmpty {
            emptyView
        } else {
            articleList
        }
    }
    
    // MARK: - Article List
    
    private var articleList: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.articles) { article in
                NavigationLink(value: article) {
                    SuncareInfoCardView(article: article)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Color.text04)
            
            Text(L10n.Info.Error.loadFailed)
                .font(.ssFont(.R3))
                .foregroundStyle(Color.text04)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        Color.clear
            .frame(height: 1)
    }
}

// MARK: - Preview

#Preview("Info List") {
    NavigationStack {
        SuncareInfoView(viewModel: .preview)
    }
}

#Preview("Info Error") {
    NavigationStack {
        SuncareInfoView(viewModel: SuncareInfoViewModel(fileName: "__nonexistent__"))
    }
}
