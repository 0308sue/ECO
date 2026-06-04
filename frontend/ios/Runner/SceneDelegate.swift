import Flutter
import NidThirdPartyLogin
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if URLContexts.contains(where: { NidOAuth.shared.handleURL($0.url) }) {
      return
    }

    super.scene(scene, openURLContexts: URLContexts)
  }
}
