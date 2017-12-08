import Foundation

/// MediaCoordinator is responsible for creating and uploading new media
/// items, independently of a specific view controller. It should be accessed
/// via the `shared` singleton.
///
class MediaCoordinator: NSObject {

    @objc static let shared = MediaCoordinator()

    private(set) var backgroundContext = ContextManager.sharedInstance().newDerivedContext()
    private let mainContext = ContextManager.sharedInstance().mainContext

    private let queue = DispatchQueue(label: "org.wordpress.mediauploadcoordinator")

    private lazy var mediaProgressCoordinator: MediaProgressCoordinator = {
        let coordinator = MediaProgressCoordinator()
        coordinator.delegate = self
        return coordinator
    }()

    // Init marked private to ensure use of shared singleton.
    private override init() {}

    // MARK: - Adding Media

    /// Adds the specified media asset to the specified blog. The upload process
    /// can be observed by adding an observer block using the `addObserver(_:for:)` method.
    ///
    /// - parameter asset: The asset to add.
    /// - parameter blog: The blog that the asset should be added to.
    ///
    func addMedia(from asset: ExportableAsset, to blog: Blog) {
        guard let asset = asset as? PHAsset else {
            return
        }

        let service = MediaService(managedObjectContext: backgroundContext)
        service.createMedia(with: asset,
                            objectID: blog.objectID,
                            thumbnailCallback: nil,
                            completion: { [weak self] media, error in
                                guard let media = media else {
                                    return
                                }

                                self?.uploadMedia(media)
        })
    }

    func retryMedia(_ media: Media) {
        guard media.remoteStatus == .failed else {
            DDLogError("Can't retry Media upload that hasn't failed. \(String(describing: media))")
            return
        }

        uploadMedia(media)
    }

    private func uploadMedia(_ media: Media) {
        mediaProgressCoordinator.track(numberOfItems: 1)

        begin(media)

        let service = MediaService(managedObjectContext: backgroundContext)

        var progress: Progress? = nil
        service.uploadMedia(media,
                            progress: &progress,
                            success: {
                                self.end(media)
        }, failure: { error in
            self.mediaProgressCoordinator.attach(error: error as NSError, toMediaID: media.uploadID)
            self.fail(media)
        })
        if let taskProgress = progress {
            self.mediaProgressCoordinator.track(progress: taskProgress, of: media, withIdentifier: media.uploadID)
        }
    }

    // MARK: - Progress

    /// - returns: The current progress for the specified media object.
    ///
    func progress(for media: Media) -> Progress? {
        return mediaProgressCoordinator.progress(forMediaID: media.uploadID)
    }

    // MARK: - Observing

    typealias ObserverBlock = (Media, MediaState) -> Void

    private var mediaObservers = [UUID: MediaObserver]()

    /// Add an observer to receive updates when media items are updated.
    ///
    /// - parameter onUpdate: A block that will be called whenever media items
    ///                       (or a specific media item) are updated. The update
    ///                       block will always be called on the main queue.
    /// - parameter media: An optional specific media item to receive updates for.
    ///                    If provided, the `onUpdate` block will only be called
    ///                    for updates to this media item, otherwise it will be
    ///                    called when changes occur to _any_ media item.
    /// - returns: A UUID that can be used to unregister the observer block at a later time.
    ///
    func addObserver(_ onUpdate: @escaping ObserverBlock, for media: Media? = nil) -> UUID {
        let uuid = UUID()

        let observer = MediaObserver(media: media, onUpdate: onUpdate)

        queue.sync {
            mediaObservers[uuid] = observer
        }

        return uuid
    }

    /// Removes the observer block for the specified UUID.
    ///
    /// - parameter uuid: The UUID that matches the observer to be removed.
    ///
    func removeObserver(withUUID uuid: UUID) {
        queue.sync {
            mediaObservers[uuid] = nil
        }
    }

    /// Encapsulates the state of a media item.
    ///
    enum MediaState: CustomDebugStringConvertible {
        case uploading
        case ended
        case failed
        case progress(value: Double)

        var debugDescription: String {
            switch self {
            case .uploading:
                return "Uploading"
            case .ended:
                return "Ended"
            case .failed:
                return "Failed"
            case .progress(let value):
                return "Progress: \(value)"
            }
        }
    }

    /// Encapsulates an observer block and an optional observed media item.
    struct MediaObserver {
        let media: Media?
        let onUpdate: ObserverBlock
    }

    /// Utility method to return all observers for a specific media item,
    /// including any 'wildcard' observers that are observing _all_ media items.
    ///
    private func observersForMedia(_ media: Media) -> [MediaObserver] {
        let values = mediaObservers.values.filter({ $0.media?.mediaID == media.mediaID })
        return values + wildcardObservers
    }

    /// Utility method to return all 'wildcard' observers that are
    /// observing _all_ media items.
    ///
    private var wildcardObservers: [MediaObserver] {
        return mediaObservers.values.filter({ $0.media == nil })
    }

    // MARK: - Notifying observers

    /// Notifies observers that a media item has begun uploading.
    ///
    func begin(_ media: Media) {
        notifyObserversForMedia(media, ofStateChange: .uploading)
    }

    /// Notifies observers that a media item has ended uploading.
    ///
    func end(_ media: Media) {
        notifyObserversForMedia(media, ofStateChange: .ended)
    }

    /// Notifies observers that a media item has failed to upload.
    ///
    func fail(_ media: Media) {
        notifyObserversForMedia(media, ofStateChange: .failed)
    }

    /// Notifies observers that a media item has ended uploading.
    ///
    func progress(_ value: Double, media: Media) {
        notifyObserversForMedia(media, ofStateChange: .progress(value: value))
    }

    func notifyObserversForMedia(_ media: Media, ofStateChange state: MediaState) {
        queue.async {
            self.observersForMedia(media).forEach({ observer in
                DispatchQueue.main.sync {
                    if let media = self.mainContext.object(with: media.objectID) as? Media {
                        observer.onUpdate(media, state)
                    }
                }
            })
        }
    }

    /// Sync the specified blog media library.
    ///
    /// - parameter blog: The blog from where to sync the media library from.
    ///
    @objc func syncMedia(for blog: Blog, success: (() -> Void)? = nil, failure: ((Error) ->Void)? = nil) {
        let service = MediaService(managedObjectContext: backgroundContext)
        service.syncMediaLibrary(for: blog, success: success, failure: failure)
    }
}

// MARK: - MediaProgressCoordinatorDelegate
extension MediaCoordinator: MediaProgressCoordinatorDelegate {

    func mediaProgressCoordinator(_ mediaProgressCoordinator: MediaProgressCoordinator, progressDidChange totalProgress: Double) {
        for (mediaID, mediaProgress) in mediaProgressCoordinator.mediaInProgress {
            guard let media = mediaProgressCoordinator.media(withIdentifier: mediaID) else {
                continue
            }
            if media.remoteStatus == .pushing {
                progress(mediaProgress.fractionCompleted, media: media)
            }
        }
    }

    func mediaProgressCoordinatorDidStartUploading(_ mediaProgressCoordinator: MediaProgressCoordinator) {

    }

    func mediaProgressCoordinatorDidFinishUpload(_ mediaProgressCoordinator: MediaProgressCoordinator) {

    }
}

extension Media {
    var uploadID: String {
        return objectID.uriRepresentation().absoluteString
    }
}
