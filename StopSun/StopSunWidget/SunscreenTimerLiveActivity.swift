//
//  SunscreenTimerLiveActivity.swift
//  StopSunWidget
//
//  Created by donghee on 2/25/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct SunscreenTimerLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SunscreenTimerAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image("sun_liveactivity")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                }
                DynamicIslandExpandedRegion(.trailing) {}
                DynamicIslandExpandedRegion(.bottom) {}
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenLiveActivityView: View {

    // MARK: - Dependencies

    let context: ActivityViewContext<SunscreenTimerAttributes>

    // MARK: - Computed

    private var warningLevel: WarningLevel {
        WarningLevel(rawValue: context.state.warningLevelRawValue) ?? .safe
    }

    private var progress: CGFloat {
        CGFloat(min(context.state.progress, 1.0))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundOverlay
            contentArea
            sunImage
        }
        .clipped()
        .activityBackgroundTint(Color(red: 0, green: 0.533, blue: 1.0))
    }

    // MARK: - Components

    private var backgroundOverlay: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white.opacity(0.2))
    }

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            timerTitle
            timerCountdown
            warningBanner
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 15)
        .padding(.top, 9)
    }

    private var timerTitle: some View {
        Text("선크림 타이머")
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
    }

    private var timerCountdown: some View {
        (Text(timerInterval: context.attributes.appliedAt...context.attributes.reapplyAt,
              countsDown: true)
         + Text(" 남음"))
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .padding(.top, 4)
    }

    private var warningBanner: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.2))

                Rectangle()
                    .fill(warningLevel.liveActivityAccentColor)
                    .frame(width: geo.size.width * progress)

                bannerText
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 37)
        .padding(.top, 5)
    }

    private var bannerText: some View {
        (Text("현재 UV  ")
            .foregroundColor(.black)
         + Text(warningLevel.title)
            .foregroundColor(warningLevel.liveActivityTitleColor)
         + Text(" 수준 !")
            .foregroundColor(.black))
            .font(.system(size: 14, weight: .semibold))
            .padding(.leading, 20)
    }

    private var sunImage: some View {
        HStack {
            Spacer()
            Image("sun_liveactivity")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 186, height: 180)
                .offset(x: 20)
        }
    }
}

// MARK: - WarningLevel + Live Activity

extension WarningLevel {

    /// Live Activity 프로그레스 바 배경색
    var liveActivityAccentColor: Color {
        switch self {
        case .safe: Color(red: 0.72, green: 0.95, blue: 0.72)
        case .caution: Color(red: 1, green: 0.95, blue: 0.72)
        case .warning: Color(red: 1, green: 0.85, blue: 0.6)
        case .danger: Color(red: 1, green: 0.7, blue: 0.7)
        }
    }

    /// Live Activity 경고 텍스트 색상
    var liveActivityTitleColor: Color {
        switch self {
        case .safe: Color(red: 0.1, green: 0.5, blue: 0.1)
        case .caution: Color(red: 0.7, green: 0.55, blue: 0.0)
        case .warning: Color(red: 0.8, green: 0.4, blue: 0.0)
        case .danger: Color(red: 0.7, green: 0.1, blue: 0.1)
        }
    }
}

// MARK: - Preview

extension SunscreenTimerAttributes {
    fileprivate static var preview: SunscreenTimerAttributes {
        SunscreenTimerAttributes(
            appliedAt: .now,
            reapplyAt: .now.addingTimeInterval(12 * 60),
            spfDisplayTitle: "SPF 50+"
        )
    }
}

extension SunscreenTimerAttributes.ContentState {
    fileprivate static var safe: SunscreenTimerAttributes.ContentState {
        .init(warningLevelRawValue: "safe", progress: 0.15)
    }

    fileprivate static var caution: SunscreenTimerAttributes.ContentState {
        .init(warningLevelRawValue: "caution", progress: 0.4)
    }

    fileprivate static var warning: SunscreenTimerAttributes.ContentState {
        .init(warningLevelRawValue: "warning", progress: 0.6)
    }

    fileprivate static var danger: SunscreenTimerAttributes.ContentState {
        .init(warningLevelRawValue: "danger", progress: 0.85)
    }
}

#Preview("Lock Screen", as: .content, using: SunscreenTimerAttributes.preview) {
    SunscreenTimerLiveActivity()
} contentStates: {
    SunscreenTimerAttributes.ContentState.safe
    SunscreenTimerAttributes.ContentState.caution
    SunscreenTimerAttributes.ContentState.warning
    SunscreenTimerAttributes.ContentState.danger
}

#Preview("Dynamic Island (Expanded)", as: .dynamicIsland(.expanded), using: SunscreenTimerAttributes.preview) {
    SunscreenTimerLiveActivity()
} contentStates: {
    SunscreenTimerAttributes.ContentState.caution
}

#Preview("Dynamic Island (Compact)", as: .dynamicIsland(.compact), using: SunscreenTimerAttributes.preview) {
    SunscreenTimerLiveActivity()
} contentStates: {
    SunscreenTimerAttributes.ContentState.caution
}

#Preview("Dynamic Island (Minimal)", as: .dynamicIsland(.minimal), using: SunscreenTimerAttributes.preview) {
    SunscreenTimerLiveActivity()
} contentStates: {
    SunscreenTimerAttributes.ContentState.caution
}
