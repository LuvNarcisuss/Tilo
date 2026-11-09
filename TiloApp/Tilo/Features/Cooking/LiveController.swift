import UIKit
import AVFoundation

final class LiveController: TiloPage, UISearchBarDelegate, UIScrollViewDelegate {
    private var videos:[CookingVideo] = []
    private var category = "All"
    private let search = UISearchBar()
    private var searchVisible = false
    private var searchAction:UIBarButtonItem?
    private let cards = UIStackView()
    private var tiles:[TiloLiveRoomCard] = []
    private var filterButtons:[UIButton] = []
    private var filterHeight:NSLayoutConstraint?
    private var visibleOnScreen = false
    private var coverSync:DispatchWorkItem?
    private var lifecycle:[NSObjectProtocol] = []
    private var loading:Task<Void,Never>?
    private var safetyRevision = TiloBackend.shared.safetyRevision
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if safetyRevision != TiloBackend.shared.safetyRevision {
            safetyRevision = TiloBackend.shared.safetyRevision; load()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Live"; content.spacing = 12; scroll.delegate = self
        add(text("The kitchen is open.",26,heading:true))
        add(text("Cooking rooms · Recorded replays",15,color:TiloTheme.muted))
        search.placeholder = "Find a cooking film"; search.searchBarStyle = .minimal; search.enablesReturnKeyAutomatically = false; search.delegate = self
        search.setImage(TiloIcon.close.image(18),for:.clear,state:.normal); search.searchTextField.font = TiloTheme.font(); search.searchTextField.leftView = UIImageView(image:TiloIcon.search.image(22)); search.isHidden = true; add(search)
        let filters = row([])
        for title in ["All","Pasta","Breakfast","Dinner","Vegetables","Baking","Salads"] {
            let button = action(title) { [weak self] in self?.category = title; self?.updateFilters(); self?.renderCards(resetPosition:true) }
            filters.addArrangedSubview(button); filterButtons.append(button)
        }
        let horizontal = UIScrollView(); horizontal.showsHorizontalScrollIndicator = false; horizontal.addSubview(filters); filters.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([filters.leadingAnchor.constraint(equalTo:horizontal.contentLayoutGuide.leadingAnchor),filters.trailingAnchor.constraint(equalTo:horizontal.contentLayoutGuide.trailingAnchor),filters.topAnchor.constraint(equalTo:horizontal.contentLayoutGuide.topAnchor),filters.bottomAnchor.constraint(equalTo:horizontal.contentLayoutGuide.bottomAnchor),filters.heightAnchor.constraint(equalTo:horizontal.frameLayoutGuide.heightAnchor)])
        filterHeight = horizontal.heightAnchor.constraint(equalToConstant:max(50,TiloTheme.font(17).lineHeight + 24)); filterHeight?.isActive = true; add(horizontal); updateFilters()
        cards.axis = .vertical; cards.spacing = 12; cards.accessibilityIdentifier = "live-room-grid"; add(cards)
        let refresh = UIRefreshControl(); refresh.addTarget(self,action:#selector(refreshFilms),for:.valueChanged); scroll.refreshControl = refresh
        let createAction = UIBarButtonItem(image:TiloIcon.camera.image(),style:.plain,target:self,action:#selector(create))
        createAction.accessibilityLabel = "Create cooking content"
        let searchAction = UIBarButtonItem(image:TiloIcon.search.image(),style:.plain,target:self,action:#selector(toggleSearch))
        searchAction.accessibilityLabel = "Search cooking rooms"; self.searchAction = searchAction
        navigationItem.rightBarButtonItems = [createAction,searchAction]
        lifecycle.append(NotificationCenter.default.addObserver(forName:UIApplication.willResignActiveNotification,object:nil,queue:.main) { [weak self] _ in self?.tiles.forEach { $0.setPreviewing(false) } })
        for name in [UIApplication.didBecomeActiveNotification,UIAccessibility.reduceMotionStatusDidChangeNotification] {
            lifecycle.append(NotificationCenter.default.addObserver(forName:name,object:nil,queue:.main) { [weak self] _ in self?.syncCovers() })
        }
        load()
    }
    override func viewDidAppear(_ animated:Bool) { super.viewDidAppear(animated); visibleOnScreen = true; scheduleCovers() }
    override func viewWillDisappear(_ animated:Bool) { super.viewWillDisappear(animated); visibleOnScreen = false; coverSync?.cancel(); tiles.forEach { $0.releasePreview() } }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); scheduleCovers() }
    func scrollViewDidScroll(_ scrollView:UIScrollView) { syncCovers() }
    override func traitCollectionDidChange(_ previousTraitCollection:UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isViewLoaded,previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            filterHeight?.constant = max(50,TiloTheme.font(17).lineHeight + 24); renderCards()
        }
    }
    @objc private func toggleSearch() {
        searchVisible.toggle(); search.isHidden = !searchVisible
        searchAction?.image = (searchVisible ? TiloIcon.close : .search).image()
        searchAction?.accessibilityLabel = searchVisible ? "Close search" : "Search cooking rooms"
        if searchVisible {
            scroll.setContentOffset(.zero,animated:false)
            search.becomeFirstResponder()
        } else {
            search.resignFirstResponder(); search.text = ""; renderCards(resetPosition:true)
        }
        view.setNeedsLayout(); scheduleCovers()
    }
    @objc private func refreshFilms() { load() }
    @objc private func create() {
        let sheet = UIAlertController(title:"From your kitchen",message:"Share a recipe with the community. Live broadcasting is not connected yet.",preferredStyle:.actionSheet)
        sheet.addAction(UIAlertAction(title:"Write a recipe",style:.default) { [weak self] _ in self?.push(RecipeEditorController()) })
        sheet.addAction(UIAlertAction(title:"Cancel",style:.cancel)); sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem; present(sheet,animated:true)
    }
    private func clearCards() { tiles.forEach { $0.releasePreview() }; tiles = []; cards.arrangedSubviews.forEach { $0.removeFromSuperview() } }
    private func load() {
        loading?.cancel(); clearCards(); cards.addArrangedSubview(text("Warming up the kitchen…",18))
        loading = Task { [weak self] in
            guard let self else { return }
            do { let loaded = try await TiloBackend.shared.videos(); guard !Task.isCancelled else { return }; videos = loaded; renderCards() }
            catch { guard !Task.isCancelled else { return }; clearCards(); cards.addArrangedSubview(panel([text("Films could not load",24,heading:true),text(error.localizedDescription),action("Try again") { [weak self] in self?.load() }])) }
            scroll.refreshControl?.endRefreshing()
        }
    }
    func searchBar(_ searchBar:UISearchBar,textDidChange searchText:String) { renderCards(resetPosition:true) }
    func searchBarSearchButtonClicked(_ searchBar:UISearchBar) { search.resignFirstResponder() }
    private func updateFilters() {
        for button in filterButtons {
            let selected = button.accessibilityLabel == category; button.isSelected = selected
            button.accessibilityTraits = selected ? [.button,.selected] : .button
            var style = button.configuration; style?.baseForegroundColor = selected ? .white : TiloTheme.olive
            style?.background.backgroundColor = selected ? TiloTheme.red : UIColor.white.withAlphaComponent(0.84); button.configuration = style
        }
    }
    private func renderCards(resetPosition:Bool = false) {
        clearCards()
        let query = (search.text ?? "").trimmingCharacters(in:.whitespacesAndNewlines)
        let visible = videos.filter { (category == "All" || $0.category == category) && (query.isEmpty || ($0.title + " " + $0.category + " " + $0.payload.chef + " " + ($0.publisher?.displayName ?? "")).localizedCaseInsensitiveContains(query)) }
        if visible.isEmpty { cards.addArrangedSubview(panel([text("Nothing on the stove yet",24,heading:true),text("Try another search or browse all cooking replays.")])) }
        let columns = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 1 : 2
        for start in stride(from:0,to:visible.count,by:columns) {
            let line = row([],spacing:12); line.distribution = .fillEqually; line.alignment = .fill
            for video in visible[start..<min(start + columns,visible.count)] {
                let tile = TiloLiveRoomCard(video:video) { [weak self] in self?.open(video) }
                tiles.append(tile); line.addArrangedSubview(tile)
            }
            if line.arrangedSubviews.count < columns { line.addArrangedSubview(UIView()) }
            cards.addArrangedSubview(line)
            line.heightAnchor.constraint(equalTo:cards.widthAnchor,multiplier:1.45 / CGFloat(columns),constant:-12 * 1.45 * CGFloat(columns - 1) / CGFloat(columns)).isActive = true
        }
        if resetPosition { scroll.setContentOffset(.zero,animated:false) }
        view.setNeedsLayout(); scheduleCovers()
    }
    private func scheduleCovers() {
        coverSync?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.syncCovers() }
        coverSync = work; DispatchQueue.main.async(execute:work)
    }
    private func syncCovers() {
        let active = visibleOnScreen && viewIfLoaded?.window != nil && UIApplication.shared.applicationState == .active && !UIAccessibility.isReduceMotionEnabled && (presentedViewController == nil || presentedViewController is UIAlertController)
        let viewport = scroll.bounds
        let candidates = tiles.filter { tile in
            let frame = tile.convert(tile.bounds,to:scroll)
            return active && frame.intersection(viewport).height > 60
        }.sorted { first,second in
            first.convert(first.bounds,to:scroll).intersection(viewport).height > second.convert(second.bounds,to:scroll).intersection(viewport).height
        }
        let playing = Array(candidates.prefix(2))
        for tile in tiles {
            if playing.contains(where: { $0 === tile }) { tile.setPreviewing(true) }
            else { tile.releasePreview() }
        }
    }
    private func open(_ video:CookingVideo) {
        visibleOnScreen = false; coverSync?.cancel(); tiles.forEach { $0.releasePreview() }
        let player = ReplayController(video:video); player.modalPresentationStyle = .fullScreen; present(player,animated:true)
    }
    deinit { coverSync?.cancel(); loading?.cancel(); lifecycle.forEach { NotificationCenter.default.removeObserver($0) } }
}

final class ContentDiscussionController:TiloPage {
    private let contentID:String
    private let heading:String
    private let input = UITextView()
    private let replies = UIStackView()
    private var sending = false
    private var loading: Task<Void, Never>?
    init(contentID:String,heading:String) { self.contentID = contentID; self.heading = heading; super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Conversation"
        if navigationController?.viewControllers.first === self { navigationItem.leftBarButtonItem = UIBarButtonItem(image:TiloIcon.close.image(),style:.plain,target:self,action:#selector(close)); navigationItem.leftBarButtonItem?.accessibilityLabel = "Close discussion" }
        add(text(heading,28,heading:true)); add(text("A place to trade tips and share what worked in your kitchen.",17,color:TiloTheme.muted))
        replies.axis = .vertical; replies.spacing = 12; add(replies)
        add(text("Your comment",18,heading:true)); input.font = TiloTheme.font(18); input.backgroundColor = .white; input.round(14); input.fixedHeight(110); input.accessibilityLabel = "Your comment"; add(input)
        add(action("Send comment",icon:.send,filled:true) { [weak self] in self?.send() })
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); load() }
    @objc private func close() { dismiss(animated:true) }
    private func load() {
        loading?.cancel()
        replies.arrangedSubviews.forEach { $0.removeFromSuperview() }
        loading = Task { [weak self] in
            guard let self else { return }
            do {
                let comments = try await TiloBackend.shared.comments(contentID:contentID)
                guard !Task.isCancelled else { return }
                if comments.isEmpty { replies.addArrangedSubview(panel([text("Be the first at the table",22,heading:true),text("Start the conversation with a cooking question or a useful tip.")])) }
                for comment in comments {
                    let author = action(comment.displayName,icon:.me) { [weak self] in self?.push(CreatorController(userID:comment.userID)) }
                    let heading = row([author],spacing:8)
                    if comment.userID != TiloBackend.shared.userID {
                        let options = action("",icon:.more) { [weak self] in
                            guard let self else { return }
                            ContentSafety.message(comment, host:self, source:replies) { [weak self] in self?.load() }
                        }
                        options.accessibilityLabel = "Comment options for " + comment.displayName
                        options.widthAnchor.constraint(equalToConstant:50).isActive = true; heading.addArrangedSubview(options)
                    }
                    replies.addArrangedSubview(panel([heading,text(comment.body,18)]))
                }
            } catch { if !Task.isCancelled { replies.addArrangedSubview(panel([text("Comments could not load",22,heading:true),text(error.localizedDescription),action("Try again") { [weak self] in self?.load() }])) } }
        }
    }
    private func send() {
        let body = input.text.trimmingCharacters(in:.whitespacesAndNewlines); guard !body.isEmpty,!sending else { return }
        guard body.count <= 2000 else { showNotice("A little shorter, please","Keep comments under 2,000 characters."); return }
        sending = true
        Task { defer { sending = false }; do { try await TiloBackend.shared.addComment(contentID:contentID,body:body); input.text = ""; view.endEditing(true); load() } catch { fail(error) } }
    }
    deinit { loading?.cancel() }
}
