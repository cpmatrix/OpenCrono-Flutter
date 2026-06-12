class AppliancesService {
  Future<void> loadAppliances() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}
