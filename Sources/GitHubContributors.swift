import Foundation

// MARK: - GitHub Contributors

/// Lightweight model for a GitHub contributor returned by the API.
struct Contributor: Codable, Identifiable, Equatable {
    let id: Int
    let login: String
    /// HTML URL to the contributor's GitHub profile.
    let htmlURL: String
    /// Avatar image URL (32px).
    let avatarURL: String
    let contributions: Int

    enum CodingKeys: String, CodingKey {
        case id, login
        case htmlURL = "html_url"
        case avatarURL = "avatar_url"
        case contributions
    }
}

/// Fetches and caches GitHub contributors for the DrogaBox/RTLWifiTahoe repo.
/// Uses URLSession with a short timeout; fails gracefully (returns empty array).
enum GitHubContributors {
    private static let repo = "DrogaBox/RTLWifiTahoe"
    private static let apiURL = URL(string: "https://api.github.com/repos/\(repo)/contributors?per_page=20")!

    /// In-memory cache so we don't re-fetch on every panel open.
    private static var cached: [Contributor]?
    /// When the cache was last populated (avoid re-fetching within 5 minutes).
    private static var cachedAt: Date?

    /// Fetch the contributor list from GitHub, or return cached data if fresh.
    /// - Parameter forceRefresh: Bypass the 5-min cache window.
    /// - Returns: Sorted list of contributors (most contributions first), or empty on failure.
    static func fetch(forceRefresh: Bool = false) async -> [Contributor] {
        // Use cached result if it's less than 5 minutes old.
        if !forceRefresh, let cached, let cachedAt, Date().timeIntervalSince(cachedAt) < 300 {
            return cached
        }

        var req = URLRequest(url: apiURL)
        req.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 8

        // GitHub API may 403 without a User-Agent, so set one.
        req.setValue("RTLWifiTahoe/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                return cached ?? []
            }
            let decoder = JSONDecoder()
            let contributors = try decoder.decode([Contributor].self, from: data)
                .sorted { $0.contributions > $1.contributions }

            // Populate cache.
            cached = contributors
            cachedAt = Date()
            return contributors
        } catch {
            // Network error, rate limit, etc. — return stale cache or empty.
            return cached ?? []
        }
    }

    /// Reset the cache (e.g. for testing or manual refresh).
    static func clearCache() {
        cached = nil
        cachedAt = nil
    }
}
