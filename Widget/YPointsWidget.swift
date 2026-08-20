import SwiftUI
import WidgetKit

struct MatchEntry: TimelineEntry {
    let date: Date
    let snapshot: MatchSnapshot
    let isActive: Bool
}

struct MatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> MatchEntry {
        MatchEntry(
            date: Date(),
            snapshot: MatchSnapshot(
                leftPoints: 2,
                rightPoints: 1,
                leftGames: 3,
                rightGames: 2,
                leftSets: 1
            ),
            isActive: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MatchEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MatchEntry>) -> Void) {
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
    }

    private func makeEntry() -> MatchEntry {
        let groupIdentifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String
            ?? "group.com.idev.ypoints"
#if IMPORTED_WIDGET_AVAILABLE
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "0"
        let isActive = !SharedFeatureFlags.cloudSyncEnabled(
            appVersion: appVersion,
            groupIdentifier: groupIdentifier
        )
#else
        let isActive = true
#endif
        return MatchEntry(
            date: Date(),
            snapshot: MatchSnapshot.load(groupIdentifier: groupIdentifier),
            isActive: isActive
        )
    }
}

struct MatchLockScreenView: View {
    let entry: MatchEntry

    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content
                .containerBackground(.clear, for: .widget)
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if entry.isActive {
            scoreContent
        } else {
            inactiveContent
        }
    }

    private var scoreContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "number")
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(
                    entry.snapshot.state == .finished
                        ? L10n.text("match.finishedPlain")
                        : L10n.text("match.section")
                )
                    .font(.caption2)
                Text(entry.snapshot.pointsScoreText)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(
                    L10n.format(
                        "widget.scoreDetailsFormat",
                        entry.snapshot.gamesScoreText,
                        entry.snapshot.setsScoreText
                    )
                )
                    .font(.caption2)
            }
            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "ypoints://match"))
    }

    private var inactiveContent: some View {
        HStack(spacing: 8) {
            Image(systemName: "nosign")
                .font(.title3)
            Text(L10n.text("widget.inactive"))
                .font(.caption)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "ypoints://match"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text("widget.inactive"))
    }
}

struct YPointsWidget: Widget {
    let kind = "YPointsLockScreenScore"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MatchProvider()) { entry in
            MatchLockScreenView(entry: entry)
        }
        .configurationDisplayName(L10n.text("widget.displayName"))
        .description(L10n.text("widget.description"))
        .supportedFamilies([.accessoryRectangular])
    }
}

@main
struct YPointsWidgetBundle: WidgetBundle {
    var body: some Widget {
        YPointsWidget()

#if IMPORTED_WIDGET_AVAILABLE
        ImportedWidget()

        if #available(iOSApplicationExtension 18.0, *) {
            ImportedControlWidget()
        }
#endif
    }
}
