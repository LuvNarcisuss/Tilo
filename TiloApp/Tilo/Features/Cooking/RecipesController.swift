import UIKit

final class TiloRecipeCard: UIView {
    init(recipe: Recipe, compact: Bool = false, showsPublisherAvatar: Bool = false, open: @escaping () -> Void) {
        super.init(frame: .zero)
        backgroundColor = .white; round(24)
        let photo = RemotePhoto(recipe.imageURL, height: 208, aspectRatio:compact ? 1 : nil)
        photo.accessibilityLabel = recipe.title
        let tag = text(compact ? recipe.category.uppercased() : recipe.category.uppercased() + "  ·  " + recipe.payload.difficulty, compact ? 12 : 13, color: TiloTheme.red)
        let title = text(recipe.title, compact ? 19 : 26, heading: true)
        let time = text("\(recipe.payload.prepMinutes + recipe.payload.cookMinutes) min  ·  \(recipe.payload.servings) servings", compact ? 13 : 16, color: TiloTheme.muted)
        if compact { title.numberOfLines = 2; tag.numberOfLines = 1; tag.adjustsFontSizeToFitWidth = true; tag.minimumScaleFactor = 0.85 }
        let body = column([tag,title,time],spacing: 5)
        let wrapper = UIView(); wrapper.addSubview(body); body.translatesAutoresizingMaskIntoConstraints = false
        let padding:CGFloat = compact ? 10 : 16
        NSLayoutConstraint.activate([body.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor,constant:padding),body.trailingAnchor.constraint(equalTo:wrapper.trailingAnchor,constant:-padding),body.topAnchor.constraint(equalTo:wrapper.topAnchor,constant:10),body.bottomAnchor.constraint(equalTo:wrapper.bottomAnchor,constant:-padding)])
        let contents = column([photo,wrapper],spacing:0); contents.isUserInteractionEnabled = false
        addSubview(contents); contents.fill(self)
        let entry = UIButton(type: .custom)
        entry.addAction(UIAction { _ in open() }, for: .touchUpInside)
        entry.accessibilityLabel = "\(recipe.title), \(recipe.category), \(recipe.payload.prepMinutes + recipe.payload.cookMinutes) minutes"
        entry.accessibilityIdentifier = "recipe-card-" + recipe.id
        addSubview(entry); entry.fill(self)
        isAccessibilityElement = false
        accessibilityElements = [entry]
        if showsPublisherAvatar, let publisher = recipe.publisher {
            let avatar = PublisherAvatarButton(publisher: publisher, contentID: recipe.id)
            addSubview(avatar)
            NSLayoutConstraint.activate([avatar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10), avatar.topAnchor.constraint(equalTo: topAnchor, constant: 10)])
            accessibilityElements = [entry, avatar]
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

@MainActor
func recipeGrid(_ recipes: [Recipe], accessible: Bool, open: @escaping (Recipe) -> Void) -> UIStackView {
    let grid = column([], spacing:12)
    let columns = accessible ? 1 : 2
    for start in stride(from:0, to:recipes.count, by:columns) {
        let line = row([], spacing:12); line.distribution = .fillEqually; line.alignment = .fill
        for recipe in recipes[start..<min(start + columns, recipes.count)] {
            line.addArrangedSubview(TiloRecipeCard(recipe:recipe, compact:!accessible) { open(recipe) })
        }
        if line.arrangedSubviews.count < columns { line.addArrangedSubview(UIView()) }
        grid.addArrangedSubview(line)
    }
    return grid
}

final class RecipesController: TiloPage, UISearchBarDelegate {
    private let search = UISearchBar()
    private var searchVisible = false
    private var searchAction: UIBarButtonItem?
    private let results = UIStackView()
    private var cuisine: String?
    private var loading: Task<Void,Never>?
    private var requestGeneration = 0
    private var hasAppeared = false
    private var recipes:[Recipe] = []
    private var filterButtons:[UIButton] = []
    private var filterHeight:NSLayoutConstraint?
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Recipes"
        add(text("Find your next favorite.",24,heading:true))
        search.placeholder = "Search recipes or ingredients"; search.searchBarStyle = .minimal; search.delegate = self; search.enablesReturnKeyAutomatically = false
        search.setImage(TiloIcon.close.image(18),for:.clear,state:.normal); search.searchTextField.font = TiloTheme.font(); search.searchTextField.leftView = UIImageView(image:TiloIcon.search.image(22)); search.isHidden = true; add(search)
        let filters = row([]); filters.distribution = .fillEqually
        for value in ["All","Italian","American","European"] {
            let button = action(value) { [weak self] in
                guard let self else { return }; cuisine = value == "All" ? nil : value; updateFilters(); load(resetPosition:true)
            }
            filterButtons.append(button); filters.addArrangedSubview(button)
        }
        let filterScroll = UIScrollView(); filterScroll.showsHorizontalScrollIndicator = false; filterScroll.addSubview(filters); filters.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([filters.leadingAnchor.constraint(equalTo:filterScroll.contentLayoutGuide.leadingAnchor),filters.trailingAnchor.constraint(equalTo:filterScroll.contentLayoutGuide.trailingAnchor),filters.topAnchor.constraint(equalTo:filterScroll.contentLayoutGuide.topAnchor),filters.bottomAnchor.constraint(equalTo:filterScroll.contentLayoutGuide.bottomAnchor),filters.heightAnchor.constraint(equalTo:filterScroll.frameLayoutGuide.heightAnchor)])
        filterHeight = filterScroll.heightAnchor.constraint(equalToConstant:max(50,TiloTheme.font(17).lineHeight + 24)); filterHeight?.isActive = true; add(filterScroll)
        updateFilters()
        results.axis = .vertical; results.spacing = 12; results.accessibilityIdentifier = "recipe-home-grid"; add(results)
        let refresh = UIRefreshControl(); refresh.addTarget(self,action:#selector(refreshRecipes),for:.valueChanged); scroll.refreshControl = refresh
        let createAction = UIBarButtonItem(image:TiloIcon.plus.image(),style:.plain,target:self,action:#selector(createRecipe)); createAction.accessibilityLabel = "Write a recipe"
        let searchAction = UIBarButtonItem(image:TiloIcon.search.image(),style:.plain,target:self,action:#selector(toggleSearch)); searchAction.accessibilityLabel = "Search recipes"; self.searchAction = searchAction
        navigationItem.rightBarButtonItems = [createAction, searchAction]
        load()
    }
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        if hasAppeared { load() }; hasAppeared = true
    }
    @objc private func createRecipe() { push(RecipeEditorController()) }
    @objc private func toggleSearch() {
        searchVisible.toggle(); search.isHidden = !searchVisible
        searchAction?.image = (searchVisible ? TiloIcon.close : .search).image()
        searchAction?.accessibilityLabel = searchVisible ? "Close search" : "Search recipes"
        if searchVisible {
            scroll.setContentOffset(.zero, animated:false); search.becomeFirstResponder()
        } else {
            search.resignFirstResponder(); search.text = ""; load(resetPosition:true)
        }
    }
    @objc private func refreshRecipes() { load() }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { load(debounce:true,resetPosition:true) }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { search.resignFirstResponder(); load() }
    override func traitCollectionDidChange(_ previousTraitCollection:UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            filterHeight?.constant = max(50,TiloTheme.font(17).lineHeight + 24)
            if !recipes.isEmpty { renderRecipes() }
        }
    }
    private func updateFilters() {
        for button in filterButtons {
            let selected = (button.accessibilityLabel == "All" && cuisine == nil) || button.accessibilityLabel == cuisine
            button.isSelected = selected; button.accessibilityTraits = selected ? [.button,.selected] : .button
            var style = button.configuration; style?.baseForegroundColor = selected ? .white : TiloTheme.olive
            style?.background.backgroundColor = selected ? TiloTheme.red : UIColor.white.withAlphaComponent(0.84); button.configuration = style
        }
    }
    private func renderRecipes() {
        results.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if recipes.isEmpty { results.addArrangedSubview(panel([text("A fresh start",24,heading:true),text("No recipes match this search. Try another ingredient or browse All.")])) ; return }
        let singleColumn = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        var index = 0
        while index < recipes.count {
            let items = row([],spacing:12); items.distribution = .fillEqually; items.alignment = .fill
            let columns = singleColumn ? 1 : 2
            for column in 0..<columns {
                if index + column < recipes.count {
                    let recipe = recipes[index + column]
                    items.addArrangedSubview(TiloRecipeCard(recipe:recipe,compact:!singleColumn,showsPublisherAvatar:true) { [weak self] in self?.push(RecipeDetailController(recipe:recipe)) })
                } else { let spacer = UIView(); spacer.isAccessibilityElement = false; items.addArrangedSubview(spacer) }
            }
            results.addArrangedSubview(items); index += columns
        }
    }
    private func load(debounce: Bool = false,resetPosition:Bool = false) {
        loading?.cancel(); requestGeneration += 1; let generation = requestGeneration
        loading = Task { [weak self] in
            guard let self else { return }
            if debounce { try? await Task.sleep(nanoseconds:300_000_000) }
            guard !Task.isCancelled else { return }
            if results.arrangedSubviews.isEmpty { results.addArrangedSubview(text("Finding your next favorite…",18,color:TiloTheme.muted)) }
            do {
                let recipes = try await TiloBackend.shared.recipes(category:cuisine,query:search.text)
                guard !Task.isCancelled, generation == requestGeneration else { return }
                self.recipes = recipes; renderRecipes()
                if resetPosition { scroll.setContentOffset(.zero,animated:false) }
            } catch {
                guard !Task.isCancelled,generation == requestGeneration else { return }
                results.arrangedSubviews.forEach { $0.removeFromSuperview() }
                results.addArrangedSubview(panel([text("Recipes could not load",23,heading:true),text(error.localizedDescription),action("Try again",icon:.recipes) { [weak self] in self?.load() }]))
            }
            scroll.refreshControl?.endRefreshing()
        }
    }
    deinit { loading?.cancel() }
}

final class RecipeCollectionController: TiloPage {
    private let scope: String
    private let userID: UUID?
    private var recipes: [Recipe] = []
    private var loading: Task<Void, Never>?
    init(scope: String,userID: UUID? = nil) { self.scope = scope; self.userID = userID; super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() { super.viewDidLoad(); title = scope.capitalized }
    override func viewWillAppear(_ animated:Bool) { super.viewWillAppear(animated); reload() }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isViewLoaded, previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory { render() }
    }
    private func render() {
        clear()
        if recipes.isEmpty { add(text("No recipes here yet.",17,color:TiloTheme.muted)) }
        add(recipeGrid(recipes, accessible:traitCollection.preferredContentSizeCategory.isAccessibilityCategory) { [weak self] recipe in self?.push(RecipeDetailController(recipe:recipe)) })
    }
    private func reload() {
        loading?.cancel(); clear(); add(text("Loading recipes…",17,color:TiloTheme.muted))
        let accountID = TiloBackend.shared.userID
        loading = Task { [weak self] in
            guard let self else { return }
            do {
                let recipes = try await TiloBackend.shared.recipeCollection(scope:scope,userID:userID)
                guard !Task.isCancelled, accountID == TiloBackend.shared.userID else { return }
                self.recipes = recipes; render()
            } catch {
                guard !Task.isCancelled else { return }
                clear(); add(text(error.localizedDescription,17,color:TiloTheme.red)); add(action("Try again") { [weak self] in self?.reload() })
            }
        }
    }
    deinit { loading?.cancel() }
}

final class RecipeDetailController: TiloPage {
    let recipe: Recipe
    private let session:RecipeCookingSession
    private var saved = false
    private var liked = false
    private var mutating = false
    private var owned = false
    private var player:RecipeTutorialPlayer?
    private var preparation:RecipeIngredientPreparationView?
    private let sections = column([],spacing:8)
    private var categoryButtons:[UIButton] = []
    private var likeButton:UIButton?
    private var saveButton:UIButton?
    private var interactionStack:UIStackView?
    private var collectionsLoaded = false
    private var collectionLoadTask: Task<Void, Never>?
    private var loadingSafety = false
    private var safetyRevision = TiloBackend.shared.safetyRevision
    private var safetyObserver: NSObjectProtocol?
    init(recipe:Recipe) { self.recipe = recipe; session = RecipeCookingSession(recipe:recipe); super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Recipe"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:TiloIcon.more.image(),style:.plain,target:self,action:#selector(more))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Recipe options"
        buildPage()
        loadCollections()
        safetyObserver = NotificationCenter.default.addObserver(forName:Notification.Name("TiloContentSafetyChanged"),object:nil,queue:.main) { [weak self] _ in self?.checkSafety() }
    }
    private func loadCollections() {
        collectionLoadTask?.cancel()
        let accountID = TiloBackend.shared.userID
        collectionLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                async let saves = TiloBackend.shared.savedRecipes()
                async let likes = TiloBackend.shared.recipeCollection(scope:"liked",userID:nil)
                let saved = try await saves.contains { $0.id == recipe.id }
                let liked = try await likes.contains { $0.id == recipe.id }
                let works = try await TiloBackend.shared.recipeCollection(scope:"works",userID:nil)
                guard !Task.isCancelled, accountID == TiloBackend.shared.userID else { return }
                self.saved = saved; self.liked = liked; owned = works.contains { $0.id == recipe.id }
                collectionsLoaded = true; updateCollections()
            } catch { if !Task.isCancelled { fail(error) } }
        }
    }
    private func buildPage() {
        content.spacing = 10
        if let tutorial = recipe.payload.tutorial,tutorial.validatedVideoID != nil {
            let player = RecipeTutorialPlayer(tutorial:tutorial); self.player = player; add(player)
            add(text("Video by " + tutorial.author,12,color:TiloTheme.muted))
        } else {
            add(panel([text("Video tutorial unavailable",20,heading:true),text("This recipe has written preparation and cooking instructions.",15)]))
        }
        add(text(recipe.title,24,heading:true))
        add(text("\(recipe.payload.prepMinutes + recipe.payload.cookMinutes) min  ·  \(recipe.payload.servings) servings  ·  \(recipe.payload.difficulty)",14,color:TiloTheme.muted))
        let categories = row([],spacing:4); categories.distribution = .fillEqually
        for (index,title) in ["Ingredient prep","Cooking steps"].enumerated() {
            let button = action(title) { [weak self] in self?.selectSection(index) }
            var configuration = button.configuration
            configuration?.contentInsets = NSDirectionalEdgeInsets(top:8,leading:8,bottom:8,trailing:8)
            configuration?.background.cornerRadius = 10
            button.configuration = configuration
            categoryButtons.append(button); categories.addArrangedSubview(button)
        }
        let categoryBox = UIView(); categoryBox.backgroundColor = UIColor.white.withAlphaComponent(0.65); categoryBox.round(14)
        categoryBox.layer.borderWidth = 1; categoryBox.layer.borderColor = TiloTheme.olive.withAlphaComponent(0.18).cgColor
        categoryBox.addSubview(categories); categories.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([categories.topAnchor.constraint(equalTo:categoryBox.topAnchor,constant:4),categories.bottomAnchor.constraint(equalTo:categoryBox.bottomAnchor,constant:-4),categories.leadingAnchor.constraint(equalTo:categoryBox.leadingAnchor,constant:4),categories.trailingAnchor.constraint(equalTo:categoryBox.trailingAnchor,constant:-4)])
        add(categoryBox); add(sections)
        let preparation = RecipeIngredientPreparationView(recipe:recipe,session:session)
        preparation.onNotice = { [weak self] in self?.showNotice("Shopping list updated","Your ingredients are ready in Kitchen.") }
        preparation.onFailure = { [weak self] error in self?.fail(error) }; self.preparation = preparation
        selectSection(0)
        let start = action("Start cooking",icon:.cutlery,filled:true) { [weak self] in guard let self else { return }; push(CookModeController(recipe:recipe,session:session)) }
        let like = socialAction("Like",icon:TiloIcon.likeState(false)) { [weak self] in self?.toggleLike() }
        let save = socialAction("Save",icon:TiloIcon.saveState(false)) { [weak self] in self?.toggleSave() }
        let share = socialAction("Share",icon:.share) { [weak self] in self?.share() }
        likeButton = like; saveButton = save
        let interactions = row([like,save,share],spacing:4); interactions.distribution = .fillEqually
        interactionStack = interactions; updateInteractionLayout()
        setFooter(column([start,interactions],spacing:4)); updateCollections()
    }
    private func updateInteractionLayout() {
        let accessible = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        interactionStack?.axis = accessible ? .vertical : .horizontal
        interactionStack?.alignment = accessible ? .fill : .center
    }
    override func traitCollectionDidChange(_ previousTraitCollection:UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory { updateInteractionLayout() }
    }
    private func socialAction(_ title:String,icon:TiloIcon,_ handler:@escaping () -> Void) -> UIButton {
        let button = action(title,icon:icon,handler)
        var configuration = button.configuration
        configuration?.background.backgroundColor = .clear
        configuration?.contentInsets = NSDirectionalEdgeInsets(top:8,leading:2,bottom:8,trailing:2)
        configuration?.imagePadding = 5
        button.configuration = configuration
        return button
    }
    private func selectSection(_ index:Int) {
        for (position,button) in categoryButtons.enumerated() {
            let selected = position == index
            button.isSelected = selected; button.accessibilityTraits = selected ? [.button,.selected] : .button
            var configuration = button.configuration
            configuration?.baseForegroundColor = selected ? .white : TiloTheme.olive
            configuration?.background.backgroundColor = selected ? TiloTheme.olive : .clear
            button.configuration = configuration
        }
        sections.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if index == 0,let preparation { sections.addArrangedSubview(preparation) }
        else if index == 1 {
            for (index,instruction) in recipe.payload.steps.enumerated() {
                let number = text(String(index + 1),20,heading:true,color:TiloTheme.red)
                number.setContentHuggingPriority(.required,for:.horizontal)
                number.setContentCompressionResistancePriority(.required,for:.horizontal)
                let instructionLabel = text(instruction,17); instructionLabel.accessibilityIdentifier = "recipe-step-\(index + 1)"
                let contents = row([number,instructionLabel],spacing:12); contents.alignment = .top
                let wrapper = UIView(); wrapper.backgroundColor = UIColor.white.withAlphaComponent(0.8); wrapper.round(14)
                wrapper.addSubview(contents); contents.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([contents.leadingAnchor.constraint(equalTo:wrapper.leadingAnchor,constant:12),contents.trailingAnchor.constraint(equalTo:wrapper.trailingAnchor,constant:-12),contents.topAnchor.constraint(equalTo:wrapper.topAnchor,constant:12),contents.bottomAnchor.constraint(equalTo:wrapper.bottomAnchor,constant:-12)])
                sections.addArrangedSubview(wrapper)
            }
        }
    }
    private func updateCollections() {
        likeButton?.accessibilityIdentifier = "recipe-like"
        saveButton?.accessibilityIdentifier = "recipe-save"
        var likeStyle = likeButton?.configuration
        likeStyle?.title = liked ? "Liked" : "Like"; likeStyle?.image = TiloIcon.likeState(liked).image()
        likeButton?.configuration = likeStyle; likeButton?.accessibilityLabel = liked ? "Liked" : "Like"
        likeButton?.accessibilityValue = collectionsLoaded ? (liked ? "Liked" : "Not liked") : "Loading"; likeButton?.isSelected = liked
        var saveStyle = saveButton?.configuration; saveStyle?.title = saved ? "Saved" : "Save"
        saveStyle?.image = TiloIcon.saveState(saved).image()
        saveButton?.configuration = saveStyle; saveButton?.accessibilityLabel = saved ? "Saved" : "Save"
        saveButton?.accessibilityValue = collectionsLoaded ? (saved ? "Saved" : "Not saved") : "Loading"
        saveButton?.isSelected = saved
        likeButton?.isEnabled = collectionsLoaded && !mutating; saveButton?.isEnabled = collectionsLoaded && !mutating
    }
    override func viewWillDisappear(_ animated:Bool) { super.viewWillDisappear(animated); player?.pause() }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); checkSafety() }
    private func checkSafety() {
        guard safetyRevision != TiloBackend.shared.safetyRevision else { return }
        safetyRevision = TiloBackend.shared.safetyRevision
        Task { [weak self] in
            guard let self else { return }
            do { let _ = try await TiloBackend.shared.safetyContext(kind:"recipe", id:recipe.id) }
            catch { leaveRecipe() }
        }
    }
    private func leaveRecipe() {
        player?.pause()
        guard let navigation = navigationController, let index = navigation.viewControllers.firstIndex(where: { $0 === self }) else { return }
        if index == 0 { navigation.dismiss(animated:true) }
        else { navigation.popToViewController(navigation.viewControllers[index - 1], animated:true) }
    }
    @objc private func more() {
        guard !loadingSafety else { return }; loadingSafety = true
        Task { [weak self] in
            guard let self else { return }; defer { loadingSafety = false }
            do {
                let context = try await TiloBackend.shared.safetyContext(kind:"recipe", id:recipe.id)
                guard viewIfLoaded?.window != nil, presentedViewController == nil else { return }
                owned = context.isOwn; showMore(context)
            } catch { fail(error) }
        }
    }
    private func showMore(_ context: ContentSafetyContext) {
        let sheet = UIAlertController(title:recipe.title,message:context.authorName.map { "Shared by " + $0 },preferredStyle:.actionSheet)
        if !collectionsLoaded { sheet.addAction(UIAlertAction(title:"Refresh recipe state",style:.default) { [weak self] _ in self?.loadCollections() }) }
        sheet.addAction(UIAlertAction(title:"Add to meal plan",style:.default) { [weak self] _ in guard let self else { return }; push(MealPickerController(recipe:recipe)) })
        sheet.addAction(UIAlertAction(title:"Join the recipe conversation",style:.default) { [weak self] _ in guard let self else { return }; push(ContentDiscussionController(contentID:recipe.id,heading:recipe.title)) })
        if player != nil,let tutorial = recipe.payload.tutorial {
            sheet.addAction(UIAlertAction(title:"Video source",style:.default) { [weak self] _ in self?.showVideoSource(tutorial) })
            sheet.addAction(UIAlertAction(title:"Reload tutorial",style:.default) { [weak self] _ in self?.player?.reload() })
        }
        if owned {
            sheet.addAction(UIAlertAction(title:"Edit recipe",style:.default) { [weak self] _ in guard let self else { return }; push(RecipeEditorController(recipe:recipe)) })
            sheet.addAction(UIAlertAction(title:"Delete recipe",style:.destructive) { [weak self] _ in self?.delete() })
        }
        ContentSafety.addActions(to:sheet, context:context, host:self) { [weak self] in self?.leaveRecipe() }
        sheet.addAction(UIAlertAction(title:"Cancel",style:.cancel)); sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem; present(sheet,animated:true)
    }
    private func showVideoSource(_ tutorial:RecipeTutorial) {
        let sheet = UIAlertController(title:tutorial.title,message:"By " + tutorial.author + " · " + tutorial.provider + "\n\n" + tutorial.note,preferredStyle:.actionSheet)
        sheet.addAction(UIAlertAction(title:"Open original video",style:.default) { [weak self] _ in self?.player?.openSource() })
        sheet.addAction(UIAlertAction(title:"Cancel",style:.cancel)); sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(sheet,animated:true)
    }
    private func toggleSave() {
        guard collectionsLoaded, !mutating else { return }; mutating = true; updateCollections()
        Task {
            defer { mutating = false; updateCollections() }
            do { try await TiloBackend.shared.toggleBookmark(recipeID:recipe.id,saved:!saved); saved.toggle() } catch { fail(error) }
        }
    }
    private func toggleLike() {
        guard collectionsLoaded, !mutating else { return }; mutating = true; updateCollections()
        Task {
            defer { mutating = false; updateCollections() }
            do { try await TiloBackend.shared.toggleLike(contentID:recipe.id,liked:!liked); liked.toggle() } catch { fail(error) }
        }
    }
    private func delete() {
        let alert = UIAlertController(title:"Delete this recipe?",message:"This removes your published recipe. This cannot be undone.",preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"Cancel",style:.cancel)); alert.addAction(UIAlertAction(title:"Delete recipe",style:.destructive) { [weak self] _ in
            guard let self else { return }; Task { do { try await TiloBackend.shared.deleteRecipe(id:self.recipe.id); self.navigationController?.popViewController(animated:true) } catch { self.fail(error) } }
        }); present(alert,animated:true)
    }
    private func share() {
        let controller = UIActivityViewController(activityItems:["\(recipe.title) on Tilo\n\(recipe.payload.summary)"],applicationActivities:nil)
        controller.popoverPresentationController?.sourceView = view; present(controller,animated:true)
    }
    deinit {
        collectionLoadTask?.cancel()
        if let safetyObserver { NotificationCenter.default.removeObserver(safetyObserver) }
    }
}

func scaledQuantity(_ value:String,factor:Double) -> String {
    guard let number = Double(value) else { return value }
    return (number * factor).formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier:"en_US")))
}

