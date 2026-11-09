import UIKit
import WebKit

private final class TutorialEventProxy:NSObject,WKScriptMessageHandler {
    weak var owner:RecipeTutorialPlayer?
    func userContentController(_ userContentController:WKUserContentController,didReceive message:WKScriptMessage) { owner?.receive(message) }
}

/// Retains the publisher's official player independently from recipe-body updates.
final class RecipeTutorialPlayer:UIView,WKNavigationDelegate,WKUIDelegate {
    private let tutorial:RecipeTutorial
    private var web:WKWebView?
    private let state = text("Loading tutorial…",14,color:TiloTheme.muted)
    private let progress = text("",1,color:.clear)
    private let proxy = TutorialEventProxy()
    private var backgroundObserver:NSObjectProtocol?
    init(tutorial:RecipeTutorial) {
        self.tutorial = tutorial; super.init(frame:.zero)
        let configuration = WKWebViewConfiguration(); configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []; configuration.websiteDataStore = .nonPersistent()
        proxy.owner = self; configuration.userContentController.add(proxy,name:"tutorial")
        let web = WKWebView(frame:.zero,configuration:configuration); self.web = web
        web.navigationDelegate = self; web.uiDelegate = self; web.backgroundColor = .black; web.isOpaque = false
        web.accessibilityIdentifier = "tutorial-player"; web.scrollView.isScrollEnabled = false
        let aspect = web.heightAnchor.constraint(equalTo:web.widthAnchor,multiplier:9.0/16.0); aspect.priority = .defaultHigh; aspect.isActive = true
        web.heightAnchor.constraint(greaterThanOrEqualToConstant:200).isActive = true
        state.accessibilityIdentifier = "tutorial-status"
        progress.accessibilityIdentifier = "tutorial-progress"; progress.accessibilityLabel = "Tutorial playback time"; progress.accessibilityValue = "0"; progress.isAccessibilityElement = true; progress.fixedHeight(1)
        let contents = column([web,state,progress],spacing:4); addSubview(contents); contents.fill(self)
        backgroundObserver = NotificationCenter.default.addObserver(forName:UIApplication.willResignActiveNotification,object:nil,queue:.main) { [weak self] _ in self?.pause() }
        reload()
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    func pause() { web?.evaluateJavaScript("if(typeof player!=='undefined'&&player&&player.pauseVideo){player.pauseVideo();}",completionHandler:nil) }
    func openSource() { guard tutorial.validatedVideoID != nil,let url = URL(string:tutorial.sourceURL) else { return }; UIApplication.shared.open(url) }
    func reload() {
        guard let videoID = tutorial.validatedVideoID else { state.text = "This tutorial link is unavailable."; return }
        let origin = "https://" + (Bundle.main.bundleIdentifier ?? "com.toli.cooking").lowercased()
        state.text = "Loading tutorial…"; progress.accessibilityValue = "0"
        let html = """
        <!doctype html><html lang="en"><head><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="referrer" content="strict-origin-when-cross-origin"><style>html,body,#player{margin:0;width:100%;height:100%;background:#000}</style></head><body><div id="player"></div><script>
        let player; function emit(value){window.webkit.messageHandlers.tutorial.postMessage(value);}
        function onYouTubeIframeAPIReady(){player=new YT.Player('player',{videoId:'\(videoID)',playerVars:{playsinline:1,autoplay:1,rel:0,hl:'en',origin:'\(origin)'},events:{onReady:()=>emit({ready:true}),onStateChange:e=>emit({state:e.data}),onError:e=>emit({error:e.data})}});}
        setInterval(()=>{if(player&&player.getPlayerState&&player.getPlayerState()===1){emit({time:player.getCurrentTime()});}},500);
        </script><script src="https://www.youtube.com/iframe_api"></script></body></html>
        """
        web?.loadHTMLString(html,baseURL:URL(string:origin))
    }
    fileprivate func receive(_ message:WKScriptMessage) {
        guard message.frameInfo.isMainFrame,let value = message.body as? [String:Any] else { return }
        if value["ready"] as? Bool == true { state.text = "Tap Play to watch the tutorial." }
        if let error = value["error"] as? Int { state.text = "The publisher could not play this video here (\(error)). Open the original video or try again." }
        if let stateValue = value["state"] as? Int {
            switch stateValue { case 1:state.text = "Playing tutorial"; case 2:state.text = "Tutorial paused"; case 0:state.text = "Tutorial finished"; case 3:state.text = "Buffering tutorial…"; default:break }
        }
        if let time = value["time"] as? Double,time.isFinite,time >= 0 { progress.accessibilityValue = String(format:"%.2f",time) }
    }
    func webView(_ webView:WKWebView,didFailProvisionalNavigation navigation:WKNavigation!,withError error:Error) { state.text = "The tutorial could not connect. Try again or open the original video." }
    func webView(_ webView:WKWebView,createWebViewWith configuration:WKWebViewConfiguration,for navigationAction:WKNavigationAction,windowFeatures:WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil,let url = navigationAction.request.url,url.scheme == "https" { UIApplication.shared.open(url) }; return nil
    }
    deinit { if let backgroundObserver { NotificationCenter.default.removeObserver(backgroundObserver) }; web?.stopLoading(); web?.configuration.userContentController.removeScriptMessageHandler(forName:"tutorial") }
}


final class RecipeTutorialController:TiloPage {
    private let tutorial:RecipeTutorial
    private var player:RecipeTutorialPlayer?
    init(tutorial:RecipeTutorial) { self.tutorial = tutorial; super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Video tutorial"
        add(text(tutorial.title,24,heading:true)); add(text("By " + tutorial.author + " · " + tutorial.provider,15,color:TiloTheme.muted))
        let player = RecipeTutorialPlayer(tutorial:tutorial); self.player = player; add(player)
        add(text(tutorial.note.replacingOccurrences(of:"Toli's recipe",with:"Tilo's recipe"),15,color:TiloTheme.muted))
        add(action("Open original video",icon:.share) { [weak self] in self?.player?.openSource() })
        add(action("Reload tutorial",icon:.video) { [weak self] in self?.player?.reload() })
    }
    override func viewWillDisappear(_ animated:Bool) { super.viewWillDisappear(animated); player?.pause() }
}
