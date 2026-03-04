//
//  SuncareInfoViewModel.swift
//  StopSun
//
//  Created by taeni on 3/1/26.
//

import Foundation

/// 정보 화면 ViewModel
///
/// Bundle 내 lproj 기반 JSON 파일에서 아티클을 로딩합니다.
/// `Bundle.main.url(forResource:withExtension:)`이
/// 기기 locale에 맞는 lproj를 자동 탐색합니다.
///
/// 외부 Manager 의존성이 없으므로 DIContainer 팩토리 메서드 불필요합니다.
///
/// ## 사용법
/// ```swift
/// @State private var viewModel = SuncareInfoViewModel()
///
/// SuncareInfoView(viewModel: viewModel)
///     .task { viewModel.loadIfNeeded() }
/// ```
///
@MainActor
@Observable
final class SuncareInfoViewModel {
    
    // MARK: - State
    
    /// 로딩된 아티클 목록
    private(set) var articles: [SuncareInfoArticle] = []
    
    /// 로딩 실패 여부
    private(set) var hasError: Bool = false
    
    /// 로딩 완료 여부
    var isLoaded: Bool { !articles.isEmpty }
    
    // MARK: - Private
    
    private let fileName: String
    
    // MARK: - Init
    
    /// - Parameter fileName: Bundle 내 JSON 파일명 (확장자 제외)
    init(fileName: String = "sunscreen_uv_info") {
        self.fileName = fileName
    }
    
    // MARK: - Data Loading
    
    /// 아티클 미로딩 시에만 로딩 수행
    ///
    /// View의 `.task`에서 호출합니다.
    /// 이미 로딩 완료되었거나 에러 상태이면 무시합니다.
    func loadIfNeeded() {
        guard articles.isEmpty && !hasError else { return }
        loadArticles()
    }
    
    /// Bundle에서 JSON 파일을 로딩하여 디코딩
    ///
    /// lproj 구조이므로 Bundle이 기기 locale에 맞는
    /// `ko.lproj/` 또는 `en.lproj/` 파일을 자동 선택합니다.
    private func loadArticles() {
        guard let url = Bundle.main.url(
            forResource: fileName,
            withExtension: "json"
        ) else {
            Log.error("JSON 파일을 찾을 수 없음: \(fileName).json")
            hasError = true
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let response = try JSONDecoder().decode(
                SunscareInfoResponse.self,
                from: data
            )
            articles = response.sunscreenInfo
            Log.info("정보 아티클 \(articles.count)건 로딩 완료")
        } catch {
            Log.error("JSON 디코딩 실패: \(error.localizedDescription)")
            hasError = true
        }
    }
    
    // MARK: - Filtering (향후 확장용)
    
    /// 고유 카테고리 목록 (등장 순서 유지)
    var categories: [String] {
        var seen = Set<String>()
        return articles.compactMap { article in
            guard !seen.contains(article.category) else { return nil }
            seen.insert(article.category)
            return article.category
        }
    }
    
    /// 카테고리별 아티클 필터링
    /// - Parameter category: nil이면 전체 반환
    func articles(for category: String?) -> [SuncareInfoArticle] {
        guard let category else { return articles }
        return articles.filter { $0.category == category }
    }
}

// MARK: - Preview Support

extension SuncareInfoViewModel {
    
    /// Preview용 ViewModel
    static var preview: SuncareInfoViewModel {
        let viewModel = SuncareInfoViewModel(fileName: "__preview_stub__")
        viewModel.articles = [
            SuncareInfoArticle(
                id: 1,
                thumbnail: "info1",
                category: "선크림 기초",
                title: "선크림을 발라야하는 이유",
                content: "자외선(UV)은 햇빛의 보이지 않는 에너지로, 우리 피부에 다양한 영향을 미칩니다.\n\n선크림은 자외선을 흡수하거나 반사하는 성분을 포함하고 있어, 피부가 자외선에 직접적으로 노출되지 않도록 돕습니다."
            ),
            SuncareInfoArticle(
                id: 2,
                thumbnail: "info2",
                category: "자외선 지식",
                title: "적절한 일광량이란?",
                content: "햇빛은 우리 몸에 꼭 필요한 자연 자원 중 하나입니다.\n\n적절한 일광량은 개인의 피부 타입, 지역, 계절에 따라 달라집니다."
            ),
            SuncareInfoArticle(
                id: 3,
                thumbnail: "info3",
                category: "피부 건강",
                title: "광노화의 적, 자외선",
                content: "피부 노화의 상당 부분은 시간이 아닌 햇빛 때문입니다.\n\n광노화는 예방할 수 있는 노화입니다."
            )
        ]
        viewModel.hasError = false
        return viewModel
    }
}
