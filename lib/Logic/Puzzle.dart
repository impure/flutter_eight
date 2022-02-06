
import 'dart:async';
import 'dart:math';

import 'package:binary_codec/binary_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_eight/Data/Data.dart';
import 'package:flutter_eight/Dialogs/SettingsDialog.dart';
import 'package:flutter_eight/Dialogs/StatsDialog.dart';
import 'package:flutter_eight/Logic/PuzzleFunctions.dart';
import 'package:flutter_eight/Logic/StatsLogic.dart';
import 'package:flutter_eight/Widgets/Tile.dart';
import 'package:tools/SaveLoadManager.dart';
import 'package:tools/Startup.dart';
import 'package:tools/TestUtils.dart';
import 'package:tuple/tuple.dart';

enum DIRECTION_HINT {
	ROW_OR_COLUMN,
	BOTH,
}

List<List<int>> magicSquares = <List<int>>[
	<int>[5, 0, 7, 6, 4, 2, 1, 8, 3],
	<int>[6, 0, 9, 8, 5, 2, 1, 10, 4],
	<int>[7, 0, 5, 2, 4, 6, 3, 8, 1],
	<int>[7, 0, 8, 6, 5, 4, 2, 10, 3],
	<int>[7, 0, 11, 10, 6, 2, 1, 12, 5],
	<int>[8, 0, 7, 4, 5, 6, 3, 10, 2],
	<int>[8, 0, 13, 12, 7, 2, 1, 14, 6],
	<int>[9, 0, 6, 2, 5, 8, 4, 10, 1],
	<int>[9, 0, 12, 10, 7, 4, 2, 14, 5],
	<int>[9, 0, 15, 14, 8, 2, 1, 16, 7],
	<int>[10, 0, 11, 8, 7, 6, 3, 14, 4],
	<int>[10, 0, 14, 12, 8, 4, 2, 16, 6],
	<int>[10, 0, 17, 16, 9, 2, 1, 18, 8],
	<int>[11, 0, 7, 2, 6, 10, 5, 12, 1],
	<int>[11, 0, 10, 6, 7, 8, 4, 14, 3],
	<int>[11, 0, 13, 10, 8, 6, 3, 16, 5],
	<int>[11, 0, 16, 14, 9, 4, 2, 18, 7],
	<int>[12, 0, 9, 4, 7, 10, 5, 14, 2],
	<int>[13, 0, 8, 2, 7, 12, 6, 14, 1],
	<int>[13, 0, 11, 6, 8, 10, 5, 16, 3],
	<int>[13, 0, 14, 10, 9, 8, 4, 18, 5],
	<int>[14, 0, 10, 4, 8, 12, 6, 16, 2],
	<int>[14, 0, 13, 8, 9, 10, 5, 18, 4],
	<int>[15, 0, 9, 2, 8, 14, 7, 16, 1],
	<int>[16, 0, 11, 4, 9, 14, 7, 18, 2],
	<int>[17, 0, 10, 2, 9, 16, 8, 18, 1],
];

const int PUZZLE_WIDTH = 3;
const int PUZZLE_HEIGHT = 3;

class Puzzle {

	// Resets everything and shuffles the tiles with the following algorithm:
	// start sorted and then apply random shuffles
	Puzzle({required this.day, required this.freePlay}) {
		numMoves = 0;
		numChecks = 0;
		lookupValues = <int>[0, 0, 0, 0, 0, 0, 0, 0, 0];
		shareInfo.clear();

		final bool alreadyWon = startGame();
		// Web does not support saving so we still have to do this on web
		if (kIsWeb && alreadyWon) {
			freePlay = true;
		}

		int getDayID() {
			final DateTime now = DateTime.now();
			return now.year * 500 + now.month * 40 + now.day;
		}

		final Random rng = Random(freePlay ? null : getDayID());

		puzzlePieces = List<int?>.filled(PUZZLE_HEIGHT * PUZZLE_WIDTH, null);
		for (int i = 0; i < puzzlePieces.length - 1; i++) {
			puzzlePieces[i] = i;
		}

		// Get end state
		solution = simulateRandomSwaps(puzzlePieces, 500, rng, keepGoing: (List<int?> currentTiles) {
			for (int i = 0; i < currentTiles.length; i++) {
				if (currentTiles[i] == i) {
					return true;
				}
			}
			return false;
		});

		// Move hole to bottom right in non-random hole mode
		if (!randomHole) {
			while (solution.last != null) {
				final int holeIndex = solution.indexOf(null);
				if (canSwapHoleWithDown(holeIndex)) {
					swapHoleWithDown(holeIndex, solution);
				} else if (canSwapHoleWithRight(holeIndex)) {
					swapHoleWithRight(holeIndex, solution);
				}
			}
		}

		final List<int> possibleLocationsSinglePiece = <int>[];
		for (int i = 0; i < puzzlePieces.length - 1; i++) {
			possibleLocationsSinglePiece.add(i);
		}
		if (randomHole) {
			possibleLocationsSinglePiece.add(puzzlePieces.length - 1);
		}

		for (int i = 0; i < puzzlePieces.length; i++) {
			if (puzzlePieces[i] != null) {
				possiblePositions[puzzlePieces[i]!] = possibleLocationsSinglePiece.toSet();
			}
		}

		// Also make sure no tiles are currently coloured
		tilesStateGroup.notifyAll(null);
	}

	factory Puzzle.fromMap(Map<dynamic, dynamic> data) {

		final Map<int, Set<int>> possiblePositions = <int, Set<int>>{};
		final Map<int, dynamic> positionData = Map<int, dynamic>.from(data[Data.POSSIBLE_POSITIONS.index]);
		for (final MapEntry<int, dynamic> position in positionData.entries) {
			possiblePositions[position.key] = Set<int>.from(position.value);
		}

		return Puzzle._(
			day: data[Data.DAY.index],
			freePlay: false,
			numMoves: data[Data.NUM_MOVES.index],
			numChecks: data[Data.NUM_CHECKS.index],
			puzzlePieces: List<int?>.from(data[Data.PUZZLE_PIECES.index]),
			solution: List<int?>.from(data[Data.SOLUTION.index]),
			possiblePositions: possiblePositions,
			lookupValues: List<int>.from(data[Data.LOOKUP_VALUES.index]),
			isBoosted: (data[Data.MAX_CHECKS_DEPRECATED.index] != null && data[Data.MAX_CHECKS_DEPRECATED.index] >= 6) || data[Data.IS_BOOSTED.index] == true,
			shareInfo: StringBuffer(data[Data.SHARE_INFO.index]),
		);
	}

	Puzzle._({
		required this.day,
		required this.freePlay,
		required this.numMoves,
		required this.numChecks,
		required this.puzzlePieces,
		required this.solution,
		required this.possiblePositions,
		required this.lookupValues,
		required this.shareInfo,
		required this.isBoosted,
	});

	List<int?> puzzlePieces = <int?>[];
	List<int?> solution = <int?>[];
	Map<int, Set<int>> possiblePositions = <int, Set<int>>{};
	int numMoves = 0;
	int numChecks = 0;
	List<int> lookupValues = <int>[];
	bool freePlay;
	bool isBoosted = false;

	// Schedule a save in the future and if no one overwrites it save.
	// This is to cut down on unnecessary saves
	DateTime? scheduledSave;

	int get currentMaxNumChecks => 6;

	StringBuffer shareInfo = StringBuffer();

	bool get solved => puzzlePieces.toString() == solution.toString();

	final int day;

	String getRequirements(Tuple4<int, int, int, int> requirements) {
		return "${requirements.item1.toString().padLeft(2, "0")} ${requirements.item2.toString().padLeft(2, "0")} ${requirements.item3.toString().padLeft(2, "0")} ${requirements.item4.toString().padLeft(2, "0")}";
	}

	void trySwapHoleWithIndex(int index) {
		if (index >= 0 && index < puzzlePieces.length) {
			trySwapHoleWith(puzzlePieces[index]!);
		}
	}

	void trySwapHoleWith(int num) {

		final int numIndex = puzzlePieces.indexOf(num);
		final int holeIndex = puzzlePieces.indexOf(null);

		void onSuccess() {
			numMoves++;
			tilesStateGroup.notifyAll(null);
			notifyGame();

			scheduledSave = DateTime.now().add(const Duration(seconds: 2));
		}

		if (numIndex == holeIndex - 1 && canSwapHoleWithLeft(holeIndex)) {
			swapHoleWithLeft(holeIndex, puzzlePieces);
			onSuccess();
		} else if (numIndex == holeIndex + 1 && canSwapHoleWithRight(holeIndex)) {
			swapHoleWithRight(holeIndex, puzzlePieces);
			onSuccess();
		} else if (numIndex == holeIndex - PUZZLE_WIDTH && canSwapHoleWithUp(holeIndex)) {
			swapHoleWithUp(holeIndex, puzzlePieces);
			onSuccess();
		} else if (numIndex == holeIndex + PUZZLE_WIDTH && canSwapHoleWithDown(holeIndex)) {
			swapHoleWithDown(holeIndex, puzzlePieces);
			onSuccess();
		}
	}

	void checkWin(BuildContext context) {
		if (solved) {
			unawaited(save());
			if (!freePlay) {
				endGame(true);
			}
			showDialog(
				context: context,
				builder: (_) {
					return const StatsDialog();
				}
			);
		}
	}

	void checkCurrentAnswer() {
		final Map<int, DIRECTION_HINT> data = <int, DIRECTION_HINT>{};

		numChecks++;

		for (int i = 0; i < puzzlePieces.length; i++) {
			if (puzzlePieces[i] == null) {
				continue;
			}
			final int currentIndex = puzzlePieces.indexOf(puzzlePieces[i]);
			final int correctIndex = solution.indexOf(puzzlePieces[i]);
			final bool correctRow = sameRow(currentIndex, correctIndex);
			final bool correctColumn = sameColumn(currentIndex, correctIndex);

			if (correctColumn && correctRow) {
				data[puzzlePieces[i]!] = DIRECTION_HINT.BOTH;
				possiblePositions[puzzlePieces[i]!]!.removeWhere((int tile) {
					return tile != i;
				});
			} else if (correctColumn || correctRow) {
				data[puzzlePieces[i]!] = DIRECTION_HINT.ROW_OR_COLUMN;
				possiblePositions[puzzlePieces[i]!]!.remove(i);
				possiblePositions[puzzlePieces[i]!]!.removeWhere((int tile) {
					return !(sameColumn(tile, i) || sameRow(tile, i));
				});
			} else {
				possiblePositions[puzzlePieces[i]!]!.removeWhere((int tile) {
					return sameRow(tile, i) || sameColumn(tile, i);
				});
			}
		}

		// Sanity check tiles
		for (int i = 0; i < puzzlePieces.length; i++) {
			final int? puzzlePiece = puzzlePieces[i];
			if (puzzlePiece == null) {
				continue;
			}
			final int solutionLocation = solution.indexOf(puzzlePiece);
			if (!possiblePositions[puzzlePiece]!.contains(solutionLocation)) {
				crashlyticsRecordError("Missing own tile! Tile: $puzzlePiece, Solution location: $solutionLocation", StackTrace.current);
				possiblePositions[puzzlePiece]!.add(solutionLocation);
			}
		}

		bool removeAlreadySolvedTiles() {

			bool didSomething = false;

			// Remove all tiles that are already a solution for another tile
			for (final MapEntry<int, Set<int>> solvedPiece in possiblePositions.entries) {
				if (solvedPiece.value.length == 1) {
					final int solvedPieceTile = solvedPiece.value.first;
					for (final MapEntry<int, Set<int>> otherPiece in possiblePositions.entries) {
						if (otherPiece.key != solvedPiece.key && otherPiece.value.contains(solvedPieceTile)) {
							didSomething = true;
							otherPiece.value.remove(solvedPieceTile);
						}
					}
				}
			}
			return didSomething;
		}

		for (int i = 0; i < 16; i++) {
			if (!removeAlreadySolvedTiles()) {
				break;
			}
		}

		tilesStateGroup.notifyAll(data);
	}

	int getValue(int index) {
		return lookupValues[index];
	}

	void trySwapHoleWithLeft() {
		trySwapHoleWithIndex(puzzlePieces.indexOf(null) - 1);
	}

	void trySwapHoleWithUp() {
		trySwapHoleWithIndex(puzzlePieces.indexOf(null) - 4);
	}

	void trySwapHoleWithRight() {
		trySwapHoleWithIndex(puzzlePieces.indexOf(null) + 1);
	}

	void trySwapHoleWithDown() {
		trySwapHoleWithIndex(puzzlePieces.indexOf(null) + 4);
	}

	Map<int, dynamic> toMap() {
		return <int, dynamic> {
			Data.PUZZLE_PIECES.index : puzzlePieces,
			Data.SOLUTION.index : solution,
			Data.POSSIBLE_POSITIONS.index : mapSetToMapList(possiblePositions),
			Data.NUM_MOVES.index : numMoves,
			Data.NUM_CHECKS.index : numChecks,
			Data.LOOKUP_VALUES.index : lookupValues,
			Data.SHARE_INFO.index : shareInfo.toString(),
			Data.DAY.index : day,
			Data.IS_BOOSTED.index : isBoosted,
		};
	}

	void checkScheduledSave(DateTime now) {
		if (scheduledSave != null && now.isAfter(scheduledSave!)) {
			scheduledSave = null;
			unawaited(save());
		}
	}

	Future<void> save() async {
		if (freePlay) {
			return;
		}
		if (kIsWeb) {
			unawaited(prefs!.setString("Save", binaryCodec.encode(toMap()).toString().
					replaceAll(" ", "").replaceAll("[", "").replaceAll("]", "")));
		} else {
			return saveToFile(
				authenticatedSaveName: "Puzzle1",
				unauthenticatedSaveName: "Puzzle2",
				dataToSave: binaryCodec.encode(toMap()),
				onSave: () {
					debugPrint("Save");
				},
				tryDisplaySavedBlockedMessage: () {
					// Flurdle saves cannot be blocked
				},
				authenticateTime: false,
			);
		}
	}
}

Map<int, List<int>> mapSetToMapList(Map<int, Set<int>> data) {
	final Map<int, List<int>> returnMap = <int, List<int>>{};
	for (final MapEntry<int, Set<int>> entry in data.entries) {
		returnMap[entry.key] = entry.value.toList();
	}
	return returnMap;
}

enum Data {
	PUZZLE_PIECES,
	SOLUTION,
	POSSIBLE_POSITIONS,
	NUM_MOVES,
	NUM_CHECKS,
	LOOKUP_VALUES,
	MAX_CHECKS_DEPRECATED,
	SHARE_INFO,
	DAY,
	IS_BOOSTED,
}
