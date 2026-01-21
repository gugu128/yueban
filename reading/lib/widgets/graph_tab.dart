import 'package:flutter/material.dart';
import 'package:reading/services/mock_data.dart';
import 'package:reading/models/book_content.dart';

class GraphTab extends StatefulWidget {
  final String bookId; // 'xyj' 或 'jane_eyre'

  const GraphTab({
    super.key,
    this.bookId = 'xyj',
  });

  @override
  State<GraphTab> createState() => _GraphTabState();
}

class _GraphTabState extends State<GraphTab> {
  GraphNode? selectedNode;
  GraphRelation? selectedRelation;
  bool showKnowledgeGraph = false;

  @override
  Widget build(BuildContext context) {
    // 如果是论文模式或cartoon模式，显示不支持此功能
    if (widget.bookId == 'paper' || widget.bookId == 'cartoon') {
      return Container(
        color: const Color(0xFF0F172A), // slate-900
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '不适用',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '人物关系图谱仅适用于小说类文本',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final useKnowledge = showKnowledgeGraph;
    final isJane = widget.bookId == 'jane_eyre';
    final isXyj = widget.bookId == 'xyj';
    final hasKnowledge = isJane || isXyj;

    final nodes = useKnowledge
        ? (isJane ? janeKnowledgeGraphNodes : xyjKnowledgeGraphNodes)
        : (isJane ? janeGraphNodes : graphNodes);
    final relations = useKnowledge
        ? (isJane ? janeKnowledgeGraphRelations : xyjKnowledgeGraphRelations)
        : (isJane ? janeGraphRelations : graphRelations);

    return Container(
      color: const Color(0xFF0F172A), // slate-900
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

          final graphCanvas = SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: Stack(
              children: [
                // 连线
                CustomPaint(
                  size: canvasSize,
                  painter: GraphLinesPainter(
                    relations: relations,
                    nodes: nodes,
                    constraints: constraints,
                    selectedRelation: selectedRelation,
                  ),
                ),
                // 节点
                ...nodes.map((node) => _buildNode(node, constraints)),
              ],
            ),
          );

          return Stack(
            children: [
              // 可缩放/拖拽画布
              Positioned.fill(
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(120),
                  minScale: 0.65,
                  maxScale: 2.0,
                  child: graphCanvas,
                ),
              ),
              // 顶部标题与开关
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_tree, size: 12, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            useKnowledge ? '知识图谱 · 情节关联' : '人物关系网',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          _GraphToggleChip(
                            label: '人物关系',
                            selected: !useKnowledge,
                            onTap: () {
                              setState(() {
                                showKnowledgeGraph = false;
                                selectedNode = null;
                                selectedRelation = null;
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          _GraphToggleChip(
                            label: '知识图谱',
                            selected: useKnowledge,
                            disabled: !hasKnowledge,
                            onTap: hasKnowledge
                                ? () {
                                    setState(() {
                                      showKnowledgeGraph = true;
                                      selectedNode = null;
                                      selectedRelation = null;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 交互提示
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    useKnowledge
                        ? '双指缩放 / 拖动画布 · 点击节点查看情节摘要'
                        : '双指缩放 / 拖动画布 · 点击节点查看人物生平',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
              // 节点详情弹窗
              if (selectedNode != null)
                _buildNodeDetailDialog(constraints),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNode(GraphNode node, BoxConstraints constraints) {
    final isSelected = selectedNode?.id == node.id;
    
    // 对于简爱的所有节点，使用矩形
    final isJaneEyreNode = widget.bookId == 'jane_eyre';
    
    // 计算文字宽度，动态调整节点大小
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    double nodeWidth, nodeHeight, nodeX, nodeY;
    
    if (isJaneEyreNode) {
      // 矩形节点：根据文字宽度和高度计算
      final padding = 10.0;
      nodeWidth = (textPainter.width + padding * 2).clamp(80.0, 120.0);
      nodeHeight = (textPainter.height + padding * 2).clamp(40.0, 60.0);
      nodeX = (node.x / 100) * constraints.maxWidth - nodeWidth / 2;
      nodeY = (node.y / 100) * constraints.maxHeight - nodeHeight / 2;
    } else {
      // 圆形节点：保持原有逻辑
      final minDiameter = 50.0;
      final maxDiameter = 90.0;
      final textWidth = textPainter.width;
      final padding = 12.0;
      final nodeDiameter = (textWidth + padding * 2).clamp(minDiameter, maxDiameter);
      final nodeRadius = nodeDiameter / 2;
      nodeWidth = nodeDiameter;
      nodeHeight = nodeDiameter;
      nodeX = (node.x / 100) * constraints.maxWidth - nodeRadius;
      nodeY = (node.y / 100) * constraints.maxHeight - nodeRadius;
    }

    return Positioned(
      left: nodeX,
      top: nodeY,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedNode = node;
            selectedRelation = null;
          });
        },
        onLongPress: () {
          // 长按可以查看详情
          setState(() {
            selectedNode = node;
          });
        },
        child: Container(
          width: nodeWidth,
          height: nodeHeight,
          decoration: BoxDecoration(
            color: _parseColor(node.color).withOpacity(0.85),
            shape: isJaneEyreNode ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isJaneEyreNode ? BorderRadius.circular(8) : null,
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _parseColor(node.color).withOpacity(0.4),
                blurRadius: isSelected ? 16 : 10,
                spreadRadius: isSelected ? 3 : 1.5,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                node.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeDetailDialog(BoxConstraints constraints) {
    if (selectedNode == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedNode = null;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 阻止点击穿透
              child: Container(
                margin: const EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: constraints.maxHeight * 0.7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _parseColor(selectedNode!.color).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _parseColor(selectedNode!.color).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头部
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _parseColor(selectedNode!.color).withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (selectedNode!.avatar != null)
                            Text(
                              selectedNode!.avatar!,
                              style: const TextStyle(fontSize: 32),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedNode!.label,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (selectedNode!.description != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      selectedNode!.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                selectedNode = null;
                              });
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // 相关事件
                    if (selectedNode!.relatedEvents != null &&
                        selectedNode!.relatedEvents!.isNotEmpty)
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '相关情节',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...selectedNode!.relatedEvents!.map((event) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(
                                          top: 6,
                                          right: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _parseColor(selectedNode!.color),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          event,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[300],
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}

class _GraphToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _GraphToggleChip({
    required this.label,
    required this.selected,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = onTap != null && !disabled;
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.withOpacity(0.18)
              : (selected ? const Color(0xFF4F46E5) : Colors.white.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF818CF8)
                : Colors.white.withOpacity(disabled ? 0.05 : 0.12),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check, size: 14, color: Colors.white),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: disabled
                    ? Colors.grey[400]
                    : (selected ? Colors.white : Colors.white.withOpacity(0.9)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GraphLinesPainter extends CustomPainter {
  final List<GraphRelation> relations;
  final List<GraphNode> nodes;
  final BoxConstraints constraints;
  final GraphRelation? selectedRelation;

  GraphLinesPainter({
    required this.relations,
    required this.nodes,
    required this.constraints,
    this.selectedRelation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制关系连线
    for (var relation in relations) {
      final fromNode = nodes.firstWhere((n) => n.id == relation.fromId);
      final toNode = nodes.firstWhere((n) => n.id == relation.toId);

      final fromX = (fromNode.x / 100) * constraints.maxWidth;
      final fromY = (fromNode.y / 100) * constraints.maxHeight;
      final toX = (toNode.x / 100) * constraints.maxWidth;
      final toY = (toNode.y / 100) * constraints.maxHeight;

      final isSelected = selectedRelation?.fromId == relation.fromId &&
          selectedRelation?.toId == relation.toId;

      // 根据关系类型选择颜色
      Color lineColor;
      switch (relation.relationType) {
        case 'family':
          lineColor = const Color(0xFFEC4899); // 粉色
          break;
        case 'friend':
          lineColor = const Color(0xFF10B981); // 绿色
          break;
        case 'enemy':
          lineColor = const Color(0xFFEF4444); // 红色
          break;
        case 'master':
          lineColor = const Color(0xFF6366F1); // 蓝色
          break;
        case 'possess':
          lineColor = const Color(0xFFF59E0B); // 橙色
          break;
        case 'location':
          lineColor = const Color(0xFF8B5CF6); // 紫色
          break;
        default:
          lineColor = Colors.white.withOpacity(0.4);
      }

      final paint = Paint()
        ..color = isSelected
            ? lineColor
            : lineColor.withOpacity(0.5)
        ..strokeWidth = isSelected ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;

      // 绘制连线
      canvas.drawLine(
        Offset(fromX, fromY),
        Offset(toX, toY),
        paint,
      );

      // 在连线中点绘制关系标签，偏移避免与节点重叠
      final dx = toX - fromX;
      final dy = toY - fromY;
      final distance = (dx * dx + dy * dy) * 0.5; // 距离的平方根
      
      // 根据距离动态调整偏移，确保不遮挡节点
      final minOffset = 30.0;
      final maxOffset = 45.0;
      final offsetDistance = (distance * 0.15).clamp(minOffset, maxOffset);
      
      // 计算垂直偏移方向（垂直于连线）
      final perpX = -dy / distance;
      final perpY = dx / distance;
      
      final midX = (fromX + toX) / 2 + perpX * offsetDistance;
      final midY = (fromY + toY) / 2 + perpY * offsetDistance;

      final textPainter = TextPainter(
        text: TextSpan(
          text: relation.label,
          style: TextStyle(
            fontSize: 9,
            color: isSelected ? Colors.white : Colors.grey[200],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 绘制标签背景，紧凑但清晰
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(midX, midY),
          width: textPainter.width + 10,
          height: textPainter.height + 4,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        labelRect,
        Paint()
          ..color = isSelected
              ? lineColor.withOpacity(0.95)
              : Colors.black.withOpacity(0.75),
      );

      textPainter.paint(
        canvas,
        Offset(midX - textPainter.width / 2, midY - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant GraphLinesPainter oldDelegate) =>
      oldDelegate.selectedRelation != selectedRelation;
}

