import UIKit

/// Shared only by the open recipe's overview, preparation and step navigation.
final class RecipeCookingSession {
    var portions:Int
    var prepared:Set<Int> = []
    var step = 0
    init(recipe:Recipe) { portions = recipe.payload.servings }
}

final class RecipeIngredientPreparationView:UIView {
    private let content = column([],spacing:8)
    var onNotice: (() -> Void)?
    var onFailure: ((Error) -> Void)?
    private let recipe:Recipe
    private let session:RecipeCookingSession
    private var saving = false
    init(recipe:Recipe,session:RecipeCookingSession) {
        self.recipe = recipe; self.session = session; super.init(frame:.zero)
        addSubview(content); content.fill(self); render()
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    private func render() {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        content.addArrangedSubview(row([text("\(session.portions) servings",21,heading:true),Tilo.action("−") { [weak self] in self?.changePortions(-1) },Tilo.action("+") { [weak self] in self?.changePortions(1) }]))
        content.addArrangedSubview(text("\(session.prepared.count) of \(recipe.payload.ingredients.count) ingredients prepared",15,color:TiloTheme.muted))
        let scale = Double(session.portions) / Double(max(1,recipe.payload.servings))
        let ingredients = column([],spacing:8); content.addArrangedSubview(ingredients)
        for (index,ingredient) in recipe.payload.ingredients.enumerated() {
            let label = text("\(scaledQuantity(ingredient.quantity,factor:scale)) \(ingredient.unit)  \(ingredient.name)",18)
            let checked = session.prepared.contains(index)
            let toggle = UIButton(type:.custom)
            toggle.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([toggle.widthAnchor.constraint(equalToConstant:44),toggle.heightAnchor.constraint(equalToConstant:44)])
            let outline = UIView(); outline.layer.cornerRadius = 5; outline.layer.borderWidth = 1.5; outline.layer.borderColor = TiloTheme.olive.cgColor
            outline.isUserInteractionEnabled = false; outline.translatesAutoresizingMaskIntoConstraints = false; toggle.addSubview(outline)
            let mark = UIImageView(image:checked ? TiloIcon.check.image(20) : nil); mark.translatesAutoresizingMaskIntoConstraints = false; outline.addSubview(mark)
            NSLayoutConstraint.activate([outline.centerXAnchor.constraint(equalTo:toggle.centerXAnchor),outline.centerYAnchor.constraint(equalTo:toggle.centerYAnchor),outline.widthAnchor.constraint(equalToConstant:24),outline.heightAnchor.constraint(equalToConstant:24),mark.centerXAnchor.constraint(equalTo:outline.centerXAnchor),mark.centerYAnchor.constraint(equalTo:outline.centerYAnchor),mark.widthAnchor.constraint(equalToConstant:20),mark.heightAnchor.constraint(equalToConstant:20)])
            toggle.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                if session.prepared.contains(index) { session.prepared.remove(index) } else { session.prepared.insert(index) }
                render()
            },for:.touchUpInside)
            toggle.accessibilityLabel = "Prepare " + ingredient.name
            toggle.accessibilityValue = checked ? "Prepared" : "Not prepared"
            toggle.isSelected = checked
            let wrapper = UIView(); wrapper.backgroundColor = .white; wrapper.round(14)
            let item = row([label,toggle]); wrapper.addSubview(item); item.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([item.leadingAnchor.constraint(equalTo:wrapper.leadingAnchor,constant:12),item.trailingAnchor.constraint(equalTo:wrapper.trailingAnchor,constant:-8),item.topAnchor.constraint(equalTo:wrapper.topAnchor,constant:4),item.bottomAnchor.constraint(equalTo:wrapper.bottomAnchor,constant:-4)])
            ingredients.addArrangedSubview(wrapper)
        }
        content.addArrangedSubview(Tilo.action("Add ingredients to shopping list",icon:.kitchen) { [weak self] in self?.addGroceries(scale:scale) })
        content.addArrangedSubview(text("Use separate utensils for raw meat and ready-to-eat food. Check ingredient labels for allergens.",14,color:TiloTheme.muted))
    }
    private func changePortions(_ change:Int) {
        let value = session.portions + change
        guard (1...20).contains(value) else { return }
        session.portions = value; session.prepared = []; render()
    }
    private func addGroceries(scale:Double) {
        guard !saving else { return }; saving = true
        Task { [weak self] in
            guard let self else { return }; defer { saving = false }
            do { try await TiloBackend.shared.addGroceries(items:recipe.payload.ingredients,scale:scale); onNotice?() }
            catch { onFailure?(error) }
        }
    }
}

final class CookModeController:TiloPage {
    private let recipe:Recipe
    private let session:RecipeCookingSession
    private weak var previous:UIButton?
    private weak var nextButton:UIButton?
    init(recipe:Recipe,session:RecipeCookingSession? = nil) { self.recipe = recipe; self.session = session ?? RecipeCookingSession(recipe:recipe); super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Cook along"
        let previous = action("Previous",icon:.back) { [weak self] in self?.move(-1) }
        let next = action("Next",icon:.check,filled:true) { [weak self] in self?.move(1) }
        self.previous = previous; self.nextButton = next
        let controls = row([previous,next]); controls.distribution = .fillEqually; setFooter(controls)
        render()
    }
    override func viewDidAppear(_ animated:Bool) { super.viewDidAppear(animated); UIApplication.shared.isIdleTimerDisabled = true }
    override func viewWillDisappear(_ animated:Bool) { super.viewWillDisappear(animated); UIApplication.shared.isIdleTimerDisabled = false }
    private func render() {
        clear(); add(text(recipe.title,24,heading:true))
        guard !recipe.payload.steps.isEmpty else { message("No steps yet","This recipe is still being prepared."); previous?.isEnabled = false; nextButton?.isEnabled = false; return }
        session.step = min(session.step,recipe.payload.steps.count - 1)
        add(text("STEP \(session.step + 1) OF \(recipe.payload.steps.count)",16,color:TiloTheme.red))
        let progress = UIProgressView(progressViewStyle:.default); progress.progressTintColor = TiloTheme.red
        progress.progress = Float(session.step + 1) / Float(recipe.payload.steps.count); progress.accessibilityLabel = "Cooking progress"; add(progress)
        add(panel([text(recipe.payload.steps[session.step],24)]))
        add(text("Cooking for \(session.portions) · Ingredients prepared: \(session.prepared.count)/\(recipe.payload.ingredients.count)",15,color:TiloTheme.muted))
        if let tutorial = recipe.payload.tutorial,tutorial.validatedVideoID != nil {
            add(action("Watch video tutorial",icon:.video) { [weak self] in self?.push(RecipeTutorialController(tutorial:tutorial)) })
        }
        add(action("Set a kitchen timer",icon:.clock) { [weak self] in self?.push(KitchenTimerController()) })
        add(text("Keep the app open for timer updates. Check safe doneness with a food thermometer.",14,color:TiloTheme.muted))
        previous?.isEnabled = session.step > 0
        let title = session.step == recipe.payload.steps.count - 1 ? "Finish" : "Next"
        nextButton?.setTitle(title,for:.normal); nextButton?.accessibilityLabel = title
    }
    private func move(_ delta:Int) {
        if delta > 0,session.step == recipe.payload.steps.count - 1 {
            if let overview = navigationController?.viewControllers.last(where: { ($0 as? RecipeDetailController)?.recipe.id == recipe.id }) { navigationController?.popToViewController(overview,animated:true) }
            else { navigationController?.popViewController(animated:true) }
            return
        }
        session.step = max(0,min(recipe.payload.steps.count - 1,session.step + delta)); render(); scroll.setContentOffset(.zero,animated:false)
    }
}
