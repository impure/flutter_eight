
import 'package:flutter/material.dart';
import 'package:flutter_eight/Logic/Puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

const int HIGHEST_NUM = 18;

void main() {
	test("Check Magic Squares", () {

		for (int i = 0; i < magicSquares.length; i++) {
			expect(magicSquares[i][0] + magicSquares[i][1] + magicSquares[i][2], magicSquares[i][3] + magicSquares[i][4] + magicSquares[i][5]);
			expect(magicSquares[i][0] + magicSquares[i][1] + magicSquares[i][2], magicSquares[i][6] + magicSquares[i][7] + magicSquares[i][8]);
			expect(magicSquares[i][0] + magicSquares[i][1] + magicSquares[i][2], magicSquares[i][0] + magicSquares[i][4] + magicSquares[i][8]);
			expect(magicSquares[i][0] + magicSquares[i][1] + magicSquares[i][2], magicSquares[i][2] + magicSquares[i][4] + magicSquares[i][6]);
			expect(magicSquares[i][0] + magicSquares[i][1] + magicSquares[i][2], magicSquares[i][0] + magicSquares[i][3] + magicSquares[i][6]);
			expect(magicSquares[i][0] + magicSquares[i][1] + magicSquares[i][2], magicSquares[i][1] + magicSquares[i][4] + magicSquares[i][7]);
			expect(magicSquares[i][0] + magicSquares[i][1] + magicSquares[i][2], magicSquares[i][2] + magicSquares[i][5] + magicSquares[i][8]);
		}
		return;

		for (int num1 = 1; num1 <= HIGHEST_NUM; num1++) {
			//if (num1 == 0) {
			//  continue;
			//}
			for (int num2 = 1; num2 <= HIGHEST_NUM; num2++) {
				//if (num2 == 0) {
				//  continue;
				//}
				if (num2 == num1) {
					continue;
				}
				for (int num3 = 1; num3 <= HIGHEST_NUM; num3++) {
					//if (num3 == 0) {
					//  continue;
					//}
					if (num3 == num2 || num3 == num1) {
						continue;
					}
					for (int num4 = 1; num4 <= HIGHEST_NUM; num4++) {
						//if (num4 == 0) {
						//  continue;
						//}
						if (num4 == num3 || num4 == num2 || num4 == num1) {
							continue;
						}
						final List<int>? square = tryGenerateMagicSquare(num1, num2, num3, num4, 1);
						if (square != null) {
							debugPrint(square.toString());
						}
					}
				}
			}
		}
	});
}

List<int>? tryGenerateMagicSquare(int num1, int num2, int num3, int num4, int holeIndex) {
	final List<int> grid = <int>[ 0, 0, 0, 0, 0, 0, 0, 0, 0 ];

	if (holeIndex == 0) {
		grid[0] = 0;
		grid[1] = num1;
		grid[2] = num2;
		grid[3] = num3;
		grid[4] = num4;
	} else if (holeIndex == 1) {
		grid[0] = num1;
		grid[1] = 0;
		grid[2] = num2;
		grid[3] = num3;
		grid[4] = num4;
	} else if (holeIndex == 4) {
		grid[0] = num1;
		grid[1] = num2;
		grid[2] = num3;
		grid[3] = num4;
		grid[4] = 0;
	} else {
		debugPrint("Unknown hole position: $holeIndex");
	}

	final int magicNumber = grid[0] + grid[1] + grid[2];

	grid[6] = magicNumber - grid[3] - grid[0];

	if (grid[6] <= 0 || grid[6] > HIGHEST_NUM) {
		return null;
	}

	grid[5] = magicNumber - grid[3] - grid[4];

	if (grid[5] <= 0 || grid[5] > HIGHEST_NUM) {
		return null;
	}

	grid[7] = magicNumber - grid[4] - grid[1];

	if (grid[7] <= 0 || grid[7] > HIGHEST_NUM) {
		return null;
	}

	grid[8] = magicNumber - grid[2] - grid[5];

	if (grid[8] <= 0 || grid[8] > HIGHEST_NUM) {
		return null;
	}

	if (grid[6] + grid[7] + grid[8] != magicNumber) {
		return null;
	}

	// Diagonals. These severely restrict the number of possible combinations.
	// When enabled no 0s can lie on the diagonals.
	if (grid[0] + grid[4] + grid[8] != magicNumber) {
		return null;
	}
	if (grid[2] + grid[4] + grid[6] != magicNumber) {
		return null;
	}

	// Check no duplicate numbers
	final Set<int> numbers = <int>{};
	for (int i = 0; i < grid.length; i++) {
		if (numbers.contains(grid[i])) {
			return null;
		}
		numbers.add(grid[i]);
	}

	// Check no duplicate factors
	Set<int> factors;
	if (grid[0] == 0) {
		factors = getNonTrivialFactors(grid[1]);
		if (grid[0] != 0) {
			factors = factors.intersection(getNonTrivialFactors(grid[0]));
		}
	} else {
		factors = getNonTrivialFactors(grid[0]);
		if (grid[1] != 0) {
			factors = factors.intersection(getNonTrivialFactors(grid[1]));
		}
	}
	if (grid[3] != 0) {
		factors = factors.intersection(getNonTrivialFactors(grid[2]));
	}
	if (grid[4] != 0) {
		factors = factors.intersection(getNonTrivialFactors(grid[3]));
	}
	factors = factors.intersection(getNonTrivialFactors(grid[4]));
	factors = factors.intersection(getNonTrivialFactors(grid[5]));
	factors = factors.intersection(getNonTrivialFactors(grid[6]));
	factors = factors.intersection(getNonTrivialFactors(grid[7]));
	factors = factors.intersection(getNonTrivialFactors(grid[8]));

	if (factors.isNotEmpty) {
		return null;
	}

	return grid;
}

Set<int> getNonTrivialFactors(int number) {
	final Set<int> factors = <int>{};
	for (int i = 2; i < number; i++) {
		if (number % i == 0) {
			factors.add(i);
		}
	}
	return factors;
}
