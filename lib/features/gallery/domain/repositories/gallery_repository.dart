import '../../domain/entities/photo_record.dart';

abstract class GalleryRepository {
  Future<List<PhotoRecord>> getPhotoRecords();
  Future<void> savePhotoRecord(PhotoRecord record);
  Future<void> deletePhotoRecord(String id);
  Future<PhotoRecord?> getPhotoRecordById(String id);
}
