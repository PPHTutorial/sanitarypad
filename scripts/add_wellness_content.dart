/// Script to add sample wellness content to Firestore
///
/// Usage:
/// 1. Make sure Firebase is initialized in your project
/// 2. Run: dart scripts/add_wellness_content.dart
///
/// Note: This script requires Firebase Admin SDK or you can manually
/// add the content via Firebase Console using the data structure below.
library;


void main() async {
  // Initialize Firebase (you may need to adjust this based on your setup)
  // For production, use Firebase Admin SDK or add via Console

  print('Wellness Content Data Structure:');
  print('================================\n');

  // Sample Tips
  final tips = [
    {
      'title': 'Stay Hydrated During Your Period',
      'content':
          'Drinking plenty of water can help reduce bloating and ease menstrual cramps. Aim for 8-10 glasses per day, and consider adding a slice of lemon for extra flavor.',
      'type': 'tip',
      'category': 'menstrual_health',
      'tags': ['hydration', 'period', 'health', 'bloating'],
      'isPremium': false,
      'readTime': 1,
    },
    {
      'title': 'Track Your Cycle Regularly',
      'content':
          'Consistent cycle tracking helps you understand your body better. Log your period dates, symptoms, and mood to identify patterns and predict your next cycle.',
      'type': 'tip',
      'category': 'menstrual_health',
      'tags': ['tracking', 'cycle', 'health'],
      'isPremium': false,
      'readTime': 2,
    },
    {
      'title': 'Gentle Exercise Can Help',
      'content':
          'Light exercises like walking, yoga, or stretching can help alleviate period cramps and improve your mood. Listen to your body and don\'t overexert yourself.',
      'type': 'tip',
      'category': 'wellness',
      'tags': ['exercise', 'period', 'cramps', 'yoga'],
      'isPremium': false,
      'readTime': 1,
    },
    {
      'title': 'Maintain Good Hygiene',
      'content':
          'Change your sanitary pad every 4-6 hours to prevent infections and odors. Wash your hands before and after changing pads, and use gentle, unscented products.',
      'type': 'tip',
      'category': 'hygiene',
      'tags': ['hygiene', 'health', 'period'],
      'isPremium': false,
      'readTime': 2,
    },
  ];

  // Sample Articles
  final articles = [
    {
      'title': 'Understanding Your Menstrual Cycle',
      'content':
          '''Your menstrual cycle is a complex process that prepares your body for pregnancy each month. It typically lasts 28 days, but can range from 21 to 35 days.

The cycle consists of four main phases:

1. **Menstrual Phase (Days 1-5)**: Your period occurs when the uterine lining sheds. This is when you experience bleeding.

2. **Follicular Phase (Days 1-13)**: Your body prepares for ovulation by developing follicles in the ovaries. Estrogen levels rise.

3. **Ovulation (Day 14)**: An egg is released from the ovary. This is your most fertile time.

4. **Luteal Phase (Days 15-28)**: The uterine lining thickens in preparation for a potential pregnancy. If no pregnancy occurs, the cycle repeats.

Understanding these phases can help you track your fertility, manage symptoms, and maintain better overall health.''',
      'type': 'article',
      'category': 'menstrual_health',
      'tags': ['cycle', 'menstruation', 'health', 'fertility'],
      'isPremium': false,
      'readTime': 5,
    },
    {
      'title': 'PMS: Symptoms and Management',
      'content':
          '''Premenstrual Syndrome (PMS) affects many women in the days leading up to their period. Common symptoms include:

- Mood swings and irritability
- Bloating and water retention
- Fatigue and sleep disturbances
- Food cravings
- Headaches
- Breast tenderness
- Acne breakouts

**Management Tips:**
- Maintain a balanced diet rich in fruits, vegetables, and whole grains
- Exercise regularly to boost mood and reduce bloating
- Get adequate sleep (7-9 hours per night)
- Practice stress-reduction techniques like meditation or deep breathing
- Consider supplements like magnesium or vitamin B6 (consult your doctor first)

If symptoms are severe, consult a healthcare provider as you may have PMDD (Premenstrual Dysphoric Disorder).''',
      'type': 'article',
      'category': 'menstrual_health',
      'tags': ['pms', 'symptoms', 'health', 'management'],
      'isPremium': false,
      'readTime': 6,
    },
    {
      'title': 'Pregnancy Nutrition Essentials',
      'content':
          '''During pregnancy, proper nutrition is crucial for both you and your baby's health. Here are key nutrients to focus on:

**Essential Nutrients:**
- **Folic Acid**: Prevents neural tube defects. Found in leafy greens, citrus fruits, and fortified cereals.
- **Iron**: Prevents anemia. Found in lean meats, beans, and spinach.
- **Calcium**: Builds strong bones. Found in dairy products, fortified plant milks, and leafy greens.
- **Protein**: Essential for growth. Found in lean meats, fish, eggs, beans, and nuts.
- **Omega-3 Fatty Acids**: Supports brain development. Found in fish (low mercury), walnuts, and flaxseeds.

**Foods to Avoid:**
- Raw or undercooked meats and fish
- Unpasteurized dairy products
- High-mercury fish (shark, swordfish, king mackerel)
- Excessive caffeine
- Alcohol

Always consult with your healthcare provider for personalized nutrition advice.''',
      'type': 'article',
      'category': 'pregnancy',
      'tags': ['pregnancy', 'nutrition', 'health', 'diet'],
      'isPremium': false,
      'readTime': 7,
    },
  ];

  // Sample Meditations
  final meditations = [
    {
      'title': '5-Minute Period Pain Relief Meditation',
      'content':
          '''Find a comfortable position, either sitting or lying down. Close your eyes and take three deep breaths.

**Step 1: Breathing (1 minute)**
Focus on your breath, inhaling slowly through your nose and exhaling through your mouth. Count each breath up to 10, then start over.

**Step 2: Body Scan (2 minutes)**
Slowly scan your body from head to toe. Notice any areas of tension or pain. Acknowledge them without judgment, then gently release the tension with each exhale.

**Step 3: Visualization (2 minutes)**
Imagine a warm, soothing light entering your body with each inhale, flowing to areas of discomfort. As you exhale, visualize the pain leaving your body as a dark cloud, dissolving into the air.

**Step 4: Return (30 seconds)**
Slowly bring your awareness back to the room. Wiggle your fingers and toes, and when ready, open your eyes.

Practice this daily, especially during your period, for best results.''',
      'type': 'meditation',
      'category': 'wellness',
      'tags': ['meditation', 'pain_relief', 'relaxation', 'period'],
      'isPremium': false,
      'readTime': 5,
    },
    {
      'title': 'Morning Affirmation Meditation',
      'content': '''Start your day with positive energy and self-love.

**Preparation:**
Sit comfortably with your back straight. Close your eyes and place your hands on your heart.

**Affirmations (repeat each 3 times):**
- "I am strong, capable, and beautiful"
- "My body is healthy and my mind is at peace"
- "I honor my body's natural rhythms"
- "I am grateful for my health and well-being"
- "I treat myself with kindness and compassion"

After each affirmation, take a deep breath and feel the words resonate within you. Visualize yourself embodying these qualities throughout your day.

End with three deep breaths and open your eyes, ready to embrace the day with confidence.''',
      'type': 'meditation',
      'category': 'mental_health',
      'tags': ['meditation', 'affirmation', 'self_love', 'morning'],
      'isPremium': false,
      'readTime': 5,
    },
    {
      'title': 'Stress Relief Breathing Exercise',
      'content':
          '''This simple breathing technique can help reduce stress and anxiety anytime, anywhere.

**4-7-8 Breathing Technique:**

1. **Inhale** through your nose for 4 counts
2. **Hold** your breath for 7 counts
3. **Exhale** through your mouth for 8 counts

Repeat this cycle 4-8 times.

**Tips:**
- Focus on the counting to keep your mind from wandering
- Make the exhale longer than the inhale to activate your body's relaxation response
- Practice in a quiet space initially, then use it anywhere you feel stressed

This technique activates your parasympathetic nervous system, promoting calm and reducing stress hormones.''',
      'type': 'meditation',
      'category': 'mental_health',
      'tags': ['meditation', 'breathing', 'stress_relief', 'anxiety'],
      'isPremium': false,
      'readTime': 3,
    },
  ];

  print('Sample Tips (${tips.length}):');
  for (var tip in tips) {
    print('\n${tip['title']}');
    print('Type: ${tip['type']}');
    print('Category: ${tip['category']}');
    print('Tags: ${tip['tags']}');
    print('Read Time: ${tip['readTime']} minutes');
    print('Premium: ${tip['isPremium']}');
  }

  print('\n\nSample Articles (${articles.length}):');
  for (var article in articles) {
    print('\n${article['title']}');
    print('Type: ${article['type']}');
    print('Category: ${article['category']}');
    print('Tags: ${article['tags']}');
    print('Read Time: ${article['readTime']} minutes');
    print('Premium: ${article['isPremium']}');
  }

  print('\n\nSample Meditations (${meditations.length}):');
  for (var meditation in meditations) {
    print('\n${meditation['title']}');
    print('Type: ${meditation['type']}');
    print('Category: ${meditation['category']}');
    print('Tags: ${meditation['tags']}');
    print('Read Time: ${meditation['readTime']} minutes');
    print('Premium: ${meditation['isPremium']}');
  }

  print('\n\nTo add this content to Firestore:');
  print('1. Go to Firebase Console > Firestore Database');
  print('2. Navigate to the "wellnessContent" collection');
  print('3. Click "Add document"');
  print('4. Add the fields shown above');
  print('5. Set "createdAt" to the current timestamp');
  print('6. Save the document');
  print('\nOr use Firebase Admin SDK to add programmatically.');
}
