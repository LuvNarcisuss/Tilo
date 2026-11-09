import UIKit
import PhotosUI

private struct RecipeEditorDraft:Codable {
    let id:String
    let title:String
    let cuisine:String
    let summary:String
    let prep:String
    let cook:String
    let portions:String
    let steps:String
    let ingredients:[RecipeIngredient]
    let photo:Data?
}

final class RecipeEditorController:TiloPage,PHPickerViewControllerDelegate,UITextViewDelegate {
    private let original:Recipe?
    private var draftID:String
    private let accountID = TiloBackend.shared.userID
    private var published = false
    private var draftReadable = true
    private var saveTask:Task<Void,Never>?
    private var draftKey:String { "recipe-" + (original?.id ?? "new") }
    private let name = UITextField()
    private let cuisine = UITextField()
    private let summary = UITextView()
    private let prep = UITextField()
    private let cook = UITextField()
    private let portions = UITextField()
    private let steps = UITextView()
    private let ingredientStack = UIStackView()
    private let draftStatus = text("",14,color:TiloTheme.muted)
    private var ingredientFields:[(UITextField,UITextField,UITextField)] = []
    private var photoData:Data?
    private let preview = RemotePhoto(nil,height:200)
    private var saving = false
    init(recipe:Recipe? = nil) { original = recipe; draftID = recipe?.id ?? "member-" + UUID().uuidString.lowercased(); super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = original == nil ? "Write a recipe" : "Edit recipe"
        add(text("Made in your kitchen.",33,heading:true)); add(text("Share a recipe you wrote and a photo you have permission to publish.",18,color:TiloTheme.muted))
        draftStatus.isHidden = true; draftStatus.accessibilityIdentifier = "recipe-draft-status"; add(draftStatus)
        preview.contentMode = .scaleAspectFill; preview.round(22); preview.backgroundColor = .white
        preview.image = TiloIcon.camera.image(72); preview.contentMode = .center
        preview.isAccessibilityElement = true; preview.accessibilityIdentifier = "recipe-photo-preview"
        preview.accessibilityLabel = "Recipe photo"; preview.accessibilityValue = "Choose a photo"
        if let url = original?.imageURL {
            preview.contentMode = .scaleAspectFill; preview.setURL(url); preview.accessibilityValue = "Current recipe photo"
        }
        add(preview)
        add(action("Choose a recipe photo",icon:.camera) { [weak self] in self?.choosePhoto() })
        addField(name,label:"Recipe name",placeholder:"A name worth sharing",value:original?.title ?? "")
        addField(cuisine,label:"Cuisine",placeholder:"Italian, French, American…",value:original?.category ?? "European")
        add(text("A little introduction",19,heading:true)); summary.accessibilityLabel = "Recipe introduction"; configure(summary,value:original?.payload.summary ?? "",height:100); add(summary)
        addField(prep,label:"Prep time in minutes",placeholder:"10",value:String(original?.payload.prepMinutes ?? 10),number:true)
        addField(cook,label:"Cook time in minutes",placeholder:"20",value:String(original?.payload.cookMinutes ?? 20),number:true)
        addField(portions,label:"Servings",placeholder:"2",value:String(original?.payload.servings ?? 2),number:true)
        add(text("Ingredients",26,heading:true)); add(text("Give each ingredient its amount and unit.",16,color:TiloTheme.muted))
        ingredientStack.axis = .vertical; ingredientStack.spacing = 12; add(ingredientStack)
        if let original { for ingredient in original.payload.ingredients { ingredientRow(ingredient) } } else { ingredientRow(nil); ingredientRow(nil); ingredientRow(nil) }
        add(action("Add ingredient",icon:.plus) { [weak self] in self?.ingredientRow(nil) })
        add(text("Method",26,heading:true)); add(text("Write one clear step per paragraph.",16,color:TiloTheme.muted))
        steps.accessibilityLabel = "Recipe method"; configure(steps,value:original?.payload.steps.joined(separator:"\n\n") ?? "",height:260); add(steps)
        add(action(original == nil ? "Publish recipe" : "Save changes",icon:.recipes,filled:true) { [weak self] in self?.save() })
        add(text("Recipes and photos you publish can be seen by other members. Include temperatures, timing and allergen details when relevant.",15,color:TiloTheme.muted))
        restoreDraft()
    }
    override func viewWillDisappear(_ animated:Bool) { super.viewWillDisappear(animated); saveTask?.cancel(); saveDraft() }
    func textViewDidChange(_ textView:UITextView) { draftChanged() }
    @objc private func draftChanged() {
        saveTask?.cancel(); saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds:500_000_000); guard !Task.isCancelled else { return }; self?.saveDraft()
        }
    }
    private func saveDraft() {
        guard !published,draftReadable,let accountID,TiloBackend.shared.userID == accountID else { return }
        let ingredients = ingredientFields.map { RecipeIngredient(name:$0.0.text ?? "",quantity:$0.1.text ?? "",unit:$0.2.text ?? "") }
        let draft = RecipeEditorDraft(id:draftID,title:name.text ?? "",cuisine:cuisine.text ?? "",summary:summary.text ?? "",prep:prep.text ?? "",cook:cook.text ?? "",portions:portions.text ?? "",steps:steps.text ?? "",ingredients:ingredients,photo:photoData)
        do { try TiloDraftStorage.save(JSONEncoder().encode(draft),key:draftKey,accountID:accountID); showDraftStatus("Private draft saved on this device") }
        catch { showDraftStatus("Draft could not be saved. Keep this page open.") }
    }
    private func restoreDraft() {
        guard let accountID else { return }
        do {
            guard let data = try TiloDraftStorage.read(key:draftKey,accountID:accountID) else { return }
            let draft = try JSONDecoder().decode(RecipeEditorDraft.self,from:data)
            draftID = draft.id; name.text = draft.title; cuisine.text = draft.cuisine; summary.text = draft.summary
            prep.text = draft.prep; cook.text = draft.cook; portions.text = draft.portions; steps.text = draft.steps
            ingredientStack.arrangedSubviews.forEach { $0.removeFromSuperview() }; ingredientFields = []
            for ingredient in draft.ingredients { ingredientRow(ingredient) }
            photoData = draft.photo; if let data = draft.photo { preview.setURL(nil); preview.image = UIImage(data:data); preview.contentMode = .scaleAspectFill; preview.accessibilityValue = "Selected recipe photo" }
            showDraftStatus("Private draft restored")
        } catch { draftReadable = false; showDraftStatus("Saved draft could not be read. Existing data has been kept.") }
    }
    private func showDraftStatus(_ value:String) { draftStatus.text = value; draftStatus.isHidden = false }
    private func addField(_ field:UITextField,label:String,placeholder:String,value:String,number:Bool=false) {
        add(text(label,18,heading:true)); field.font = TiloTheme.font(18); field.text = value; field.placeholder = placeholder; field.accessibilityLabel = label; field.borderStyle = .roundedRect; field.backgroundColor = .white; field.heightAnchor.constraint(greaterThanOrEqualToConstant:48).isActive = true
        if number { field.keyboardType = .numberPad }; field.addTarget(self,action:#selector(draftChanged),for:.editingChanged); add(field)
    }
    private func configure(_ input:UITextView,value:String,height:CGFloat) { input.text = value; input.delegate = self; input.font = TiloTheme.font(18); input.round(14); input.backgroundColor = .white; input.fixedHeight(height) }
    private func ingredientRow(_ ingredient:RecipeIngredient?) {
        guard ingredientFields.count < 30 else { return }
        let item = UITextField(),quantity = UITextField(),unit = UITextField()
        for field in [item,quantity,unit] { field.font = TiloTheme.font(17); field.borderStyle = .roundedRect; field.backgroundColor = .white; field.fixedHeight(48); field.addTarget(self,action:#selector(draftChanged),for:.editingChanged) }
        item.placeholder = "Ingredient"; item.text = ingredient?.name; item.accessibilityLabel = "Ingredient name"
        quantity.placeholder = "Amount"; quantity.keyboardType = .decimalPad; quantity.text = ingredient?.quantity; quantity.accessibilityLabel = "Ingredient amount"
        unit.placeholder = "Unit"; unit.text = ingredient?.unit; unit.accessibilityLabel = "Ingredient unit"
        let values = row([quantity,unit]); values.distribution = .fillEqually
        ingredientStack.addArrangedSubview(panel([item,values])); ingredientFields.append((item,quantity,unit))
    }
    private func choosePhoto() { var configuration = PHPickerConfiguration(); configuration.filter = .images; configuration.selectionLimit = 1; let picker = PHPickerViewController(configuration:configuration); picker.delegate = self; present(picker,animated:true) }
    func picker(_ picker:PHPickerViewController,didFinishPicking results:[PHPickerResult]) {
        picker.dismiss(animated:true); guard let provider = results.first?.itemProvider,provider.canLoadObject(ofClass:UIImage.self) else { return }
        provider.loadObject(ofClass:UIImage.self) { [weak self] item,error in
            guard let image = item as? UIImage else { return }
            let ratio = min(1,1400/max(image.size.width,image.size.height)); let size = CGSize(width:image.size.width*ratio,height:image.size.height*ratio)
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let scaled = UIGraphicsImageRenderer(size:size,format:format).image { _ in image.draw(in:CGRect(origin:.zero,size:size)) }
            guard let data = scaled.jpegData(compressionQuality:0.84),data.count < 10_000_000 else { return }
            Task { @MainActor in self?.photoData = data; self?.preview.setURL(nil); self?.preview.image = scaled; self?.preview.contentMode = .scaleAspectFill; self?.preview.accessibilityValue = "Selected recipe photo"; self?.saveDraft() }
        }
    }
    private func save() {
        guard !saving,let accountID,TiloBackend.shared.userID == accountID else { return }
        saveDraft()
        let title = (name.text ?? "").trimmingCharacters(in:.whitespacesAndNewlines)
        let cuisine = (cuisine.text ?? "").trimmingCharacters(in:.whitespacesAndNewlines)
        let intro = summary.text.trimmingCharacters(in:.whitespacesAndNewlines)
        let method = steps.text.components(separatedBy:.newlines).map { $0.trimmingCharacters(in:.whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let ingredients:[RecipeIngredient] = ingredientFields.compactMap { item,quantity,unit in
            guard let name = item.text?.trimmingCharacters(in:.whitespacesAndNewlines),!name.isEmpty else { return nil }
            return RecipeIngredient(name:name,quantity:quantity.text ?? "",unit:unit.text ?? "")
        }
        guard (3...120).contains(title.count),!cuisine.isEmpty,!intro.isEmpty,!ingredients.isEmpty,!method.isEmpty,
              let prep = Int(prep.text ?? ""),(0...1440).contains(prep),let cook = Int(cook.text ?? ""),(0...1440).contains(cook),let portions = Int(portions.text ?? ""),(1...30).contains(portions) else { showNotice("A few finishing touches","Add a name, introduction, ingredients, method, valid cooking times and servings."); return }
        guard original?.imageURL != nil || photoData != nil else { showNotice("Add your photo","Choose a clear photo of your dish before publishing."); return }
        saving = true; view.endEditing(true)
        Task {
            defer { saving = false }
            do {
                var photo = original?.imageURL
                if let photoData { photo = try await TiloBackend.shared.uploadRecipePhoto(data:photoData) }
                guard TiloBackend.shared.userID == accountID else { return }
                let payload = RecipePayload(summary:intro,prepMinutes:prep,cookMinutes:cook,servings:portions,calories:0,protein:0,carbs:0,fat:0,difficulty:"Home cooking",ingredients:ingredients,steps:method,tags:[],tutorial:original?.payload.tutorial)
                let saved = try await TiloBackend.shared.saveRecipe(draft:RecipeDraft(id:draftID,title:title,category:cuisine,imageURL:photo,payload:payload))
                published = true
                do { try TiloDraftStorage.remove(key:draftKey,accountID:accountID) } catch { showDraftStatus("Recipe published; a private draft copy could not be removed.") }
                guard let nav = navigationController else { return }
                var controllers = nav.viewControllers; controllers.removeLast()
                if self.original != nil, let previous = controllers.last as? RecipeDetailController, previous.recipe.id == saved.id { controllers.removeLast() }
                controllers.append(RecipeDetailController(recipe:saved)); nav.setViewControllers(controllers,animated:true)
            } catch { fail(error) }
        }
    }
    deinit { saveTask?.cancel() }
}
