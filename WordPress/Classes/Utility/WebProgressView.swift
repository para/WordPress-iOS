import UIKit
import WordPressShared

class WebProgressView: UIProgressView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    func startedLoading() {
        alpha = Animation.visibleAlpha
        progress = Progress.initial
    }

    func finishedLoading() {
        UIView.animate(withDuration: Animation.longDuration, animations: { [weak self] in
            self?.progress = Progress.final
        }, completion: { [weak self] _ in
            UIView.animate(withDuration: Animation.shortDuration, animations: {
                self?.alpha = Animation.hiddenAlhpa
            })
        })
    }

    private func configure() {
        progressTintColor = WPStyleGuide.lightBlue()
    }

    private enum Progress {
        static let initial = Float(0.1)
        static let final = Float(1.0)
    }

    private enum Animation {
        static let shortDuration = 0.1
        static let longDuration = 0.4
        static let visibleAlpha = CGFloat(1.0)
        static let hiddenAlhpa = CGFloat(0.0)
    }
}
