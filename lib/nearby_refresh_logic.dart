class NearbyRefreshLogic {
  static bool shouldFetch({
    required bool hasExistingResources,
    required bool forceRefresh,
    required bool requireFreshLocation,
    required String? currentSignature,
    required String? lastSignature,
  }) {
    if (currentSignature == null) {
      return false;
    }

    if (forceRefresh || requireFreshLocation) {
      return true;
    }

    if (!hasExistingResources) {
      return true;
    }

    return currentSignature != lastSignature;
  }
}
