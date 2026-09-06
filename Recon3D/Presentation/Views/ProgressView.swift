import UIKit

class ProgressView: UIProgressView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        progressTintColor = .systemBlue
        trackTintColor = .systemGray
    }
    required init?(coder: NSCoder) { fatalError() }
}
