

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
import 'package:tools/BasicExtensions.dart';
import 'package:tools/RandomBag.dart';
import 'package:tools/SaveLoadManager.dart';
import 'package:tools/Startup.dart';
import 'package:tools/TestUtils.dart';
import 'package:tuple/tuple.dart';

enum DIRECTION_HINT {
	ROW_OR_COLUMN,
	BOTH,
}

const int PUZZLE_WIDTH = 3;
const int PUZZLE_HEIGHT = 3;

class Puzzle {

	// Resets everything and shuffles the tiles with the following algorithm:
	// start sorted and then apply random shuffles
	Puzzle({required this.day, required this.freePlay}) {
		numMoves = 0;
		numChecks = 0;
		lookupListEmojis.clear();
		lookupListRunes.clear();
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
			lookupListRunes: List<String>.from(data[Data.LOOKUP_RUNES.index]),
			lookupListEmojis: List<String>.from(data[Data.LOOKUP_EMOJIS.index]),
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
		required this.lookupListRunes,
		required this.lookupListEmojis,
		required this.shareInfo,
		required this.isBoosted,
	});

	List<int?> puzzlePieces = <int?>[];
	List<int?> solution = <int?>[];
	Map<int, Set<int>> possiblePositions = <int, Set<int>>{};
	int numMoves = 0;
	int numChecks = 0;
	List<String> lookupListRunes = <String>[];
	List<String> lookupListEmojis = <String>[];
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

		void writeEmojiToSolution(int index, StringBuffer buffer, Map<int, DIRECTION_HINT> data, [bool rowEndPiece = false]) {
			final int? value = puzzlePieces[index];
			if (value == null) {
				if (rowEndPiece) {
					return;
				} else {
					buffer.write("🟥"); // Red
					return;
				}
			}
			switch (data[value]) {
				case DIRECTION_HINT.ROW_OR_COLUMN:
					buffer.write("🟨"); // Yellow
					break;
				case DIRECTION_HINT.BOTH:
					buffer.write("🟩"); // Green
					break;
				case null:
					buffer.write("⬛"); // Black
					break;
			}
		}

		shareInfo.write("\n\n");

		writeEmojiToSolution(0, shareInfo, data);
		writeEmojiToSolution(1, shareInfo, data);
		writeEmojiToSolution(2, shareInfo, data);
		writeEmojiToSolution(3, shareInfo, data, true);
		shareInfo.write("\n");
		writeEmojiToSolution(4, shareInfo, data);
		writeEmojiToSolution(5, shareInfo, data);
		writeEmojiToSolution(6, shareInfo, data);
		writeEmojiToSolution(7, shareInfo, data, true);
		shareInfo.write("\n");
		writeEmojiToSolution(8, shareInfo, data);
		writeEmojiToSolution(9, shareInfo, data);
		writeEmojiToSolution(10, shareInfo, data);
		writeEmojiToSolution(11, shareInfo, data, true);
		shareInfo.write("\n");
		writeEmojiToSolution(12, shareInfo, data);
		writeEmojiToSolution(13, shareInfo, data);
		writeEmojiToSolution(14, shareInfo, data);
		writeEmojiToSolution(15, shareInfo, data, true);
	}

	String getDisplayString(int index) {

		if (thirstyEmojis) {
			if (lookupListEmojis.isEmpty) {
				lookupListEmojis = <String>["🍆", "🍌", "🍒", "🍑", "♋", "😉", "🤤", "💋", "👅", "😈", "😏", "👌", "🤫", "😇", "☝", "💦", "👉"].scramble(Random());
			}
			assert(lookupListEmojis.length >= 15);
			return lookupListEmojis[index];
		} else {
			if (lookupListRunes.isEmpty) {
				lookupListRunes = RandomBag<String>.fromList(<String>["ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "ᛋ", "ᚷ", "ᚻ", "ᚾ", "ᛒ", "ᛏ", "ᛇ", "ᛈ", "ᛉ", "ᛗ", "ᛊ", "ᛝ", "ᛟ", "ᛞ"]).getListOfRandomItems(15, Random());
			}
			assert(lookupListRunes.length >= 15);
			return lookupListRunes[index];
		}
		// Note: have to run in web renderer (flutter run -d chrome --web-renderer html) otherwise characters can't be found
		//const List<String> lookupList = <String>["ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "ᛋ", "ᚷ", "ᚹ", "ᚻ", "ᚾ", "ᛒ", "ᛏ", "ᛇ", "ᛈ", "ᛉ"];
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
			Data.LOOKUP_RUNES.index : lookupListRunes,
			Data.LOOKUP_EMOJIS.index : lookupListEmojis,
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
	LOOKUP_RUNES,
	LOOKUP_EMOJIS,
	MAX_CHECKS_DEPRECATED,
	SHARE_INFO,
	DAY,
	IS_BOOSTED,
}
