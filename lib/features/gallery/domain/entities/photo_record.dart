class PhotoRecord {
  final String id;
  final String filePath;
  final DateTime captureTime;
  final dynamic analysisResult;
  final String? referenceTemplateId;
  final dynamic cameraParams;
  final Map<String, dynamic> metadata;

  const PhotoRecord({
    required this.id,
    required this.filePath,
    required this.captureTime,
    this.analysisResult,
    this.referenceTemplateId,
    this.cameraParams,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'captureTime': captureTime.toIso8601String(),
        'referenceTemplateId': referenceTemplateId,
        'metadata': metadata,
      };

  factory PhotoRecord.fromJson(Map<String, dynamic> json) => PhotoRecord(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        captureTime: DateTime.parse(json['captureTime'] as String),
        referenceTemplateId: json['referenceTemplateId'] as String?,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      );
}
