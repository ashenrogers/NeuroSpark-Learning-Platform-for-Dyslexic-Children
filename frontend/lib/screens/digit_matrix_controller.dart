import 'dart:math';

class DigitMatrixController {
  int level = 1;
  int score = 0;
  int attemptsLeft = 0;

  late int gridSize;
  late int memorizeSeconds;
  late List<List<int>> matrix;
  late int targetRow;
  late int targetCol;

  final Random _rand = Random();

  void startGame() {
    level = 1;
    score = 0;
    _configureLevel();
  }

  void advanceLevel() {
    level++;
    _configureLevel();
  }

  void _configureLevel() {
    if (level <= 3) {
      gridSize = 2;
      memorizeSeconds = 6 - level; // 5,4,3
      attemptsLeft = 999;
    } else if (level <= 5) {
      gridSize = 3;
      memorizeSeconds = 7 - level; // 4,3
      attemptsLeft = 3;
    } else {
      gridSize = 4;
      memorizeSeconds = 3;
      attemptsLeft = 1;
    }

    _generateMatrix();
    _pickTarget();
  }

  void _generateMatrix() {
    matrix = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => _rand.nextInt(10)),
    );
  }

  void _pickTarget() {
    targetRow = _rand.nextInt(gridSize);
    targetCol = _rand.nextInt(gridSize);
  }

  int get expectedDigit => matrix[targetRow][targetCol];

  String get targetLabel =>
      "Row ${targetRow + 1}, Column ${targetCol + 1}";
}
