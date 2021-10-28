import UIKit

/**
 * This provides the methods to create view controllers from the backing
 * array, and to go back and forth between index <-> view controller.
 */
public protocol ArrayPageViewControllerDataSource: AnyObject {
    func create(index: Int) -> UIViewController
    func indexOf(viewController: UIViewController) -> Int
    func count() -> Int
    func initialPage() -> Int?
    func didShowPage(index: Int)
}

/**
 * This transforms a ArrayPageViewControllerDataSource to a
 * UIPageViewControllerDataSource. Note that this does not provide the
 * presentation{Index,Count} methods so that the underlying view controller
 * does not display its own page indicators.
 */
fileprivate class ArrayPageViewControllerDataSourceAdapter
    : NSObject
    , UIPageViewControllerDataSource
{
    private weak var dataSource: ArrayPageViewControllerDataSource?

    fileprivate init(_ dataSource: ArrayPageViewControllerDataSource) {
        self.dataSource = dataSource
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let dataSource = self.dataSource else { return nil }
        let packIndex = dataSource.indexOf(viewController: viewController)
        guard packIndex > 0 else { return nil }
        return dataSource.create(index: packIndex - 1)
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let dataSource = self.dataSource else { return nil }
        let packIndex = dataSource.indexOf(viewController: viewController)
        guard packIndex < dataSource.count() - 1 else { return nil }
        return dataSource.create(index: packIndex + 1)
    }
}

/**
 * This behaves like a UIPageViewController, but it assumes that you have a
 * linear, fixed set of pages to display. It also allows you to specify an
 * arbitrary UIPageControl to bind to.
 */
public class ArrayPageViewController: UIViewController, UIPageViewControllerDelegate {
    private var inner: UIPageViewController!
    private var emptyView: UILabel!

    /**
     * Returns the currently visible view controller, if one exists.
     */
    public var viewController: UIViewController? {
        get {
            // When someone sets the data source to nil/empty, we show a dummy empty
            // view controller as a workaround for UIPageViewController limitations.
            // In such cases, treat it as if there's nothing there.
            guard self.numberOfPages > 0 else { return nil }

            guard let viewControllers = self.inner.viewControllers else { return nil }
            assert(viewControllers.count <= 1)
            return viewControllers.first
        }
    }

    /**
     * Returns the total number of pages in this page controller.
     * Returns zero if there is no data source set.
     */
    public var numberOfPages: Int {
        get {
            return self.dataSource?.count() ?? 0
        }
    }

    /**
     * The index of the current visible page. It is an error to
     * set this field to nil if the data source is not nil and has at
     * least one element, or to set this field to non-nil if the data
     * source is nil or empty.
     */
    public var currentPage: Int? {
        get {
            guard let dataSource = self.dataSource else { return nil }
            guard let viewController = self.viewController else { return nil }
            return dataSource.indexOf(viewController: viewController)
        }
        set {
            assert((newValue == nil) == (self.numberOfPages == 0))
            if let newValue = newValue, let dataSource = self.dataSource {
                assert(newValue >= 0 && newValue < dataSource.count())
                let oldValue = self.currentPage ?? Int.max
                let direction: UIPageViewController.NavigationDirection
                if newValue > oldValue {
                    direction = .forward
                } else if newValue < oldValue {
                    direction = .reverse
                } else {
                    return
                }

                self.inner.setViewControllers(
                    [dataSource.create(index: newValue)],
                    direction: direction,
                    animated: self.animatePageTransitions
                )

                self.updatePageControl(currentPage: newValue, numberOfPages: nil)
                self.dataSource?.didShowPage(index: newValue)
            }
        }
    }

    /**
     * This is the proxy data source for our underlying page view controller.
     * It must be kept in sync with the dataSource field. Note that this field
     * itself is not weak, however the adapter itself holds a weak reference
     * to the real data source. Without this field, the adapter would be immediately
     * destroyed since the UIPageViewController.dataSource field is weak.
     */
    private var dataSourceAdapter: ArrayPageViewControllerDataSourceAdapter?

    /**
     * The data source for this page view controller. Writing to this field
     * will reset the currently visible page.
     */
    public weak var dataSource: ArrayPageViewControllerDataSource? {
        didSet {
            if let newValue = self.dataSource {
                // UIPageViewController has a bug where giving it an empty
                // data source will cause crashes. To avoid this, make the
                // data source nil if it doesn't contain any elements.
                if newValue.count() > 0 {
                    let adapter = ArrayPageViewControllerDataSourceAdapter(newValue)
                    self.dataSourceAdapter = adapter
                    self.inner.dataSource = adapter
                    let index = newValue.initialPage() ?? 0

                    self.inner.setViewControllers(
                        [newValue.create(index: index)],
                        direction: .reverse,
                        animated: false
                    )

                    self.updatePageControl(currentPage: index, numberOfPages: newValue.count())
                    self.emptyView.isHidden = true
                    newValue.didShowPage(index: index)
                    return
                }
            }

            self.dataSourceAdapter = nil
            self.inner.dataSource = nil

            // We can't clear the view controller list, but we can at least replace
            // it with a dummy empty one to clear the existing view.
            self.inner.setViewControllers(
                [UIViewController()],
                direction: .reverse,
                animated: false,
                completion: nil
            )

            self.updatePageControl(currentPage: nil, numberOfPages: 0)
            self.emptyView.isHidden = (self.dataSource == nil)
        }
    }

    /**
     * An arbitrary page control to bind the status of this controller to.
     */
    public weak var pageControl: UIPageControl? {
        didSet {
            oldValue?.removeTarget(
                self,
                action: #selector(self.pageControlSelectionDidChange),
                for: .valueChanged
            )
            guard let newValue = self.pageControl else { return }
            newValue.addTarget(
                self,
                action: #selector(self.pageControlSelectionDidChange),
                for: .valueChanged
            )
            self.updatePageControl(
                currentPage: self.currentPage,
                numberOfPages: self.numberOfPages
            )
        }
    }

    /**
     * Some text to show in place of the normal view in case the data source
     * is set, but empty. Note that this is NOT shown if the data source is nil.
     */
    public var emptyText: String? {
        get {
            return self.emptyView.text
        }
        set {
            self.emptyView.text = newValue
        }
    }

    /**
     * Whether to animate the page transitions when the user drags the page
     * indicators.
     */
    public var animatePageTransitions: Bool = true

    public override func viewDidLoad() {
        self.inner = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        self.addChild(self.inner)
        self.inner.view
            .autoLayoutInView(self.view)
            .fill(self.view.safeAreaLayoutGuide)
            .activate()
        self.inner.didMove(toParent: self)
        self.inner.delegate = self

        self.emptyView = UILabel()
        self.emptyView
            .autoLayoutInView(self.view)
            .fill(self.view.layoutMarginsGuide)
            .activate()
        self.emptyView.numberOfLines = 0
        self.emptyView.lineBreakMode = .byClipping
        self.emptyView.adjustsFontSizeToFitWidth = true
        self.emptyView.textAlignment = .center
        self.emptyView.isHidden = true
    }

    /**
     * Called when the user swipes through the pages directly.
     * Updates the indicator dot index.
     */
    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed {
            guard let currentPage = self.currentPage else { return }
            self.dataSource?.didShowPage(index: currentPage)
            self.pageControl?.currentPage = currentPage
        }
    }

    /**
     * Updates the page control state while animations are disabled.
     * This helps avoid some weird ghosting issues on load.
     */
    private func updatePageControl(currentPage: Int?, numberOfPages: Int?) {
        guard let pageControl = self.pageControl else { return }
        UIView.setAnimationsEnabled(false)
        if let numberOfPages = numberOfPages {
            pageControl.numberOfPages = numberOfPages
        }
        if let currentPage = currentPage {
            pageControl.currentPage = currentPage
        }
        UIView.setAnimationsEnabled(true)
    }

    /**
     * Called when the user swipes on the indicator dots. Updates
     * the page accordingly.
     */
    @objc
    private func pageControlSelectionDidChange(sender: UIPageControl) {
        self.currentPage = sender.currentPage
    }
}
