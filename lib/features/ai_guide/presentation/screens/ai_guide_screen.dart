import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

class AiGuideScreen extends StatefulWidget {
  const AiGuideScreen({super.key});

  @override
  State<AiGuideScreen> createState() => _AiGuideScreenState();
}

class _AiGuideScreenState extends State<AiGuideScreen> {
  _AiGuideFilter _selectedFilter = _AiGuideFilter.all;

  static const _quickExamples = ['Expense', 'Income', 'Receipt', 'Smart Mode'];

  static const _topics = [
    _AiGuideTopic(
      title: 'Single expense',
      badge: 'চ্যাট',
      icon: Icons.shopping_bag_outlined,
      filter: _AiGuideFilter.add,
      whereToUse: 'Chat tab এ text input box-এ লিখুন।',
      pattern: '[date] [item/category/merchant] [amount] টাকা',
      examples: [
        _GuideExample('আজকে খাবারে ২২০ টাকা'),
        _GuideExample('গতকাল রিকশা ৮০ টাকা'),
        _GuideExample('গত শুক্রবার Uber ৪৫০ টাকা Transport'),
      ],
      steps: [
        _GuideStep('খরচের কারণ বা দোকানের নাম লিখুন।'),
        _GuideStep('Amount এবং date যোগ করুন।'),
        _GuideStep('AI draft দেখলে category/date/wallet confirm করুন।'),
      ],
      tips: [
        'Category লিখলে ভুল category কম হয়।',
        'Date না দিলে সাধারণত আজকের date ধরা হয়।',
      ],
      checklist: ['Amount', 'Date', 'Category', 'Wallet'],
    ),
    _AiGuideTopic(
      title: 'Multiple expenses',
      badge: 'চ্যাট',
      icon: Icons.playlist_add_check_rounded,
      filter: _AiGuideFilter.add,
      whereToUse: 'এক message-এ কয়েকটা খরচ লিখুন।',
      pattern: '[date] item amount, item amount, item amount',
      examples: [
        _GuideExample('আজকে চা ৩০, দুপুরের খাবার ১৮০, রিকশা ৬০'),
        _GuideExample('গতকাল বাজার ৮৫০, ফার্মেসি ৩২০'),
        _GuideExample('শুক্রবার coffee ২০০, movie ৫০০, bus ৬০'),
      ],
      steps: [
        _GuideStep('প্রতিটি খরচ comma দিয়ে আলাদা করুন।'),
        _GuideStep('একই date হলে শুরুতে date লিখুন।'),
        _GuideStep('Confirmation card থেকে যেগুলো save করবেন select করুন।'),
      ],
      tips: [
        'এক message-এ খুব বেশি item দিলে review কঠিন হয়।',
        'প্রতিটি item-এর amount স্পষ্ট রাখুন।',
      ],
      checklist: ['Item count', 'Amount', 'Category', 'Date'],
    ),
    _AiGuideTopic(
      title: 'Income',
      badge: 'চ্যাট',
      icon: Icons.payments_outlined,
      filter: _AiGuideFilter.add,
      whereToUse: 'Chat tab থেকে income লিখুন।',
      pattern: '[date] [source] পেলাম [amount] টাকা',
      examples: [
        _GuideExample('বেতন পেলাম ৩০,০০০ টাকা'),
        _GuideExample('আজকে freelance income ৫,০০০ টাকা'),
        _GuideExample('গতকাল bonus ২,০০০ টাকা'),
      ],
      steps: [
        _GuideStep('Income source লিখুন: salary, freelance, bonus ইত্যাদি।'),
        _GuideStep('Amount এবং date স্পষ্ট করুন।'),
        _GuideStep('Income confirmation থেকে save করুন।'),
      ],
      tips: [
        'Recurring income হলে মাসিক/regular কথাটা লিখতে পারেন।',
        'Expense আর income একসাথে লিখলেও AI আলাদা করতে পারে।',
      ],
      checklist: ['Source', 'Amount', 'Date', 'Wallet'],
    ),
    _AiGuideTopic(
      title: 'Mixed income + expense',
      badge: 'চ্যাট',
      icon: Icons.compare_arrows_rounded,
      filter: _AiGuideFilter.add,
      whereToUse: 'একই chat message-এ আয় এবং খরচ দুটোই লিখুন।',
      pattern: 'income + expenses in one message',
      examples: [
        _GuideExample('আজকে বেতন ৩০,০০০, খাবারে ২০০, বাস ৫০'),
        _GuideExample('Freelance ৫,০০০ পেলাম, lunch ১৮০ খরচ'),
      ],
      steps: [
        _GuideStep('Income এবং expense অংশ আলাদা phrase-এ লিখুন।'),
        _GuideStep('AI যে cards দেখাবে সেগুলো আলাদা review করুন।'),
        _GuideStep('প্রয়োজনে income/expense separately save করুন।'),
      ],
      tips: [
        'Mixed entry বেশি complex হলে দুই message-এ পাঠানো ভালো।',
        'Income source এবং expense category আলাদা করে লিখুন।',
      ],
      checklist: ['Income source', 'Expense category', 'Amount', 'Date'],
    ),
    _AiGuideTopic(
      title: 'Split bill',
      badge: 'চ্যাট',
      icon: Icons.group_work_outlined,
      filter: _AiGuideFilter.add,
      whereToUse: 'Chat tab-এ group bill লিখুন।',
      pattern: '[item] [amount] টাকা [person count] জনে split',
      examples: [
        _GuideExample('Pizza ১২০০ টাকা ৪ জনে split'),
        _GuideExample('আমরা ৫ জন মিলে কাচ্চি ২৫০০ টাকা'),
        _GuideExample('দলের খাবার ৮০০ টাকা ৪ জনে ভাগ'),
      ],
      steps: [
        _GuideStep('Total amount লিখুন, per-person amount নয়।'),
        _GuideStep('কয়জন ভাগ করবেন সেটা লিখুন।'),
        _GuideStep('Split suggestion থেকে save বা split screen খুলুন।'),
      ],
      tips: [
        'Person count না দিলে app default count ধরে নিতে পারে।',
        'Tax/service charge থাকলে total amount লিখুন।',
      ],
      checklist: ['Total amount', 'Person count', 'Category', 'Date'],
    ),
    _AiGuideTopic(
      title: 'Voice',
      badge: 'ভয়েস',
      icon: Icons.mic_none_rounded,
      filter: _AiGuideFilter.scanVoice,
      whereToUse: 'Chat input empty থাকলে mic button চাপুন।',
      pattern: 'same as chat, but spoken clearly',
      examples: [
        _GuideExample('আজকে খাবারে দুইশ বিশ টাকা'),
        _GuideExample('গতকাল রিকশা আশি টাকা'),
        _GuideExample('বেতন পেলাম ত্রিশ হাজার টাকা'),
      ],
      steps: [
        _GuideStep('Mic চাপুন এবং পরিষ্কারভাবে বলুন।'),
        _GuideStep('Stop চাপলে voice transcript AI-তে যাবে।'),
        _GuideStep('Detected draft save করার আগে review করুন।'),
      ],
      tips: [
        'Noise কম হলে transcript ভালো হয়।',
        'Amount digit বা spoken number দুইভাবেই বলুন, যেটা সহজ লাগে।',
      ],
      checklist: ['Transcript', 'Amount', 'Date', 'Category'],
    ),
    _AiGuideTopic(
      title: 'Receipt scan',
      badge: 'Scan',
      icon: Icons.receipt_long_outlined,
      filter: _AiGuideFilter.scanVoice,
      whereToUse: 'Chat input-এর + button থেকে camera বা gallery খুলুন।',
      pattern: '+ -> camera/gallery -> confirm',
      examples: [
        _GuideExample('রিসিট সোজা রেখে clear photo তুলুন'),
        _GuideExample('Total, date, merchant visible রাখুন'),
        _GuideExample('Blur বা folded receipt হলে আবার scan করুন'),
      ],
      steps: [
        _GuideStep('+ button চাপুন।'),
        _GuideStep('Camera scan বা gallery receipt select করুন।'),
        _GuideStep('AI parsed merchant/amount/category confirm করুন।'),
      ],
      tips: [
        'OCR device-এ text পড়ে, তারপর receipt text AI-তে যায়।',
        'Low light বা cropped total হলে result ভুল হতে পারে।',
      ],
      checklist: ['Merchant', 'Total', 'Date', 'Category'],
    ),
    _AiGuideTopic(
      title: 'Smart Mode today',
      badge: 'Smart Mode',
      icon: Icons.today_outlined,
      filter: _AiGuideFilter.smartMode,
      whereToUse: 'Chat header-এর brain icon on রাখুন।',
      pattern: 'today spending questions',
      examples: [
        _GuideExample('আজকে কত খরচ হয়েছে?'),
        _GuideExample('আজকে কোন category তে বেশি খরচ?'),
        _GuideExample('আজকের transaction summary দাও'),
      ],
      steps: [
        _GuideStep('Brain icon on আছে কিনা দেখুন।'),
        _GuideStep('আজকের expense/income নিয়ে প্রশ্ন করুন।'),
        _GuideStep('AI answer-এর card ও numbers review করুন।'),
      ],
      tips: [
        'Smart Mode local finance context ব্যবহার করে।',
        'Data কম থাকলে answer কম useful হতে পারে।',
      ],
      checklist: ['Smart Mode on', 'Date scope', 'Numbers'],
    ),
    _AiGuideTopic(
      title: 'Smart Mode monthly',
      badge: 'Smart Mode',
      icon: Icons.calendar_month_outlined,
      filter: _AiGuideFilter.smartMode,
      whereToUse: 'Chat tab-এ Smart Mode on করে monthly question করুন।',
      pattern: 'month/category questions',
      examples: [
        _GuideExample('এই মাসে কোথায় বেশি খরচ?'),
        _GuideExample('Food category breakdown দেখাও'),
        _GuideExample('এই মাসের top ৫ expense দেখাও'),
      ],
      steps: [
        _GuideStep('Question-এ month/category স্পষ্ট করুন।'),
        _GuideStep('Summary/category card দেখুন।'),
        _GuideStep('Actionable suggestion চাইলে follow-up করুন।'),
      ],
      tips: [
        'Specific category লিখলে better answer আসে।',
        'বাংলা বা English category name দুটোই ব্যবহার করতে পারেন।',
      ],
      checklist: ['Month', 'Category', 'Top expenses', 'Suggestion'],
    ),
    _AiGuideTopic(
      title: 'Smart Mode comparison',
      badge: 'Smart Mode',
      icon: Icons.stacked_line_chart_rounded,
      filter: _AiGuideFilter.smartMode,
      whereToUse: 'Chat tab-এ comparison question করুন।',
      pattern: 'compare period questions',
      examples: [
        _GuideExample('গত মাসের সাথে এই মাস compare করো'),
        _GuideExample('এই মাসে Transport খরচ কি বেড়েছে?'),
        _GuideExample('গত মাসের Food আর এই মাসের Food তুলনা করো'),
      ],
      steps: [
        _GuideStep('Compare করার দুইটা period লিখুন।'),
        _GuideStep('Category চাইলে category name দিন।'),
        _GuideStep('Difference amount/percent দেখে decision নিন।'),
      ],
      tips: [
        'গত মাস, এই মাস, today, week এসব শব্দ app বুঝতে পারে।',
        'Comparison useful হতে historical data দরকার।',
      ],
      checklist: ['Period', 'Category', 'Difference', 'Reason'],
    ),
    _AiGuideTopic(
      title: 'AI Budget Planner',
      badge: 'Settings',
      icon: Icons.account_balance_wallet_outlined,
      filter: _AiGuideFilter.planning,
      whereToUse: 'Settings -> AI Features -> AI Budget Planner।',
      pattern: 'income + spending history based plan',
      examples: [
        _GuideExample('Monthly income দিন, তারপর budget rule select করুন'),
        _GuideExample('Plan save করার আগে category budgets review করুন'),
      ],
      steps: [
        _GuideStep('Monthly income দিন।'),
        _GuideStep('Budget rule select করুন।'),
        _GuideStep('AI plan review করে active budget হিসেবে save করুন।'),
      ],
      tips: [
        'আগের expense history বেশি থাকলে plan realistic হয়।',
        'Category budget পরে manually adjust করতে পারবেন।',
      ],
      checklist: ['Income', 'Budget rule', 'Category limits', 'Savings target'],
    ),
    _AiGuideTopic(
      title: 'Prediction',
      badge: 'Analytics',
      icon: Icons.auto_graph_rounded,
      filter: _AiGuideFilter.planning,
      whereToUse: 'Analytics/Dashboard prediction card দেখুন।',
      pattern: 'forecast current month',
      examples: [
        _GuideExample('এই মাস শেষে কত খরচ হতে পারে?'),
        _GuideExample('Prediction card refresh করে trend/confidence দেখুন'),
      ],
      steps: [
        _GuideStep('Current month expenses add করুন।'),
        _GuideStep('Prediction card refresh করুন।'),
        _GuideStep('Trend, confidence, category forecast দেখুন।'),
      ],
      tips: [
        'মাসের শুরুতে confidence কম হতে পারে।',
        'Recent big expense forecast বদলে দিতে পারে।',
      ],
      checklist: [
        'Predicted total',
        'Confidence',
        'Trend',
        'Category forecast',
      ],
    ),
    _AiGuideTopic(
      title: 'Spending alerts',
      badge: 'Analytics',
      icon: Icons.warning_amber_rounded,
      filter: _AiGuideFilter.planning,
      whereToUse: 'Analytics alerts tab এবং notification দেখুন।',
      pattern: 'understand anomaly/budget warnings',
      examples: [
        _GuideExample('Large transaction alert dismiss করার আগে review করুন'),
        _GuideExample('Category spike হলে ওই category breakdown দেখুন'),
      ],
      steps: [
        _GuideStep('Alert open করে category/date/amount দেখুন।'),
        _GuideStep('Budget threshold হলে category budget adjust করুন।'),
        _GuideStep('False alarm হলে dismiss করুন।'),
      ],
      tips: [
        'Alerts local spending pattern থেকেও আসতে পারে।',
        'Budget alert পেতে category budget set থাকতে হবে।',
      ],
      checklist: ['Alert type', 'Amount', 'Category', 'Budget threshold'],
    ),
    _AiGuideTopic(
      title: 'Recurring expenses',
      badge: 'Settings',
      icon: Icons.sync_alt_rounded,
      filter: _AiGuideFilter.planning,
      whereToUse: 'Settings -> AI Features -> Regular Expenses।',
      pattern: 'detect repeated expenses',
      examples: [
        _GuideExample('Rent ৩ মাস save থাকলে monthly pattern detect হতে পারে'),
        _GuideExample('Internet bill, tuition, subscription track করুন'),
      ],
      steps: [
        _GuideStep('Similar expense at least 3 বার add করুন।'),
        _GuideStep('Regular Expenses screen থেকে detect/run করুন।'),
        _GuideStep('Next expected date এবং confidence review করুন।'),
      ],
      tips: [
        'Description/category consistent রাখলে pattern ভালো detect হয়।',
        'One-off expense recurring হিসেবে save করবেন না।',
      ],
      checklist: ['Description', 'Category', 'Frequency', 'Confidence'],
    ),
    _AiGuideTopic(
      title: 'Privacy and cost',
      badge: 'Safety',
      icon: Icons.privacy_tip_outlined,
      filter: _AiGuideFilter.safety,
      whereToUse: 'AI feature ব্যবহার করার আগে জানা দরকার।',
      pattern: 'what leaves device',
      examples: [
        _GuideExample('Chat text OpenAI-তে যায়'),
        _GuideExample('Voice audio transcription-এর জন্য OpenAI-তে যায়'),
        _GuideExample('Receipt OCR text OpenAI-তে যায়; OCR device-এ হয়'),
      ],
      steps: [
        _GuideStep('Sensitive info পাঠানোর আগে review করুন।'),
        _GuideStep('Smart Mode on থাকলে personal finance context যায়।'),
        _GuideStep('Token/cost estimate usage details থেকে দেখুন।'),
      ],
      tips: [
        'AI draft সবসময় manually verify করুন।',
        'Internet ছাড়া OpenAI-backed feature কাজ করবে না।',
      ],
      checklist: [
        'Sensitive text',
        'Smart Mode',
        'Network',
        'Review before save',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    AppPreferences.setAiGuidePromptSeen(true);
  }

  List<_AiGuideTopic> get _visibleTopics {
    if (_selectedFilter == _AiGuideFilter.all) {
      return _topics;
    }

    return _topics
        .where((topic) => topic.filter == _selectedFilter)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final visibleTopics = _visibleTopics;

    return AppPageScaffold(
      title: 'AI Guide',
      useGradientBackground: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          const _HeroGuideCard(quickExamples: _quickExamples),
          const SizedBox(height: AppSpacing.md),
          _FilterBar(
            selectedFilter: _selectedFilter,
            onSelected: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ব্যবহারযোগ্য pattern',
            style: AppTextStyles.sectionTitle.copyWith(
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'প্রতিটি example copy করে chat-এ paste করতে পারবেন।',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final topic in visibleTopics) ...[
            _GuideTopicCard(topic: topic),
            const SizedBox(height: AppSpacing.md),
          ],
          const _CommonMistakesCard(),
          const SizedBox(height: AppSpacing.md),
          const _PrivacyNoteCard(),
        ],
      ),
    );
  }
}

class _HeroGuideCard extends StatelessWidget {
  const _HeroGuideCard({required this.quickExamples});

  final List<String> quickExamples;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 3,
      gradient: context.primaryGradient,
      borderRadius: AppRadius.heroCardAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'AI দিয়ে কাজ দ্রুত করুন',
            style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'নিচের pattern copy করে chat-এ ব্যবহার করুন। Save করার আগে AI result review করুন।',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final label in quickExamples) _HeroPill(label: label),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(AppRadius.chip),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: AppTextStyles.chipLabel.copyWith(color: Colors.white),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selectedFilter, required this.onSelected});

  final _AiGuideFilter selectedFilter;
  final ValueChanged<_AiGuideFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final filter in _AiGuideFilter.values)
          AppChip(
            label: filter.label,
            icon: filter.icon,
            selected: selectedFilter == filter,
            onTap: () => onSelected(filter),
            compact: true,
          ),
      ],
    );
  }
}

class _GuideTopicCard extends StatelessWidget {
  const _GuideTopicCard({required this.topic});

  final _AiGuideTopic topic;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.appColors.primary.withValues(
                    alpha: context.isDarkMode ? 0.18 : 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  topic.icon,
                  color: context.appColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            topic.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: context.primaryTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _TopicBadge(label: topic.badge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      topic.whereToUse,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _PatternBlock(pattern: topic.pattern),
          const SizedBox(height: AppSpacing.md),
          _SectionLabel(label: 'Examples'),
          const SizedBox(height: AppSpacing.sm),
          for (final example in topic.examples) ...[
            _CopyableExampleCard(example: example),
            const SizedBox(height: AppSpacing.sm),
          ],
          _SectionLabel(label: 'Steps'),
          const SizedBox(height: AppSpacing.sm),
          for (final step in topic.steps)
            _GuideBullet(text: step.text, icon: Icons.arrow_forward_rounded),
          if (topic.tips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _SectionLabel(label: 'Tips'),
            const SizedBox(height: AppSpacing.sm),
            for (final tip in topic.tips)
              _GuideBullet(
                text: tip,
                icon: Icons.tips_and_updates_outlined,
                color: AppColors.warning,
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _Checklist(items: topic.checklist),
        ],
      ),
    );
  }
}

class _TopicBadge extends StatelessWidget {
  const _TopicBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.appColors.primary.withValues(
          alpha: context.isDarkMode ? 0.18 : 0.1,
        ),
        borderRadius: const BorderRadius.all(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: context.appColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PatternBlock extends StatelessWidget {
  const _PatternBlock({required this.pattern});

  final String pattern;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: const BorderRadius.all(AppRadius.input),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.6,
        ),
      ),
      child: Text(
        pattern,
        style: AppTextStyles.bodyMedium.copyWith(
          color: context.primaryTextColor,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CopyableExampleCard extends StatelessWidget {
  const _CopyableExampleCard({required this.example});

  final _GuideExample example;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.mutedSurfaceColor,
      borderRadius: const BorderRadius.all(AppRadius.input),
      child: InkWell(
        onTap: () => _copyExample(context),
        borderRadius: const BorderRadius.all(AppRadius.input),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  example.text,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.copy_rounded,
                size: 18,
                color: context.appColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyExample(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: example.text));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Example copy হয়েছে')));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: context.secondaryTextColor,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(
          alpha: context.isDarkMode ? 0.14 : 0.08,
        ),
        borderRadius: const BorderRadius.all(AppRadius.input),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save করার আগে দেখুন',
            style: AppTextStyles.chipLabel.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in items)
                AppChip(
                  label: item,
                  icon: Icons.check_rounded,
                  color: AppColors.success,
                  compact: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommonMistakesCard extends StatelessWidget {
  const _CommonMistakesCard();

  static const _mistakes = [
    'Amount অস্পষ্ট রাখা: "অনেক খরচ" না লিখে exact টাকা লিখুন।',
    'Date না বলা: পুরনো expense হলে "গতকাল" বা exact date লিখুন।',
    'Blurry receipt scan করা: total/date visible না থাকলে result ভুল হতে পারে।',
    'Smart Mode off রেখে personal finance question করা।',
    'AI draft review না করে save করা।',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_outlined, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Common mistakes',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final mistake in _mistakes)
            _GuideBullet(
              text: mistake,
              icon: Icons.error_outline_rounded,
              color: AppColors.warning,
            ),
        ],
      ),
    );
  }
}

class _PrivacyNoteCard extends StatelessWidget {
  const _PrivacyNoteCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: context.appColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Privacy note',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chat text, voice audio, receipt OCR text এবং Smart Mode context OpenAI-তে পাঠানো হয়। Receipt image থেকে text পড়া Google ML Kit দিয়ে device-এ হয়।',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  const _GuideBullet({
    required this.text,
    required this.icon,
    this.color = AppColors.success,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AiGuideFilter {
  all('সব', Icons.auto_awesome_rounded),
  add('যোগ করুন', Icons.add_circle_outline_rounded),
  scanVoice('Scan/Voice', Icons.document_scanner_outlined),
  smartMode('Smart Mode', Icons.psychology_outlined),
  planning('Planning', Icons.insights_outlined),
  safety('Safety', Icons.privacy_tip_outlined);

  const _AiGuideFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _AiGuideTopic {
  const _AiGuideTopic({
    required this.title,
    required this.badge,
    required this.icon,
    required this.filter,
    required this.whereToUse,
    required this.pattern,
    required this.examples,
    required this.steps,
    required this.tips,
    required this.checklist,
  });

  final String title;
  final String badge;
  final IconData icon;
  final _AiGuideFilter filter;
  final String whereToUse;
  final String pattern;
  final List<_GuideExample> examples;
  final List<_GuideStep> steps;
  final List<String> tips;
  final List<String> checklist;
}

class _GuideExample {
  const _GuideExample(this.text);

  final String text;
}

class _GuideStep {
  const _GuideStep(this.text);

  final String text;
}
