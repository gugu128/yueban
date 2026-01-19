// Demo演示数据 - 第五十九回硬编码内容
// 注意：所有内容已移除emoji，保留加粗格式标记（**text**）

// 1. AI欢迎语（阅读意向确认）
const String aiWelcomeMessage = '''好的，收到！

针对中考名著备考，这一回（第五十九回）绝对是重难点区域。我已经为你开启了**"考点雷达"模式**，会在接下来的阅读中重点标注核心情节冲突和人物性格分析。

准备好了吗？那让我们开始阅读吧！''';

// 2. AI探讨（考点梳理）
const String aiExamGuideContent = '''收到！针对中考名著阅读，《西游记》第五十九回是极高频的考点。以下是为你整理的**"满分"笔记**：

**1. 核心情节梳理（起因与经过）**

**起因**： 师徒四人路阻火焰山，酷热难行。得知必须向铁扇公主借芭蕉扇才能灭火过山。

**冲突（一调芭蕉扇）**： 孙悟空去借扇，但因之前请观音收伏了红孩儿（第五十九回的关键前情），铁扇公主怀恨在心，拒绝借扇。

**斗法**： 铁扇公主用扇子将悟空扇飞五万余里。

**转折**： 悟空得灵吉菩萨赠送**"定风丹"，二次登门。悟空变作蟭蟟虫**钻入公主腹中折腾，公主疼痛难忍被迫借扇。

**结局**： 悟空借来的是假扇，越扇火越大。

**2. 人物性格分析（必考点）**

**孙悟空**： 机智勇敢（钻肚子体现其变通），但也有些急躁（未查验扇子真伪就去灭火）。同时也体现了他重情重义（为了师父西行，不得不与昔日结拜兄弟的家属反目）。

**铁扇公主（罗刹女）**： 爱子心切（因红孩儿记恨悟空），性格刚烈、固执，但也欺软怕硬（肚子疼时立马求饶）。

**3. 考题预测**

**问**： 孙悟空为什么第一次借扇失败？

**答**： 未有定风丹，被扇飞。

**问**： 铁扇公主为什么给悟空假扇子？

**答**： 心存怨恨，想烧死悟空。''';

// 3. 角色伴读对话数据
class CompanionDialogue {
  final String roleId;
  final List<String> dialogues;

  CompanionDialogue({
    required this.roleId,
    required this.dialogues,
  });
}

final Map<String, List<String>> companionDialogues = {
  'trump': [
    '糟糕的交易，相信我，这是史上最糟糕的交易之一！孙悟空走进那个洞穴，但他手里没有筹码。如果你想要那把扇子，你得展现实力。他被那个女人扇飞了五万里？太弱了！如果是我，我会先切断她的水源，然后说："把扇子给我，或者你的翠云山破产。"这就是艺术，交易的艺术！',
    '听着，那个"铁扇女士"——哪怕是个强硬的女人——她太情绪化了。红孩儿现在在观音那里工作，那可是体制内的高级职位，那是公务员！她应该感谢悟空给了她儿子一份好工作。但她却说是"绑架"？假新闻！完全是假新闻。她只是想以此为借口抬高扇子的价格。',
    '假货！到处都是假货！这就像某些媒体一样不诚实。孙悟空太轻信了，他拿到扇子时甚至没有检查一下。如果是我，我会让专家鉴定，还要签合同："如果火没灭，你会面临巨大的诉讼，巨大的！"但他没有，所以他被烧了屁股。可悲！',
  ],
  'miyazaki': [
    '这真是一幅悲伤的画面啊。人类——或者说是神魔——的贪婪和愤怒让大地失去了绿色。火焰山就像是被诅咒的自然，在愤怒地燃烧。那把芭蕉扇，不仅仅是武器，它是风的灵魂。当风吹过的时候，本来应该带来生命的种子，而不是争斗。我希望能画出那种被风吹动时，火焰瞬间变成绿草的瞬间。',
    '哈哈，这很有趣。你知道吗，这不能画得太恶心。那只小虫子（蟭蟟虫）应该有它自己的性格，也许它在那个巨大的"肚子迷宫"里迷路了，周围是粉红色的肉壁，像云层一样柔软但又充满危险。孙悟空虽然在战斗，但他其实只是个顽皮的孩子。这种身体里的冒险，充满了童趣和荒诞感。',
    '所有的母亲都是强大的。铁扇公主虽然是妖怪，但她此时此刻只是一个失去了孩子的母亲。她的愤怒是有力量的，就像暴风雨一样。在我的电影里，女性往往背负着诅咒或重担，她也是一样。她不是单纯的坏人，她只是在守护她认为珍贵的东西，即便那意味着要对抗整个世界。',
  ],
  'luxun': [
    '这大约便是吃人的世道了。百姓要种地，本是靠天吃饭，如今却要仰仗一家妖怪的鼻息。那扇子本是天地灵宝，却成了罗刹女敛财的私器。百姓们长年累月地被"热"煎熬着，还要千恩万谢地去求那一点凉风，这是何等的奴性，又是何等的悲凉。',
    '泼猴的手段，虽嫌无赖，却是对付顽固者的必需。对于那些手握强权（扇子）、不讲道理的人，你同他作揖打拱，他是看不见的；非得钻进他的肚肠里，让他痛得打滚，他才晓得你也是个人物。在这个世上，有时候"讲理"是行不通的，得有点"钻肚子"的精神。',
    '给人虚假的希望，比直接拒绝更加可恶。这假扇子，像极了那些开给国民的空头支票。你以为挥一挥就能灭火、就能太平，结果那火势反而更猛，烧焦了你的皮肉。然而人们往往拿到这"假扇子"时是狂喜的，非得被烧痛了，才肯承认那只是涂了色的簸箕。',
  ],
};

// 4. 跨时空群聊数据
class GroupChatRound {
  final String title;
  final List<GroupChatMessage> messages;

  GroupChatRound({
    required this.title,
    required this.messages,
  });
}

class GroupChatMessage {
  final String roleId;
  final String content;

  GroupChatMessage({
    required this.roleId,
    required this.content,
  });
}

final List<GroupChatRound> groupChatRounds = [
  GroupChatRound(
    title: '第一轮：关于"火焰山的所有权与垄断"',
    messages: [
      GroupChatMessage(
        roleId: 'trump',
        content: '只要她是合法拥有的，这就是聪明的商业模式！垄断？那是赢家的代名词。百姓给钱，她提供服务，公平交易！',
      ),
      GroupChatMessage(
        roleId: 'luxun',
        content: '哼，所谓的公平，不过是弱肉强食的遮羞布。垄断了生机，便是扼住了百姓的咽喉，这哪里是交易，分明是勒索。',
      ),
    ],
  ),
  GroupChatRound(
    title: '第二轮：关于"定风丹"的作用',
    messages: [
      GroupChatMessage(
        roleId: 'miyazaki',
        content: '那定风丹，大概就是内心的平静吧。无论外面的风暴（铁扇公主的愤怒）多么猛烈，只要心是定的，就不会被吹跑。',
      ),
      GroupChatMessage(
        roleId: 'trump',
        content: '错！定风丹就是制裁豁免权！或者是坚固的防弹玻璃。有了它，别人攻击不了你，你就可以为所欲为。我也想要一颗定风丹。',
      ),
    ],
  ),
  GroupChatRound(
    title: '第三轮：关于"结局的假扇子"',
    messages: [
      GroupChatMessage(
        roleId: 'luxun',
        content: '即使是齐天大圣，也难免被虚伪的外表蒙蔽。悟空啊，切记，莫要在未曾检验真理之前，便盲目地欢呼。',
      ),
      GroupChatMessage(
        roleId: 'miyazaki',
        content: '也许火没有灭，是因为那把扇子里没有"爱"吧。假的扇子只能带来风，却带不走内心的仇恨之火。',
      ),
      GroupChatMessage(
        roleId: 'trump',
        content: '悟空，下次找我，我给你介绍最好的律师。我们要起诉翠云山芭蕉洞，让她们赔偿你的猴毛，还要赔偿精神损失费！',
      ),
    ],
  ),
];

// 5. 生活实验室（COT建议模式）数据
class CotStep {
  final int step;
  final String title;
  final String content;

  CotStep({
    required this.step,
    required this.title,
    required this.content,
  });
}

class CotAdvice {
  final List<CotStep> steps;
  final String finalAdvice;
  final String actionCommand;

  CotAdvice({
    required this.steps,
    required this.finalAdvice,
    required this.actionCommand,
  });
}

final CotAdvice cotAdviceData = CotAdvice(
  steps: [
    CotStep(
      step: 1,
      title: 'Step 1 分析 (Analyze)',
      content: '场景情绪：焦虑（面对考试）、愤怒（被没收手机）、无助（想摆烂）。\n\n核心矛盾：外部压力（数学难） vs 内部资源匮乏（失去调节渠道）。你把父母投射成了"铁扇公主"，把手机当成了"芭蕉扇"。',
    ),
    CotStep(
      step: 2,
      title: 'Step 2 映射 (Map)',
      content: '原著映射：硬抢（吵架）= 被扇飞（冷战）。你需要**"定风丹"（情绪稳定）和"非暴力沟通"**（智取）。\n\n理论引用：Marshall Rosenberg《非暴力沟通》：观察 -> 感受 -> 需要 -> 请求。',
    ),
    CotStep(
      step: 3,
      title: 'Step 3 迁移 (Transfer)',
      content: '定风丹 = 自我平复：冷战是假扇子扇出的火，只会内耗。\n\n借真扇 = 协商使用权：吵架无效，需要策略性沟通。\n\n火焰山 = 数学题：手机不能灭火，解题技巧才是降温的关键。',
    ),
    CotStep(
      step: 4,
      title: 'Step 4 生成 (Generate)',
      content: '嘿，同学，看来你正处在"火焰山"最热的时候！试试这套《孙行者破局法》：\n\n获得"定风丹"（停止内耗）\n调整"借扇"话术（非暴力沟通）\n翻越"火焰山"（拆解任务）',
    ),
  ],
  finalAdvice: '''获得"定风丹"（停止内耗）

现在的冷战状态正在消耗你复习的能量。先深呼吸，承认自己现在的愤怒和无助，不要责怪自己想"摆烂"，这是正常的防御机制。

调整"借扇"话术（非暴力沟通）

去跟父母破冰，不要说"你们凭什么收我手机"，试试这样说：

观察： "爸妈，你们收走手机后，我们吵了一架，现在两天没说话了。"

感受： "我现在感觉压力很大，也很焦虑，因为数学真的很难。"

需要： "我需要一点放松的空间，也需要你们的信任和支持，而不是单纯的管制。"

请求： "能不能把手机还给我，但我承诺每天只看30分钟，剩下的时间全力攻克数学？如果我做不到，你们再收走。"

翻越"火焰山"（拆解任务）

不要盯着整座山看。把数学复习拆解成极小的关卡（比如只复习一个公式）。每完成一个，就奖励自己一点"凉风"。''',
  actionCommand: '行动指令：哪怕不复习，先去喝杯水，给父母写张小纸条试试？',
);

// 6. 番外AI写作（Fanfic）数据
class FanficBranch {
  final String tag;
  final String color; // 'purple' or 'pink'
  final String title;
  final String content;
  final String analysis;

  FanficBranch({
    required this.tag,
    required this.color,
    required this.title,
    required this.content,
    required this.analysis,
  });
}

final List<FanficBranch> fanficBranches = [
  FanficBranch(
    tag: '分支 A',
    color: 'purple',
    title: '如果铁扇公主直接借扇...',
    content: '铁扇公主听闻红孩儿已在南海修成正果，心中怨气顿消，长叹一声道："既是儿子的前程，我这做娘的怎好阻拦。"说罢，吐出那枚杏叶小的芭蕉扇，念动咒语，递予悟空。\n\n悟空大喜，叩谢而去。只需一扇，火焰山顿熄；二扇，凉风习习；三扇，细雨霏霏。唐僧师徒顺利过山，毫发无伤。',
    analysis: '虽然师徒四人省去了许多皮肉之苦，但悟空却失去了一次磨炼心性、习得"定风丹"定力的机会。此后路上遇到更大的风浪时，悟空因未受此挫折，反而显得有些急躁，团队磨合度略逊于原著。',
  ),
  FanficBranch(
    tag: '分支 B',
    color: 'pink',
    title: '如果红孩儿未被观音收去...',
    content: '悟空正欲变虫钻肚，忽见天边红光大作，一杆火尖枪破空而来！原来是红孩儿听说母亲受辱，特来助战。\n\n"泼猴！休欺我母！"红孩儿口吐三昧真火，配合铁扇公主的芭蕉扇阴风。风助火势，火借风威，这火焰山瞬间变成了炼狱。悟空虽有金刚不坏之身，却也被这混合双打逼得狼狈不堪，连毫毛都被烧焦了大半。',
    analysis: '难度升级为"地狱模式"。悟空不得不去请观音菩萨再次出山，甚至还需要请来牛魔王从中调停。这一难，变成了真正的"家庭伦理大调解"。',
  ),
];

