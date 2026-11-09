import UIKit

private struct MediaCredit:Decodable {
    let id:String
    let kind:String
    let title:String
    let sourceURL:String
    let author:String
    let license:String
    let licenseURL:String
}
final class MediaCreditsController:TiloPage {
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Made with care"
        add(text("A little credit,\na lot of gratitude.",32,heading:true))
        add(text("Cooking films and food photographs are independently sourced. Photographed people are not represented as Tilo members or endorsers.",18,color:TiloTheme.muted))
        add(panel([text("Original shell artwork",23,heading:true),text("Tilo's icons, cooking-pot mark and paper background were generated for this app with an image model.")]))
        add(panel([text("Handwritten type",23,heading:true),text("Kalam Bold and Comic Neue Regular. Bundled unchanged under the SIL Open Font License 1.1.")]))
        do {
            guard let url = Bundle.main.url(forResource:"MediaCredits",withExtension:"json") else { throw NSError(domain:"Tilo",code:1,userInfo:[NSLocalizedDescriptionKey:"Credits could not be found."]) }
            let credits = try JSONDecoder().decode([MediaCredit].self,from:Data(contentsOf:url))
            for credit in credits {
                add(panel([text(credit.title,22,heading:true),text("\(credit.author) · \(credit.license)",16,color:TiloTheme.muted),action("View source",icon:.share) { Self.open(credit.sourceURL) },action("Read license",icon:.list) { Self.open(credit.licenseURL) }]))
            }
        } catch { message("Credits unavailable",error.localizedDescription) }
    }
    private static func open(_ value:String) { guard let url = URL(string:value),url.scheme == "https" else { return }; UIApplication.shared.open(url) }
}
