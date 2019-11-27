import Foundation
import SwiftSoup
import Combine
import CoreGraphics

public struct Frigg {
    public static let shared = Frigg()
    
    var session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func parse(_ urlString: String) -> AnyPublisher<Metadata, Error>? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        return parse(url)
    }
    
    public func parse(_ url: URL) -> AnyPublisher<Metadata, Error> {
        parseDocumentPublisher(for: documentPublisher(for: url))
    }
    
    func documentPublisher(for url: URL) -> AnyPublisher<Document, Error> {
        session.dataTaskPublisher(for: url)
        .compactMap { String(data: $0.data, encoding: .utf8) }
        .tryMap { try SwiftSoup.parse($0) }
        .eraseToAnyPublisher()
    }
    
    func parseDocumentPublisher(for publisher: AnyPublisher<Document, Error>) -> AnyPublisher<Metadata, Error> {
        publisher
        .tryMap { try Metadata($0.head() ?? $0) }
        .eraseToAnyPublisher()
    }
}

extension Element {
    enum PropertyKey: String {
        case title
        case image
        case imageHeight = "image:height"
        case imageWidth = "image:width"
        case description
        case type
    }
    
    func fetchGraphContent(for property: PropertyKey, fallback: String?) throws -> String? {
        try self.select("meta[property=\"og:\(property.rawValue)\"]").first()?.attr("content") ?? fallback
    }
    
    func fetchContent(for property: PropertyKey, fallback: String?) throws -> String? {
        try self.select("meta[property=\"\(property.rawValue)\"]").first()?.attr("content") ?? fallback
    }
    
    func fetchContent(for property: String, fallback: String?) throws -> String? {
        try self.select("meta[property=\"\(property)\"]").first()?.attr("content") ?? fallback
    }
}

public struct Metadata {
    public enum MetadataType: String {
        case music
        case musicSong = "music.song"
        case musicPlaylist = "music.playlist"
        case musicAlbum = "music.album"
        case musicRadioStation = "music.radio_station"
        
        case videoMovie = "video.movie"
        case videoEpisode = "video.episode"
        case videoTvShow = "video.tv_show"
        case video
        case article
        case book
        case profile
        case website
        
        case fileImage = "file.image"
        case fileVideo = "file.video"
        case fileAudio = "file.audio"
        case fileDocument = "file.document"
        case fileArchive = "file.archive"
        case fileOther = "file.other"
    }
    
    public var title: String?
    public var type: MetadataType
    public var description: String?
    public var imageURL: URL?
    public var imageSize: CGSize?

    public init(_ head: Element) throws {
        title = try head.fetchGraphContent(for: .title, fallback: head.ownerDocument()?.title())
        
        type = MetadataType(rawValue: try head.fetchGraphContent(for: .type, fallback: nil) ?? MetadataType.website.rawValue) ?? .website
        
        description = try head.fetchGraphContent(for: .description, fallback: head.fetchContent(for: .description, fallback: nil))
        
        if let imageURL = try head.fetchGraphContent(for: .image, fallback: head.fetchContent(for: "thumbnail", fallback: nil)) {
            self.imageURL = URL(string: imageURL)
        }
        
        if let imageWidth = try Double(head.fetchGraphContent(for: .imageWidth, fallback: nil) ?? ""),
           let imageHeight = try Double(head.fetchGraphContent(for: .imageHeight, fallback: nil) ?? "") {

            if imageHeight + imageWidth > 0 {
                imageSize = CGSize(width: imageWidth, height: imageHeight)
            }
            
        } else {
            imageSize = nil
        }
    }
}
