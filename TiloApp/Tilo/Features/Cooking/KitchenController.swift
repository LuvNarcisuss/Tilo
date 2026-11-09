import UIKit

final class KitchenController: TiloPage {
    private var selectedDay = Date()
    private var plans: [MealPlan] = []
    private var groceries: [GroceryItem] = []
    private var busy = false
    override func viewDidLoad() { super.viewDidLoad(); title = "Kitchen" }
    override func viewWillAppear(_ animated:Bool) { super.viewWillAppear(animated); load() }
    private func load() {
        guard !busy else { return }; busy = true
        if content.arrangedSubviews.isEmpty { message("Setting the table…", "Loading your meal plan and shopping list.") }
        Task {
            defer { busy = false }
            do {
                async let meals = TiloBackend.shared.mealPlans()
                async let shopping = TiloBackend.shared.groceries()
                (plans,groceries) = try await (meals,shopping); render()
            } catch { clear(); message("Your kitchen could not load",error.localizedDescription); add(action("Try again") { [weak self] in self?.load() }) }
        }
    }
    private func render() {
        clear(); add(text("A lovely week,\none meal at a time.",34,heading:true))
        add(text("Plan a little. Cook with less fuss.",19,color:TiloTheme.muted))
        add(action("Kitchen timer",icon:.clock) { [weak self] in self?.push(KitchenTimerController()) })
        let calendar = UIDatePicker(); calendar.datePickerMode = .date; calendar.preferredDatePickerStyle = .compact; calendar.date = selectedDay
        calendar.tintColor = TiloTheme.red; calendar.addAction(UIAction { [weak self,weak calendar] _ in guard let self,let calendar else { return }; self.selectedDay = calendar.date; self.render() },for:.valueChanged)
        add(panel([text("The meal plan",28,heading:true),calendar]))
        let day = dayKey(selectedDay)
        for slot in ["Breakfast","Lunch","Dinner"] {
            let meal = plans.first { $0.date == day && $0.slot == slot }
            var views: [UIView] = [text(slot.uppercased(),14,color:TiloTheme.red)]
            if let meal {
                views.append(RemotePhoto(meal.imageURL,height:120)); views.append(text(meal.recipeTitle,23,heading:true))
                views.append(row([action("Open recipe",icon:.recipes) { [weak self] in
                    Task { do { let recipe = try await TiloBackend.shared.recipe(id:meal.recipeID); self?.push(RecipeDetailController(recipe:recipe)) } catch { self?.fail(error) } }
                },action("Remove",icon:.trash) { [weak self] in self?.remove(meal) }]))
            } else { views.append(text("What sounds good?",20)); views.append(action("Choose a recipe",icon:.plus) { [weak self] in
                guard let self else { return }; self.push(RecipeChooserController(date:day,slot:slot))
            }) }
            add(panel(views))
        }
        add(text("Shopping list",29,heading:true))
        let remaining = groceries.filter { !$0.checked }.count
        add(text("\(remaining) items to pick up",17,color:TiloTheme.muted))
        add(action("Add an item",icon:.plus) { [weak self] in self?.addItem() })
        if groceries.isEmpty { message("Fresh list, fresh possibilities","Add ingredients from a recipe or jot down anything you need.") }
        let grouped = Dictionary(grouping:groceries,by: { $0.name.lowercased() })
        for key in grouped.keys.sorted() {
            let items = grouped[key] ?? []
            for item in items {
                let name = text(item.name,20,heading:true,color:item.checked ? TiloTheme.muted : TiloTheme.ink)
                let detail = text(item.quantity,16,color:TiloTheme.muted)
                let itemText = column([name,detail],spacing:3)
                let toggle = action(item.checked ? "Done" : "Pick up",icon:item.checked ? .check : .kitchen) { [weak self] in self?.toggle(item) }
                toggle.isSelected = item.checked
                toggle.accessibilityValue = item.checked ? "Completed" : "To pick up"
                let remove = action("Remove",icon:.trash) { [weak self] in self?.remove(item) }
                add(panel([row([itemText,toggle]),remove]))
            }
        }
    }
    private func remove(_ meal:MealPlan) {
        Task { do { try await TiloBackend.shared.removeMeal(id:meal.id); load() } catch { fail(error) } }
    }
    private func toggle(_ item:GroceryItem) {
        Task { do { try await TiloBackend.shared.updateGrocery(id:item.id,checked:!item.checked); load() } catch { fail(error) } }
    }
    private func remove(_ item:GroceryItem) {
        Task { do { try await TiloBackend.shared.removeGrocery(id:item.id); load() } catch { fail(error) } }
    }
    private func addItem() {
        let alert = UIAlertController(title:"Add to your list",message:nil,preferredStyle:.alert)
        alert.addTextField { $0.placeholder = "Ingredient or item"; $0.font = TiloTheme.font() }
        alert.addTextField { $0.placeholder = "Quantity, such as 2 lemons"; $0.font = TiloTheme.font() }
        alert.addAction(UIAlertAction(title:"Cancel",style:.cancel)); alert.addAction(UIAlertAction(title:"Add",style:.default) { [weak self,weak alert] _ in
            guard let self,let name = alert?.textFields?.first?.text?.trimmingCharacters(in:.whitespacesAndNewlines),!name.isEmpty else { return }
            let quantity = alert?.textFields?.last?.text ?? ""
            Task { do { try await TiloBackend.shared.addGrocery(name:name,quantity:quantity); self.load() } catch { self.fail(error) } }
        }); present(alert,animated:true)
    }
}

func dayKey(_ date:Date) -> String {
    let formatter = DateFormatter(); formatter.calendar = Calendar(identifier:.gregorian); formatter.locale = Locale(identifier:"en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"; return formatter.string(from:date)
}

final class MealPickerController: TiloPage {
    private let recipe:Recipe
    private let date = UIDatePicker()
    private var slot = "Dinner"
    private var saving = false
    init(recipe:Recipe) { self.recipe = recipe; super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Plan a meal"
        add(RemotePhoto(recipe.imageURL,height:190)); add(text(recipe.title,30,heading:true))
        date.datePickerMode = .date; date.preferredDatePickerStyle = .inline; date.tintColor = TiloTheme.red; add(date)
        let picker = UISegmentedControl(items:["Breakfast","Lunch","Dinner"]); picker.selectedSegmentIndex = 2
        picker.setTitleTextAttributes([.font:TiloTheme.font(16)],for:.normal); picker.fixedHeight(48)
        picker.addAction(UIAction { [weak self,weak picker] _ in guard let picker else { return }; self?.slot = ["Breakfast","Lunch","Dinner"][picker.selectedSegmentIndex] },for:.valueChanged); add(picker)
        add(action("Save meal",icon:.calendar,filled:true) { [weak self] in self?.save() })
        add(text("A new choice replaces the meal already planned for this slot.",15,color:TiloTheme.muted))
    }
    private func save() {
        guard !saving else { return }; saving = true
        Task { defer { saving = false }; do { try await TiloBackend.shared.saveMeal(date:dayKey(date.date),slot:slot,recipeID:recipe.id); navigationController?.popViewController(animated:true) } catch { fail(error) } }
    }
}

final class RecipeChooserController: TiloPage {
    private let date:String
    private let slot:String
    private var saving = false
    init(date:String,slot:String) { self.date = date; self.slot = slot; super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Choose \(slot.lowercased())"; load()
    }
    private func load() {
        clear(); add(text("What shall we cook?",31,heading:true))
        Task {
            do {
                let recipes = try await TiloBackend.shared.recipes()
                for recipe in recipes { add(TiloRecipeCard(recipe:recipe) { [weak self] in self?.choose(recipe) }) }
                if recipes.isEmpty { message("No recipes yet","Published recipes will appear here.") }
            } catch { message("Could not load recipes",error.localizedDescription); add(action("Retry") { [weak self] in self?.load() }) }
        }
    }
    private func choose(_ recipe:Recipe) {
        guard !saving else { return }; saving = true
        Task { defer { saving = false }; do { try await TiloBackend.shared.saveMeal(date:date,slot:slot,recipeID:recipe.id); navigationController?.popViewController(animated:true) } catch { fail(error) } }
    }
}

final class KitchenTimerController: TiloPage {
    private let display = text("10:00",62,heading:true)
    private var endDate:Date?
    private var remaining:TimeInterval = 600
    private var ticker:Timer?
    private let minutes = UIDatePicker()
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Kitchen timer"
        display.textAlignment = .center; add(text("Take your time.",36,heading:true)); add(panel([display]))
        minutes.datePickerMode = .countDownTimer; minutes.countDownDuration = 600; minutes.tintColor = TiloTheme.olive; add(minutes)
        add(action("Start timer",icon:.play,filled:true) { [weak self] in self?.start() })
        add(row([action("Pause",icon:.pause) { [weak self] in self?.pause() },action("Reset",icon:.clock) { [weak self] in self?.reset() }]))
        add(text("The timer follows the clock if you leave this screen. Return here to check it; Tilo does not send a background alarm.",17,color:TiloTheme.muted))
        if let data = UserDefaults.standard.dictionary(forKey:"ToliKitchenTimer"), let end = data["end"] as? Double { endDate = Date(timeIntervalSince1970:end); tick(); installTicker() }
    }
    private func installTicker() { ticker?.invalidate(); ticker = Timer.scheduledTimer(withTimeInterval:1,repeats:true) { [weak self] _ in Task { @MainActor in self?.tick() } } }
    private func start() {
        if endDate != nil { return }
        let interval = (remaining == 600 || remaining <= 0) ? minutes.countDownDuration : remaining
        remaining = max(1,interval); endDate = Date().addingTimeInterval(remaining)
        UserDefaults.standard.set(["end":endDate!.timeIntervalSince1970],forKey:"ToliKitchenTimer"); tick(); installTicker()
    }
    private func pause() {
        if let endDate { remaining = max(0,endDate.timeIntervalSinceNow) }; endDate = nil; ticker?.invalidate(); UserDefaults.standard.removeObject(forKey:"ToliKitchenTimer"); updateDisplay()
    }
    private func reset() { ticker?.invalidate(); endDate = nil; remaining = 600; UserDefaults.standard.removeObject(forKey:"ToliKitchenTimer"); updateDisplay() }
    private func tick() {
        guard let endDate else { return }; remaining = max(0,endDate.timeIntervalSinceNow); updateDisplay()
        if remaining == 0 { self.endDate = nil; ticker?.invalidate(); UserDefaults.standard.removeObject(forKey:"ToliKitchenTimer"); if viewIfLoaded?.window != nil { showNotice("Time to check your dish","Your kitchen timer has finished.") } }
    }
    private func updateDisplay() { let seconds = Int(ceil(remaining)); display.text = String(format:"%02d:%02d",seconds/60,seconds%60); display.accessibilityLabel = "\(seconds/60) minutes and \(seconds%60) seconds remaining" }
    deinit { ticker?.invalidate() }
}
