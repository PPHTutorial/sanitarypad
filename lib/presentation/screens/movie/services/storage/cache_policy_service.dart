class CachePolicyService {
  CachePolicyService._();
  static final CachePolicyService instance = CachePolicyService._();

  bool _forceNetworkOnce = true;

  /// Returns true once per app launch to bypass cache for first loads
  bool consumeForceNetwork() {
    if (_forceNetworkOnce) {
      _forceNetworkOnce = false;
      return true;
    }
    return false;
  }
}
