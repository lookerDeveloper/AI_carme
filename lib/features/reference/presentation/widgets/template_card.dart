import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/template.dart';

class TemplateCard extends StatelessWidget {
  final Template template;
  final VoidCallback onTap;
  final bool isSelected;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF1A73E8), width: 2)
              : Border.all(color: Colors.white10, width: 0.5),
          color: const Color(0xFF2A2A2A),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildImageArea(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(template.category),
                        color: Colors.white38,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getCameraParamsText(template),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    if (template.isPlaceholder) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCategoryColor(template.category).withValues(alpha: 0.3),
              _getCategoryColor(template.category).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                template.isCustomUpload ? Icons.upload_file : _getCategoryIcon(template.category),
                color: Colors.white54,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                template.isCustomUpload ? '点击上传' : '暂无模板',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              if (template.isCustomUpload) ...[
                const SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A73E8).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '自定义参考图',
                    style: TextStyle(
                      color: Color(0xFF1A73E8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (template.hasValidImage) {
      return CachedNetworkImage(
        imageUrl: template.displayImageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1A73E8),
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white24, size: 32),
              SizedBox(height: 4),
              Text('加载失败', style: TextStyle(color: Colors.white24, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white10,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getCategoryIcon(template.category), color: Colors.white38, size: 32),
            SizedBox(height: 4),
            Text(template.name, style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'portrait':
        return Icons.person_outline;
      case 'landscape':
        return Icons.landscape;
      case 'food':
        return Icons.restaurant;
      case 'pet':
        return Icons.pets;
      case 'street':
        return Icons.location_city;
      case 'custom':
        return Icons.add_photo_alternate_outlined;
      default:
        return Icons.photo_camera;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'portrait':
        return Colors.purple;
      case 'landscape':
        return Colors.green;
      case 'food':
        return Colors.orange;
      case 'pet':
        return Colors.pink;
      case 'street':
        return Colors.blue;
      case 'custom':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getCameraParamsText(Template template) {
    final params = template.cameraParams;
    if (params.isEmpty) return template.category.toUpperCase();
    
    final focal = params['focal_length'] ?? '50mm';
    final aperture = params['aperture'] ?? 'f/2.8';
    return '$focal · $aperture';
  }
}
