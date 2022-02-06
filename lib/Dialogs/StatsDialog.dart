
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_eight/Data/Data.dart';
import 'package:flutter_eight/Logic/Puzzle.dart';
import 'package:flutter_eight/Logic/StatsLogic.dart';
import 'package:flutter_eight/Widgets/NextFlurdleTimer.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StatsDialog extends StatefulWidget {
	const StatsDialog({Key? key}) : super(key: key);

	@override
	StatsDialogState createState() => StatsDialogState();
}

class StatsDialogState extends State<StatsDialog> {

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			title: Center(
				child: Text(puzzle.solved ? "Congratulations!" : "Statistics"),
			),
			content: Column(
				mainAxisSize: MainAxisSize.min,
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					Text(
						"Wins: $numWins\n"
						"Played: $numPlays\n"
						"Win percentage: $winPercentage%\n"
						"Current Streak: $currentStreak\n"
						"Max Streak: $maxStreak\n"
					),
					const NextFlurdleTimer(),
				],
			),
			actions: <Widget>[
				TextButton(
					child: Text("SHUFFLE", style: Theme.of(context).textTheme.bodyText1),
					onPressed: () {
						puzzle = Puzzle(day: DateTime.now().day, freePlay: true);
						statDisplayStateGroup.notifyAll();
						boardStateGroup.notifyAll();
						bottomButtonStateGroup.notifyAll();
						Navigator.pop(context);
					},
				),
				(puzzle.solved && !puzzle.freePlay) ? TextButton(
					child: Text("SHARE (CLIPBOARD)", style: Theme.of(context).textTheme.bodyText1),
					onPressed: () {
						Clipboard.setData(ClipboardData(text: "I solved the Flurtle for ${todaysDate(DateTime.now())} in ${puzzle.numChecks} checks and ${puzzle.numMoves} moves.${puzzle.shareInfo}"));
						Fluttertoast.showToast(msg: "Copied to clipboard");
					},
				) : Container(),
				TextButton(
					child: Text("DISMISS", style: Theme.of(context).textTheme.bodyText1),
					onPressed: () => Navigator.pop(context),
				),
			],
		);
	}
}

String todaysDate(DateTime now) {
	const List<String> months = <String>["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	return "${months[now.month - 1]} ${now.day}, ${now.year}";
}
