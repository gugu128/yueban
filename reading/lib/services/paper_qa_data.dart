// 论文问答数据 - 共享单车需求预测研究

class PaperQA {
  final String question;
  final String answer;
  final List<Citation> citations;
  final String thinkingProcess;

  PaperQA({
    required this.question,
    required this.answer,
    required this.citations,
    required this.thinkingProcess,
  });
}

class Citation {
  final int index;
  final String sourceText;

  Citation({
    required this.index,
    required this.sourceText,
  });
}

// Q1: 在共享单车短期需求预测中，相比于普通线性回归（OLS），随机森林（RF）和迭代决策树（GBDT）等机器学习集成模型表现出了怎样的优势？
final PaperQA q1 = PaperQA(
  question: '在共享单车短期需求预测中，相比于普通线性回归（OLS），随机森林（RF）和迭代决策树（GBDT）等机器学习集成模型表现出了怎样的优势？',
  answer: '随机森林（RF）和迭代决策树（GBDT）在样本内拟合和样本外预测中均展现出更高的拟合优度（R²）和更低的标准误差（RMSE），显著优于OLS模型[1]。其中，RF模型在样本外预测中的表现最佳[3]。这是因为集成模型能够综合考虑协变量之间的相互作用（例如高峰时段与周末、极端天气的非线性叠加影响），捕捉到OLS模型容易忽略的复杂交互效应，从而不仅提升了预测精度，还具有更强的泛化能力[2][4]。',
  citations: [
    Citation(
      index: 1,
      sourceText: '摘要提到"相比普通线性回归……随机森林和迭代决策树模型对共享单车短期即时需求预测的结果更精确……拟合优度(R²)更高，标准误差(RMSE)更低"。',
    ),
    Citation(
      index: 2,
      sourceText: '正文指出"RF和GBDT模型在样本外预测效果来看……在R²上提升分别达到约39和29个百分点……这两个集成模型在样本内拟合和样本外预测方面都具有较大优势"。',
    ),
    Citation(
      index: 3,
      sourceText: '正文指出"RF比GBDT在样本外预测的效果更佳……RF模型的R²比GBDT模型高约10个百分点"。',
    ),
    Citation(
      index: 4,
      sourceText: '结论部分解释原因："RF和GBDT模型在进行模型预测分析时能够综合考虑模型协变量之间的相互作用……这是此类机器学习模型在算法上的优势……OLS模型能够观测到高峰时段的重要影响，但该变量在叠加周末、假日时的影响会有所减弱……这是OLS模型在预测过程中无法考量的问题"。',
    ),
  ],
  thinkingProcess: '问题核心在于对比不同模型的性能优势。首先从摘要和模型评估部分（表3及相关文字）提取数据表现（R²和RMSE的对比），确定RF和GBDT优于OLS。其次，从结论部分找到造成这种差异的理论原因（对协变量交互作用的处理能力），从而形成完整的回答。',
);

// Q2: 在特征工程中，该研究发现影响共享单车"小时级"需求量的最关键因素有哪些？不同模型对变量重要性的识别有何差异？
final PaperQA q2 = PaperQA(
  question: '在特征工程中，该研究发现影响共享单车"小时级"需求量的最关键因素有哪些？不同模型对变量重要性的识别有何差异？',
  answer: '研究发现，影响共享单车短期需求的主要因素包括特定的位置因素（如是否位于旧金山）、时间因素（尤其是早晚通勤高峰时段及工作日特征）以及天气条件（最高气温和风向）[1]。在变量识别差异上，OLS、Lasso和Ridge模型倾向于强调特定的时间点（如上午8点、下午5点）和位置变量[2]；而RF和GBDT模型不仅识别了位置和高峰时段，还更敏锐地捕捉到了工作日特征（如周日或周一）以及具体的天气指标（风向、最高气温）的重要性，能够识别出更广泛的综合影响因素[3]。',
  citations: [
    Citation(
      index: 1,
      sourceText: '摘要和结论总结道："影响共享单车小时需求的主要因素包括特定的位置因素、时间因素以及天气条件因素"。',
    ),
    Citation(
      index: 2,
      sourceText: '正文指出OLS、Lasso和Ridge指向了相同的五个变量，"包括上午8点、9点……和下午4点、5点……两个上下班通勤高峰期的四个时间段变量和特定空间位置（旧金山城市）变量"。',
    ),
    Citation(
      index: 3,
      sourceText: '正文提到RF和GBDT"综合包含了位置、时间和天气特征……在位置变量上……选择了旧金山和San Jose，在时间变量上选择了高峰时段、工作日和周末变量，在天气特征上选择了风向和最高气温"。',
    ),
  ],
  thinkingProcess: '问题侧重于影响因素和模型间的"解释性"差异。我首先归纳了所有模型共识的核心因素（时间、地点、天气）。然后对比表4和表5的分析结果，区分传统线性模型（侧重具体时刻点）和树模型（侧重更广泛的特征组合，如加入了风向和气温的具体指标）在特征重要性排序上的不同。',
);

// Q3: 既然Lasso和Ridge回归旨在解决多重共线性和高维数据问题，为何在本研究的共享单车预测中，它们的表现并未优于普通OLS模型？
final PaperQA q3 = PaperQA(
  question: '既然Lasso和Ridge回归旨在解决多重共线性和高维数据问题，为何在本研究的共享单车预测中，它们的表现并未优于普通OLS模型？',
  answer: '这是因为本研究基于经济学基本理论选取变量，所选取的变量（如时间、天气、地点）多为直接影响因素，自变量之间的多重共线性问题并不突出，且变量维度虽多但并未达到极高维度的"灾难"级别[1]。Lasso和Ridge的主要优势在于处理协变量过多或存在严重共线性的情况，且它们缺乏处理变量间复杂非线性交互作用的能力（这正是集成模型的强项）[2]。因此，在缺乏显著共线性且主要依赖直接因果变量的数据集中，这两类模型无法发挥其降维优势，预测效果仅与OLS相当[2]。',
  citations: [
    Citation(
      index: 1,
      sourceText: '正文明确解释："由于模型选取依据了经济学的基本理论，非直接影响的变量基本没有选取，其自变量之间的共线性问题也并不突出，因此没有体现出这类模型（Lasso和Ridge）的优势"。',
    ),
    Citation(
      index: 2,
      sourceText: '结论部分进一步补充："Lasso和Ridge模型的优势在于处理协变量数量过多或变量之间存在多重共线的情况，对于变量之间的交互作用也缺乏处理……因而预测效果与OLS相当"。',
    ),
  ],
  thinkingProcess: '这是一个关于模型适用性边界的问题。Lasso/Ridge通常用于高维数据，但在此文中表现平平。通过阅读"模型评估与预测结果"章节，作者明确指出了原因：一是数据本身的特性（共线性不强，特征选择基于理论而非盲目罗列），二是模型本身的局限（无法处理交互项，这一点与RF/GBDT形成对比）。将这两点结合即可解释为何它们没有超越OLS。',
);

// 所有问答的列表
final List<PaperQA> paperQAs = [q1, q2, q3];

// 匹配问题的辅助函数（支持模糊匹配）
bool matchesQuestion(String userInput, String question) {
  final normalizedInput = userInput
      .replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '')
      .toLowerCase();
  final normalizedQuestion = question
      .replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '')
      .toLowerCase();

  // 检查是否包含关键短语
  final keyPhrases = [
    'Q1',
    'q1',
    '随机森林',
    'RF',
    'GBDT',
    'OLS',
    '线性回归',
    '集成模型',
    '优势',
    'Q2',
    'q2',
    '特征工程',
    '小时级',
    '需求量',
    '最关键因素',
    '变量重要性',
    'Q3',
    'q3',
    'Lasso',
    'Ridge',
    '多重共线性',
    '高维数据',
    '表现',
    '优于',
  ];

  // 如果输入包含问题编号，直接匹配
  if (normalizedInput.contains('q1') || normalizedInput.contains('q2') || normalizedInput.contains('q3')) {
    if (normalizedInput.contains('q1') && question == q1.question) return true;
    if (normalizedInput.contains('q2') && question == q2.question) return true;
    if (normalizedInput.contains('q3') && question == q3.question) return true;
  }

  // 检查关键短语匹配度
  int matchCount = 0;
  for (var phrase in keyPhrases) {
    if (normalizedInput.contains(phrase) && normalizedQuestion.contains(phrase)) {
      matchCount++;
    }
  }

  // 如果匹配的关键短语数量足够，认为匹配
  if (matchCount >= 3) {
    return true;
  }

  // 检查是否包含问题的核心关键词
  if (question == q1.question) {
    return (normalizedInput.contains('随机森林') || normalizedInput.contains('rf') || normalizedInput.contains('gbdt')) &&
        (normalizedInput.contains('ols') || normalizedInput.contains('线性回归')) &&
        normalizedInput.contains('优势');
  }
  if (question == q2.question) {
    return (normalizedInput.contains('特征工程') || normalizedInput.contains('影响因素') || normalizedInput.contains('变量重要性')) &&
        (normalizedInput.contains('小时') || normalizedInput.contains('需求量'));
  }
  if (question == q3.question) {
    return (normalizedInput.contains('lasso') || normalizedInput.contains('ridge')) &&
        (normalizedInput.contains('多重共线性') || normalizedInput.contains('高维')) &&
        (normalizedInput.contains('表现') || normalizedInput.contains('优于') || normalizedInput.contains('为什么'));
  }

  return false;
}

