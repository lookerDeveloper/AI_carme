import '../../domain/entities/photo_record.dart';
import '../../domain/repositories/gallery_repository.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  final List<PhotoRecord> _records = [];

  @override
  Future<List<PhotoRecord>> getPhotoRecords() async {
    return List.from(_records)
      ..sort((a, b) => b.captureTime.compareTo(a.captureTime));
  }

  @override
  Future<void> savePhotoRecord(PhotoRecord record) async {
    _records.add(record);
  }

  @override
  Future<void> deletePhotoRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
  }

  @override
  Future<PhotoRecord?> getPhotoRecordById(String id) async {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
}
