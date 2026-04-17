import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/reference_provider.dart';
import 'widgets/template_card.dart';

class ReferenceScreen extends ConsumerStatefulWidget {
  const ReferenceScreen({super.key});

  @override
  ConsumerState<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends ConsumerState<ReferenceScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referenceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('参考图库'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryTabs(state),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTemplateGrid(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '搜索模板...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: (query) async {
          if (query.isEmpty) return;
          await ref.read(referenceProvider.notifier).searchTemplates(query);
        },
      ),
    );
  }

  Widget _buildCategoryTabs(ReferenceState state) {
    final categories = [null, 'portrait', 'landscape', 'food', 'pet', 'street'];
    final labels = ['全部', '人像', '风景', '美食', '宠物', '街拍'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = state.selectedCategory == categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[index]),
              selected: isSelected,
              onSelected: (_) {
                ref.read(referenceProvider.notifier).selectCategory(categories[index]);
              },
              backgroundColor: const Color(0xFF2A2A2A),
              selectedColor: const Color(0xFF1A73E8),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateGrid(ReferenceState state) {
    if (state.templates.isEmpty) {
      return const Center(
        child: Text('暂无模板', style: TextStyle(color: Colors.white38, fontSize: 16)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: state.templates.length,
      itemBuilder: (context, index) {
        final template = state.templates[index];
        final isSelected = state.selectedTemplate?.id == template.id;
        return TemplateCard(
          template: template,
          isSelected: isSelected,
          onTap: () {
            ref.read(referenceProvider.notifier).selectTemplate(template);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已选择: ${template.name}'),
                duration: const Duration(seconds: 1),
                backgroundColor: const Color(0xFF1A73E8),
              ),
            );
          },
        );
      },
    );
  }
}
