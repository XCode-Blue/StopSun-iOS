//
//  SettingsView.swift
//  StopSun
//
//  Created by taeni on 2/23/26.
//

import SwiftUI

/// 설정 메인 화면
///
/// - 서비스 설정: 앱 권한(iOS 설정), 건강 데이터 권한(Bottom Sheet 안내)
/// - 피부 정보: 피부 타입(NavigationLink), SPF(Bottom Sheet Wheel Picker)
/// - 앱 정보: 개인정보 처리 방침, 앱 정보 및 지원 (인앱 Safari)
///
struct SettingsView: View {
    
    // MARK: - Dependencies
    
    @State private var viewModel: SettingsViewModel
    
    // MARK: - State
    
    @State private var showSPFPicker = false
    @State private var pendingSPFLevel: SPFLevel = .spf30
    @State private var showHealthKitGuide = false
    @State private var healthKitGuideStep = 0
    @State private var selectedURL: IdentifiableURL?
    
    init() {
        _viewModel = State(wrappedValue: DIContainer.shared.makeSettingsViewModel())
    }
    
    /// Preview / 테스트용 생성자
    init(viewModel: SettingsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    serviceSection
                    divider
                    skinInfoSection
                    divider
                    appInfoSection
                    appVersionLabel
                }
            }
            .background(Color.white00)
            .sheet(isPresented: $showSPFPicker) {
                spfPickerSheet
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showHealthKitGuide) {
                healthKitGuideSheet
                    .presentationDetents([.height(480)])
                    .presentationDragIndicator(.visible)
                    .onDisappear { healthKitGuideStep = 0 }
            }
            .sheet(item: $selectedURL) { item in
                SafariView(url: item.url)
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        Text(L10n.Settings.title)
            .font(.ssFont(.B2))
            .foregroundStyle(Color.text00)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
            .padding(.bottom, 28)
            .padding(.horizontal, 20)
    }
    
    // MARK: - 서비스 설정 Section
    
    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(L10n.Settings.Section.service)
                .padding(.bottom, 20)
            
            // 앱 권한 설정 (알림 + 위치 통합) → iOS 설정
            settingsRow(
                title: L10n.Settings.Permission.title,
                description: L10n.Settings.Permission.desc,
                trailing: linkButton(L10n.Settings.title) {
                    viewModel.openAppSettings()
                }
            )
            
            Spacer().frame(height: 24)
            
            // 건강 데이터 권한 → 안내 Bottom Sheet
            settingsRow(
                title: L10n.Settings.HealthKit.title,
                description: L10n.Settings.HealthKit.desc,
                trailing: linkButton(L10n.Button.guide) {
                    showHealthKitGuide = true
                }
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 피부 정보 Section
    
    private var skinInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(L10n.Settings.Section.skin)
                .padding(.bottom, 20)
            
            // 피부 타입 → NavigationLink
            NavigationLink {
                SkinTypeSettingView(
                    currentSkinType: viewModel.skinType,
                    onComplete: { newType in
                        viewModel.updateSkinType(newType)
                    }
                )
            } label: {
                settingsRow(
                    title: L10n.Settings.SkinTypeSetting.title,
                    description: L10n.Settings.SkinTypeSetting.desc,
                    trailing: navigationValue(viewModel.skinTypeDisplayText)
                )
            }
            .buttonStyle(.plain)
            
            Spacer().frame(height: 24)
            
            // SPF → Bottom Sheet Wheel Picker
            Button {
                pendingSPFLevel = viewModel.spfLevel
                showSPFPicker = true
            } label: {
                settingsRow(
                    title: L10n.Settings.SPFSetting.title,
                    description: L10n.Settings.SPFSetting.desc,
                    trailing: navigationValue(viewModel.spfDisplayText)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 앱 정보 Section
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(L10n.Settings.Section.appInfo)
                .padding(.bottom, 20)
            
            Button {
                selectedURL = IdentifiableURL(url: viewModel.privacyURL)
            } label: {
                appInfoRow(title: L10n.Settings.AppInfo.privacy)
            }
            .buttonStyle(.plain)
            
            Spacer().frame(height: 24)
            
            Button {
                selectedURL = IdentifiableURL(url: viewModel.supportURL)
            } label: {
                appInfoRow(title: L10n.Settings.AppInfo.support)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - SPF Picker Bottom Sheet
    
    private var spfPickerSheet: some View {
        VStack(spacing: 0) {
            Text(L10n.Settings.SPFSetting.title)
                .font(.ssFont(.SB2))
                .foregroundStyle(Color.text00)
                .padding(.top, 24)
            
            Picker("SPF", selection: $pendingSPFLevel) {
                ForEach(SPFLevel.pickerCases) { level in
                    Text(level.displayTitle).tag(level)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 180)
            
            SSButton(L10n.Button.confirm, style: .primary) {
                viewModel.updateSPFLevel(pendingSPFLevel)
                showSPFPicker = false
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - HealthKit Guide Bottom Sheet
    
    /// 건강 데이터 권한 경로 안내 시트 (가로 페이징)
    ///
    /// Asset 이미지: `guide_healthKit_1` ~ `guide_healthKit_5`
    private var healthKitGuideSheet: some View {
        let steps: [(image: ImageResource, description: String)] = [
            (.imgGuideHealthKit1, L10n.Settings.HealthKit.Guide.step1),
            (.imgGuideHealthKit2, L10n.Settings.HealthKit.Guide.step2),
            (.imgGuideHealthKit3, L10n.Settings.HealthKit.Guide.step3),
            (.imgGuideHealthKit4, L10n.Settings.HealthKit.Guide.step4),
            (.imgGuideHealthKit5, L10n.Settings.HealthKit.Guide.step5)
        ]
        
        return VStack(spacing: 0) {
            Text(L10n.Settings.HealthKit.title)
                .font(.ssFont(.SB2))
                .foregroundStyle(Color.text00)
                .padding(.top, 24)
                .padding(.bottom, 16)
            
            TabView(selection: $healthKitGuideStep) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    VStack(spacing: 12) {
                        Text(step.description)
                            .font(.ssFont(.R3))
                            .foregroundStyle(Color.text01)
                        
                        Image(step.image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: healthKitGuideStep)
            
            // 커스텀 페이지 인디케이터 (TabView 바깥)
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index == healthKitGuideStep ? Color.key00 : Color.gray00)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: healthKitGuideStep)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            SSButton(
                healthKitGuideStep < steps.count - 1
                    ? L10n.Button.next
                    : L10n.Button.confirm,
                style: .primary
            ) {
                if healthKitGuideStep < steps.count - 1 {
                    withAnimation { healthKitGuideStep += 1 }
                } else {
                    showHealthKitGuide = false
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - App Version
    
    private var appVersionLabel: some View {
        VStack(spacing: 4) {
            Text(viewModel.appNameText)
                .font(.ssFont(.R5))
                .foregroundStyle(Color.text03)
            
            Text(viewModel.appVersionText)
                .font(.ssFont(.R5))
                .foregroundStyle(Color.text03)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
        .padding(.bottom, 40)
    }
    
    // MARK: - Reusable Components
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.ssFont(.R5))
            .foregroundStyle(Color.text03)
    }
    
    private func settingsRow(
        title: String,
        description: String,
        trailing: some View
    ) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.ssFont(.SB2))
                    .foregroundStyle(Color.text00)
                
                Text(description)
                    .font(.ssFont(.R1))
                    .foregroundStyle(Color.text03)
            }
            
            Spacer()
            
            trailing
        }
    }
    
    /// 앱 정보 행 — 타이틀 + chevron만
    private func appInfoRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.ssFont(.SB2))
                .foregroundStyle(Color.text00)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.text03)
        }
    }
    
    /// "설정 >" 스타일 링크 버튼
    private func linkButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text(text)
                    .font(.ssFont(.R5))
                    .foregroundStyle(Color.key00)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.key00)
            }
        }
    }
    
    /// "4형 >" 네비게이션 값 표시
    private func navigationValue(_ text: String) -> some View {
        HStack(spacing: 2) {
            Text(text)
                .font(.ssFont(.R5))
                .foregroundStyle(Color.key00)
            
            Image(systemName: "chevron.right")
                .font(.ssFont(.R5))
                .foregroundStyle(Color.key00)
        }
    }
    
    /// 섹션 구분선
    private var divider: some View {
        Rectangle()
            .fill(Color.gray01)
            .frame(height: 4)
            .padding(.vertical, 28)
    }
}

// MARK: - Preview
#if DEBUG
#Preview("Settings") {
    SettingsView(
        viewModel: SettingsViewModel(
            localStorage: MockLocalStorageManager(),
            permissionManager: PermissionManager(
                notification: MockNotificationManager(),
                healthKit: MockHealthKitManager(),
                location: MockLocationManager()
            )
        )
    )
}
#endif
