import '../../domain/entities/template.dart';

class LocalTemplateDataSource {
  List<Template> getTemplates() {
    return _builtInTemplates;
  }
}

final _builtInTemplates = <Template>[
  Template(
    id: 'portrait_half',
    name: '半身人像',
    category: 'portrait',
    thumbnailAsset: 'assets/templates/portrait_half.jpg',
    tags: ['人像', '半身', '经典'],
    compositionRules: {
      'subject_position': 'center_left',
      'head_room': '1/3',
      'eye_line': 'upper_third',
    },
    cameraParams: {
      'focal_length': '50mm',
      'aperture': 'f/2.8',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
  Template(
    id: 'portrait_full',
    name: '全身人像',
    category: 'portrait',
    thumbnailAsset: 'assets/templates/portrait_full.jpg',
    tags: ['人像', '全身', '站姿'],
    compositionRules: {
      'subject_position': 'center',
      'head_room': '1/6',
      'foot_room': '1/12',
    },
    cameraParams: {
      'focal_length': '35mm',
      'aperture': 'f/4',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
  Template(
    id: 'portrait_closeup',
    name: '头像特写',
    category: 'portrait',
    thumbnailAsset: 'assets/templates/portrait_closeup.jpg',
    tags: ['人像', '特写', '头像'],
    compositionRules: {
      'subject_position': 'center',
      'head_room': '1/4',
      'crop': 'shoulders',
    },
    cameraParams: {
      'focal_length': '85mm',
      'aperture': 'f/2.8',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
  Template(
    id: 'landscape_mountain',
    name: '山海景',
    category: 'landscape',
    thumbnailAsset: 'assets/templates/landscape_mountain.jpg',
    tags: ['风景', '山海', '远景'],
    compositionRules: {
      'horizon': 'lower_third',
      'subject_position': 'center',
    },
    cameraParams: {
      'focal_length': '24mm',
      'aperture': 'f/8',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
  Template(
    id: 'landscape_sunset',
    name: '日落剪影',
    category: 'landscape',
    thumbnailAsset: 'assets/templates/landscape_sunset.jpg',
    tags: ['风景', '日落', '剪影'],
    compositionRules: {
      'horizon': 'lower_third',
      'subject_position': 'center_left',
      'exposure': 'silhouette',
    },
    cameraParams: {
      'focal_length': '35mm',
      'aperture': 'f/5.6',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
  Template(
    id: 'food_overhead',
    name: '美食俯拍',
    category: 'food',
    thumbnailAsset: 'assets/templates/food_overhead.jpg',
    tags: ['美食', '俯拍', 'flat_lay'],
    compositionRules: {
      'angle': 'overhead',
      'subject_position': 'center',
    },
    cameraParams: {
      'focal_length': '35mm',
      'aperture': 'f/4',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
  Template(
    id: 'food_45degree',
    name: '美食45度',
    category: 'food',
    thumbnailAsset: 'assets/templates/food_45degree.jpg',
    tags: ['美食', '45度', '特写'],
    compositionRules: {
      'angle': '45_degree',
      'subject_position': 'center_left',
    },
    cameraParams: {
      'focal_length': '50mm',
      'aperture': 'f/2.8',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
  Template(
    id: 'pet_closeup',
    name: '宠物特写',
    category: 'pet',
    thumbnailAsset: 'assets/templates/pet_closeup.jpg',
    tags: ['宠物', '特写', '可爱'],
    compositionRules: {
      'subject_position': 'center',
      'focus': 'eyes',
    },
    cameraParams: {
      'focal_length': '85mm',
      'aperture': 'f/2.8',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
  Template(
    id: 'street_depth',
    name: '街拍纵深感',
    category: 'street',
    thumbnailAsset: 'assets/templates/street_depth.jpg',
    tags: ['街拍', '纵深', '引导线'],
    compositionRules: {
      'composition': 'leading_lines',
      'subject_position': 'lower_third',
    },
    cameraParams: {
      'focal_length': '35mm',
      'aperture': 'f/5.6',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
  Template(
    id: 'architecture_symmetry',
    name: '建筑对称',
    category: 'landscape',
    thumbnailAsset: 'assets/templates/architecture_symmetry.jpg',
    tags: ['建筑', '对称', '几何'],
    compositionRules: {
      'composition': 'symmetry',
      'angle': 'straight_on',
    },
    cameraParams: {
      'focal_length': '24mm',
      'aperture': 'f/8',
    },
    usageCount: 0,
    createdAt: DateTime(2026, 1, 1),
  ),
];
