
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz Application',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF7F7F1),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> categories = [
    'Science',
    'History',
    'Geography',
    'Technology',
  ];

  Map<String, List<Map<String, dynamic>>> questions = {
    'Science': [
      {
        'question': 'Which planet is known as the Red Planet?',
        'options': ['Earth', 'Mars', 'Jupiter', 'Venus'],
        'answer': 1,
      },
      {
        'question': 'What is the chemical formula of water?',
        'options': ['CO2', 'O2', 'H2O', 'NaCl'],
        'answer': 2,
      },
    ],
    'History': [
      {
        'question': 'Who was the first President of India?',
        'options': [
          'Nehru',
          'Rajendra Prasad',
          'Gandhi',
          'Sardar Patel'
        ],
        'answer': 1,
      },
      {
        'question': 'Who built the Taj Mahal?',
        'options': ['Akbar', 'Shah Jahan', 'Ashoka', 'Babur'],
        'answer': 1,
      },
    ],
    'Geography': [
      {
        'question': 'Which is the largest ocean?',
        'options': [
          'Indian Ocean',
          'Atlantic Ocean',
          'Pacific Ocean',
          'Arctic Ocean'
        ],
        'answer': 2,
      },
      {
        'question': 'Which is the highest mountain?',
        'options': ['K2', 'Mount Everest', 'Alps', 'Andes'],
        'answer': 1,
      },
    ],
    'Technology': [
      {
        'question': 'What does CPU stand for?',
        'options': [
          'Central Processing Unit',
          'Computer Personal Unit',
          'Control Program Unit',
          'Central Power Unit'
        ],
        'answer': 0,
      },
      {
        'question': 'Which language is used in Flutter?',
        'options': ['Java', 'Python', 'Dart', 'C'],
        'answer': 2,
      },
    ],
  };

  Map<String, int> bestScores = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedQuestions = prefs.getString('customQuestions');
    final savedScores = prefs.getString('bestScores');

    if (savedQuestions != null) {
      final decoded = jsonDecode(savedQuestions);
      for (var key in decoded.keys) {
        questions[key] = List<Map<String, dynamic>>.from(
          decoded[key].map((item) => Map<String, dynamic>.from(item)),
        );
        if (!categories.contains(key)) {
          categories.add(key);
        }
      }
    }

    if (savedScores != null) {
      bestScores = Map<String, int>.from(jsonDecode(savedScores));
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> saveQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = <String, dynamic>{};

    for (var category in questions.keys) {
      if (!['Science', 'History', 'Geography', 'Technology']
          .contains(category)) {
        custom[category] = questions[category];
      }
    }

    await prefs.setString('customQuestions', jsonEncode(custom));
  }

  Future<void> saveScore(String category, int score) async {
    final prefs = await SharedPreferences.getInstance();

    if (score > (bestScores[category] ?? 0)) {
      bestScores[category] = score;
      await prefs.setString('bestScores', jsonEncode(bestScores));
    }

    setState(() {});
  }

  void addQuestionDialog() {
    final categoryController = TextEditingController();
    final questionController = TextEditingController();
    final optionControllers =
        List.generate(4, (_) => TextEditingController());

    int correctAnswer = 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, updateDialog) {
            return AlertDialog(
              title: const Text('Add Custom Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                      ),
                    ),
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Question',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(4, (index) {
                      return TextField(
                        controller: optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                        ),
                      );
                    }),
                    const SizedBox(height: 15),
                    const Text('Select Correct Answer'),
                    DropdownButton<int>(
                      value: correctAnswer,
                      isExpanded: true,
                      items: List.generate(
                        4,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text('Option ${index + 1}'),
                        ),
                      ),
                      onChanged: (value) {
                        updateDialog(() {
                          correctAnswer = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final category =
                        categoryController.text.trim();
                    final question =
                        questionController.text.trim();

                    if (category.isEmpty ||
                        question.isEmpty ||
                        optionControllers.any(
                          (controller) =>
                              controller.text.trim().isEmpty,
                        )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                        ),
                      );
                      return;
                    }

                    if (!categories.contains(category)) {
                      categories.add(category);
                      questions[category] = [];
                    }

                    questions[category]!.add({
                      'question': question,
                      'options': optionControllers
                          .map((controller) => controller.text.trim())
                          .toList(),
                      'answer': correctAnswer,
                    });

                    await saveQuestions();

                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    setState(() {});

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Question added successfully!'),
                      ),
                    );
                  },
                  child: const Text('Add Question'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Master'),
        backgroundColor: const Color(0xFF355D43),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addQuestionDialog,
        backgroundColor: const Color(0xFF355D43),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Your Knowledge!',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Color(0xFF253329),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a category and start your quiz.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            const Text(
              'QUIZ CATEGORIES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return GestureDetector(
                    onTap: () {
                      if (questions[category]!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No questions in this category'),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizPage(
                            category: category,
                            questions: questions[category]!,
                            onComplete: saveScore,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.menu_book,
                            size: 38,
                            color: Color(0xFF496D50),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            category,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${questions[category]!.length} Questions',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Best: ${bestScores[category] ?? 0}',
                            style: const TextStyle(
                              color: Color(0xFF355D43),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Your best scores are saved automatically.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String category;
  final List<Map<String, dynamic>> questions;
  final Future<void> Function(String, int) onComplete;

  const QuizPage({
    super.key,
    required this.category,
    required this.questions,
    required this.onComplete,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int questionIndex = 0;
  int score = 0;
  int? selectedAnswer;

  void checkAnswer(int index) {
    if (selectedAnswer != null) return;

    setState(() {
      selectedAnswer = index;

      if (index ==
          widget.questions[questionIndex]['answer']) {
        score++;
      }
    });
  }

  Future<void> nextQuestion() async {
    if (questionIndex < widget.questions.length - 1) {
      setState(() {
        questionIndex++;
        selectedAnswer = null;
      });
    } else {
      await widget.onComplete(widget.category, score);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            score: score,
            total: widget.questions.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.questions[questionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: const Color(0xFF355D43),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${questionIndex + 1} of ${widget.questions.length}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: (questionIndex + 1) /
                  widget.questions.length,
              color: const Color(0xFF496D50),
            ),
            const SizedBox(height: 30),
            Text(
              current['question'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            ...List.generate(4, (index) {
              Color buttonColor = Colors.white;

              if (selectedAnswer != null) {
                if (index == current['answer']) {
                  buttonColor = Colors.green.shade100;
                } else if (index == selectedAnswer) {
                  buttonColor = Colors.red.shade100;
                }
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => checkAnswer(index),
                  child: Text(current['options'][index]),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedAnswer == null ? null : nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF355D43),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                child: Text(
                  questionIndex == widget.questions.length - 1
                      ? 'Finish Quiz'
                      : 'Next Question',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final int score;
  final int total;

  const ResultPage({
    super.key,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 85,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                'Quiz Completed!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Your Score: $score / $total',
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF355D43),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Percentage: ${(score / total * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF355D43),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomePage(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
