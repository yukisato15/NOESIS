enum RelationshipLevel { level1, level2, level3, level4 }

enum PersonInputKind { scale, category, freeText }

enum QuestionStrategy {
  direct,
  indirect,
  assumption,
  comparison,
  past,
  situational,
  observation,
  hypothetical,
}

extension RelationshipLevelLabel on RelationshipLevel {
  String get label {
    switch (this) {
      case RelationshipLevel.level1:
        return 'LEVEL_1 初対面';
      case RelationshipLevel.level2:
        return 'LEVEL_2 知人';
      case RelationshipLevel.level3:
        return 'LEVEL_3 友人';
      case RelationshipLevel.level4:
        return 'LEVEL_4 親しい関係';
    }
  }
}

class PersonAttributeDefinition {
  final String category;
  final String name;
  final String description;
  final List<String> options;
  final bool intrusive;
  final List<String> questionSeeds;
  final List<String> conversationOpeners;
  final List<String> observationClues;
  final bool freeTextOnly;
  final PersonInputKind inputKind;

  const PersonAttributeDefinition({
    required this.category,
    required this.name,
    required this.description,
    required this.options,
    required this.questionSeeds,
    required this.conversationOpeners,
    required this.observationClues,
    required this.inputKind,
    this.freeTextOnly = false,
    this.intrusive = false,
  });
}

class SuggestedPersonQuestion {
  final String questionText;
  final RelationshipLevel relationshipLevel;
  final String category;
  final String purpose;
  final List<String> linkedAttributes;
  final QuestionStrategy questionType;

  const SuggestedPersonQuestion({
    required this.questionText,
    required this.relationshipLevel,
    required this.category,
    required this.purpose,
    required this.linkedAttributes,
    required this.questionType,
  });
}

class PersonQuestionTactic {
  final String attribute;
  final String category;
  final QuestionStrategy questionType;
  final String questionText;
  final String purpose;

  const PersonQuestionTactic({
    required this.attribute,
    required this.category,
    required this.questionType,
    required this.questionText,
    required this.purpose,
  });
}

extension QuestionStrategyLabel on QuestionStrategy {
  String get label {
    switch (this) {
      case QuestionStrategy.direct:
        return '直球';
      case QuestionStrategy.indirect:
        return '間接';
      case QuestionStrategy.assumption:
        return 'カマかけ';
      case QuestionStrategy.comparison:
        return '比較';
      case QuestionStrategy.past:
        return '回想';
      case QuestionStrategy.situational:
        return '状況';
      case QuestionStrategy.observation:
        return '観察誘導';
      case QuestionStrategy.hypothetical:
        return '仮定';
    }
  }

  String get apiName {
    switch (this) {
      case QuestionStrategy.direct:
        return 'DIRECT';
      case QuestionStrategy.indirect:
        return 'INDIRECT';
      case QuestionStrategy.assumption:
        return 'ASSUMPTION';
      case QuestionStrategy.comparison:
        return 'COMPARISON';
      case QuestionStrategy.past:
        return 'PAST';
      case QuestionStrategy.situational:
        return 'SITUATIONAL';
      case QuestionStrategy.observation:
        return 'OBSERVATION';
      case QuestionStrategy.hypothetical:
        return 'HYPOTHETICAL';
    }
  }
}

class PersonQuestionGuides {
  static const levelScale = ['かなり低い', 'やや低い', '中間', 'やや高い', 'かなり高い', '不明'];
  static const freeText = <String>[];
  static const frequencyScale = [
    'かなり少ない',
    'やや少ない',
    '中間',
    'やや多い',
    'かなり多い',
    '不明',
  ];
  static const speedScale = ['かなり遅い', 'やや遅い', '中間', 'やや速い', 'かなり速い', '不明'];
  static const regionOptions = [
    '北海道',
    '東北',
    '関東',
    '中部',
    '近畿',
    '中国',
    '四国',
    '九州',
    '沖縄',
    '海外',
    '不明',
    'その他',
  ];
  static const residenceOptions = [
    '北海道',
    '東北',
    '関東',
    '中部',
    '近畿',
    '中国',
    '四国',
    '九州',
    '沖縄',
    '海外',
    '不明',
    'その他',
  ];
  static const nationalityOptions = [
    '日本',
    'アメリカ',
    '中国',
    '韓国',
    '台湾',
    'イギリス',
    'フランス',
    'ドイツ',
    'カナダ',
    'オーストラリア',
    'その他',
    '不明',
  ];
  static const languageOptions = [
    '日本語',
    '英語',
    '中国語',
    '韓国語',
    'スペイン語',
    'フランス語',
    'ドイツ語',
    'ポルトガル語',
    'その他',
    '不明',
  ];
  static const appearanceOptions = [
    '落ち着いた印象',
    '明るい印象',
    '柔らかい印象',
    'シャープな印象',
    'カジュアル',
    'フォーマル',
    '個性的',
    '清潔感が強い',
    'その他',
    '不明',
  ];
  static const occupationOptions = [
    '会社員',
    '経営者',
    '公務員',
    '教員',
    '研究職',
    '医療職',
    'エンジニア',
    'デザイナー',
    '営業',
    '販売・接客',
    'クリエイター',
    '学生',
    'フリーランス',
    '無職',
    'その他',
    '不明',
  ];
  static const industryOptions = [
    'IT・ソフトウェア',
    'Web・メディア',
    '広告・マーケティング',
    'メーカー',
    '小売・流通',
    '金融',
    '不動産',
    '教育',
    '医療・福祉',
    '行政・公共',
    '建築・建設',
    '飲食・サービス',
    '芸術・エンタメ',
    '学術・研究',
    'その他',
    '不明',
  ];
  static const roleOptions = [
    '一般職',
    '主任',
    '係長',
    '課長',
    '部長',
    '役員',
    '代表',
    'マネージャー',
    'リーダー',
    '担当者',
    '専門職',
    'その他',
    '不明',
  ];
  static const educationOptions = [
    '中学校',
    '高校',
    '専門学校',
    '短大',
    '高専',
    '大学',
    '大学院修士',
    '大学院博士',
    '留学経験あり',
    '不明',
    'その他',
  ];
  static const majorOptions = [
    '文学・語学',
    '法学',
    '経済・経営',
    '社会学',
    '教育学',
    '心理学',
    '理学',
    '工学',
    '情報科学',
    '医学',
    '看護・福祉',
    '芸術',
    'デザイン',
    '農学',
    'その他',
    '不明',
  ];
  static const snsPlatformOptions = [
    'X',
    'Instagram',
    'TikTok',
    'YouTube',
    'Facebook',
    'LINE',
    'Discord',
    'Reddit',
    'Threads',
    'その他',
    '不明',
  ];
  static const mediaPreferenceOptions = [
    '映画',
    'ドラマ',
    'アニメ',
    'ドキュメンタリー',
    '小説',
    '実用書',
    '漫画',
    'ロック',
    'ポップス',
    'クラシック',
    'ジャズ',
    'スポーツ観戦',
    'その他',
    '不明',
  ];
  static const logicBalanceIntuition = [
    'かなり論理型',
    'やや論理型',
    'バランス',
    'やや直感型',
    'かなり直感型',
    '不明',
  ];
  static const abstractConcrete = [
    'かなり抽象型',
    'やや抽象型',
    'バランス',
    'やや具体型',
    'かなり具体型',
    '不明',
  ];
  static const relationScale = ['かなり遠い', 'やや遠い', '中間', 'やや近い', 'かなり近い', '不明'];
  static const reputationScale = ['かなり低い', 'やや低い', '中間', 'やや高い', 'かなり高い', '不明'];
  static const importanceScale = ['かなり弱い', 'やや弱い', '中間', 'やや強い', 'かなり強い', '不明'];
  static const lifeViewOptions = [
    '成長重視',
    '安定重視',
    '自由重視',
    '貢献重視',
    '経験重視',
    'その他',
    '不明',
  ];
  static const happinessOptions = ['安心', '自由', '達成', '人間関係', '没頭', 'その他', '不明'];
  static const successOptions = [
    '自己実現',
    '社会的評価',
    '経済的達成',
    '安定継続',
    '他者貢献',
    'その他',
    '不明',
  ];
  static const familyValueOptions = [
    '家族中心',
    '大切だが自立重視',
    '状況次第',
    '距離を保つ',
    '未整理',
    'その他',
    '不明',
  ];
  static const workValueOptions = [
    'かなり生活重視',
    'やや生活重視',
    'バランス',
    'やややりがい重視',
    'かなりやりがい重視',
    '不明',
  ];
  static const wealthValueOptions = [
    'かなり軽視',
    'やや軽視',
    '中間',
    'やや重視',
    'かなり重視',
    '不明',
  ];
  static const homeStabilityScale = [
    'かなり不安定',
    'やや不安定',
    '中間',
    'やや安定',
    'かなり安定',
    '不明',
  ];
  static const environmentInterestScale = [
    'かなり低関心',
    'やや低関心',
    '中間',
    'やや高関心',
    'かなり高関心',
    '不明',
  ];
  static const politicsScale = [
    'かなり保守寄り',
    'やや保守寄り',
    '中立',
    'やや革新寄り',
    'かなり革新寄り',
    '不明',
  ];
  static const economicsScale = [
    'かなり市場重視',
    'やや市場重視',
    'バランス',
    'やや分配重視',
    'かなり分配重視',
    '不明',
  ];
  static const socialViewScale = [
    'かなり個人努力重視',
    'やや個人努力重視',
    'バランス',
    'やや構造要因重視',
    'かなり構造要因重視',
    '不明',
  ];
  static const techViewScale = [
    'かなり慎重',
    'やや慎重',
    'バランス',
    'やや肯定的',
    'かなり肯定的',
    '不明',
  ];
  static const decisionScale = [
    'かなり熟考型',
    'やや熟考型',
    'バランス',
    'やや即断型',
    'かなり即断型',
    '不明',
  ];
  static const stressReactionScale = [
    'かなり内向き',
    'やや内向き',
    'バランス',
    'やや外向き',
    'かなり外向き',
    '不明',
  ];
  static const interpersonalScale = [
    'かなり受動的',
    'やや受動的',
    'バランス',
    'やや能動的',
    'かなり能動的',
    '不明',
  ];
  static const trustScale = [
    'かなり慎重',
    'やや慎重',
    'バランス',
    'やや信頼しやすい',
    'かなり信頼しやすい',
    '不明',
  ];
  static const conflictScale = [
    'かなり回避型',
    'やや回避型',
    '対話型',
    'やや衝突型',
    'かなり衝突型',
    '不明',
  ];
  static const friendshipScale = [
    'かなり狭く深い',
    'やや狭く深い',
    'バランス',
    'やや広く浅い',
    'かなり広く浅い',
    '不明',
  ];
  static const routineScale = [
    'かなり乱れがち',
    'やや乱れがち',
    '普通',
    'やや整っている',
    'かなり整っている',
    '不明',
  ];
  static const spendingScale = [
    'かなり慎重',
    'やや慎重',
    'バランス',
    'やや積極的',
    'かなり積極的',
    '不明',
  ];
  static const forecastScale = ['かなり低い', 'やや低い', '中立', 'やや高い', 'かなり高い', '不明'];
  static const relationLabels = {
    RelationshipLevel.level1: '初対面',
    RelationshipLevel.level2: '知人',
    RelationshipLevel.level3: '友人',
    RelationshipLevel.level4: '親しい関係',
  };

  static const _scalePresets = <List<String>>[
    levelScale,
    frequencyScale,
    speedScale,
    logicBalanceIntuition,
    abstractConcrete,
    relationScale,
    reputationScale,
    importanceScale,
    workValueOptions,
    wealthValueOptions,
    homeStabilityScale,
    environmentInterestScale,
    politicsScale,
    economicsScale,
    socialViewScale,
    techViewScale,
    decisionScale,
    stressReactionScale,
    interpersonalScale,
    trustScale,
    conflictScale,
    friendshipScale,
    routineScale,
    spendingScale,
    forecastScale,
  ];

  static const categoryOrder = [
    '基本属性',
    '社会属性',
    '家族背景',
    '性格',
    '思考スタイル',
    '価値観',
    '思想',
    '動機',
    '行動パターン',
    '人間関係',
    'ライフスタイル',
    '情報環境',
    '能力',
    '弱点',
    '人生イベント',
    '社会評価',
    '行動履歴',
    '将来予測',
  ];

  static final definitions = <PersonAttributeDefinition>[
    ..._build('基本属性', [
      _spec(
        '本名',
        '呼ばれ方や表記のされ方。',
        freeText,
        seeds: ['どんな呼ばれ方が自然か', '通称や表記の使い分け'],
        openers: ['呼び方って人によって違いますよね。'],
        clues: ['自称する名前', '周囲が使う呼称'],
      ),
      _spec(
        'ニックネーム',
        '親しい場面での呼ばれ方。',
        freeText,
        seeds: ['どんな愛称で呼ばれているか', '場面ごとの呼ばれ方'],
        openers: ['学生時代のあだ名って残る人いますよね。'],
        clues: ['愛称への反応', '自己紹介の仕方'],
      ),
      _spec(
        '年齢層',
        'おおよその年代。',
        ['10代', '20代', '30代', '40代', '50代以上', '不明'],
        seeds: ['年代感が出る経験談', '同世代感覚の話'],
        openers: ['世代で流行って違いますよね。'],
        clues: ['学生時代の年代', '話題の世代感'],
      ),
      _spec(
        '出身地域',
        '育った地域や地元感覚。',
        regionOptions,
        seeds: ['地元の話題', '地域文化の影響'],
        openers: ['出身地の話ってその人らしさ出ますよね。'],
        clues: ['地元ネタ', '方言や土地勘'],
      ),
      _spec(
        '居住地域',
        '今の生活圏。',
        residenceOptions,
        seeds: ['普段の生活エリア', '移動のしやすさ'],
        openers: ['住む場所で生活リズム変わりますよね。'],
        clues: ['行動範囲', '周辺情報への詳しさ'],
      ),
      _spec(
        '国籍',
        '国籍や文化的な背景。',
        nationalityOptions,
        seeds: ['文化圏の違い', '慣習の話'],
        openers: ['文化圏が違うと当たり前も変わりますよね。'],
        clues: ['文化比較の話題', '祝祭日や習慣の知識'],
      ),
      _spec(
        '言語',
        '普段使う言語や表現圏。',
        languageOptions,
        seeds: ['普段の言語環境', '使い分けている言語'],
        openers: ['言語が違うと考え方も少し変わりますよね。'],
        clues: ['言語切り替え', '語彙の出方'],
      ),
      _spec(
        '外見特徴',
        '装い、雰囲気、声や話し方の印象。',
        appearanceOptions,
        seeds: ['第一印象の出方', '装いへのこだわり'],
        openers: ['雰囲気って服装や話し方に出ますよね。'],
        clues: ['服装傾向', '声量や話速'],
      ),
    ]),
    ..._build('社会属性', [
      _spec(
        '職業',
        '現在の主な仕事。',
        occupationOptions,
        seeds: ['今どんな仕事をしているか', '仕事の役割'],
        openers: ['最近どんなお仕事してるんですか。'],
        clues: ['仕事の説明の仕方', '日常の予定'],
      ),
      _spec(
        '業界',
        '所属する業界や領域。',
        industryOptions,
        seeds: ['どんな業界にいるか', '業界の空気感'],
        openers: ['業界でカルチャー違いますよね。'],
        clues: ['専門用語', '業界ニュースへの反応'],
      ),
      _spec(
        '所属組織',
        '会社、団体、コミュニティなどの所属。',
        freeText,
        seeds: ['どんな組織に関わっているか', '所属先との距離感'],
        openers: ['どんな場に所属しているかで日々変わりますよね。'],
        clues: ['組織名の出し方', '帰属意識'],
      ),
      _spec(
        '役職',
        '組織内での役割や責任範囲。',
        roleOptions,
        seeds: ['どんな立場を担っているか', '責任の持ち方'],
        openers: ['役割が変わると見える景色も変わりますよね。'],
        clues: ['意思決定の範囲', '責任の言及'],
      ),
      _spec(
        '学歴',
        '教育歴の概要。',
        educationOptions,
        seeds: ['どんな学びをしてきたか', '学校での経験'],
        openers: ['学生時代って今にも影響残りますよね。'],
        clues: ['学校経験の語り', '専門知識の土台'],
      ),
      _spec(
        '専攻',
        '専門的に学んだ分野。',
        majorOptions,
        seeds: ['何を中心に学んだか', '今に活きている学び'],
        openers: ['学生時代の専攻って意外と今に残りますよね。'],
        clues: ['専門分野へのこだわり', '知識の偏り'],
      ),
      _spec(
        'キャリア年数',
        '実務経験の長さ。',
        ['0-2年', '3-5年', '6-10年', '10年以上', '不明'],
        seeds: ['仕事歴の長さ', '経験の積み上がり'],
        openers: ['続けている年数って感覚変わりますよね。'],
        clues: ['ベテラン感', '経験談の厚み'],
      ),
      _spec(
        '収入層',
        'おおよその収入レンジ。',
        levelScale,
        intrusive: true,
        seeds: ['暮らしぶりの余裕感', 'お金の制約感'],
        openers: ['生活コストの感じ方って人それぞれですよね。'],
        clues: ['支出判断', '価格への反応'],
      ),
    ]),
    ..._build('家族背景', [
      _spec(
        '家族構成',
        '家族の人数や形。',
        freeText,
        seeds: ['家族の構成', '家での役割'],
        openers: ['家族の話って生活感出ますよね。'],
        clues: ['家族に触れる頻度', '家での役割語り'],
      ),
      _spec(
        '両親関係',
        '両親との距離感や関係性。',
        relationScale,
        intrusive: true,
        seeds: ['親との距離感', '頼り方や影響'],
        openers: ['親との距離感って年齢で変わりますよね。'],
        clues: ['親の話し方', '帰省や相談頻度'],
      ),
      _spec(
        '兄弟姉妹',
        '兄弟姉妹の有無や関わり。',
        freeText,
        seeds: ['兄弟姉妹との関係', '育ち方の違い'],
        openers: ['兄弟姉妹がいると役割感変わりますよね。'],
        clues: ['兄弟の話', '長子っぽさなどの自己認識'],
      ),
      _spec(
        '結婚状況',
        '結婚やパートナー関係の状況。',
        ['未婚', '既婚', '離別', '不明'],
        intrusive: true,
        seeds: ['生活を共にする相手の有無', '関係のスタイル'],
        openers: ['暮らし方って人それぞれですよね。'],
        clues: ['同居人の言及', '週末の過ごし方'],
      ),
      _spec(
        '子供',
        '子供の有無や関わり。',
        ['いない', 'いる', '不明'],
        intrusive: true,
        seeds: ['育児の関わり', '子供との接点'],
        openers: ['子供がいると生活リズム変わりますよね。'],
        clues: ['時間の使い方', '学校行事への言及'],
      ),
      _spec(
        '家庭環境',
        '育った家庭の安定感や雰囲気。',
        homeStabilityScale,
        intrusive: true,
        seeds: ['育った家庭の空気', '安心感の土台'],
        openers: ['育った環境って今にも残りますよね。'],
        clues: ['家の話題への温度感', '安心の求め方'],
      ),
    ]),
    ..._build('性格', [
      _spec(
        'BigFiveメモ',
        'BigFive全体をどう見ているかの総評。',
        freeText,
        seeds: ['性格傾向の全体像', '行動の一貫性'],
        openers: ['性格って場面ごとに出方違いますよね。'],
        clues: ['全体的な振る舞い'],
      ),
      _spec(
        '外向性',
        '人との接点でエネルギーを得やすいか。',
        levelScale,
        seeds: ['人と過ごす時間の好み', '一人時間とのバランス'],
        openers: ['休日の過ごし方って性格出ますよね。'],
        clues: ['人混みへの反応', '会話開始の頻度'],
      ),
      _spec(
        '協調性',
        '人に合わせたり配慮する度合い。',
        levelScale,
        seeds: ['相手への合わせ方', '衝突の避け方'],
        openers: ['気を配るタイプかって仕事にも出ますよね。'],
        clues: ['譲り方', '対立時の言い回し'],
      ),
      _spec(
        '誠実性',
        '几帳面さ、計画性、責任感。',
        levelScale,
        seeds: ['締切や約束の扱い', '準備の仕方'],
        openers: ['段取りの取り方って人それぞれですよね。'],
        clues: ['時間厳守', 'タスク管理'],
      ),
      _spec(
        '神経症傾向',
        '不安や揺れやすさ。',
        levelScale,
        intrusive: true,
        seeds: ['不安の出やすさ', '気分変動'],
        openers: ['忙しい時のコンディション管理って難しいですよね。'],
        clues: ['失敗への反応', '不安表現'],
      ),
      _spec(
        '開放性',
        '新しいものへの開かれやすさ。',
        levelScale,
        seeds: ['未知への反応', '好奇心の方向'],
        openers: ['新しいこと試すの得意な人っていますよね。'],
        clues: ['新規体験への前向きさ', '趣味の幅'],
      ),
      _spec(
        '承認欲求',
        '評価されたい気持ちの強さ。',
        levelScale,
        intrusive: true,
        seeds: ['評価への敏感さ', '見られ方の意識'],
        openers: ['人からどう見られるかって少し気になりますよね。'],
        clues: ['反応確認', '実績アピール'],
      ),
      _spec(
        '完璧主義',
        '完成度へのこだわり。',
        levelScale,
        seeds: ['どこまで詰めるか', '妥協のしにくさ'],
        openers: ['どこまで仕上げるかの感覚って人によりますよね。'],
        clues: ['細部確認', 'やり直し傾向'],
      ),
      _spec(
        '共感性',
        '他者感情への敏感さ。',
        levelScale,
        seeds: ['相手の気持ちへの反応', '空気の読み方'],
        openers: ['人の気持ちを拾うのが上手い人いますよね。'],
        clues: ['感情への言及', '話の聞き方'],
      ),
    ]),
    ..._build('思考スタイル', [
      _spec(
        '論理 / 直感',
        '判断における論理と直感の比重。',
        logicBalanceIntuition,
        seeds: ['判断のよりどころ', '決める時の癖'],
        openers: ['決め方って論理派か直感派か分かれますよね。'],
        clues: ['根拠の出し方', 'ひらめきの扱い'],
      ),
      _spec(
        '抽象 / 具体',
        '抽象化して捉えるか、具体から入るか。',
        abstractConcrete,
        seeds: ['話の粒度', '例え方の傾向'],
        openers: ['説明の仕方って抽象派と具体派がありますよね。'],
        clues: ['比喩の多さ', '細部志向'],
      ),
      _spec(
        '分析志向',
        '物事を分解して考える傾向。',
        levelScale,
        seeds: ['比較や整理の仕方', '要素分解の癖'],
        openers: ['考える時に一回分解する人いますよね。'],
        clues: ['比較表現', '因果の整理'],
      ),
      _spec(
        '判断速度',
        '意思決定の速さ。',
        speedScale,
        seeds: ['決断のタイミング', '保留の長さ'],
        openers: ['決断って早い人と慎重な人いますよね。'],
        clues: ['返答速度', '検討期間'],
      ),
      _spec(
        '認知バイアス傾向',
        '先入観や偏りに引っ張られやすい度合い。',
        levelScale,
        seeds: ['決めつけやすさ', '見直しのしやすさ'],
        openers: ['最初の印象に引っ張られることってありますよね。'],
        clues: ['断定の多さ', '反証への反応'],
      ),
      _spec(
        '思考柔軟性',
        '見方を切り替えやすいか。',
        levelScale,
        seeds: ['考えを更新する柔らかさ', '別視点の受け入れ'],
        openers: ['考え方を変えられる人って強いですよね。'],
        clues: ['意見修正', '他視点の採用'],
      ),
    ]),
    ..._build('価値観', [
      _spec(
        '人生観',
        '人生をどう捉えているか。',
        lifeViewOptions,
        seeds: ['人生のテーマ', '大切にしたい方向'],
        openers: ['人それぞれ生き方の軸ありますよね。'],
        clues: ['人生全体への言及', '優先順位'],
      ),
      _spec(
        '幸福観',
        '何を幸せと感じるか。',
        happinessOptions,
        seeds: ['幸せの条件', '満足の感じ方'],
        openers: ['何を幸せと思うかって人柄出ますよね。'],
        clues: ['満足の語り方', '喜びの源'],
      ),
      _spec(
        '成功観',
        '何を成功とみなすか。',
        successOptions,
        seeds: ['成功の定義', '達成感の基準'],
        openers: ['成功って人によって定義違いますよね。'],
        clues: ['成果へのこだわり', '比較対象'],
      ),
      _spec(
        '労働観',
        '仕事をどう位置づけているか。',
        workValueOptions,
        seeds: ['仕事の意味づけ', '働く目的'],
        openers: ['仕事の位置づけって人それぞれですよね。'],
        clues: ['やりがい語り', '生活優先の発言'],
      ),
      _spec(
        '家族観',
        '家族をどれほど重視するか。',
        familyValueOptions,
        seeds: ['家族への優先順位', '家族に求めるもの'],
        openers: ['家族との距離感って価値観出ますよね。'],
        clues: ['家族優先の判断', '家庭像'],
      ),
      _spec(
        '富の価値観',
        'お金や資産をどう見ているか。',
        wealthValueOptions,
        seeds: ['お金の使い道', '資産への考え方'],
        openers: ['お金の使い方って価値観出ますよね。'],
        clues: ['投資や節約の話', '価格感度'],
      ),
      _spec(
        '自由志向',
        '自由や裁量を求める強さ。',
        levelScale,
        seeds: ['束縛への反応', '自分で決めたい度合い'],
        openers: ['自由度って働き方にも効きますよね。'],
        clues: ['裁量へのこだわり', 'ルールへの反応'],
      ),
    ]),
    ..._build('思想', [
      _spec(
        '政治思想',
        '政治的な立ち位置。',
        politicsScale,
        intrusive: true,
        seeds: ['政治的な関心方向', '制度への見方'],
        openers: ['社会の仕組みの見方って人によって違いますよね。'],
        clues: ['政策話題への反応', '価値判断の軸'],
      ),
      _spec(
        '経済思想',
        '経済や分配の見方。',
        economicsScale,
        intrusive: true,
        seeds: ['競争と分配の見方', '市場への期待'],
        openers: ['経済の見方って仕事観にも繋がりますよね。'],
        clues: ['格差の捉え方', '市場原理への反応'],
      ),
      _spec(
        '宗教',
        '宗教や信仰との関わり。',
        freeText,
        intrusive: true,
        seeds: ['信仰や儀礼との距離', '精神的支え'],
        openers: ['文化や習慣ってルーツが出ますよね。'],
        clues: ['宗教行事への言及', '信念の由来'],
      ),
      _spec(
        '社会観',
        '社会をどう見ているか。',
        socialViewScale,
        seeds: ['社会問題の見方', '責任の置き方'],
        openers: ['社会の見方って経験で変わりますよね。'],
        clues: ['自己責任論への反応', '制度批判'],
      ),
      _spec(
        '技術観',
        '技術への期待と警戒。',
        techViewScale,
        seeds: ['新技術への姿勢', '便利さと不安のバランス'],
        openers: ['新しい技術への反応って性格出ますよね。'],
        clues: ['AIやSNSへの態度', '導入速度'],
      ),
      _spec(
        '環境観',
        '環境問題への関心。',
        environmentInterestScale,
        seeds: ['環境への関心度', '生活での配慮'],
        openers: ['環境の話って生活習慣にも出ますよね。'],
        clues: ['消費選択', '環境ニュースへの反応'],
      ),
    ]),
    ..._build('動機', [
      _spec(
        '安定志向',
        '安定や安全を重視する度合い。',
        levelScale,
        seeds: ['安心できる状態の条件', '変化への慎重さ'],
        openers: ['安定を大事にするかって選び方に出ますよね。'],
        clues: ['変化への慎重さ', '固定ルート志向'],
      ),
      _spec(
        '成長志向',
        '成長や変化を求める強さ。',
        levelScale,
        seeds: ['成長したい方向', '挑戦への前向きさ'],
        openers: ['成長したい気持ちが強い人っていますよね。'],
        clues: ['学習意欲', '挑戦機会の取り方'],
      ),
      _spec(
        '承認欲求',
        '評価されたい気持ちの強さ。',
        levelScale,
        intrusive: true,
        seeds: ['評価の必要性', '反応を求める傾向'],
        openers: ['人からの反応って少し気になりますよね。'],
        clues: ['SNS反応確認', '評価に落ち込むか'],
      ),
      _spec(
        '競争志向',
        '勝ち負けや比較を重視する度合い。',
        levelScale,
        seeds: ['比較意識', '勝負事への熱量'],
        openers: ['競争が燃える人と疲れる人いますよね。'],
        clues: ['比較発言', '順位や結果への関心'],
      ),
      _spec(
        '知識欲',
        '知ること自体への欲求。',
        levelScale,
        seeds: ['学ぶことの楽しさ', '掘り下げる力'],
        openers: ['何かを調べ始めると止まらない人いますよね。'],
        clues: ['話題の深掘り', '本や動画の蓄積'],
      ),
      _spec(
        '権力志向',
        '影響力や統率を求める度合い。',
        levelScale,
        intrusive: true,
        seeds: ['主導権への欲求', '影響を持ちたいか'],
        openers: ['前に立ちたい人と支える人っていますよね。'],
        clues: ['主導権の取り方', '立場へのこだわり'],
      ),
    ]),
    ..._build('行動パターン', [
      _spec(
        '意思決定',
        '決め方の行動パターン。',
        decisionScale,
        seeds: ['決める時に何を見るか', '迷い方'],
        openers: ['決断の仕方って結構個性出ますよね。'],
        clues: ['比較検討の深さ', '即答かどうか'],
      ),
      _spec(
        'ストレス反応',
        'ストレス時に出やすい反応。',
        stressReactionScale,
        intrusive: true,
        seeds: ['負荷がかかった時の変化', '疲れた時の振る舞い'],
        openers: ['忙しい時に出る癖ってありますよね。'],
        clues: ['無口化', '攻撃性や焦り'],
      ),
      _spec(
        '失敗時反応',
        '失敗後の立て直し方。',
        ['引きずる', '学習化する', '切り替えが早い', '不明'],
        seeds: ['失敗の受け止め方', '回復の速さ'],
        openers: ['失敗した後の切り替えって人それぞれですよね。'],
        clues: ['反省の仕方', '再挑戦の早さ'],
      ),
      _spec(
        '対人行動',
        '対人場面での動き方。',
        interpersonalScale,
        seeds: ['人に話しかけるタイミング', '距離の詰め方'],
        openers: ['人との距離の取り方って個性出ますよね。'],
        clues: ['話しかけ頻度', '気配りの出方'],
      ),
      _spec(
        'リーダーシップ',
        '前に立つ傾向。',
        levelScale,
        seeds: ['人を引っ張る場面', 'まとめ役の自然さ'],
        openers: ['自然にまとめ役になる人っていますよね。'],
        clues: ['場の整理', '意思決定を引き受けるか'],
      ),
      _spec(
        '衝動性',
        '衝動的に動く傾向。',
        levelScale,
        intrusive: true,
        seeds: ['思い立ったら動くか', '我慢のしやすさ'],
        openers: ['勢いで決めることってありますよね。'],
        clues: ['即買い', '感情での判断'],
      ),
    ]),
    ..._build('人間関係', [
      _spec(
        '友人関係',
        '友人関係の持ち方。',
        friendshipScale,
        seeds: ['友人との距離感', '関係の広さ'],
        openers: ['友達付き合いのスタイルって人それぞれですよね。'],
        clues: ['会う人数', '付き合いの継続性'],
      ),
      _spec(
        '恋愛観',
        '恋愛や親密さの捉え方。',
        freeText,
        intrusive: true,
        seeds: ['恋愛で大事にするもの', '親密さの作り方'],
        openers: ['人との近さの作り方っていろいろありますよね。'],
        clues: ['関係への言及', '親密さへの価値観'],
      ),
      _spec(
        '家族距離',
        '家族との距離感。',
        relationScale,
        intrusive: true,
        seeds: ['家族との近さ', '関わる頻度'],
        openers: ['家族との連絡頻度って人それぞれですよね。'],
        clues: ['連絡頻度', '帰省や相談の有無'],
      ),
      _spec(
        '信頼傾向',
        '人を信頼する速度。',
        trustScale,
        seeds: ['相手を信じるまでの距離', '慎重さ'],
        openers: ['信頼って積み上がる速度が違いますよね。'],
        clues: ['個人情報の開示速度', '相談のしやすさ'],
      ),
      _spec(
        '対立傾向',
        '対立への向き合い方。',
        conflictScale,
        intrusive: true,
        seeds: ['揉め事への向き合い方', '言い返し方'],
        openers: ['意見がぶつかった時の反応って個性出ますよね。'],
        clues: ['対立の避け方', '感情表現'],
      ),
      _spec(
        'ネットワーク',
        '人脈の広さ。',
        frequencyScale,
        seeds: ['知り合いの広さ', '紹介の多さ'],
        openers: ['知り合いが多い人っていますよね。'],
        clues: ['紹介の発生', '接点の多様さ'],
      ),
    ]),
    ..._build('ライフスタイル', [
      _spec(
        '睡眠',
        '睡眠習慣。',
        routineScale,
        seeds: ['寝る時間帯', '睡眠の優先度'],
        openers: ['睡眠の取り方ってかなり差ありますよね。'],
        clues: ['連絡時間帯', '眠そうな様子'],
      ),
      _spec(
        '食生活',
        '食習慣。',
        routineScale,
        seeds: ['普段の食事', '健康意識'],
        openers: ['食生活って生活感出ますよね。'],
        clues: ['外食頻度', '食へのこだわり'],
      ),
      _spec(
        '運動',
        '運動習慣。',
        frequencyScale,
        seeds: ['体を動かす頻度', '運動の目的'],
        openers: ['運動習慣ある人って生活リズム安定してますよね。'],
        clues: ['体力の話', '運動予定'],
      ),
      _spec(
        '趣味',
        '継続的に楽しんでいること。',
        freeText,
        seeds: ['没頭している趣味', '時間の使い道'],
        openers: ['趣味の話ってその人らしさ出ますよね。'],
        clues: ['繰り返し話すテーマ', '休日の使い方'],
      ),
      _spec(
        '趣味の詳細',
        '趣味の内容や、どこに魅力を感じているか。',
        freeText,
        seeds: ['どんなところが面白いと感じているか', 'どれくらい深く続けているか'],
        openers: ['趣味って詳しく聞くとその人らしさ出ますよね。'],
        clues: ['具体的な語り', '道具や場所へのこだわり'],
      ),
      _spec(
        '娯楽',
        '気分転換の仕方。',
        freeText,
        seeds: ['何で息抜きするか', '気分転換のパターン'],
        openers: ['息抜きの仕方って大事ですよね。'],
        clues: ['疲れた時の選択', '娯楽消費'],
      ),
      _spec(
        '好きな映画',
        '印象に残っている映画や映像作品。',
        mediaPreferenceOptions,
        seeds: ['どんな作品が印象に残っているか', 'なぜそれが好きなのか'],
        openers: ['好きな映画の話って価値観出ますよね。'],
        clues: ['作品名の引用', '映像体験の語り'],
      ),
      _spec(
        '好きな本',
        '好きな本やよく読むジャンル。',
        mediaPreferenceOptions,
        seeds: ['どんな本を好むか', 'なぜその本が残っているか'],
        openers: ['好きな本ってその人の考え方が出ますよね。'],
        clues: ['著者名の言及', '本の引用'],
      ),
      _spec(
        '好きなスポーツ',
        '好きなスポーツや観戦対象。',
        ['サッカー', '野球', 'バスケ', 'テニス', '格闘技', '陸上', '特になし', 'その他', '不明'],
        seeds: ['どんなスポーツが好きか', '見るのかやるのか'],
        openers: ['スポーツの好みって意外と性格出ますよね。'],
        clues: ['試合の話題', '競技への熱量'],
      ),
      _spec(
        '好きな音楽',
        '好きな音楽やアーティスト。',
        mediaPreferenceOptions,
        seeds: ['どんな音楽をよく聴くか', '気分でどう選ぶか'],
        openers: ['音楽の好みって空気感出ますよね。'],
        clues: ['アーティスト名', '再生習慣'],
      ),
      _spec(
        '好きな食べ物',
        '好んで食べるもの。',
        [
          '和食',
          '洋食',
          '中華',
          '辛いもの',
          '甘いもの',
          '肉料理',
          '魚料理',
          'ジャンクフード',
          'その他',
          '不明',
        ],
        seeds: ['何を食べると機嫌が上がるか', '好みの傾向'],
        openers: ['食の好みって話しやすいですよね。'],
        clues: ['注文傾向', '店選び'],
      ),
      _spec(
        '好きな動物',
        '好きな動物や生き物への好み。',
        ['犬', '猫', '鳥', '魚', 'うさぎ', '爬虫類', '特になし', 'その他', '不明'],
        seeds: ['どんな動物が好きか', 'なぜ惹かれるか'],
        openers: ['動物の好みって意外と性格出ますよね。'],
        clues: ['写真への反応', '飼育経験'],
      ),
      _spec(
        '消費行動',
        'お金の使い方。',
        spendingScale,
        seeds: ['買い物の判断軸', '使いどころ'],
        openers: ['買い物の基準って価値観出ますよね。'],
        clues: ['衝動買い', 'レビュー確認'],
      ),
    ]),
    ..._build('情報環境', [
      _spec(
        'ニュース源',
        'どこからニュースを得るか。',
        freeText,
        seeds: ['普段の情報源', '信頼している媒体'],
        openers: ['ニュースってどこで見てますか、で個性出ますよね。'],
        clues: ['媒体名の言及', '速報性の重視'],
      ),
      _spec(
        'SNS',
        '主に使うSNS。',
        snsPlatformOptions,
        seeds: ['よく使うSNS', '見る専か発信するか'],
        openers: ['SNSって使い方かなり分かれますよね。'],
        clues: ['投稿頻度', 'プラットフォーム名'],
      ),
      _spec(
        'SNS使用時間',
        'SNSにどれくらい時間を使っているか。',
        frequencyScale,
        seeds: ['SNSに使う時間感覚', '生活の中での占め方'],
        openers: ['SNSって気づくと時間使いますよね。'],
        clues: ['利用時間帯', '通知確認の頻度'],
      ),
      _spec(
        'SNS利用理由',
        'なぜそのSNSを使っているか。',
        freeText,
        seeds: ['SNSを使う目的', '得たいもの'],
        openers: ['そのSNSを使う理由って人それぞれですよね。'],
        clues: ['情報収集目的', '交流目的', '暇つぶし目的'],
      ),
      _spec(
        '読書',
        '読書習慣。',
        frequencyScale,
        seeds: ['本を読む頻度', '読むジャンル'],
        openers: ['最近読んだ本って何かありますか、って面白いですよね。'],
        clues: ['本の引用', '積読の話'],
      ),
      _spec(
        'YouTube',
        'YouTube視聴習慣。',
        frequencyScale,
        seeds: ['どんな動画を見るか', '娯楽か学習か'],
        openers: ['YouTubeって見方に性格出ますよね。'],
        clues: ['チャンネル名', '視聴時間帯'],
      ),
      _spec(
        'ポッドキャスト',
        '音声メディアの習慣。',
        frequencyScale,
        seeds: ['どんな音声を聞くか', 'ながら時間の使い方'],
        openers: ['音声コンテンツって生活リズム出ますよね。'],
        clues: ['番組名', '通勤中の習慣'],
      ),
      _spec(
        '思想的影響',
        '強く影響を受けた人物や媒体。',
        freeText,
        seeds: ['考え方に影響した存在', '繰り返し参照するもの'],
        openers: ['影響受けた人や本って残りますよね。'],
        clues: ['引用頻度', '好むフレームワーク'],
      ),
    ]),
    ..._build('能力', [
      _spec(
        '言語能力',
        '言葉で伝える力。',
        levelScale,
        seeds: ['説明のうまさ', '語彙や表現力'],
        openers: ['説明が上手い人っていますよね。'],
        clues: ['言い換えの多さ', '文章力'],
      ),
      _spec(
        '数理能力',
        '数的・論理的処理の強さ。',
        levelScale,
        seeds: ['数字への強さ', '構造理解'],
        openers: ['数字に強い人って考え方も特徴ありますよね。'],
        clues: ['定量発言', '構造化の速さ'],
      ),
      _spec(
        '創造性',
        '新しい発想や表現の力。',
        levelScale,
        seeds: ['アイデアの出し方', '新しい組み合わせ'],
        openers: ['発想が面白い人っていますよね。'],
        clues: ['独自視点', '企画の着眼点'],
      ),
      _spec(
        '技術能力',
        '技術や道具の扱い。',
        levelScale,
        seeds: ['ツール習熟', '実装力や応用力'],
        openers: ['道具を使いこなすの上手い人いますよね。'],
        clues: ['ツール選定', 'トラブル対応'],
      ),
      _spec(
        '身体能力',
        '身体的な強み。',
        levelScale,
        seeds: ['体力や運動性能', '身体の使い方'],
        openers: ['体の使い方って仕事にも出ますよね。'],
        clues: ['体力', '運動経験'],
      ),
      _spec(
        'コミュニケーション能力',
        '対人伝達の力。',
        levelScale,
        seeds: ['伝え方と聞き方', '場に合わせる力'],
        openers: ['話しやすさって能力ですよね。'],
        clues: ['会話の回し方', '相手への合わせ方'],
      ),
    ]),
    ..._build('弱点', [
      _spec(
        'コンプレックス',
        '引け目や自信のなさを感じる領域。',
        freeText,
        intrusive: true,
        seeds: ['自信の持ちにくい点', '避けたい話題'],
        openers: ['誰でもちょっと苦手意識あるものありますよね。'],
        clues: ['自己卑下', '避けるテーマ'],
      ),
      _spec(
        '不安',
        '不安を感じやすい度合い。',
        levelScale,
        intrusive: true,
        seeds: ['何に不安を感じやすいか', '先回りして心配するか'],
        openers: ['不安の出方って人それぞれですよね。'],
        clues: ['心配の表現', '確認行動'],
      ),
      _spec(
        '恐怖',
        '避けたい対象や状況。',
        freeText,
        intrusive: true,
        seeds: ['強く避けたいもの', '怖さの対象'],
        openers: ['誰でも苦手なものってありますよね。'],
        clues: ['回避行動', '表情の変化'],
      ),
      _spec(
        'ストレス要因',
        '消耗しやすい引き金。',
        freeText,
        intrusive: true,
        seeds: ['疲れやすい状況', '消耗のきっかけ'],
        openers: ['疲れやすい環境ってありますよね。'],
        clues: ['機嫌の変化', '避ける場面'],
      ),
      _spec(
        '怒りトリガー',
        '怒りや苛立ちの引き金。',
        freeText,
        intrusive: true,
        seeds: ['イラッとしやすいこと', '許せないライン'],
        openers: ['苦手な振る舞いって人それぞれありますよね。'],
        clues: ['苛立ちの表現', '批判の対象'],
      ),
    ]),
    ..._build('人生イベント', [
      _spec(
        '人生転機',
        '大きな転機の有無や印象。',
        freeText,
        intrusive: true,
        seeds: ['人生が変わった出来事', '方向転換の契機'],
        openers: ['人生の流れ変わる瞬間ってありますよね。'],
        clues: ['Before/Afterの語り', '転機の強調'],
      ),
      _spec(
        '成功体験',
        '印象的な成功体験。',
        freeText,
        seeds: ['誇りに思っている経験', '成功の記憶'],
        openers: ['うまくいった経験って支えになりますよね。'],
        clues: ['自信の源', '繰り返し語る成功'],
      ),
      _spec(
        '失敗体験',
        '印象的な失敗体験。',
        freeText,
        intrusive: true,
        seeds: ['忘れられない失敗', '教訓になった出来事'],
        openers: ['失敗から学ぶことって多いですよね。'],
        clues: ['避ける話題', '反省の強さ'],
      ),
      _spec(
        '大きな変化',
        '生活や考えを変えた変化。',
        freeText,
        seeds: ['環境変化の経験', '考え方が変わった契機'],
        openers: ['環境変わると価値観も変わりますよね。'],
        clues: ['移住や転職', '価値観の更新'],
      ),
      _spec(
        '人生の師',
        '影響を受けた人物の有無。',
        freeText,
        seeds: ['尊敬している人', '学びの源'],
        openers: ['影響を受けた人っていますよね。'],
        clues: ['名前をよく出す人物', '引用'],
      ),
      _spec(
        '価値観変化',
        '価値観が変わった経験。',
        freeText,
        seeds: ['前と今で変わったこと', '変化の理由'],
        openers: ['昔と今で考え変わることってありますよね。'],
        clues: ['昔はこうだった発言', '転換点の説明'],
      ),
    ]),
    ..._build('社会評価', [
      _spec(
        'reputation',
        '一般的な評判。',
        reputationScale,
        seeds: ['周囲での見られ方', '評判の方向'],
        openers: ['周りからどう見られてるかって面白いですよね。'],
        clues: ['第三者評価', '評判の一貫性'],
      ),
      _spec(
        '信頼度',
        '周囲からの信頼。',
        reputationScale,
        seeds: ['任されやすさ', '信用のされ方'],
        openers: ['信頼って積み上がり方に個性ありますよね。'],
        clues: ['相談される頻度', '任される仕事'],
      ),
      _spec(
        '支持者',
        '支持する人の多さ。',
        frequencyScale,
        seeds: ['応援してくれる人の層', '支持の広がり'],
        openers: ['応援してくれる人がつくタイプっていますよね。'],
        clues: ['ファンの存在', '推す人の熱量'],
      ),
      _spec(
        '批判者',
        '批判者の多さ。',
        frequencyScale,
        seeds: ['反発を受けやすさ', '賛否の割れ方'],
        openers: ['賛否が分かれる人っていますよね。'],
        clues: ['炎上や摩擦', '批判の話題'],
      ),
    ]),
    ..._build('行動履歴', [
      _spec(
        '学歴履歴',
        '教育履歴の記録。',
        freeText,
        seeds: ['学校歴の流れ', '学びの経路'],
        openers: ['どんなふうに学んできたかって面白いですよね。'],
        clues: ['学校名や時系列', '学び直しの有無'],
      ),
      _spec(
        '職歴履歴',
        '職歴の流れ。',
        freeText,
        seeds: ['仕事の変遷', 'キャリアの転換'],
        openers: ['キャリアの流れってその人らしさ出ますよね。'],
        clues: ['転職回数', '役割変化'],
      ),
      _spec(
        'SNS発言',
        'SNS上での発信傾向。',
        freeText,
        seeds: ['何を発信しがちか', '発信頻度'],
        openers: ['SNSの発信って性格出ますよね。'],
        clues: ['投稿内容', '炎上/拡散歴'],
      ),
      _spec(
        '著作',
        '著作や公開物の有無。',
        freeText,
        seeds: ['書いたものや作ったもの', '公開している成果物'],
        openers: ['何か形に残している人って面白いですよね。'],
        clues: ['執筆歴', 'ポートフォリオ'],
      ),
    ]),
    ..._build('将来予測', [
      _spec(
        'キャリア予測',
        '今後のキャリアの伸び方予測。',
        forecastScale,
        seeds: ['今後伸びそうな方向', '次の役割'],
        openers: ['この先どう広がりそうかって見えてきますよね。'],
        clues: ['今の積み上げ', '周囲の期待'],
      ),
      _spec(
        '行動予測',
        '今後の行動パターン予測。',
        forecastScale,
        seeds: ['次に取りそうな行動', '変化の方向'],
        openers: ['次の一手ってその人らしさ出ますよね。'],
        clues: ['最近の流れ', '意思決定傾向'],
      ),
      _spec(
        'リスク',
        '今後のリスク要因。',
        levelScale,
        seeds: ['つまずきやすい点', '今後の不安要素'],
        openers: ['強みの裏返しでリスク出ますよね。'],
        clues: ['無理のし方', '環境依存性'],
      ),
      _spec(
        '潜在能力',
        'まだ表れていない伸びしろ。',
        levelScale,
        seeds: ['今後伸びそうな力', '未発揮の可能性'],
        openers: ['まだ出てない強みってありますよね。'],
        clues: ['学習速度', '環境が合った時の伸び'],
      ),
    ]),
  ];

  static PersonAttributeDefinition? definitionByKey(
    String category,
    String name,
  ) {
    for (final definition in definitions) {
      if (definition.category == category && definition.name == name) {
        return definition;
      }
    }
    return null;
  }

  static List<PersonAttributeDefinition> definitionsForCategory(
    String category,
  ) {
    return definitions
        .where((definition) => definition.category == category)
        .toList();
  }

  static Map<String, List<PersonAttributeDefinition>>
  definitionMapByCategory() {
    final map = <String, List<PersonAttributeDefinition>>{};
    for (final category in categoryOrder) {
      map[category] = definitionsForCategory(category);
    }
    return map;
  }

  static List<SuggestedPersonQuestion> suggestQuestions({
    required Set<String> knownAttributeKeys,
    required RelationshipLevel level,
    int limit = 24,
  }) {
    final unknownDefinitions = definitions.where((definition) {
      final key = attributeKey(definition.category, definition.name);
      if (knownAttributeKeys.contains(key)) {
        return false;
      }
      if (definition.intrusive &&
          (level == RelationshipLevel.level1 ||
              level == RelationshipLevel.level2)) {
        return false;
      }
      return true;
    }).toList();

    final groupedByCategory = <String, List<PersonAttributeDefinition>>{};
    for (final category in categoryOrder) {
      groupedByCategory[category] = unknownDefinitions
          .where((definition) => definition.category == category)
          .toList();
    }

    final pickedDefinitions = <PersonAttributeDefinition>[];
    var added = true;
    while (pickedDefinitions.length < (limit ~/ 3 + 1) && added) {
      added = false;
      for (final category in categoryOrder) {
        final queue = groupedByCategory[category]!;
        if (queue.isEmpty) {
          continue;
        }
        pickedDefinitions.add(queue.removeAt(0));
        added = true;
        if (pickedDefinitions.length >= (limit ~/ 3 + 1)) {
          break;
        }
      }
    }

    final suggestions = <SuggestedPersonQuestion>[];
    for (final definition in pickedDefinitions) {
      for (final tactic in tacticsForDefinition(definition, level)) {
        suggestions.add(
          SuggestedPersonQuestion(
            questionText: tactic.questionText,
            relationshipLevel: level,
            category: definition.category,
            purpose: definition.description,
            linkedAttributes: [
              attributeKey(definition.category, definition.name),
            ],
            questionType: tactic.questionType,
          ),
        );
        if (suggestions.length >= limit) {
          return suggestions;
        }
      }
    }
    return suggestions;
  }

  static List<PersonQuestionTactic> tacticsForDefinition(
    PersonAttributeDefinition definition,
    RelationshipLevel level,
  ) {
    final seedA = definition.questionSeeds.first;
    final seedB = definition.questionSeeds.length > 1
        ? definition.questionSeeds[1]
        : definition.questionSeeds.first;
    final opener = definition.conversationOpeners.first;
    final clue = definition.observationClues.first;
    final purpose = definition.description;
    final relaxed = _softener(level);
    return [
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.direct,
        questionText: '${definition.name}って、いま自分ではどんな感じだと思っていますか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.direct,
        questionText: '${definition.name}について聞くなら、いちばん近い言い方はどれですか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.indirect,
        questionText: '$opener その流れでいうと、$seedAって自然に出ますか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.indirect,
        questionText: '$relaxed たとえば$seedBの話って、普段の会話でも出やすいですか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.assumption,
        questionText: '$seedAは、わりと強めにある方かなと思ったんですがどうですか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.assumption,
        questionText: '$seedBって、たぶん大事にしている方ですよね。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.comparison,
        questionText: '$seedAを重視する人とそうでもない人がいますよね。自分はどちら寄りですか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.comparison,
        questionText: '$seedBって、人によってかなり差が出ると思うんですが、自分はどうですか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.past,
        questionText: '昔から$seedAは同じ感じでしたか。それとも変わってきましたか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.past,
        questionText: '前は$seedBをどう捉えていたか、覚えていますか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.situational,
        questionText: '$seedAが必要な場面だと、ふだんどういう動き方になりますか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.situational,
        questionText: '$seedBが問われる状況だと、自然にどう反応しやすいですか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.observation,
        questionText: '$clue が出ている印象なんですが、自分でもそう思いますか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.observation,
        questionText: '話していて、$seedAがわりと自然に見える感じがあります。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.hypothetical,
        questionText: 'もし今よりもっと$seedAが必要な環境に入ったら、どうしそうですか。',
        purpose: purpose,
      ),
      PersonQuestionTactic(
        attribute: definition.name,
        category: definition.category,
        questionType: QuestionStrategy.hypothetical,
        questionText: 'もし理想どおりに$seedBを選べるなら、どんな形がしっくりきますか。',
        purpose: purpose,
      ),
    ];
  }

  static List<Map<String, dynamic>> exportUiDefinitions() {
    return definitions
        .map(
          (definition) => {
            'category': definition.category,
            'attribute_name': definition.name,
            'description': definition.description,
            'options': definition.options,
            'intrusive': definition.intrusive,
            'conversation_openers': definition.conversationOpeners,
            'observation_clues': definition.observationClues,
            'question_tactics':
                tacticsForDefinition(
                      definition,
                      definition.intrusive
                          ? RelationshipLevel.level3
                          : RelationshipLevel.level2,
                    )
                    .map(
                      (tactic) => {
                        'attribute': tactic.attribute,
                        'question_type': tactic.questionType.apiName,
                        'question_text': tactic.questionText,
                        'purpose': tactic.purpose,
                      },
                    )
                    .toList(),
          },
        )
        .toList();
  }

  static String attributeKey(String category, String name) =>
      '$category::$name';

  static Map<String, List<T>> groupByCategory<T>(
    Iterable<T> values, {
    required String Function(T value) categoryOf,
  }) {
    final grouped = <String, List<T>>{};
    for (final value in values) {
      final category = categoryOf(value);
      grouped.putIfAbsent(category, () => []).add(value);
    }
    final ordered = <String, List<T>>{};
    for (final category in categoryOrder) {
      if (grouped.containsKey(category)) {
        ordered[category] = grouped[category]!;
      }
    }
    for (final entry in grouped.entries) {
      ordered.putIfAbsent(entry.key, () => entry.value);
    }
    return ordered;
  }

  static List<PersonAttributeDefinition> _build(
    String category,
    List<_AttributeSpec> specs,
  ) {
    return specs
        .map(
          (spec) => PersonAttributeDefinition(
            category: category,
            name: spec.name,
            description: spec.description,
            options: spec.options,
            intrusive: spec.intrusive,
            questionSeeds: spec.seeds,
            conversationOpeners: spec.openers,
            observationClues: spec.clues,
            freeTextOnly: spec.freeTextOnly || spec.options.isEmpty,
            inputKind: _inferInputKind(spec.options, spec.freeTextOnly),
          ),
        )
        .toList();
  }

  static PersonInputKind _inferInputKind(
    List<String> options,
    bool freeTextOnly,
  ) {
    if (freeTextOnly || options.isEmpty) {
      return PersonInputKind.freeText;
    }
    for (final preset in _scalePresets) {
      if (_sameOptions(options, preset)) {
        return PersonInputKind.scale;
      }
    }
    return PersonInputKind.category;
  }

  static bool _sameOptions(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static String _softener(RelationshipLevel level) {
    switch (level) {
      case RelationshipLevel.level1:
        return '軽く触れられる話題から入るのが自然です。';
      case RelationshipLevel.level2:
        return '少し具体例を聞くくらいが自然です。';
      case RelationshipLevel.level3:
        return '背景も含めて丁寧に聞ける関係です。';
      case RelationshipLevel.level4:
        return '無理のない範囲で深い話まで触れられます。';
    }
  }

  static _AttributeSpec _spec(
    String name,
    String description,
    List<String> options, {
    required List<String> seeds,
    required List<String> openers,
    required List<String> clues,
    bool intrusive = false,
    bool freeTextOnly = false,
  }) {
    return _AttributeSpec(
      name: name,
      description: description,
      options: options,
      intrusive: intrusive,
      freeTextOnly: freeTextOnly,
      seeds: seeds,
      openers: openers,
      clues: clues,
    );
  }
}

class _AttributeSpec {
  final String name;
  final String description;
  final List<String> options;
  final bool intrusive;
  final bool freeTextOnly;
  final List<String> seeds;
  final List<String> openers;
  final List<String> clues;

  const _AttributeSpec({
    required this.name,
    required this.description,
    required this.options,
    required this.intrusive,
    required this.freeTextOnly,
    required this.seeds,
    required this.openers,
    required this.clues,
  });
}
