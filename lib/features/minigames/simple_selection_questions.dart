import 'dart:math';

/*
Lógica pura de generación de preguntas para SimpleSelectionMinigame.

Se extrae del StatefulWidget para poder testearla de forma aislada (sin
Flutter, sin TTS, sin contexto de build). Las tres entradas soportadas son:

1. `steps` / `pictogramSteps`: genera dinámicamente 3 preguntas a partir de
   los captions e imágenes de los pasos.
2. `questions` (List o Map de Firestore): parsea preguntas explícitas.
3. Ninguna de las anteriores: `buildQuestionsFromData` retorna una lista
   vacía y el minijuego provee una pregunta por defecto.
*/

const String kSimpleSelectionQuestionPrefix =
    'Cuál es la imagen correcta para el paso... ';

/// Opción de selección: una imagen con su etiqueta.
class SelectionOption {
  final String imagePath;
  final String label;

  SelectionOption({required this.imagePath, required this.label});

  factory SelectionOption.fromMap(Map<String, dynamic> map) {
    return SelectionOption(
      imagePath: map['imagePath'] as String? ?? '',
      label: map['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'imagePath': imagePath, 'label': label};
  }
}

/// Datos de una pregunta de selección simple.
class QuestionData {
  final String question;
  final int correctIndex;
  final int maxAttempts;
  final List<SelectionOption> options;

  QuestionData({
    required this.question,
    required this.correctIndex,
    required this.maxAttempts,
    required this.options,
  });

  factory QuestionData.fromMap(Map<String, dynamic> map) {
    // Manejar options de manera robusta: puede venir como List o como Map
    // (LinkedMap de Firestore).
    List<dynamic> optionsData = [];
    try {
      final rawOptions = map['options'];
      if (rawOptions == null) {
        optionsData = [];
      } else if (rawOptions is List) {
        optionsData = rawOptions;
      } else if (rawOptions is Map) {
        optionsData = rawOptions.values.toList();
      } else {
        optionsData = [];
      }
    } catch (e) {
      optionsData = [];
    }

    final options = optionsData.map((opt) {
      if (opt is Map<String, dynamic>) {
        return SelectionOption.fromMap(opt);
      }
      return SelectionOption(imagePath: opt.toString(), label: '');
    }).toList();

    return QuestionData(
      question: map['question'] as String? ?? '¿Cuál es la imagen correcta?',
      correctIndex: _parseInt(map['correctIndex'], 0),
      maxAttempts: _parseInt(map['maxAttempts'], 3),
      options: options,
    );
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class _SimpleSelectionStep {
  final String imagePath;
  final String caption;

  _SimpleSelectionStep({required this.imagePath, required this.caption});
}

int parseIntValue(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/*
Extrae steps válidos desde actividadData (`steps` o `pictogramSteps`).
Descarta entradas sin imagePath o caption y deduplica por (imagePath, caption).
*/
List<_SimpleSelectionStep> parseStepsForSimpleSelection(
  Map<String, dynamic> data,
) {
  final rawSteps = data['steps'] ?? data['pictogramSteps'];
  if (rawSteps is! List) return [];

  final unique = <String, _SimpleSelectionStep>{};
  for (final raw in rawSteps) {
    if (raw is! Map) continue;
    final step = Map<String, dynamic>.from(raw);
    final imagePath =
        (step['url'] ??
                step['imagePath'] ??
                step['src'] ??
                step['pictogramaUrl'] ??
                '')
            .toString()
            .trim();
    final caption = (step['caption'] ?? step['label'] ?? step['text'] ?? '')
        .toString()
        .trim();

    if (imagePath.isEmpty || caption.isEmpty) continue;
    final key = '$imagePath|$caption';
    unique[key] = _SimpleSelectionStep(imagePath: imagePath, caption: caption);
  }

  return unique.values.toList();
}

/*
Genera exactamente 3 preguntas usando captions e imágenes de `steps`.
Retorna una lista vacía si hay menos de 2 steps.
*/
List<QuestionData> buildQuestionsFromSteps(
  Map<String, dynamic> data, {
  Random? random,
}) {
  final steps = parseStepsForSimpleSelection(data);
  if (steps.length < 2) return [];

  final rnd = random ?? Random();
  final shuffledTargets = List<_SimpleSelectionStep>.from(steps)..shuffle(rnd);
  final maxAttempts = parseIntValue(
    data['maxAttempts'],
    fallback: 3,
  ).clamp(1, 10);

  final questions = <QuestionData>[];
  for (int i = 0; i < 3; i++) {
    final target = shuffledTargets[i % shuffledTargets.length];
    final distractors =
        steps
            .where(
              (s) =>
                  s.imagePath != target.imagePath ||
                  s.caption != target.caption,
            )
            .toList()
          ..shuffle(rnd);

    final options = <SelectionOption>[
      SelectionOption(imagePath: target.imagePath, label: target.caption),
    ];

    final distractorCount = (steps.length >= 4) ? 3 : (steps.length - 1);
    options.addAll(
      distractors
          .take(distractorCount)
          .map(
            (s) => SelectionOption(imagePath: s.imagePath, label: s.caption),
          ),
    );

    options.shuffle(rnd);
    final correctIndex = options.indexWhere(
      (o) => o.imagePath == target.imagePath && o.label == target.caption,
    );

    questions.add(
      QuestionData(
        question: '$kSimpleSelectionQuestionPrefix${target.caption}',
        correctIndex: correctIndex < 0 ? 0 : correctIndex,
        maxAttempts: maxAttempts,
        options: options,
      ),
    );
  }

  return questions;
}

/*
Parsea el campo `questions` (formato nuevo) que puede venir como List o como
Map (LinkedMap de Firestore). Limita a un máximo de 3 preguntas.
*/
List<QuestionData> parseQuestionsField(Map<String, dynamic> data) {
  List<dynamic> questionsData = [];
  try {
    final rawQuestions = data['questions'];
    if (rawQuestions == null) {
      questionsData = [];
    } else if (rawQuestions is List) {
      questionsData = rawQuestions;
    } else if (rawQuestions is Map) {
      questionsData = rawQuestions.values.toList();
    } else {
      questionsData = [];
    }
  } catch (e) {
    questionsData = [];
  }

  var questions = questionsData.map((q) {
    if (q is Map) {
      return QuestionData.fromMap(Map<String, dynamic>.from(q));
    }
    return QuestionData(
      question: '¿Cuál es la imagen correcta?',
      correctIndex: 0,
      maxAttempts: 3,
      options: [],
    );
  }).toList();

  if (questions.length > 3) {
    questions.removeRange(3, questions.length);
  }
  return questions;
}

/*
Construye la lista de preguntas para el minijuego a partir de actividadData.

Prioridad:
1. Generar preguntas dinámicamente desde `steps`/`pictogramSteps`.
2. Parsear el campo `questions` (List o Map).
3. Retornar una lista vacía — el llamador provee una pregunta por defecto.
*/
List<QuestionData> buildQuestionsFromData(
  Map<String, dynamic> data, {
  Random? random,
}) {
  final fromSteps = buildQuestionsFromSteps(data, random: random);
  if (fromSteps.isNotEmpty) return fromSteps;

  if (data.containsKey('questions')) {
    return parseQuestionsField(data);
  }

  return [];
}
