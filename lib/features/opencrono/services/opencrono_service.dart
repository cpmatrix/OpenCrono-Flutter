class OpenCronoService {
  Future<void> sync() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}
