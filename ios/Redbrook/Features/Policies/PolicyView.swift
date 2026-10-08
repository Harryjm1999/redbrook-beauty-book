import SwiftUI
import WebKit

/// The clinic's published policies on redbrookclinic.com. They're shown live,
/// so edits on the website appear in the app without an update.
enum PolicyPage: String, CaseIterable, Hashable, Identifiable {
  case privacy
  case recordsManagement

  var id: String { rawValue }

  var title: String {
    switch self {
    case .privacy: "Privacy Policy"
    case .recordsManagement: "Records Management Policy"
    }
  }

  var url: URL {
    switch self {
    case .privacy: URL(string: "https://www.redbrookclinic.com/privacy")!
    case .recordsManagement: URL(string: "https://www.redbrookclinic.com/records-management-policy")!
    }
  }
}

struct PolicyView: View {
  let page: PolicyPage

  @State private var isLoading = true
  @State private var failed = false
  @State private var reloadToken = 0

  var body: some View {
    ZStack {
      PolicyWebView(url: page.url, isLoading: $isLoading, failed: $failed)
        .id(reloadToken)
        .opacity(failed ? 0 : 1)

      if failed {
        VStack(spacing: 16) {
          Text("We couldn't load the \(page.title.lowercased()).")
            .bodyText(15)
            .multilineTextAlignment(.center)
          Text("Check your connection and try again, or read it on our website.")
            .mutedText(14)
            .multilineTextAlignment(.center)
          HStack(spacing: 8) {
            Button("Try again") {
              failed = false
              isLoading = true
              reloadToken += 1
            }
            .buttonStyle(.clinic(.primary))
            Link("Open website", destination: page.url)
              .buttonStyle(.clinic(.outline))
          }
        }
        .foregroundStyle(Palette.foreground)
        .padding(24)
      } else if isLoading {
        ProgressView()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.background)
    .navigationTitle(page.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(Palette.cream, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Link(destination: page.url) {
          Image(systemName: "safari")
        }
        .accessibilityLabel("Open in Safari")
      }
    }
  }
}

private struct PolicyWebView: UIViewRepresentable {
  let url: URL
  @Binding var isLoading: Bool
  @Binding var failed: Bool

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.userContentController.addUserScript(
      WKUserScript(source: Self.tidyScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    )
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = context.coordinator
    webView.isOpaque = false
    webView.backgroundColor = UIColor(Palette.background)
    webView.allowsBackForwardNavigationGestures = false
    webView.load(URLRequest(url: url))
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {}

  /// Hides the website's own floating header, menu and cookie banner so the screen shows
  /// just the policy under the app's navigation bar. Anything pinned to the viewport
  /// (position fixed or sticky) is hidden, re-checked briefly as the site finishes loading.
  private static let tidyScript = """
    (function () {
      function tidy() {
        document.querySelectorAll('body *').forEach(function (el) {
          var position = window.getComputedStyle(el).position;
          if (position === 'fixed' || position === 'sticky') {
            el.style.setProperty('display', 'none', 'important');
          }
        });
      }
      tidy();
      var runs = 0;
      var timer = setInterval(function () {
        tidy();
        if (++runs >= 20) clearInterval(timer);
      }, 500);
    })();
    """

  final class Coordinator: NSObject, WKNavigationDelegate {
    private let parent: PolicyWebView

    init(_ parent: PolicyWebView) { self.parent = parent }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
      // Keep the screen on the policy itself; any other link opens in Safari or Mail.
      if navigationAction.navigationType == .linkActivated, let target = navigationAction.request.url {
        let samePage = target.host == parent.url.host && target.path == parent.url.path
        if !samePage {
          UIApplication.shared.open(target)
          decisionHandler(.cancel)
          return
        }
      }
      decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      parent.isLoading = false
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      fail()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
      fail()
    }

    private func fail() {
      parent.isLoading = false
      parent.failed = true
    }
  }
}

/// Links to both policies, shown at the bottom of every screen.
struct PolicyLinks: View {
  var color: Color = Palette.mutedForeground

  var body: some View {
    HStack(spacing: 6) {
      NavigationLink(value: PolicyPage.privacy) {
        Text(PolicyPage.privacy.title)
      }
      Text("·").accessibilityHidden(true)
      NavigationLink(value: PolicyPage.recordsManagement) {
        Text(PolicyPage.recordsManagement.title)
      }
    }
    .font(AppFont.body(12))
    .underline()
    .foregroundStyle(color)
    .tint(color)
    .frame(maxWidth: .infinity)
    .multilineTextAlignment(.center)
  }
}

extension View {
  /// Registers the policy screens for a tab's navigation stack.
  func policyDestinations() -> some View {
    navigationDestination(for: PolicyPage.self) { PolicyView(page: $0) }
  }
}
