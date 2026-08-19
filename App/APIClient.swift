import Foundation

struct PushRegistration: Codable {
    let token: String?
    let environment: String
    let enabled: Bool
}

struct SyncRequest: Encodable {
    let appId: String
    let installationId: String
    let matchToken: String?
    let clientRevision: Int
    let snapshot: MatchSnapshot
    let push: PushRegistration
}

struct SyncResponse: Decodable {
    let status: String
    let matchToken: String
    let serverRevision: Int
    let snapshot: MatchSnapshot
    let pushStatus: String
    let serverTime: String
}

struct FeatureFlagsResponse: Decodable {
    let flags: [String: Bool]
}

final class FeatureFlagStore {
    enum Source {
        case defaultValue
        case cached
        case remote
    }

    private let defaults: UserDefaults
    private let cloudSyncKey: String
    private let appVersion: String
    private let appGroupIdentifier: String
    private(set) var cloudSyncEnabled: Bool
    private(set) var source: Source

    init(defaults: UserDefaults, appVersion: String, appGroupIdentifier: String) {
        let key = "feature.cloudSyncEnabled.\(appVersion)"
        self.defaults = defaults
        cloudSyncKey = key
        self.appVersion = appVersion
        self.appGroupIdentifier = appGroupIdentifier
        if defaults.object(forKey: key) == nil {
            cloudSyncEnabled = true
            source = .defaultValue
        } else {
            cloudSyncEnabled = defaults.bool(forKey: key)
            source = .cached
        }
        SharedFeatureFlags.saveCloudSyncEnabled(
            cloudSyncEnabled,
            appVersion: appVersion,
            groupIdentifier: appGroupIdentifier
        )
    }

    @discardableResult
    func apply(_ response: FeatureFlagsResponse) -> Bool {
        guard let enabled = response.flags["cloudSyncEnabled"] else { return false }
        cloudSyncEnabled = enabled
        source = .remote
        defaults.set(enabled, forKey: cloudSyncKey)
        SharedFeatureFlags.saveCloudSyncEnabled(
            enabled,
            appVersion: appVersion,
            groupIdentifier: appGroupIdentifier
        )
        return true
    }
}

enum APIClientError: LocalizedError {
    case invalidResponse
    case serverStatus(Int)
    case encoding

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Сервер вернул неизвестный ответ"
        case let .serverStatus(status):
            return "Сервер вернул код \(status)"
        case .encoding:
            return "Не удалось подготовить данные"
        }
    }
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(baseURL: URL, session: URLSession) {
        self.baseURL = baseURL
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    @discardableResult
    func fetchFeatureFlags(
        appId: String,
        appVersion: String,
        completion: @escaping (Result<FeatureFlagsResponse, Error>) -> Void
    ) -> URLSessionDataTask? {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("config"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "appId", value: appId),
            URLQueryItem(name: "appVersion", value: appVersion)
        ]
        guard let url = components?.url else {
            completion(.failure(APIClientError.encoding))
            return nil
        }

        let task = session.dataTask(with: URLRequest(url: url)) { [decoder] data, response, error in
            let result: Result<FeatureFlagsResponse, Error>
            if let error {
                result = .failure(error)
            } else if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                result = .failure(APIClientError.serverStatus(response.statusCode))
            } else if let data, let decoded = try? decoder.decode(FeatureFlagsResponse.self, from: data) {
                result = .success(decoded)
            } else {
                result = .failure(APIClientError.invalidResponse)
            }
            DispatchQueue.main.async { completion(result) }
        }
        task.resume()
        return task
    }

    func sync(_ payload: SyncRequest, completion: @escaping (Result<SyncResponse, Error>) -> Void) {
        var request = URLRequest(url: baseURL.appendingPathComponent("sync"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(payload)
        } catch {
            completion(.failure(APIClientError.encoding))
            return
        }

        session.dataTask(with: request) { [decoder] data, response, error in
            let result: Result<SyncResponse, Error>
            if let error {
                result = .failure(error)
            } else if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                result = .failure(APIClientError.serverStatus(response.statusCode))
            } else if let data, let decoded = try? decoder.decode(SyncResponse.self, from: data) {
                result = .success(decoded)
            } else {
                result = .failure(APIClientError.invalidResponse)
            }
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }
}
