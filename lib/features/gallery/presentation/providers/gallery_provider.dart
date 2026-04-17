import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/photo_record.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../../data/repositories/gallery_repository_impl.dart';

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepositoryImpl();
});

class GalleryState {
  final List<PhotoRecord> records;
  final bool isLoading;

  const GalleryState({
    this.records = const [],
    this.isLoading = false,
  });

  GalleryState copyWith({
    List<PhotoRecord>? records,
    bool? isLoading,
  }) {
    return GalleryState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GalleryNotifier extends StateNotifier<GalleryState> {
  final GalleryRepository _repository;

  GalleryNotifier(this._repository) : super(const GalleryState()) {
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    state = state.copyWith(isLoading: true);
    final records = await _repository.getPhotoRecords();
    state = state.copyWith(records: records, isLoading: false);
  }

  Future<void> addRecord(PhotoRecord record) async {
    await _repository.savePhotoRecord(record);
    await _loadRecords();
  }

  Future<void> deleteRecord(String id) async {
    await _repository.deletePhotoRecord(id);
    await _loadRecords();
  }

  Future<void> refresh() async {
    await _loadRecords();
  }
}

final galleryProvider =
    StateNotifierProvider<GalleryNotifier, GalleryState>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return GalleryNotifier(repository);
});
