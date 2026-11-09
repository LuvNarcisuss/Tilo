import Foundation

struct ProfileDisplayBaseline: Codable, Hashable {
    let likes: Int
    let saves: Int
    let following: Int
    let followers: Int
}

struct PublisherSummary: Codable, Hashable {
    let id: UUID
    let displayName: String
    let avatarURL: String?
    let isEditorial: Bool
}

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var displayName: String
    var username: String
    var bio: String
    var avatarURL: String?
    var dietaryTags: [String]
    var skillLevel: String
    var worksCount: Int
    var followersCount: Int
    var followingCount: Int
    var likesCount: Int
    var savesCount: Int
    var isEditorial: Bool? = nil
    var displayBaseline: ProfileDisplayBaseline? = nil

    var visibleMetrics: [Int] {
        let base = isEditorial == true ? displayBaseline : nil
        return [likesCount + (base?.likes ?? 0), savesCount + (base?.saves ?? 0),
                followingCount + (base?.following ?? 0), followersCount + (base?.followers ?? 0)]
    }
}

struct Conversation: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var isGroup: Bool
    var ownerID: UUID
    var lastMessage: String?
    var updatedAt: String
    var unreadCount: Int
    var isPinned: Bool
    var isMuted: Bool
    var draft: String
    var peerID: UUID?
    var avatarURL: String?
}

struct Message: Codable, Identifiable, Hashable {
    let id: UUID
    let conversationID: UUID
    let senderID: UUID
    let clientID: UUID
    let body: String
    let createdAt: String
    let imagePath: String?
}

struct RecipeIngredient: Codable, Hashable {
    let name: String
    let quantity: String
    let unit: String
}

struct RecipeTutorial: Codable, Hashable {
    let videoID:String
    let title:String
    let author:String
    let sourceURL:String
    let provider:String
    let note:String
    var validatedVideoID:String? {
        guard provider == "YouTube",videoID.range(of:"^[A-Za-z0-9_-]{11}$",options:.regularExpression) != nil,
              let url = URL(string:sourceURL),url.scheme == "https",url.host == "www.youtube.com",url.path == "/watch",
              URLComponents(url:url,resolvingAgainstBaseURL:false)?.queryItems?.first(where:{$0.name == "v"})?.value == videoID else { return nil }
        return videoID
    }
}

struct RecipePayload: Codable, Hashable {
    let summary: String
    let prepMinutes: Int
    let cookMinutes: Int
    let servings: Int
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let difficulty: String
    let ingredients: [RecipeIngredient]
    let steps: [String]
    let tags: [String]
    var tutorial:RecipeTutorial? = nil
}

struct Recipe: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let imageURL: String?
    let payload: RecipePayload
    var publisher: PublisherSummary? = nil
}

struct VideoPayload: Codable, Hashable {
    let chef: String
    let durationSeconds: Int
    let summary: String
    let recipeID: String?
}

struct CookingVideo: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let imageURL: String?
    let videoURL: String?
    let payload: VideoPayload
    var publisher: PublisherSummary? = nil
}

struct ContentComment: Codable, Identifiable, Hashable {
    let id: UUID
    let contentID: String
    let userID: UUID
    let displayName: String
    let avatarURL: String?
    let body: String
    let createdAt: String
}

struct ContentSafetyContext: Decodable {
    let kind: String
    let id: String
    let title: String
    let authorID: UUID?
    let authorName: String?
    let isOwn: Bool
}

struct HiddenContent: Decodable {
    let kind: String
    let id: String
    let title: String
}

struct MealPlan: Codable, Identifiable, Hashable {
    let id: UUID
    let date: String
    let slot: String
    let recipeID: String
    let recipeTitle: String
    let imageURL: String?
}

struct GroceryItem: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let quantity: String
    let checked: Bool
}

struct RecipeDraft: Codable {
    var id: String
    var title: String
    var category: String
    var imageURL: String?
    var payload: RecipePayload
}
