import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Pregnancy model
class Pregnancy extends Equatable {
  final String? id;
  final String userId;
  final DateTime lastMenstrualPeriod; // LMP
  final DateTime? dueDate;
  final int currentWeek;
  final int currentDay;
  final double? weight; // in kg
  final List<String> symptoms;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Pregnancy({
    this.id,
    required this.userId,
    required this.lastMenstrualPeriod,
    this.dueDate,
    required this.currentWeek,
    required this.currentDay,
    this.weight,
    this.symptoms = const [],
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Calculate due date from LMP (40 weeks)
  static DateTime calculateDueDate(DateTime lmp) {
    return lmp.add(const Duration(days: 280)); // 40 weeks
  }

  /// Calculate current week and day from LMP
  static Map<String, int> calculateCurrentWeek(DateTime lmp) {
    final now = DateTime.now();
    final difference = now.difference(lmp).inDays;
    final weeks = (difference / 7).floor();
    final days = difference % 7;
    return {'week': weeks, 'day': days};
  }

  /// Create from Firestore document
  factory Pregnancy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final lmp = (data['lastMenstrualPeriod'] as Timestamp).toDate();
    final weekDay = calculateCurrentWeek(lmp);

    return Pregnancy(
      id: doc.id,
      userId: data['userId'] as String,
      lastMenstrualPeriod: lmp,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : calculateDueDate(lmp),
      currentWeek: weekDay['week']!,
      currentDay: weekDay['day']!,
      weight: (data['weight'] as num?)?.toDouble(),
      symptoms: (data['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'lastMenstrualPeriod': Timestamp.fromDate(lastMenstrualPeriod),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'weight': weight,
      'symptoms': symptoms,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create copy with updated fields
  Pregnancy copyWith({
    DateTime? lastMenstrualPeriod,
    DateTime? dueDate,
    double? weight,
    List<String>? symptoms,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Pregnancy(
      id: id,
      userId: userId,
      lastMenstrualPeriod: lastMenstrualPeriod ?? this.lastMenstrualPeriod,
      dueDate: dueDate ?? this.dueDate,
      currentWeek: lastMenstrualPeriod != null
          ? calculateCurrentWeek(lastMenstrualPeriod)['week']!
          : currentWeek,
      currentDay: lastMenstrualPeriod != null
          ? calculateCurrentWeek(lastMenstrualPeriod)['day']!
          : currentDay,
      weight: weight ?? this.weight,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get trimester (1, 2, or 3)
  int get trimester {
    if (currentWeek < 13) return 1;
    if (currentWeek < 27) return 2;
    return 3;
  }

  /// Get pregnancy progress percentage
  double get progressPercentage {
    return (currentWeek / 40 * 100).clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        lastMenstrualPeriod,
        dueDate,
        currentWeek,
        currentDay,
        weight,
        symptoms,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Pregnancy milestone
class PregnancyMilestone {
  final int week;
  final String title;
  final String description;
  final String? content;
  final List<String> precautions;
  final List<String> expectations;
  final List<String> remedies;
  final String? notes;
  final String? imageUrl;

  const PregnancyMilestone({
    required this.week,
    required this.title,
    required this.description,
    this.content,
    this.precautions = const [],
    this.expectations = const [],
    this.remedies = const [],
    this.notes,
    this.imageUrl,
  });

  static List<PregnancyMilestone> getMilestones() {
    return pregnancyMilestone
        .map((m) => PregnancyMilestone(
              week: m['week'] as int,
              title: m['title'] as String,
              description: m['desc'] as String,
              content: m['content'] as String?,
              precautions: (m['precaution'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  const [],
              expectations: (m['expectations'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  const [],
              remedies: (m['remedies'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  const [],
              notes: m['notes'] as String?,
            ))
        .toList();
  }
}

final pregnancyMilestone = [
  {
    "week": 1,
    "title": "Preparing for Pregnancy",
    "desc":
        "Pregnancy week one begins the cycle as your body prepares for ovulation, hormone levels shift, and the uterine lining thickens, even though conception has not yet occurred and most women feel completely normal during this time",
    "content":
        "Week one is counted as the first week of pregnancy even though conception has not yet occurred. This timing is based on the first day of your last menstrual period, which doctors use to estimate due dates consistently. During this week, your body is essentially preparing for the possibility of pregnancy. Hormones such as estrogen and progesterone begin to regulate the menstrual cycle, and the uterus starts rebuilding its lining in anticipation of a fertilized egg. Physically, most women experience their regular period or its conclusion, with no pregnancy symptoms present. Emotionally and mentally, this is often a neutral phase, though planning and awareness may begin if pregnancy is intended. Lifestyle choices made now, such as improving nutrition, avoiding harmful substances, and managing stress, can positively affect the coming weeks. Even though pregnancy has not technically started, week one lays the biological foundation for everything that follows.",
    "precaution": [
      "Avoid smoking and alcohol",
      "Start or continue folic acid supplementation",
      "Maintain a balanced diet"
    ],
    "expectations": [
      "Menstrual bleeding",
      "No pregnancy symptoms",
      "Normal energy levels"
    ],
    "remedies": [
      "Rest if experiencing cramps",
      "Stay hydrated",
      "Light physical activity if comfortable"
    ],
    "notes": "Pregnancy dating begins before conception for medical accuracy."
  },
  {
    "week": 2,
    "title": "Ovulation and Fertilization Window",
    "desc":
        "Week two focuses on ovulation as an egg is released, fertilization may happen, and sperm can survive several days, making this the most important time for conception planning and natural body rhythms play a major role",
    "content":
        "During week two, ovulation usually occurs, releasing a mature egg from the ovary into the fallopian tube. This egg remains viable for about twenty-four hours, while sperm can survive for several days inside the reproductive tract. Because of this, pregnancy can occur even if intercourse happens a few days before ovulation. Hormonal changes may cause subtle signs such as mild pelvic discomfort, increased cervical mucus, or a slight rise in basal body temperature. Many women do not notice any clear physical changes, but internally the body is highly active. If fertilization occurs, genetic material from both parents combines, determining traits such as eye color and biological sex. Maintaining healthy habits during this week is particularly important, as early cellular development depends heavily on the environment created by the mother’s body.",
    "precaution": [
      "Avoid exposure to harmful chemicals",
      "Limit caffeine intake",
      "Continue prenatal vitamins"
    ],
    "expectations": [
      "Ovulation symptoms in some women",
      "No confirmed pregnancy yet",
      "Normal daily functioning"
    ],
    "remedies": [
      "Track ovulation signs if planning pregnancy",
      "Eat nutrient-rich foods",
      "Get adequate sleep"
    ],
    "notes":
        "Fertilization usually occurs during this week but is not immediately detectable."
  },
  {
    "week": 3,
    "title": "Fertilization and Early Cell Division",
    "desc":
        "During week three, fertilization typically occurs, the embryo starts dividing rapidly, travels toward the uterus, and prepares for implantation while early cellular development quietly begins without noticeable physical pregnancy symptoms for most women at this stage",
    "content":
        "Week three is when fertilization most often happens, marking the true biological beginning of pregnancy. Once a sperm fertilizes the egg, a single-celled zygote forms and immediately begins dividing into multiple cells. This cluster of cells, now called a blastocyst, travels through the fallopian tube toward the uterus over several days. Although monumental development is occurring at the microscopic level, there are usually no outward signs of pregnancy. Hormone production begins subtly, but levels are still too low to trigger symptoms or a positive pregnancy test. The embryo’s cells start specializing, setting the foundation for future organs and body systems. During this week, it is especially important to avoid harmful substances, as the embryo is extremely sensitive to environmental factors, even before implantation occurs.",
    "precaution": [
      "Avoid alcohol completely",
      "Do not take unapproved medications",
      "Reduce exposure to toxins"
    ],
    "expectations": [
      "No visible pregnancy signs",
      "Possible mild hormonal shifts",
      "Normal routine activities"
    ],
    "remedies": [
      "Maintain healthy meals",
      "Manage stress levels",
      "Stay physically active in moderation"
    ],
    "notes": "Most women are unaware they are pregnant during this week."
  },
  {
    "week": 4,
    "title": "Implantation and Hormonal Changes",
    "desc":
        "Week four marks implantation and the official start of pregnancy, as hormone levels rise, the placenta begins forming, and very early symptoms like fatigue or mild cramps may appear in some women during this sensitive phase",
    "content":
        "In week four, the blastocyst implants into the uterine wall, officially establishing pregnancy. This process triggers a rise in human chorionic gonadotropin, the hormone detected by pregnancy tests. The placenta starts developing, creating the vital connection that will supply oxygen and nutrients to the embryo. Some women notice early signs such as light spotting, mild cramping, breast tenderness, or unusual fatigue, while others feel no changes at all. Emotionally, this week can be significant, especially if pregnancy is confirmed. The embryo remains extremely small but is rapidly organizing its basic structure. Proper nutrition, hydration, and rest are particularly important now, as early development is sensitive to both physical and emotional stressors.",
    "precaution": [
      "Confirm pregnancy with a test if suspected",
      "Avoid strenuous activities",
      "Consult a healthcare provider if spotting is heavy"
    ],
    "expectations": [
      "Possible positive pregnancy test",
      "Mild cramps or spotting",
      "Increased tiredness"
    ],
    "remedies": [
      "Rest when fatigued",
      "Eat small, balanced meals",
      "Stay hydrated"
    ],
    "notes": "Implantation timing can vary slightly between individuals."
  },
  {
    "week": 5,
    "title": "Early Embryo Development",
    "desc":
        "In week five, the embryo develops a neural tube, the heart begins forming, hormones increase significantly, and pregnancy symptoms such as nausea, breast tenderness, and heightened tiredness often become noticeable for many first-time expectant mothers worldwide",
    "content":
        "Week five is a critical phase of early development. The neural tube, which will later form the brain and spinal cord, begins to develop, making folic acid especially important at this stage. The heart also starts forming and will soon begin beating. Hormone levels rise rapidly, often leading to noticeable pregnancy symptoms such as nausea, food aversions, breast sensitivity, and fatigue. Emotionally, mood swings may appear due to hormonal changes. Although the embryo is still very small, development is happening at an extraordinary pace. Many women schedule their first prenatal appointment around this time. Listening to your body, getting enough rest, and maintaining gentle routines can help manage early pregnancy discomforts effectively.",
    "precaution": [
      "Take folic acid daily",
      "Avoid raw or undercooked foods",
      "Limit physical overexertion"
    ],
    "expectations": [
      "Morning sickness may begin",
      "Increased need for rest",
      "Heightened sense of smell"
    ],
    "remedies": [
      "Eat small frequent meals",
      "Ginger or lemon for nausea",
      "Light stretching or walking"
    ],
    "notes": "Early prenatal care supports healthy development."
  },
  {
    "week": 6,
    "title": "Hormonal Surge and Rapid Growth",
    "desc":
        "Week six brings stronger pregnancy hormones, rapid embryo growth, early facial features, limb buds, and noticeable symptoms like nausea, fatigue, frequent urination, and emotional sensitivity as the body adapts to sustaining early pregnancy changes daily rhythms",
    "content":
        "During week six, the embryo grows rapidly, and early structures such as the brain, spinal cord, and facial features begin forming. Small limb buds appear, marking the early development of arms and legs. Hormonal levels increase significantly, often intensifying pregnancy symptoms. Many women experience nausea, vomiting, fatigue, and increased sensitivity to smells. Frequent urination may begin as blood flow to the pelvic area increases. Emotionally, mood swings and heightened sensitivity are common due to hormonal fluctuations. Although the embryo remains very small, the foundations for major organs are being established. This is a critical period for healthy development, making nutrition, rest, and prenatal vitamins especially important. Some women may notice mild abdominal discomfort, which is usually normal as the uterus begins to expand.",
    "precaution": [
      "Avoid alcohol and smoking",
      "Continue folic acid supplementation",
      "Limit exposure to strong odors"
    ],
    "expectations": [
      "Increased nausea",
      "Low energy levels",
      "Heightened emotional responses"
    ],
    "remedies": [
      "Eat small frequent meals",
      "Rest when tired",
      "Drink fluids regularly"
    ],
    "notes": "Symptoms vary widely and may intensify during this week."
  },
  {
    "week": 7,
    "title": "Brain Development and Growing Limbs",
    "desc":
        "Week seven features accelerating embryo development, forming brain regions, growing arms and legs, and intensifying maternal symptoms such as nausea, smell sensitivity, bloating, mood shifts, and exhaustion as hormonal levels continue rising steadily throughout early pregnancy",
    "content":
        "In week seven, the embryo’s brain develops rapidly, dividing into distinct regions that will later control movement, thinking, and sensory functions. Arms and legs grow longer, and joints begin forming. The heart continues beating steadily, supporting increased circulation. For many women, pregnancy symptoms become more pronounced. Nausea, food aversions, bloating, and extreme fatigue are common during this stage. Heightened sensitivity to smells may interfere with appetite and daily activities. Emotionally, mood changes may feel sudden or intense. These reactions are normal responses to hormonal shifts. Maintaining balanced nutrition, even if appetite is limited, helps support ongoing development. Gentle activity and adequate rest can reduce discomfort and improve energy levels during this demanding phase.",
    "precaution": [
      "Avoid greasy or triggering foods",
      "Stay hydrated",
      "Avoid self-medicating nausea"
    ],
    "expectations": [
      "Stronger nausea symptoms",
      "Emotional fluctuations",
      "Breast tenderness"
    ],
    "remedies": [
      "Ginger or peppermint tea",
      "Small bland meals",
      "Short rest breaks"
    ],
    "notes": "This week often represents peak discomfort for some women."
  },
  {
    "week": 8,
    "title": "Transition Toward Fetal Form",
    "desc":
        "During week eight, the embryo transitions toward a fetal form, organs organize, fingers appear, facial features refine, and many parents experience peak nausea, heartburn, fatigue, and heightened emotional responses during daily routines and personal health awareness",
    "content":
        "Week eight marks a visible shift in development as the embryo begins to resemble a recognizable human form. Fingers and toes become more defined, and facial features such as the nose, eyes, and ears continue to refine. Internal organs are organizing into their permanent positions. Despite this progress, the embryo remains highly sensitive to environmental factors. For the mother, symptoms such as nausea, heartburn, fatigue, and food aversions may reach their peak. Emotional sensitivity is also common, influenced by both hormonal changes and psychological adjustment to pregnancy. Appetite may fluctuate, making balanced nutrition challenging. Focusing on hydration, gentle meals, and adequate rest can support both physical comfort and emotional stability during this demanding week.",
    "precaution": [
      "Avoid spicy or acidic foods",
      "Continue prenatal care routines",
      "Minimize stress"
    ],
    "expectations": [
      "Strong nausea or heartburn",
      "Low stamina",
      "Emotional sensitivity"
    ],
    "remedies": [
      "Eat slowly",
      "Use pillows for comfort",
      "Practice light relaxation techniques"
    ],
    "notes": "Symptoms often peak around this time before gradually easing."
  },
  {
    "week": 9,
    "title": "Strengthening Muscles and Early Movement",
    "desc":
        "Week nine emphasizes continued fetal growth, strengthening muscles, early movement, and developing reproductive structures, while maternal symptoms may fluctuate, appetite changes occur, and emotional adjustment deepens as pregnancy becomes more real for many expectant parents emotionally",
    "content":
        "By week nine, the fetus begins strengthening muscles and may start making small movements, though these are not yet felt. Reproductive organs begin forming internally, though external sex characteristics are not visible yet. The head remains proportionally large as brain development continues at a rapid pace. For many women, symptoms may fluctuate rather than consistently worsen. Nausea may ease slightly or remain strong, and appetite can change unexpectedly. Emotionally, pregnancy often feels more real, prompting deeper reflection and adjustment. Fatigue remains common, and adequate rest is still essential. Maintaining gentle routines, nourishing meals, and emotional support can help stabilize both physical and mental well-being during this transitional stage.",
    "precaution": [
      "Avoid excessive physical strain",
      "Continue vitamin intake",
      "Monitor hydration levels"
    ],
    "expectations": [
      "Fluctuating nausea",
      "Mental adjustment",
      "Continued tiredness"
    ],
    "remedies": [
      "Light walking",
      "Protein-rich snacks",
      "Mindfulness breathing"
    ],
    "notes": "Symptom patterns may change week to week."
  },
  {
    "week": 10,
    "title": "End of Early Development Phase",
    "desc":
        "By week ten, the fetus has vital organs formed, bones harden, heartbeat strengthens, and pregnancy symptoms often stabilize slightly, marking the transition toward the end of the first trimester milestone with increasing reassurance confidence, growth, stability",
    "content":
        "Week ten represents an important milestone as most major organs are now formed and begin functioning in coordinated ways. Bones start hardening, and the heartbeat grows stronger and more regular. The fetus is now entering a stage of growth and refinement rather than initial formation. For many women, pregnancy symptoms such as nausea and fatigue may begin to stabilize or slightly improve, although this varies individually. Emotionally, reassurance often increases as the risk of early complications gradually decreases. Some women may feel renewed energy or optimism. Continuing healthy habits, attending prenatal appointments, and listening to the body’s needs remain essential as the first trimester approaches its conclusion.",
    "precaution": [
      "Maintain prenatal checkups",
      "Avoid harmful substances",
      "Support bone health with nutrition"
    ],
    "expectations": [
      "Possible symptom relief",
      "Emotional reassurance",
      "Improved daily functioning"
    ],
    "remedies": [
      "Balanced calcium intake",
      "Gentle exercise",
      "Consistent sleep schedule"
    ],
    "notes": "This week marks a shift toward steadier pregnancy progression."
  },
  {
    "week": 11,
    "title": "Growing Confidence and Stronger Development",
    "desc":
        "Week eleven brings steady fetal growth, clearer facial features, active organ function, and often easing nausea, while many mothers experience improved energy, emotional reassurance, and growing confidence as pregnancy progresses beyond the most fragile early stage",
    "content":
        "During week eleven, the fetus continues to grow steadily, with facial features becoming more defined and organs beginning to function more efficiently. Fingers and toes are fully separated, and early tooth buds form beneath the gums. The head remains large in proportion to the body, reflecting ongoing brain development. Many women begin to notice an improvement in early pregnancy symptoms, especially nausea and extreme fatigue. Energy levels may slowly return, and emotional reassurance often increases as this stage marks greater stability. Appetite may improve, making balanced nutrition easier to maintain. While the pregnancy may not yet be visible externally, internal changes are significant. Maintaining healthy routines and attending prenatal visits helps support continued growth and maternal well-being.",
    "precaution": [
      "Continue prenatal vitamins",
      "Avoid high-risk activities",
      "Maintain balanced nutrition"
    ],
    "expectations": [
      "Reduced nausea",
      "Improving energy",
      "Emotional reassurance"
    ],
    "remedies": [
      "Nutritious snacks",
      "Moderate physical activity",
      "Adequate rest"
    ],
    "notes": "Many women feel more optimistic during this stage."
  },
  {
    "week": 12,
    "title": "First Trimester Milestone",
    "desc":
        "Week twelve marks a major milestone as fetal organs are established, reflexes develop, and miscarriage risk decreases, while many mothers notice improved comfort, appetite, emotional balance, and readiness to share pregnancy news with others socially",
    "content":
        "Week twelve represents the conclusion of the first trimester, a milestone often associated with relief and reassurance. The fetus now has established organs, developing reflexes, and improved muscle tone. Facial features are well defined, and the intestines move into their proper position within the abdomen. For many women, nausea and fatigue continue to lessen, allowing daily activities to feel more manageable. Emotionally, this week often brings confidence and readiness to share pregnancy news more openly. Some physical changes, such as subtle weight gain or a fuller abdomen, may begin to appear. Continuing prenatal care and maintaining healthy habits remain important as the pregnancy transitions into the next phase.",
    "precaution": [
      "Attend scheduled prenatal visits",
      "Maintain hydration",
      "Avoid unnecessary stress"
    ],
    "expectations": [
      "Improved comfort",
      "Emotional stability",
      "Growing confidence"
    ],
    "remedies": ["Balanced meals", "Light exercise", "Mindful relaxation"],
    "notes": "Risk of early pregnancy loss decreases after this week."
  },
  {
    "week": 13,
    "title": "Beginning of the Second Trimester",
    "desc":
        "Week thirteen begins the second trimester, featuring rapid fetal growth, improved organ coordination, and often noticeable symptom relief, while mothers may feel increased energy, clearer focus, and renewed motivation to plan for pregnancy and childbirth",
    "content":
        "Week thirteen marks the start of the second trimester, a phase many women find more comfortable. The fetus continues rapid growth, with bones hardening and muscles strengthening. Internal organs work together more efficiently, and the nervous system becomes increasingly coordinated. For the mother, nausea often decreases significantly, and energy levels rise. Appetite may improve, making it easier to meet nutritional needs. Emotionally, this week often brings renewed motivation and a clearer sense of planning for the months ahead. Some women notice early physical changes, such as a slightly rounded abdomen. This stage is ideal for focusing on healthy routines, gentle exercise, and emotional preparation for ongoing pregnancy changes.",
    "precaution": [
      "Avoid overexertion",
      "Continue healthy diet",
      "Stay hydrated"
    ],
    "expectations": ["Increased energy", "Reduced nausea", "Improved mood"],
    "remedies": [
      "Regular walks",
      "Protein-rich meals",
      "Consistent sleep patterns"
    ],
    "notes": "Many women feel noticeably better during this week."
  },
  {
    "week": 14,
    "title": "Visible Growth and Strengthening",
    "desc":
        "During week fourteen, fetal movements increase internally, muscles strengthen, facial expressions form, and maternal comfort often improves, while growing confidence, appetite, and emotional connection help many parents feel more engaged with pregnancy progress",
    "content":
        "In week fourteen, the fetus becomes more active, practicing movements that help strengthen muscles and joints, although these motions are still too subtle to be felt externally. Facial muscles develop further, allowing for simple expressions. The body grows more proportionate as the neck lengthens. For many women, pregnancy feels more manageable, with stable energy levels and improved appetite. Emotional connection to the pregnancy often deepens as physical comfort increases. Skin changes, such as a healthy glow or mild pigmentation shifts, may appear. Maintaining hydration, nutrition, and moderate activity supports both maternal comfort and healthy fetal development during this increasingly enjoyable stage.",
    "precaution": [
      "Protect skin from sun exposure",
      "Avoid skipping meals",
      "Maintain posture awareness"
    ],
    "expectations": [
      "Stable energy",
      "Improved appetite",
      "Emotional connection"
    ],
    "remedies": [
      "Stretching exercises",
      "Healthy snacks",
      "Supportive footwear"
    ],
    "notes": "Physical comfort often improves significantly around this time."
  },
  {
    "week": 15,
    "title": "Strengthened Senses and Awareness",
    "desc":
        "Week fifteen highlights sensory development as hearing structures mature, bones strengthen, and maternal awareness grows, with many women feeling steady energy, emotional calm, and anticipation as pregnancy progresses deeper into the second trimester stage",
    "content":
        "By week fifteen, the fetus’s sensory systems continue developing, with structures related to hearing becoming more defined. Bones strengthen further, and muscles continue to grow in coordination. Although movements remain mostly unfelt, internal activity increases. For the mother, energy levels are often steady, and emotional calm may replace earlier uncertainty. Appetite remains strong, supporting healthy weight gain and nutritional balance. Some women notice minor physical changes such as nasal congestion or skin sensitivity. This is a good time to reinforce healthy habits, attend routine prenatal checkups, and begin thinking about long-term preparation for childbirth and parenting. Overall, this week reflects a period of stability and forward momentum.",
    "precaution": [
      "Avoid loud prolonged noise exposure",
      "Maintain regular prenatal care",
      "Stay physically active safely"
    ],
    "expectations": [
      "Stable energy",
      "Growing anticipation",
      "Emotional balance"
    ],
    "remedies": ["Prenatal yoga", "Hydration focus", "Relaxation breathing"],
    "notes": "Second trimester stability continues to build."
  },
  {
    "week": 16,
    "title": "Growing Strength and Early Movements",
    "desc":
        "Week sixteen brings stronger fetal muscles, improving coordination, and early movements, while many mothers feel increased energy, emotional stability, and subtle physical changes as the pregnancy becomes more visible and comfortable in daily routines",
    "content":
        "During week sixteen, the fetus continues to grow stronger, with muscles and bones developing better coordination. Small movements occur more frequently, though many women may not yet clearly recognize them. Facial features continue refining, and the head becomes more proportionate to the body. For mothers, energy levels are often improved, and early pregnancy discomforts usually remain minimal. Some women notice subtle physical changes, such as a more noticeable abdomen or mild back discomfort as posture adjusts. Emotionally, confidence and connection to the pregnancy often deepen. Maintaining proper posture, gentle exercise, and balanced nutrition helps support physical comfort and healthy development during this stage.",
    "precaution": [
      "Avoid lifting heavy objects",
      "Practice good posture",
      "Maintain prenatal appointments"
    ],
    "expectations": [
      "Improved physical comfort",
      "Possible subtle movements",
      "Stable emotional state"
    ],
    "remedies": ["Light stretching", "Supportive seating", "Regular hydration"],
    "notes": "Some women may start feeling early fetal flutters."
  },
  {
    "week": 17,
    "title": "Increasing Awareness and Body Changes",
    "desc":
        "Week seventeen focuses on continued fetal growth, fat development, and improving temperature regulation, while mothers may notice body changes, shifting balance, increased appetite, and growing awareness of pregnancy during daily physical activities",
    "content":
        "By week seventeen, the fetus begins developing fat stores that help regulate body temperature after birth. The skeleton continues hardening, and joints grow more flexible. Internally, organ systems work more efficiently together. For mothers, physical changes may become more noticeable, including a shifting center of gravity and mild back or hip discomfort. Appetite often increases, supporting ongoing growth. Emotionally, pregnancy awareness becomes stronger, and many women feel more connected to their baby. Gentle movement, posture awareness, and adequate rest can help manage physical adjustments. This week encourages adapting routines to accommodate a changing body.",
    "precaution": [
      "Avoid sudden movements",
      "Wear supportive shoes",
      "Maintain balanced nutrition"
    ],
    "expectations": [
      "Increased appetite",
      "Body balance adjustments",
      "Growing emotional connection"
    ],
    "remedies": [
      "Prenatal stretches",
      "Healthy frequent meals",
      "Proper sleep positioning"
    ],
    "notes": "Body awareness increases as pregnancy progresses."
  },
  {
    "week": 18,
    "title": "Recognizing Baby Movements",
    "desc":
        "Week eighteen often introduces noticeable fetal movements, strengthening muscles, and developing hearing, while mothers experience excitement, emotional bonding, physical adjustments, and a deeper sense of reassurance as pregnancy milestones become more tangible",
    "content":
        "Week eighteen is exciting for many mothers because fetal movements may become noticeable for the first time, often described as flutters or gentle taps. These movements help strengthen muscles and improve coordination. Hearing structures develop further, allowing the fetus to begin responding to sounds. For mothers, emotional bonding often deepens as movements provide reassurance of growth and health. Physical adjustments continue, including mild backaches or round ligament discomfort. Maintaining gentle activity, stretching, and proper hydration supports comfort. This stage often feels rewarding as pregnancy experiences become more tangible and emotionally meaningful.",
    "precaution": [
      "Avoid loud sustained noises",
      "Practice gentle movements",
      "Monitor posture"
    ],
    "expectations": [
      "First noticeable movements",
      "Emotional excitement",
      "Mild physical discomfort"
    ],
    "remedies": [
      "Prenatal yoga",
      "Warm compress for aches",
      "Relaxation breathing"
    ],
    "notes": "Movement patterns vary among individuals."
  },
  {
    "week": 19,
    "title": "Rapid Growth and Sensory Development",
    "desc":
        "During week nineteen, rapid fetal growth continues, sensory systems mature, protective skin coating forms, and mothers may experience skin changes, shifting posture, increased appetite, and emotional anticipation as pregnancy progresses steadily forward",
    "content":
        "In week nineteen, the fetus grows rapidly, and sensory systems such as taste and smell continue developing. A protective coating begins forming on the skin, helping guard against the surrounding fluid. The body becomes more proportionate, and movements grow stronger. For mothers, physical changes may include skin stretching, mild itching, or pigmentation changes. Appetite remains strong, supporting increased nutritional needs. Emotionally, anticipation and planning often increase as pregnancy becomes more visible. Proper skin care, hydration, and posture awareness can improve comfort. This week emphasizes steady progress and continued adaptation to physical changes.",
    "precaution": [
      "Moisturize skin regularly",
      "Avoid excessive sun exposure",
      "Maintain proper nutrition"
    ],
    "expectations": [
      "Skin changes",
      "Stronger movements",
      "Increased planning"
    ],
    "remedies": [
      "Gentle moisturizers",
      "Stretching routines",
      "Hydration focus"
    ],
    "notes": "Skin changes are common and usually temporary."
  },
  {
    "week": 20,
    "title": "Halfway Point and Detailed Assessment",
    "desc":
        "Week twenty marks the pregnancy midpoint, with detailed fetal assessment, consistent movements, continued organ maturation, and maternal confidence growth, as many parents feel reassurance, excitement, and motivation while reaching this significant milestone together",
    "content":
        "Week twenty is a major milestone, marking the halfway point of pregnancy. The fetus continues developing steadily, with organs maturing and movements becoming more regular. Many women undergo a detailed anatomical assessment around this time, providing reassurance about growth and development. For mothers, physical comfort remains generally good, though backaches or leg discomfort may increase as weight shifts. Emotionally, confidence and excitement often grow as pregnancy feels more real and stable. This stage encourages continued healthy habits, gentle exercise, and open communication with healthcare providers as preparations gradually begin for the months ahead.",
    "precaution": [
      "Attend scheduled assessments",
      "Avoid prolonged standing",
      "Support back posture"
    ],
    "expectations": [
      "Consistent fetal movement",
      "Emotional reassurance",
      "Increased physical awareness"
    ],
    "remedies": [
      "Prenatal massage",
      "Supportive footwear",
      "Regular rest breaks"
    ],
    "notes": "This week represents a meaningful halfway milestone."
  },
  {
    "week": 21,
    "title": "Refined Movements and Body Awareness",
    "desc":
        "Week twenty one highlights refined fetal movements, growing coordination, and digestive system development, while mothers notice stronger kicks, skin stretching, posture changes, and increased awareness of daily comfort, nutrition, and physical balance needs",
    "content":
        "During week twenty one, the fetus continues refining movements, with improved coordination and muscle control. Digestive system development progresses as the intestines practice movement. Kicks and stretches often feel stronger and more defined, making pregnancy feel increasingly interactive. For mothers, physical awareness grows as the abdomen expands and posture shifts. Skin stretching may cause mild itching, and maintaining hydration becomes more important. Emotionally, many women feel a deepening connection as movements become more predictable. Gentle exercise, proper posture, and balanced nutrition help support comfort and ongoing development during this active phase of pregnancy.",
    "precaution": [
      "Avoid sudden posture changes",
      "Support skin hydration",
      "Maintain gentle exercise routines"
    ],
    "expectations": [
      "Stronger fetal movements",
      "Skin stretching sensations",
      "Growing physical awareness"
    ],
    "remedies": [
      "Moisturizing lotions",
      "Prenatal stretching",
      "Adequate fluid intake"
    ],
    "notes": "Movement strength varies but often increases noticeably."
  },
  {
    "week": 22,
    "title": "Sensory Awareness and Steady Growth",
    "desc":
        "Week twenty two focuses on steady fetal growth, enhanced sensory awareness, and continued fat accumulation, while mothers may notice stretch marks, mild back discomfort, emotional engagement, and a stronger sense of routine adjustment during pregnancy progression",
    "content":
        "By week twenty two, the fetus continues gaining weight and refining sensory awareness, responding more clearly to sound and movement. Fat accumulation supports temperature regulation and overall growth. For mothers, physical changes such as stretch marks or mild back discomfort may appear as the body adapts. Emotional engagement often increases, with routines adjusting to accommodate physical needs. Maintaining supportive footwear, gentle movement, and proper rest helps manage discomfort. Balanced nutrition and hydration remain essential as growth accelerates. This week emphasizes adapting daily habits to support both physical comfort and emotional well-being.",
    "precaution": [
      "Wear supportive shoes",
      "Avoid prolonged standing",
      "Continue skin care routines"
    ],
    "expectations": [
      "Noticeable growth",
      "Skin changes",
      "Routine adjustments"
    ],
    "remedies": ["Supportive cushions", "Light walking", "Stretch mark care"],
    "notes": "Body changes become more apparent during this period."
  },
  {
    "week": 23,
    "title": "Lung Development and Active Movement",
    "desc":
        "Week twenty three emphasizes lung development, increasing fetal strength, and active movement patterns, while mothers experience stronger kicks, occasional discomfort, emotional reassurance, and growing confidence as pregnancy advances through the second trimester",
    "content":
        "In week twenty three, the fetus focuses on lung development, practicing breathing-like movements that prepare for life after birth. Muscles grow stronger, and movements become more pronounced and rhythmic. For mothers, kicks may feel sharp or surprising, sometimes causing brief discomfort. Emotionally, reassurance often grows as movements become consistent. Physical adjustments continue, including mild swelling or posture changes. Maintaining hydration, gentle exercise, and adequate rest supports comfort and circulation. This week highlights increasing vitality and the growing presence of the baby within daily life.",
    "precaution": [
      "Monitor swelling",
      "Avoid restrictive clothing",
      "Maintain hydration"
    ],
    "expectations": [
      "Strong fetal movements",
      "Occasional discomfort",
      "Emotional reassurance"
    ],
    "remedies": ["Elevate legs", "Prenatal yoga", "Relaxation techniques"],
    "notes": "Consistent movement patterns are reassuring signs."
  },
  {
    "week": 24,
    "title": "Viability Awareness and Sensory Response",
    "desc":
        "Week twenty four brings increased awareness of fetal viability, enhanced sensory responses, and continued lung maturation, while mothers feel emotional connection, physical adjustment, mild swelling, and a growing sense of responsibility and preparation",
    "content":
        "Week twenty four is often associated with increased awareness of fetal viability as lung and organ development continues. The fetus responds more clearly to sounds and external stimuli. For mothers, emotional connection deepens, often accompanied by a growing sense of responsibility and preparation. Physical changes such as mild swelling in the feet or hands may appear due to fluid retention. Maintaining gentle activity, proper hydration, and rest helps manage discomfort. This stage emphasizes monitoring body signals and communicating with healthcare providers about any concerns.",
    "precaution": [
      "Monitor swelling patterns",
      "Avoid dehydration",
      "Attend routine checkups"
    ],
    "expectations": [
      "Enhanced sensory responses",
      "Emotional bonding",
      "Mild swelling"
    ],
    "remedies": [
      "Compression socks",
      "Rest with feet elevated",
      "Hydration focus"
    ],
    "notes": "This week often brings emotional reassurance and awareness."
  },
  {
    "week": 25,
    "title": "Strengthening Systems and Emotional Bonding",
    "desc":
        "Week twenty five highlights strengthening body systems, continued brain growth, and regular movement patterns, while mothers experience emotional bonding, occasional fatigue, physical adjustments, and an increasing focus on comfort and preparation strategies",
    "content":
        "By week twenty five, the fetus continues strengthening body systems, with rapid brain growth and improving neurological coordination. Movement patterns become regular and familiar, often providing reassurance. For mothers, emotional bonding deepens, and attention shifts toward comfort and preparation. Occasional fatigue may return as physical demands increase. Maintaining supportive routines, gentle exercise, and balanced nutrition supports ongoing well-being. This stage encourages mindful rest, posture awareness, and emotional preparation for the upcoming third trimester.",
    "precaution": [
      "Avoid overexertion",
      "Support sleep posture",
      "Maintain nutrition balance"
    ],
    "expectations": [
      "Regular movements",
      "Emotional bonding",
      "Occasional fatigue"
    ],
    "remedies": [
      "Body pillows",
      "Gentle stretching",
      "Consistent rest periods"
    ],
    "notes": "Preparation and comfort become growing priorities."
  },
  {
    "week": 26,
    "title": "Rapid Brain Growth and Stronger Kicks",
    "desc":
        "Week twenty six features rapid brain development, increased nerve activity, and stronger fetal kicks, while mothers notice heightened movement patterns, occasional sleep disruption, physical stretching, and growing awareness of body limits and rest needs",
    "content":
        "During week twenty six, the fetus experiences rapid brain development, with increasing nerve connections that support coordinated movement and sensory awareness. Kicks and stretches often feel stronger and more frequent, sometimes disrupting sleep. For mothers, physical stretching becomes more noticeable as the uterus expands, which may cause mild discomfort in the abdomen or back. Sleep patterns may change due to movement, heartburn, or finding comfortable positions. Emotionally, awareness of the baby’s presence becomes constant and reassuring. Supporting rest through proper sleep positioning, gentle evening routines, and listening to the body’s limits helps maintain comfort as physical demands increase.",
    "precaution": [
      "Avoid sleeping flat on the back",
      "Support the abdomen during movement",
      "Monitor sleep quality"
    ],
    "expectations": [
      "Stronger fetal kicks",
      "Sleep interruptions",
      "Increased body awareness"
    ],
    "remedies": [
      "Use pregnancy pillows",
      "Stretch before bedtime",
      "Practice calming routines"
    ],
    "notes": "Sleep positioning becomes increasingly important."
  },
  {
    "week": 27,
    "title": "Transition Toward the Third Trimester",
    "desc":
        "Week twenty seven marks the transition toward the third trimester, with continued brain maturation, lung development, and stronger movements, while mothers may feel renewed fatigue, emotional sensitivity, and a heightened focus on comfort and health routines",
    "content":
        "Week twenty seven represents the final week of the second trimester and a transition toward the third. The fetus continues developing brain structures and lungs, practicing breathing movements more frequently. Movements remain strong and regular. For mothers, fatigue may return as physical demands increase, and emotional sensitivity may resurface. Concentration on comfort, sleep, and physical support becomes more important. Gentle exercise, balanced nutrition, and stress management help maintain energy. This week encourages preparing mentally and physically for the final phase of pregnancy while continuing consistent prenatal care.",
    "precaution": [
      "Avoid overexertion",
      "Maintain regular prenatal visits",
      "Monitor energy levels"
    ],
    "expectations": [
      "Return of fatigue",
      "Consistent fetal movement",
      "Emotional sensitivity"
    ],
    "remedies": [
      "Scheduled rest breaks",
      "Light activity routines",
      "Mindful breathing"
    ],
    "notes": "This week bridges the second and third trimesters."
  },
  {
    "week": 28,
    "title": "Beginning of the Third Trimester",
    "desc":
        "Week twenty eight begins the third trimester, highlighting rapid fetal growth, maturing senses, and stronger responses, while mothers experience increased physical strain, sleep challenges, emotional awareness, and a growing focus on preparation and support systems",
    "content":
        "Week twenty eight marks the start of the third trimester, a period of rapid fetal growth and increasing physical demands. The fetus’s senses continue maturing, with clearer responses to sound, light, and movement. For mothers, physical strain may increase, including back discomfort, leg cramps, and difficulty sleeping. Emotionally, awareness shifts toward preparation and support, as the final weeks approach. Maintaining hydration, gentle movement, and consistent rest becomes essential. Prenatal appointments may become more frequent, reinforcing monitoring and reassurance during this important phase.",
    "precaution": [
      "Avoid prolonged standing",
      "Monitor swelling or discomfort",
      "Maintain hydration"
    ],
    "expectations": [
      "Increased physical strain",
      "Sleep difficulties",
      "Preparation mindset"
    ],
    "remedies": ["Leg stretches", "Warm baths", "Supportive sleep positioning"],
    "notes": "Third trimester adjustments begin here."
  },
  {
    "week": 29,
    "title": "Strengthening Bones and Muscles",
    "desc":
        "Week twenty nine emphasizes strengthening bones and muscles, continued weight gain, and developing immune support, while mothers experience posture challenges, increased fatigue, emotional anticipation, and an ongoing need for rest and body support",
    "content":
        "During week twenty nine, the fetus continues gaining weight, strengthening bones and muscles in preparation for birth. The immune system develops further, receiving protective support. Movements remain strong but may feel more constrained as space decreases. For mothers, posture challenges increase due to the growing abdomen, often causing back or hip discomfort. Fatigue may become more noticeable, reinforcing the need for rest and pacing daily activities. Emotionally, anticipation builds as the pregnancy enters its final stretch. Supportive footwear, posture awareness, and regular rest periods help manage discomfort effectively.",
    "precaution": [
      "Support posture during sitting",
      "Avoid sudden twisting movements",
      "Monitor energy levels"
    ],
    "expectations": [
      "Continued fetal growth",
      "Posture-related discomfort",
      "Rising anticipation"
    ],
    "remedies": [
      "Prenatal support belts",
      "Gentle stretching",
      "Short rest breaks"
    ],
    "notes": "Comfort strategies become increasingly important."
  },
  {
    "week": 30,
    "title": "Preparing for Final Growth Phase",
    "desc":
        "Week thirty focuses on preparing for the final growth phase, with continued brain development, strong movements, and maternal physical adjustments, as comfort management, emotional readiness, and planning for delivery gradually become central priorities",
    "content":
        "By week thirty, the fetus continues rapid brain development and maintains strong, regular movements, though space becomes more limited. The body prepares for final growth and refinement before birth. For mothers, physical adjustments intensify, including back pressure, heartburn, or shortness of breath during activity. Emotional readiness often increases, and attention shifts toward planning for delivery and postpartum needs. Prioritizing comfort, rest, and gentle activity supports physical well-being. This stage encourages finalizing support systems and maintaining open communication with healthcare providers.",
    "precaution": [
      "Avoid heavy lifting",
      "Monitor breathing comfort",
      "Attend prenatal checkups"
    ],
    "expectations": [
      "Strong fetal movements",
      "Physical adjustments",
      "Increased planning focus"
    ],
    "remedies": [
      "Upright sitting posture",
      "Slow paced movement",
      "Relaxation techniques"
    ],
    "notes": "Preparation becomes a key theme from this point onward."
  },
  {
    "week": 31,
    "title": "Optical Development and Lung Maturation",
    "desc":
        "Baby opens eyes and practices breathing as lungs continue to mature for life outside the womb.",
    "content":
        "At week 31, your baby's brain is working overtime to develop the complex connections needed for life after birth. They're now able to open and close their eyes, noticing light filtering through the uterine wall. The lungs are producing surfactant, a crucial substance that keeps the air sacs from sticking together. Maternal symptoms like heartburn and Braxton Hicks contractions may become more frequent as your body prepares for labor. Staying active with gentle stretches and maintaining a balanced diet remains key.",
    "precaution": [
      "Watch for signs of preterm labor",
      "Avoid lying on your back for long periods"
    ],
    "expectations": [
      "Frequent urination",
      "Shortness of breath",
      "Active fetal movements"
    ],
    "remedies": [
      "Eat small meals to combat heartburn",
      "Use a pregnancy pillow for better sleep"
    ],
    "notes": "Fetal sleep cycles are becoming more regular."
  },
  {
    "week": 32,
    "title": "Practice Breathing and Rapid Weight Gain",
    "desc":
        "Baby practices breathing movements and gains weight rapidly as fat stores begin to fill out their skin.",
    "content":
        "Week 32 sees the baby gaining weight at a rate of about half a pound per week. This layer of fat under the skin makes them look more like a newborn. The baby is practicing breathing by inhaling amniotic fluid, which helps the lungs expand and strengthen. You might feel more pressure on your diaphragm and ribs as the uterus reaches its highest point. It's a good time to finalize your birth plan and pack your hospital bag.",
    "precaution": [
      "Stay hydrated to minimize swelling",
      "Monitor kick counts daily"
    ],
    "expectations": [
      "Lower back pain",
      "Intensified Braxton Hicks",
      "Nesting instinct begins"
    ],
    "remedies": [
      "Elevate feet to reduce swelling",
      "Practice pelvic tilts for back relief"
    ],
    "notes":
        "The baby can now track light and respond to noises outside the womb."
  },
  {
    "week": 33,
    "title": "Maturing Immune System and Bone Hardening",
    "desc":
        "Baby's immune system matures and bones harden, while the brain continues developing billions of complex neural connections.",
    "content":
        "At week 33, the baby's skull bones are still soft and flexible, which will allow them to pass through the birth canal more easily. Other bones are hardening significantly. The immune system is receiving precious antibodies from the mother through the placenta. You may experience carpal tunnel symptoms as fluid retention puts pressure on the nerves in your wrists. Focus on gentle wrist stretches and continuing your prenatal exercises.",
    "precaution": [
      "Avoid excessive salt to control fluid retention",
      "Watch for vision changes"
    ],
    "expectations": [
      "Wrist tingling or numbness",
      "Increased pelvic pressure",
      "Vivid dreams"
    ],
    "remedies": [
      "Wear wrist splints if needed at night",
      "Stay cool to manage body heat"
    ],
    "notes": "The baby is likely in a head-down position now or very soon."
  },
  {
    "week": 34,
    "title": "Central Nervous System Maturation",
    "desc":
        "Central nervous system and lungs are almost fully mature, and baby continues filling out with essential protective fat.",
    "content":
        "Week 34 is a major milestone for lung and central nervous system development. If born now, babies usually thrive with minimal support. The baby is focusing on growing and maturing their organs. You might feel more tired again, similar to the first trimester, as your body carries the extra weight. It's important to pace yourself and listen to your body's signals for rest.",
    "precaution": [
      "Rest frequently to avoid burnout",
      "Consult your doctor about Group B Strep testing"
    ],
    "expectations": [
      "Increased fatigue",
      "Heavy feeling in the pelvis",
      "Sensitive skin"
    ],
    "remedies": [
      "Take short naps during the day",
      "Use gentle moisturizers for itchy skin"
    ],
    "notes": "Baby’s vision is now well-developed."
  },
  {
    "week": 35,
    "title": "Rapid Brain Development and Weight Gain",
    "desc":
        "Baby's brain is developing at a staggering rate, and they are gaining weight quickly as they prepare for birth.",
    "content":
        "At week 35, the baby's brain development is incredibly rapid. They're gaining about an ounce of weight every day. Most of this growth is fat and brain tissue. The baby's movements might feel more like rolls and shoves than sharp kicks due to the lack of space. You might find yourself the target of frequent bathroom trips as the baby's head presses against your bladder.",
    "precaution": [
      "Monitor for excessive swelling or sudden weight gain",
      "Stay close to home"
    ],
    "expectations": [
      "Frequent urination",
      "Difficulty getting comfortable at night",
      "Colostrum leakage"
    ],
    "remedies": [
      "Use nursing pads if needed",
      "Lean forward while urinating to empty the bladder"
    ],
    "notes": "The baby's kidneys are fully developed now."
  },
  {
    "week": 36,
    "title": "Moving into Birth Position",
    "desc":
        "Baby often moves into the head-down position and begins \"dropping\" into the pelvis as birth draws nearer.",
    "content":
        "Week 36 marks the start of the final month. The baby may \"drop\" or engage in the pelvis, which might make breathing easier but walking more uncomfortable. This is known as lightening. Most babies are in the head-down position by now. Your prenatal appointments will likely become weekly from this point on. Make sure your hospital route is planned and you're ready for the big day.",
    "precaution": ["Know the signs of labor", "Avoid heavy exertion"],
    "expectations": [
      "Increased pelvic pressure",
      "Waddling walk",
      "Easier breathing"
    ],
    "remedies": [
      "Use a maternity belt for pelvic support",
      "Practice deep breathing"
    ],
    "notes": "Your baby is almost considered \"early term.\""
  },
  {
    "week": 37,
    "title": "Early Term Milestone",
    "desc":
        "Baby is officially \"early term\" as lungs and brain continue final maturation for a healthy transition at birth.",
    "content":
        "At week 37, your baby is considered \"early term.\" This means their systems are generally mature enough to survive outside the womb, though every day counts for brain and lung refinement. They're practicing their sucking and swallowing reflexes. You might notice an increase in vaginal discharge (the \"show\" or mucus plug) as your cervix begins to thin and prepare for labor.",
    "precaution": [
      "Have your hospital bag at the door",
      "Finalize childcare or pet care plans"
    ],
    "expectations": [
      "Increased discharge",
      "Braxton Hicks may become more regular",
      "Nesting instinct peaks"
    ],
    "remedies": ["Rest as much as possible", "Keep meals light and frequent"],
    "notes": "This is a great time to review your postpartum recovery plan."
  },
  {
    "week": 38,
    "title": "Organ Refinement and Fat Accumulation",
    "desc":
        "Baby is busy refining their organs and accumulating fat, while the placenta continues provided vital nutrients and oxygen.",
    "content":
        "Week 38 is about fine-tuning. The baby's organs are fully formed but continue to mature. Their grasp is now firm! The lanugo (fine hair) that covered their body is mostly gone. Your body is producing more hormones that help ripen the cervix. You may feel \"electric\" zaps in your pelvis as the baby's head presses on nerves. This is normal but can be startling.",
    "precaution": [
      "Monitor baby's movement patterns closely",
      "Stay hydrated and nourished"
    ],
    "expectations": [
      "Lightning pain in the pelvis",
      "Loss of mucus plug",
      "Increased anxiety or excitement"
    ],
    "remedies": [
      "Pelvic tilts can help baby move into position",
      "Listen to calming music"
    ],
    "notes": "Your baby’s eye color might change after birth."
  },
  {
    "week": 39,
    "title": "Full Term Milestone",
    "desc":
        "Baby is now \"full term\" and ready to meet you, with all systems fully functional for life in the world.",
    "content":
        "Week 39 is officially \"full term.\" The baby is about the size of a small watermelon and is just waiting for the signal to start labor. Their brain and lungs are fully developed. You might be feeling very impatient and uncomfortable now. Try to stay calm and focus on the exciting fact that you will meet your baby very soon. Keep track of any regular, intensifying contractions.",
    "precaution": [
      "Go to the hospital if your water breaks",
      "Monitor contraction frequency"
    ],
    "expectations": [
      "Intense pressure",
      "Loss of appetite or cleansing diarrhea",
      "Emotional readiness"
    ],
    "remedies": [
      "Gentle walking can help labor progress",
      "Try to sleep whenever you can"
    ],
    "notes": "The baby's skin is now smooth and soft."
  },
  {
    "week": 40,
    "title": "Official Due Date",
    "desc":
        "The official due date arrives! Baby is fully grown and ready to emerge whenever the time is right.",
    "content":
        "Welcome to week 40! Only about 5% of babies are actually born on their due date, so don't be discouraged if you're still waiting. Your baby is perfectly formed and ready for life. The placenta is still working, but doctors will monitor you more closely now. Use this time to rest, watch movies, and enjoy some quiet before the baby arrives. You're doing a great job!",
    "precaution": [
      "Maintain all monitoring appointments",
      "Don't try unverified induction methods"
    ],
    "expectations": [
      "Feeling very pregnant",
      "Frequent check-ins from others",
      "Ready for labor"
    ],
    "remedies": ["Bounce on a birth ball", "Keep a positive mindset"],
    "notes": "The baby is roughly 19-21 inches long now."
  },
  {
    "week": 41,
    "title": "Late Term Readiness",
    "desc":
        "Baby is \"late term\" and being closely monitored as your healthcare team discusses potential induction options for safety.",
    "content":
        "At week 41, you are officially overdue. Your doctor will likely schedule tests (like a non-stress test or ultrasound) to ensure the baby and placenta are still doing well. They may also discuss induction options. While it's tough to wait, remember that your baby is just taking a little extra time to get ready. Stay active and keep your bags ready—the wait is almost over!",
    "precaution": [
      "Follow all medical advice for monitoring",
      "Watch for any decrease in fetal movement"
    ],
    "expectations": [
      "Impatience",
      "Frequent medical tests",
      "Discussions about induction"
    ],
    "remedies": ["Treat yourself to a nice meal", "Stay focused on the goal"],
    "notes": "Post-term babies often have longer fingernails and less vernix."
  }
];

/// Kick counter entry
class KickEntry extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final DateTime date;
  final DateTime time;
  final int kickCount;
  final Duration? duration; // Time taken to count kicks
  final String? notes;
  final DateTime createdAt;

  const KickEntry({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.date,
    required this.time,
    required this.kickCount,
    this.duration,
    this.notes,
    required this.createdAt,
  });

  factory KickEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KickEntry(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      time: (data['time'] as Timestamp).toDate(),
      kickCount: data['kickCount'] as int,
      duration: data['duration'] != null
          ? Duration(seconds: data['duration'] as int)
          : null,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'date': Timestamp.fromDate(date),
      'time': Timestamp.fromDate(time),
      'kickCount': kickCount,
      'duration': duration?.inSeconds,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        date,
        time,
        kickCount,
        duration,
        notes,
        createdAt
      ];
}

/// Contraction timer entry
class ContractionEntry extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final Duration? interval; // Time since last contraction
  final int? intensity; // 1-10 scale
  final String? notes;
  final DateTime createdAt;

  const ContractionEntry({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.startTime,
    this.endTime,
    this.duration,
    this.interval,
    this.intensity,
    this.notes,
    required this.createdAt,
  });

  factory ContractionEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContractionEntry(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      duration: data['duration'] != null
          ? Duration(seconds: data['duration'] as int)
          : null,
      interval: data['interval'] != null
          ? Duration(seconds: data['interval'] as int)
          : null,
      intensity: data['intensity'] as int?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration?.inSeconds,
      'interval': interval?.inSeconds,
      'intensity': intensity,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        startTime,
        endTime,
        duration,
        interval,
        intensity,
        notes,
        createdAt
      ];
}

/// Pregnancy appointment
class PregnancyAppointment extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final String? location;
  final String? doctorName;
  final String? appointmentType; // ultrasound, checkup, test, etc.
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PregnancyAppointment({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.title,
    this.description,
    required this.scheduledDate,
    this.location,
    this.doctorName,
    this.appointmentType,
    this.isCompleted = false,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PregnancyAppointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyAppointment(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      location: data['location'] as String?,
      doctorName: data['doctorName'] as String?,
      appointmentType: data['appointmentType'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'title': title,
      'description': description,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'location': location,
      'doctorName': doctorName,
      'appointmentType': appointmentType,
      'isCompleted': isCompleted,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        title,
        description,
        scheduledDate,
        location,
        doctorName,
        appointmentType,
        isCompleted,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Pregnancy medication reminder
class PregnancyMedication extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final String medicationName;
  final String? dosage;
  final String frequency; // daily, twice daily, weekly, etc.
  final DateTime startDate;
  final DateTime? endDate;
  final List<int> timesOfDay; // Hours of day (0-23)
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PregnancyMedication({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.medicationName,
    this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.timesOfDay = const [],
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PregnancyMedication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyMedication(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      medicationName: data['medicationName'] as String,
      dosage: data['dosage'] as String?,
      frequency: data['frequency'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      timesOfDay: (data['timesOfDay'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      isActive: data['isActive'] as bool? ?? true,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'timesOfDay': timesOfDay,
      'isActive': isActive,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        medicationName,
        dosage,
        frequency,
        startDate,
        endDate,
        timesOfDay,
        isActive,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Pregnancy journal entry
class PregnancyJournalEntry extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final DateTime date;
  final String? mood; // happy, anxious, excited, tired, etc.
  final List<String> symptoms;
  final String? journalText;
  final List<String>? photoUrls;
  final int? sleepHours;
  final String? sleepQuality; // good, fair, poor
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PregnancyJournalEntry({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.date,
    this.mood,
    this.symptoms = const [],
    this.journalText,
    this.photoUrls,
    this.sleepHours,
    this.sleepQuality,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PregnancyJournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyJournalEntry(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      mood: data['mood'] as String?,
      symptoms: (data['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      journalText: data['journalText'] as String?,
      photoUrls: (data['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sleepHours: data['sleepHours'] as int?,
      sleepQuality: data['sleepQuality'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'date': Timestamp.fromDate(date),
      'mood': mood,
      'symptoms': symptoms,
      'journalText': journalText,
      'photoUrls': photoUrls,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        date,
        mood,
        symptoms,
        journalText,
        photoUrls,
        sleepHours,
        sleepQuality,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Weight entry for pregnancy
class PregnancyWeightEntry extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final DateTime date;
  final double weight; // in kg
  final String? notes;
  final DateTime createdAt;

  const PregnancyWeightEntry({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.date,
    required this.weight,
    this.notes,
    required this.createdAt,
  });

  factory PregnancyWeightEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyWeightEntry(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, pregnancyId, date, weight, notes, createdAt];
}

/// Baby name suggestion
class BabyName extends Equatable {
  final String name;
  final String gender; // boy, girl, unisex
  final String? meaning;
  final String? origin;
  final int? popularity; // 1-100

  const BabyName({
    required this.name,
    required this.gender,
    this.meaning,
    this.origin,
    this.popularity,
  });

  @override
  List<Object?> get props => [name, gender, meaning, origin, popularity];
}

/// Hospital checklist item
class HospitalChecklistItem extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final String category; // documents, personal_items, baby_items, etc.
  final String item;
  final bool isChecked;
  final int? priority; // 1-5
  final DateTime createdAt;
  final DateTime? updatedAt;

  const HospitalChecklistItem({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.category,
    required this.item,
    this.isChecked = false,
    this.priority,
    required this.createdAt,
    this.updatedAt,
  });

  factory HospitalChecklistItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HospitalChecklistItem(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      category: data['category'] as String,
      item: data['item'] as String,
      isChecked: data['isChecked'] as bool? ?? false,
      priority: data['priority'] as int?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'category': category,
      'item': item,
      'isChecked': isChecked,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        category,
        item,
        isChecked,
        priority,
        createdAt,
        updatedAt
      ];
}
