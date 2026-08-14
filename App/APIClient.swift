import Foundation

struct SyncRequest: Encodable {
    let installationId: String
    let deviceToken: String?
    let match: MatchSnapshot
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession) {
        self.baseURL = baseURL
        self.session = session
    }

    func checkHealth(completion: @escaping (Bool) -> Void) {
        let request = URLRequest(url: baseURL.appendingPathComponent("health"))
        session.dataTask(with: request) { _, response, _ in
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            DispatchQueue.main.async { completion(statusCode == 200) }
        }.resume()
    }

    func sync(_ payload: SyncRequest, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: baseURL.appendingPathComponent("sync"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(payload)

        session.dataTask(with: request) { _, response, _ in
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            DispatchQueue.main.async { completion(statusCode == 200) }
        }.resume()
    }
}
