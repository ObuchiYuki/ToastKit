import UIKit

open class ToastView: UIView {
    
    // MARK: - UIAppearance

    @objc dynamic open var duration: TimeInterval = 2
    
    // MARK: - Properties

    open var presentSide: ToastPresentSide = .top
    
    open var dismissByDrag: Bool = true {
        didSet { self.setGesture() }
    }
    
    open var completion: (() -> Void)? = nil
    
    // MARK: - Views
    
    open var titleLabel: UILabel?
    open var subtitleLabel: UILabel?
    open var iconView: UIView?
    
    private lazy var backgroundView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        view.isUserInteractionEnabled = false
        return view
    }()
    
    weak open var presentWindow: UIWindow?
    
    // MARK: - Init
    
    public init(title: String, message: String? = nil, preset: ToastIconPreset) {
        super.init(frame: CGRect.zero)
        self.commonInit()
        self.layout = ToastLayout(for: preset)
        self.setTitle(title)
        if let message = message {
            self.setMessage(message)
        }
        self.setIcon(for: preset)
    }
    
    public init(title: String, message: String?) {
        super.init(frame: CGRect.zero)
        self.titleAreaFactor = 1.8
        self.minimumAreaWidth = 100
        self.commonInit()
        self.layout = ToastLayout.message()
        self.setTitle(title)
        if let message = message {
            self.setMessage(message)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.presentSide = .top
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.preservesSuperviewLayoutMargins = false
        self.insetsLayoutMarginsFromSafeArea = false
        
        self.backgroundColor = .clear
        self.backgroundView.layer.masksToBounds = true
        self.addSubview(backgroundView)
        
        self.setShadow()
        self.setGesture()
    }
    
    // MARK: - Configure
    
    private func setTitle(_ text: String) {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote, weight: .semibold, addPoints: 0)
        label.numberOfLines = 1
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        style.lineSpacing = 3
        label.attributedText = NSAttributedString(
            string: text, attributes: [.paragraphStyle: style]
        )
        label.textAlignment = .center
        label.textColor = UIColor.label.withAlphaComponent(0.6)
        titleLabel = label
        addSubview(label)
    }
    
    private func setMessage(_ text: String) {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote, weight: .semibold, addPoints: 0)
        label.numberOfLines = 1
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        style.lineSpacing = 2
        label.attributedText = NSAttributedString(
            string: text, attributes: [.paragraphStyle: style]
        )
        label.textAlignment = .center
        label.textColor = UIColor.label.withAlphaComponent(0.3)
        subtitleLabel = label
        self.addSubview(label)
    }
    
    private func setIcon(for preset: ToastIconPreset) {
        let view = preset.createView()
        self.iconView = view
        self.addSubview(view)
    }
    
    private func setShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.22
        self.layer.shadowOffset = .init(width: 0, height: 7)
        self.layer.shadowRadius = 40
    }
    
    private func setGesture() {
        if self.dismissByDrag {
            let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            self.addGestureRecognizer(gestureRecognizer)
            self.gestureRecognizer = gestureRecognizer
        } else {
            self.gestureRecognizer = nil
        }
    }
    
    // MARK: - Present
    
    private var presentAndDismissDuration: TimeInterval = 0.6
    
    private var presentWithOpacity: Bool {
        if presentSide == .center { return true }
        return false
    }
    
    open func present(haptic: ToastHaptic = .success, completion: (() -> Void)? = nil) {
        present(duration: self.duration, haptic: haptic, completion: completion)
    }
    
    open func present(duration: TimeInterval, haptic: ToastHaptic = .success, completion: (() -> Void)? = nil) {
        
        if self.presentWindow == nil {
            assert(!UIApplication.shared.supportsMultipleScenes, "ToastView: You should set presentWindow for multiple scenes.")
            self.presentWindow = UIApplication.shared.sceneKeyWindows.first
        }
        
        guard let window = self.presentWindow else { return }
        
        window.addSubview(self)
        
        // Prepare for present
        
        self.whenGestureEndShoudHide = false
        self.completion = completion
        
        isHidden = true
        sizeToFit()
        self.layoutSubviews()
        center.x = window.frame.midX
        self.toPresentPosition(.prepare(presentSide))
        
        self.alpha = self.presentWithOpacity ? 0 : 1
        
        // Present
        
        isHidden = false
        haptic.impact()
        UIView.animate(withDuration: self.presentAndDismissDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            self.toPresentPosition(.visible(self.presentSide))
            if self.presentWithOpacity { self.alpha = 1 }
        }, completion: { finished in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                if self.gestureIsDragging {
                    self.whenGestureEndShoudHide = true
                } else {
                    self.dismiss()
                }
            }
        })
        
        if let iconView = self.iconView as? ToastIconAnimatable {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + presentAndDismissDuration / 3) {
                iconView.animate()
            }
        }
    }
    
    @objc open func dismiss() {
        UIView.animate(withDuration: presentAndDismissDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            self.toPresentPosition(.prepare(self.presentSide))
            if self.presentWithOpacity { self.alpha = 0 }
        }, completion: { finished in
            self.removeFromSuperview()
            self.completion?()
        })
    }
    
    // MARK: - Internal
    
    private var minimumYTranslationForHideByGesture: CGFloat = -10
    private var maximumYTranslationByGesture: CGFloat = 60
    
    private var gestureRecognizer: UIPanGestureRecognizer?
    private var gestureIsDragging: Bool = false
    private var whenGestureEndShoudHide: Bool = false
    
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            self.gestureIsDragging = true
            let translation = gestureRecognizer.translation(in: self)
            let newTranslation: CGFloat = {
                switch presentSide {
                case .top:
                    if translation.y <= 0 {
                        return translation.y
                    } else {
                        return min(maximumYTranslationByGesture, translation.y.squareRoot())
                    }
                case .bottom:
                    if translation.y >= 0 {
                        return translation.y
                    } else {
                        let absolute = abs(translation.y)
                        return -min(maximumYTranslationByGesture, absolute.squareRoot())
                    }
                case .center:
                    let absolute = abs(translation.y).squareRoot()
                    let newValue = translation.y < 0 ? -absolute : absolute
                    return min(maximumYTranslationByGesture, newValue)
                }
            }()
            toPresentPosition(.fromVisible(newTranslation, from: (presentSide)))
        }
        
        if gestureRecognizer.state == .ended {
            gestureIsDragging = false
            
            var shoudDismissWhenEndAnimation: Bool = false
            
            UIView.animate(withDuration: presentAndDismissDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
                if self.whenGestureEndShoudHide {
                    self.toPresentPosition(.prepare(self.presentSide))
                    shoudDismissWhenEndAnimation = true
                } else {
                    let translation = gestureRecognizer.translation(in: self)
                    if translation.y < self.minimumYTranslationForHideByGesture {
                        self.toPresentPosition(.prepare(self.presentSide))
                        shoudDismissWhenEndAnimation = true
                    } else {
                        self.toPresentPosition(.visible(self.presentSide))
                    }
                }
            }, completion: { _ in
                if shoudDismissWhenEndAnimation {
                    self.dismiss()
                }
            })
        }
    }
    
    private func toPresentPosition(_ position: PresentPosition) {
        
        let getPrepareTransform: ((_ side: ToastPresentSide) -> CGAffineTransform) = { [weak self] side in
            guard let self = self else { return .identity }
                        
            guard let window = UIApplication.shared.sceneWindows.first else { return .identity }
            switch side {
            case .top:
                let topInset = window.safeAreaInsets.top
                let position = -(topInset + 50)
                return CGAffineTransform.identity.translatedBy(x: 0, y: position)
            case .bottom:
                let height = window.frame.height
                let bottomInset = window.safeAreaInsets.bottom
                let position = height + bottomInset + 50
                return CGAffineTransform.identity.translatedBy(x: 0, y: position)
            case .center:
                return CGAffineTransform.identity.translatedBy(x: 0, y: window.frame.height / 2 - self.frame.height / 2).scaledBy(x: 0.9, y: 0.9)
            }
        }
        
        let getVisibleTransform: ((_ side: ToastPresentSide) -> CGAffineTransform) = { [weak self] side in
            guard let self = self else { return .identity }
            guard let window = UIApplication.shared.sceneWindows.first else { return .identity }
            switch side {
            case .top:
                var topSafeAreaInsets = window.safeAreaInsets.top
                if topSafeAreaInsets < 20 { topSafeAreaInsets = 20 }
                let position = topSafeAreaInsets - 3 + self.offset
                return CGAffineTransform.identity.translatedBy(x: 0, y: position)
            case .bottom:
                let height = window.frame.height
                var bottomSafeAreaInsets = window.safeAreaInsets.top
                if bottomSafeAreaInsets < 20 { bottomSafeAreaInsets = 20 }
                let position = height - bottomSafeAreaInsets - 3 - self.frame.height - self.offset
                return CGAffineTransform.identity.translatedBy(x: 0, y: position)
            case .center:
                return CGAffineTransform.identity.translatedBy(x: 0, y: window.frame.height / 2 - self.frame.height / 2)
            }
        }
        
        switch position {
        case .prepare(let presentSide):
            transform = getPrepareTransform(presentSide)
        case .visible(let presentSide):
            transform = getVisibleTransform(presentSide)
        case .fromVisible(let translation, let presentSide):
            transform = getVisibleTransform(presentSide).translatedBy(x: 0, y: translation)
        }
    }
    
    // MARK: - Layout
    
    /**
     SPIndicator: Wraper of layout values.
     */
    open var layout: ToastLayout = .init()
    
    /**
     SPIndicator: Alert offset
     */
    open var offset: CGFloat = 0
    
    private var areaHeight: CGFloat = 50
    private var minimumAreaWidth: CGFloat = 196
    private var maximumAreaWidth: CGFloat = 260
    private var titleAreaFactor: CGFloat = 2.5
    private var spaceBetweenTitles: CGFloat = 1
    private var spaceBetweenTitlesAndImage: CGFloat = 16
    
    private var titlesCompactWidth: CGFloat {
        if let iconView = self.iconView {
            let space = iconView.frame.maxY + spaceBetweenTitlesAndImage
            return frame.width - space * 2
        } else {
            return frame.width - layoutMargins.left - layoutMargins.right
        }
    }
    
    private var titlesFullWidth: CGFloat {
        if let iconView = self.iconView {
            let space = iconView.frame.maxY + spaceBetweenTitlesAndImage
            return frame.width - space - layoutMargins.right - self.spaceBetweenTitlesAndImage
        } else {
            return frame.width - layoutMargins.left - layoutMargins.right
        }
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        titleLabel?.sizeToFit()
        let titleWidth: CGFloat = titleLabel?.frame.width ?? 0
        subtitleLabel?.sizeToFit()
        let subtitleWidth: CGFloat = subtitleLabel?.frame.width ?? 0
        var width = (max(titleWidth, subtitleWidth) * titleAreaFactor).rounded()
        
        if width < minimumAreaWidth { width = minimumAreaWidth }
        if width > maximumAreaWidth { width = maximumAreaWidth }
        
        return .init(width: width, height: areaHeight)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutMargins = layout.margins
        layer.cornerRadius = frame.height / 2
        backgroundView.frame = bounds
        backgroundView.layer.cornerRadius = layer.cornerRadius
        
        // Flags
        
        let hasIcon = (self.iconView != nil)
        let hasTitle = (self.titleLabel != nil)
        let hasSubtite = (self.subtitleLabel != nil)
        
        let fitTitleToCompact: Bool = {
            guard let titleLabel = self.titleLabel else { return true }
            titleLabel.numberOfLines = 1
            titleLabel.sizeToFit()
            return titleLabel.frame.width < titlesCompactWidth
        }()
        
        let fitSubtitleToCompact: Bool = {
            guard let subtitleLabel = self.subtitleLabel else { return true }
            subtitleLabel.numberOfLines = 1
            subtitleLabel.sizeToFit()
            return subtitleLabel.frame.width < titlesCompactWidth
        }()
        
        let notFitAnyLabelToCompact: Bool = {
            if !fitTitleToCompact { return true }
            if !fitSubtitleToCompact { return true }
            return false
        }()
        
        var layout: LayoutGrid = .iconTitleCentered
        
        if (hasIcon && hasTitle && hasSubtite) && !notFitAnyLabelToCompact {
            layout = .iconTitleMessageCentered
        }
        
        if (hasIcon && hasTitle && hasSubtite) && notFitAnyLabelToCompact {
            layout = .iconTitleMessageLeading
        }
        
        if (hasIcon && hasTitle && !hasSubtite) {
            layout = .iconTitleCentered
        }
        
        if (!hasIcon && hasTitle && !hasSubtite) {
            layout = .title
        }
        
        if (!hasIcon && hasTitle && hasSubtite) {
            layout = .titleMessage
        }
        
        // Actions
        
        let layoutIcon = { [weak self] in
            guard let self = self else { return }
            guard let iconView = self.iconView else { return }
            iconView.frame = .init(
                origin: .init(x: self.layoutMargins.left, y: iconView.frame.origin.y),
                size: self.layout.iconSize
            )
            iconView.center.y = self.bounds.midY
        }
        
        let layoutTitleCenteredCompact = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            titleLabel.textAlignment = .center
            titleLabel.layoutDynamicHeight(width: self.titlesCompactWidth)
            titleLabel.center.x = self.frame.width / 2
        }
        
        let layoutTitleCenteredFullWidth = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            titleLabel.textAlignment = .center
            titleLabel.layoutDynamicHeight(width: self.titlesFullWidth)
            titleLabel.center.x = self.frame.width / 2
        }
        
        let layoutTitleLeadingFullWidth = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            guard let iconView = self.iconView else { return }
            let rtl = self.effectiveUserInterfaceLayoutDirection == .rightToLeft
            titleLabel.textAlignment = rtl ? .right : .left
            titleLabel.layoutDynamicHeight(width: self.titlesFullWidth)
            titleLabel.frame.origin.x = self.layoutMargins.left + iconView.frame.width + self.spaceBetweenTitlesAndImage
        }
        
        let layoutSubtitle = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            guard let subtitleLabel = self.subtitleLabel else { return }
            subtitleLabel.textAlignment = titleLabel.textAlignment
            subtitleLabel.layoutDynamicHeight(width: titleLabel.frame.width)
            subtitleLabel.frame.origin.x = titleLabel.frame.origin.x
        }
        
        let layoutTitleSubtitleByVertical = { [weak self] in
            guard let self = self else { return }
            guard let titleLabel = self.titleLabel else { return }
            guard let subtitleLabel = self.subtitleLabel else {
                titleLabel.center.y = self.bounds.midY
                return
            }
            let allHeight = titleLabel.frame.height + subtitleLabel.frame.height + self.spaceBetweenTitles
            titleLabel.frame.origin.y = (self.frame.height - allHeight) / 2
            subtitleLabel.frame.origin.y = titleLabel.frame.maxY + self.spaceBetweenTitles
        }
        
        // Apply
        
        switch layout {
        case .iconTitleMessageCentered:
            layoutIcon()
            layoutTitleCenteredCompact()
            layoutSubtitle()
        case .iconTitleMessageLeading:
            layoutIcon()
            layoutTitleLeadingFullWidth()
            layoutSubtitle()
        case .iconTitleCentered:
            layoutIcon()
            titleLabel?.numberOfLines = 2
            layoutTitleCenteredCompact()
        case .iconTitleLeading:
            layoutIcon()
            titleLabel?.numberOfLines = 2
            layoutTitleLeadingFullWidth()
        case .title:
            titleLabel?.numberOfLines = 2
            layoutTitleCenteredFullWidth()
        case .titleMessage:
            layoutTitleCenteredFullWidth()
            layoutSubtitle()
        }
        
        layoutTitleSubtitleByVertical()
    }
    
    // MARK: - Models
    
    enum PresentPosition {
        case prepare(_ from: ToastPresentSide)
        case visible(_ from: ToastPresentSide)
        case fromVisible(_ translation: CGFloat, from: ToastPresentSide)
    }
    
    enum LayoutGrid {
        case iconTitleMessageCentered
        case iconTitleMessageLeading
        case iconTitleCentered
        case iconTitleLeading
        case title
        case titleMessage
    }
}

extension UIApplication {
    var sceneWindows: [UIWindow] {
        UIApplication.shared.connectedScenes.compactMap{ $0 as? UIWindowScene }.flatMap{ $0.windows }
    }
    
    var sceneKeyWindows: [UIWindow] {
        UIApplication.shared.connectedScenes.compactMap{ $0 as? UIWindowScene }.flatMap{ $0.windows }.filter{ $0.isKeyWindow }
    }
}
