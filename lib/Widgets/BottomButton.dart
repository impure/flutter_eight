
import 'package:flutter/material.dart';
import 'package:flutter_eight/Data/Data.dart';
import 'package:flutter_eight/Dialogs/SettingsDialog.dart';
import 'package:flutter_eight/Logic/Puzzle.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:state_groups/state_groups.dart';

class BottomButton extends StatefulWidget {
  const BottomButton(this.width, {Key? key}) : super(key: key);

  final double width;

	@override
	BottomButtonState createState() => BottomButtonState();
}

class BottomButtonState extends SyncState<void, BottomButton> {

	BottomButtonState() : super(bottomButtonStateGroup);

	@override
	Widget build(BuildContext context) {

		final bool enabled = randomHole || puzzle.puzzlePieces[puzzle.puzzlePieces.length - 1] == null;
		final bool shuffleButton = puzzle.solved;
		final String text = shuffleButton ? "Shuffle" : "Check";

		void onTap() {
			final bool enabled = randomHole || puzzle.puzzlePieces[puzzle.puzzlePieces.length - 1] == null;
			final bool shuffleButton = puzzle.solved;

			if (shuffleButton) {
				puzzle = Puzzle(day: DateTime
						.now()
						.day, freePlay: true);
				statDisplayStateGroup.notifyAll();
			} else if (enabled) {
				statDisplayStateGroup.notifyAll();
			} else {
				Fluttertoast.showToast(msg: "Move empty space to bottom right.");
			}
		}

		return Semantics(
			label: "$text${enabled ? "" : " disabled"}",
			child: MaterialButton(
				onPressed: onTap,
				shape: RoundedRectangleBorder(
					side: BorderSide(
						color: Theme.of(context).textTheme.button?.color ?? Colors.black,
					),
					borderRadius: BorderRadius.circular(widget.width),
				),
				child: Padding(
					padding: const EdgeInsets.only(top: 10, bottom: 10),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						mainAxisAlignment: MainAxisAlignment.center,
						children: <Widget>[
							const SizedBox(width: 20),
							const Icon(Icons.grading, size: 30),
							const SizedBox(width: 5),
							Text(text, style: const TextStyle(fontSize: 25)),
							const SizedBox(width: 20),
						],
					),
				),
			),
		);
	}
}
