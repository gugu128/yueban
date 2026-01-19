// 书籍内容数据模型
class BookContent {
  final String type; // 'title', 'text', 'image_gen'
  final String content;
  final String? prompt; // 用于图片生成
  final String? url; // 图片URL
  final bool highlight; // 是否高亮
  final int? refId; // 溯源ID
  final bool underline; // 是否下划线标记
  final String? explanation; // 下划线标记的释义

  BookContent({
    required this.type,
    required this.content,
    this.prompt,
    this.url,
    this.highlight = false,
    this.refId,
    this.underline = false,
    this.explanation,
  });
}

// 角色模型
class Role {
  final String id;
  final String name;
  final String avatar; // emoji
  final String style;
  final String colorClass; // 用于UI样式
  final String greeting;

  Role({
    required this.id,
    required this.name,
    required this.avatar,
    required this.style,
    required this.colorClass,
    required this.greeting,
  });
}

// 图谱节点模型
class GraphNode {
  final int id;
  final String label;
  final double x; // 百分比位置
  final double y;
  final String color; // 颜色代码
  final double size;
  final String? description; // 人物简介
  final List<String>? relatedEvents; // 相关情节事件
  final String? avatar; // 人物头像emoji

  GraphNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    this.description,
    this.relatedEvents,
    this.avatar,
  });
}

// 图谱关系模型
class GraphRelation {
  final int fromId; // 起始节点ID
  final int toId; // 目标节点ID
  final String relationType; // 关系类型：'family', 'friend', 'enemy', 'master', 'possess', 'location'
  final String label; // 关系标签
  final String? description; // 关系描述
  final List<String>? relatedEvents; // 相关情节事件

  GraphRelation({
    required this.fromId,
    required this.toId,
    required this.relationType,
    required this.label,
    this.description,
    this.relatedEvents,
  });
}

// 引用证据模型（用于生活实验室）
class CitationEvidence {
  final int index; // 引用编号 [1], [2]...
  final String sourceText; // 原文内容
  final int pageNumber; // 页码
  final int paragraphIndex; // 段落索引
  final String chapterTitle; // 章节标题
  final int contentBlockIndex; // 内容块索引（用于定位）
  final String derivedConclusion; // 推导出的结论

  CitationEvidence({
    required this.index,
    required this.sourceText,
    required this.pageNumber,
    required this.paragraphIndex,
    required this.chapterTitle,
    required this.contentBlockIndex,
    required this.derivedConclusion,
  });
}

// 阅读意图模型
class ReadingIntent {
  final String id;
  final String icon; // emoji
  final String title;
  final String desc;

  ReadingIntent({
    required this.id,
    required this.icon,
    required this.title,
    required this.desc,
  });
}

// 最近阅读的书籍模型
class RecentBook {
  final String title;
  final String colorClass; // 背景颜色
  final int progress; // 0-100
  final bool dark; // 是否深色主题

  RecentBook({
    required this.title,
    required this.colorClass,
    required this.progress,
    this.dark = false,
  });
}

// 分支卡片模型
class BranchCard {
  final String tag;
  final String color; // 'purple' or 'pink'
  final String title;
  final String desc;

  BranchCard({
    required this.tag,
    required this.color,
    required this.title,
    required this.desc,
  });
}

// 批注模型
class Comment {
  final String commentId; // 批注ID
  final String content; // 高亮文本内容
  final int contentIndex; // 对应的内容块索引
  final List<Annotation> annotations; // 评论者批注列表

  Comment({
    required this.commentId,
    required this.content,
    required this.contentIndex,
    required this.annotations,
  });
}

// 单个批注
class Annotation {
  final String reviewerId; // 评论者ID
  final String reviewerName; // 评论者名称
  final String reviewerAvatar; // 评论者头像（emoji）
  final String comment; // 批注内容

  Annotation({
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.comment,
  });
}

// 目录章节模型
class Chapter {
  final int chapterNumber; // 回数
  final String title; // 章节标题
  final String aiSummary; // AI章节概括（通俗易懂）

  Chapter({
    required this.chapterNumber,
    required this.title,
    required this.aiSummary,
  });
}

