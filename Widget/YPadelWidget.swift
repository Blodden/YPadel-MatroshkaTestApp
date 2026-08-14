import SwiftUI
import WidgetKit

struct MatchEntry: TimelineEntry {
    let date: Date
    let snapshot: MatchSnapshot
}

struct MatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> MatchEntry {
        MatchEntry(date: Date(), snapshot: MatchSnapshot(leftScore: 3, rightScore: 2))
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
            ?? "group.com.example.ypadel"
        return MatchEntry(
            date: Date(),
            snapshot: MatchSnapshot.load(groupIdentifier: groupIdentifier)
        )
    }
}

struct MatchLockScreenView: View {
    let entry: MatchEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "tennisball.fill")
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("YPadel • текущий матч")
                    .font(.caption2)
                Text("\(entry.snapshot.leftScore) : \(entry.snapshot.rightScore)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }
            Spacer(minLength: 0)
        }
        .widgetURL(URL(string: "ypadel://match"))
    }
}

@main
struct YPadelWidget: Widget {
    let kind = "YPadelLockScreenScore"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MatchProvider()) { entry in
            MatchLockScreenView(entry: entry)
        }
        .configurationDisplayName("Счет YPadel")
        .description("Текущий счет матча на экране блокировки.")
        .supportedFamilies([.accessoryRectangular])
    }
}
