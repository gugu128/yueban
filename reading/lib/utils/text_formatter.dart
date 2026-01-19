import 'package:flutter/material.dart';

// 解析包含加粗标记的文本（**text**）并返回TextSpan列表
List<TextSpan> parseFormattedText(String text, TextStyle baseStyle) {
  final List<TextSpan> spans = [];
  final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
  
  int lastEnd = 0;
  
  for (var match in boldRegex.allMatches(text)) {
    // 添加匹配前的普通文本
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: text.substring(lastEnd, match.start),
        style: baseStyle,
      ));
    }
    
    // 添加加粗文本
    spans.add(TextSpan(
      text: match.group(1),
      style: baseStyle.copyWith(
        fontWeight: FontWeight.bold,
      ),
    ));
    
    lastEnd = match.end;
  }
  
  // 添加剩余的文本
  if (lastEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastEnd),
      style: baseStyle,
    ));
  }
  
  // 如果没有匹配到任何加粗标记，返回原始文本
  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: baseStyle));
  }
  
  return spans;
}

// 创建一个支持加粗格式的Text Widget
Widget buildFormattedText(
  String text, {
  TextStyle? style,
  TextAlign? textAlign,
  int? maxLines,
  TextOverflow? overflow,
}) {
  final baseStyle = style ?? const TextStyle();
  final spans = parseFormattedText(text, baseStyle);
  
  return Text.rich(
    TextSpan(children: spans),
    textAlign: textAlign ?? TextAlign.start,
    maxLines: maxLines,
    overflow: overflow ?? TextOverflow.clip,
  );
}

