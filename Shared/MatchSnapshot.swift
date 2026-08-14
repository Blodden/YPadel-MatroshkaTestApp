import Foundation

struct MatchSnapshot: Codable {
    let leftName: String
    let rightName: String
    let leftScore: Int
    let rightScore: Int
    let updatedAt: Date

    init(
        leftName: String = "Мы",
        rightName: String = "Соперники",
        leftScore: Int = 0,
        rightScore: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.leftName = leftName
        self.rightName = rightName
        self.leftScore = leftScore
        self.rightScore = rightScore
        self.updatedAt = updatedAt
    }

    func save(groupIdentifier: String) {
        guard
            let defaults = UserDefaults(suiteName: groupIdentifier),
            let data = try? JSONEncoder().encode(self)
        else { return }

        defaults.set(data, forKey: "match.snapshot")
    }

    static func load(groupIdentifier: String) -> MatchSnapshot {
        guard
            let defaults = UserDefaults(suiteName: groupIdentifier),
            let data = defaults.data(forKey: "match.snapshot"),
            let snapshot = try? JSONDecoder().decode(MatchSnapshot.self, from: data)
        else {
            return MatchSnapshot()
        }

        return snapshot
    }
}
