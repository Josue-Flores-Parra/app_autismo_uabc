import 'dart:math';

import 'package:appy/features/minigames/simple_selection_questions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildQuestionsFromData — generación desde minigamePool', () {
    test('genera exactamente 3 preguntas con ≥2 elementos', () {
      final data = <String, dynamic>{
        'minigamePool': [
          {'url': 'a.png', 'caption': 'A'},
          {'url': 'b.png', 'caption': 'B'},
          {'url': 'c.png', 'caption': 'C'},
        ],
      };

      final questions = buildQuestionsFromData(data, random: Random(42));

      expect(questions, hasLength(3));
      for (final q in questions) {
        expect(q.options, isNotEmpty);
        expect(q.maxAttempts, inInclusiveRange(1, 10));
        expect(q.question, startsWith(kSimpleSelectionQuestionPrefix));
        // La opción correcta debe estar presente entre las opciones
        expect(
          q.options.any((o) => o.imagePath.isNotEmpty && o.label.isNotEmpty),
          isTrue,
        );
        // correctIndex apunta a una opción existente
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
        // La opción señalada por correctIndex coincide con la del enunciado
        final target = q.question.substring(
          kSimpleSelectionQuestionPrefix.length,
        );
        expect(q.options[q.correctIndex].label, target);
      }
    });

    test('extrae las opciones de minigamePool y no de steps', () {
      final data = <String, dynamic>{
        'steps': [
          {'url': 'step-a.png', 'caption': 'Step A'},
          {'url': 'step-b.png', 'caption': 'Step B'},
        ],
        'minigamePool': [
          {'imagePath': 'x.png', 'caption': 'X'},
          {'imagePath': 'y.png', 'caption': 'Y'},
        ],
      };

      final questions = buildQuestionsFromData(data, random: Random(1));

      expect(questions, hasLength(3));
      for (final question in questions) {
        expect(
          question.options.map((option) => option.label),
          everyElement(isIn(<String>['X', 'Y'])),
        );
      }
    });

    test('retorna vacío con menos de 2 elementos sin recurrir a steps', () {
      final data = <String, dynamic>{
        'steps': [
          {'url': 'step-a.png', 'caption': 'Step A'},
          {'url': 'step-b.png', 'caption': 'Step B'},
        ],
        'minigamePool': [
          {'url': 'a.png', 'caption': 'A'},
        ],
      };

      expect(buildQuestionsFromData(data, random: Random(0)), isEmpty);
    });

    test('deduplica elementos por (imagePath, caption)', () {
      final data = <String, dynamic>{
        'minigamePool': [
          {'url': 'a.png', 'caption': 'A'},
          {'url': 'a.png', 'caption': 'A'}, // duplicado
          {'url': 'b.png', 'caption': 'B'},
        ],
      };

      final questions = buildQuestionsFromData(data, random: Random(7));

      expect(questions, hasLength(3));
      // Solo hay 2 imágenes únicas → cada pregunta usa solo A y B
      for (final q in questions) {
        expect(q.options, hasLength(2));
      }
    });
  });

  group('buildQuestionsFromData — campo questions explícito', () {
    test('parsea questions como List', () {
      final data = <String, dynamic>{
        'questions': [
          {
            'question': '¿Cuál es A?',
            'correctIndex': 0,
            'maxAttempts': 2,
            'options': [
              {'imagePath': 'a.png', 'label': 'A'},
              {'imagePath': 'b.png', 'label': 'B'},
            ],
          },
          {
            'question': '¿Cuál es B?',
            'correctIndex': 1,
            'maxAttempts': 3,
            'options': [
              {'imagePath': 'a.png', 'label': 'A'},
              {'imagePath': 'b.png', 'label': 'B'},
            ],
          },
        ],
      };

      final questions = buildQuestionsFromData(data);

      expect(questions, hasLength(2));
      expect(questions[0].question, '¿Cuál es A?');
      expect(questions[0].correctIndex, 0);
      expect(questions[0].maxAttempts, 2);
      expect(questions[0].options, hasLength(2));
      expect(questions[0].options[0].imagePath, 'a.png');
      expect(questions[1].correctIndex, 1);
    });

    test('parsea questions como Map (LinkedMap de Firestore)', () {
      final data = <String, dynamic>{
        'questions': <String, dynamic>{
          'q1': {
            'question': '¿Cuál?',
            'correctIndex': 0,
            'maxAttempts': 3,
            'options': [
              {'imagePath': 'a.png', 'label': 'A'},
            ],
          },
        },
      };

      final questions = buildQuestionsFromData(data);

      expect(questions, hasLength(1));
      expect(questions[0].question, '¿Cuál?');
      expect(questions[0].options, hasLength(1));
    });

    test('limita a un máximo de 3 preguntas', () {
      final data = <String, dynamic>{
        'questions': List.generate(5, (i) {
          return <String, dynamic>{
            'question': 'P$i',
            'correctIndex': 0,
            'maxAttempts': 3,
            'options': [
              {'imagePath': '$i.png', 'label': 'L$i'},
            ],
          };
        }),
      };

      final questions = buildQuestionsFromData(data);

      expect(questions, hasLength(3));
    });

    test('QuestionData.fromMap usa defaults para campos faltantes', () {
      final data = <String, dynamic>{
        'questions': [
          <String, dynamic>{}, // sin campos
        ],
      };

      final questions = buildQuestionsFromData(data);

      expect(questions, hasLength(1));
      expect(questions[0].question, '¿Cuál es la imagen correcta?');
      expect(questions[0].correctIndex, 0);
      expect(questions[0].maxAttempts, 3);
      expect(questions[0].options, isEmpty);
    });
  });

  group('buildQuestionsFromData — sin datos de preguntas', () {
    test('retorna vacío cuando no hay minigamePool ni questions', () {
      expect(buildQuestionsFromData(<String, dynamic>{}), isEmpty);
    });

    test('prioriza minigamePool sobre questions', () {
      final data = <String, dynamic>{
        'minigamePool': [
          {'url': 'a.png', 'caption': 'A'},
          {'url': 'b.png', 'caption': 'B'},
        ],
        'questions': [
          {
            'question': 'Ignorada',
            'correctIndex': 0,
            'maxAttempts': 3,
            'options': [],
          },
        ],
      };

      final questions = buildQuestionsFromData(data, random: Random(0));

      // La generación desde minigamePool produce 3 preguntas con prefijo.
      expect(questions, hasLength(3));
      expect(questions[0].question, startsWith(kSimpleSelectionQuestionPrefix));
    });
  });
}
