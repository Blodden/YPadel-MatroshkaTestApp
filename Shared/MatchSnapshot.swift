import Foundation

enum MatchSide {
    case left
    case right
}

enum MatchState: String, Codable {
    case active
    case finished
}

struct MatchSnapshot: Codable {
    var leftName: String
    var rightName: String
    var leftPoints: Int
    var rightPoints: Int
    var leftGames: Int
    var rightGames: Int
    var leftSets: Int
    var rightSets: Int
    var state: MatchState
    var revision: Int
    var updatedAt: Date

    init(
        leftName: String = "Мы",
        rightName: String = "Соперники",
        leftPoints: Int = 0,
        rightPoints: Int = 0,
        leftGames: Int = 0,
        rightGames: Int = 0,
        leftSets: Int = 0,
        rightSets: Int = 0,
        state: MatchState = .active,
        revision: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.leftName = leftName
        self.rightName = rightName
        self.leftPoints = leftPoints
        self.rightPoints = rightPoints
        self.leftGames = leftGames
        self.rightGames = rightGames
        self.leftSets = leftSets
        self.rightSets = rightSets
        self.state = state
        self.revision = revision
        self.updatedAt = updatedAt
    }

    var isTieBreak: Bool {
        leftGames == 6 && rightGames == 6
    }

    var pointsScoreText: String {
        if isTieBreak {
            return "\(leftPoints) : \(rightPoints)"
        }
        return "\(regularPointText(leftPoints)) : \(regularPointText(rightPoints))"
    }

    var gamesScoreText: String {
        "\(leftGames) : \(rightGames)"
    }

    var setsScoreText: String {
        "\(leftSets) : \(rightSets)"
    }

    var scoreSummary: String {
        "Очки \(pointsScoreText) • Геймы \(gamesScoreText) • Сеты \(setsScoreText)"
    }

    func awardingPoint(to side: MatchSide) -> MatchSnapshot {
        guard state == .active else { return self }
        var next = self
        next.revision += 1
        next.updatedAt = Date()

        if next.isTieBreak {
            switch side {
            case .left:
                next.leftPoints += 1
            case .right:
                next.rightPoints += 1
            }
            if max(next.leftPoints, next.rightPoints) >= 7,
               abs(next.leftPoints - next.rightPoints) >= 2 {
                next.completeSet(for: next.leftPoints > next.rightPoints ? .left : .right)
            }
            return next
        }

        let gameWinner: MatchSide?
        switch side {
        case .left:
            if next.leftPoints < 3 {
                next.leftPoints += 1
                gameWinner = nil
            } else if next.leftPoints == 3, next.rightPoints == 3 {
                next.leftPoints = 4
                gameWinner = nil
            } else if next.leftPoints == 3, next.rightPoints == 4 {
                next.rightPoints = 3
                gameWinner = nil
            } else {
                gameWinner = .left
            }
        case .right:
            if next.rightPoints < 3 {
                next.rightPoints += 1
                gameWinner = nil
            } else if next.rightPoints == 3, next.leftPoints == 3 {
                next.rightPoints = 4
                gameWinner = nil
            } else if next.rightPoints == 3, next.leftPoints == 4 {
                next.leftPoints = 3
                gameWinner = nil
            } else {
                gameWinner = .right
            }
        }

        if let gameWinner {
            next.completeGame(for: gameWinner)
        }
        return next
    }

    func finishing() -> MatchSnapshot {
        var next = self
        next.state = .finished
        next.revision += 1
        next.updatedAt = Date()
        return next
    }

    func resetting() -> MatchSnapshot {
        MatchSnapshot(
            leftName: leftName,
            rightName: rightName,
            revision: revision + 1
        )
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

    private func regularPointText(_ points: Int) -> String {
        switch points {
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        case 4: return "БОЛ"
        default: return "0"
        }
    }

    private mutating func completeGame(for side: MatchSide) {
        leftPoints = 0
        rightPoints = 0
        switch side {
        case .left:
            leftGames += 1
        case .right:
            rightGames += 1
        }

        if max(leftGames, rightGames) >= 6, abs(leftGames - rightGames) >= 2 {
            completeSet(for: leftGames > rightGames ? .left : .right)
        }
    }

    private mutating func completeSet(for side: MatchSide) {
        leftPoints = 0
        rightPoints = 0
        leftGames = 0
        rightGames = 0
        switch side {
        case .left:
            leftSets += 1
        case .right:
            rightSets += 1
        }
        if max(leftSets, rightSets) >= 2 {
            state = .finished
        }
    }
}
