import 'package:flutter/material.dart';
import 'package:reading/services/mock_data.dart';
import 'package:reading/models/book_content.dart';

class CompanionSelectionScreen extends StatefulWidget {
  final Function(List<Role>, bool isGroupMode) onConfirm;

  const CompanionSelectionScreen({super.key, required this.onConfirm});

  @override
  State<CompanionSelectionScreen> createState() => _CompanionSelectionScreenState();
}

class _CompanionSelectionScreenState extends State<CompanionSelectionScreen> {
  final Set<String> selectedRoleIds = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            '希望哪些角色陪你阅读？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '最多选择3个角色',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          // 角色网格
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 角色列表
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: allCompanionRoles.map((role) {
                      final isSelected = selectedRoleIds.contains(role.id);
                      final canSelect = selectedRoleIds.length < 3 || isSelected;
                      
                      return GestureDetector(
                        onTap: canSelect
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    selectedRoleIds.remove(role.id);
                                  } else {
                                    selectedRoleIds.add(role.id);
                                  }
                                });
                              }
                            : null,
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFF3F4F6),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected
                                ? const Color(0xFFEEF2FF)
                                : Colors.white,
                          ),
                          child: Column(
                            children: [
                              Text(
                                role.avatar,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                role.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFF111827),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                role.style,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          // 确认按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedRoleIds.isNotEmpty
                  ? () {
                      final selectedRoles = allCompanionRoles
                          .where((role) => selectedRoleIds.contains(role.id))
                          .toList();
                      widget.onConfirm(selectedRoles, false);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: selectedRoleIds.isNotEmpty ? 8 : 0,
              ),
              child: Text(
                selectedRoleIds.isEmpty
                    ? '请至少选择一个角色'
                    : '开始阅读 (${selectedRoleIds.length}/3)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

