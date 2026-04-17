import 'package:flutter/material.dart';
import '../../domain/entities/template.dart';

class ReferenceOverlay extends StatelessWidget {
  final Template template;

  const ReferenceOverlay({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      right: 16,
      child: GestureDetector(
        onTap: () {
        },
        child: Container(
          width: 100,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white38, width: 1),
            color: Colors.black54,
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(7),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.white38,
                      size: 32,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                child: Text(
                  template.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
