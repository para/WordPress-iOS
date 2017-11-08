import Foundation

struct SiteRef {
    let siteID: Int
    let accountID: Int

    init(siteID: Int, accountID: Int) {
        self.siteID = siteID
        self.accountID = accountID
    }

    init?(blog: Blog) {
        guard let dotComID = blog.dotComID as? Int,
            let accountID = blog.account?.userID as? Int else {
                return nil
        }

        self.siteID = dotComID
        self.accountID = accountID
    }
}

extension SiteRef: Equatable {
    public static func ==(lhs: SiteRef, rhs: SiteRef) -> Bool {
        return lhs.accountID == rhs.accountID
            && lhs.siteID == rhs.accountID
    }
}

extension SiteRef: Hashable {
    var hashValue: Int {
        return accountID.hashValue ^ siteID.hashValue
    }
}
