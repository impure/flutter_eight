
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InstructionsDialog extends StatefulWidget {
	const InstructionsDialog({Key? key}) : super(key: key);

	@override
	InstructionsDialogState createState() => InstructionsDialogState();
}

class InstructionsDialogState extends State<InstructionsDialog> {

	late ScrollController _controller;

	@override
	void initState() {
		_controller = ScrollController();
    super.initState();
  }

  @override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	List<InlineSpan> makeText() {

		final List<InlineSpan> spans = <InlineSpan>[];

		if (kIsWeb) {
			spans.add(
				const TextSpan(text: "Note: The following does not work on the web version: extending guesses to 6 and free play. It is recommended to play on the Android version to get all available features here: "),
			);
			spans.add(
				TextSpan(
					text: "here.",
					style: const TextStyle(
						decoration: TextDecoration.underline,
						decorationThickness: 2,
					),
					recognizer: TapGestureRecognizer()..onTap = () => launch("https://play.google.com/store/apps/details?id=com.amorfatite.flurdle"),
				),
			);
			spans.add(
				const TextSpan(text: "\n\n"),
			);
		}

		spans.add(
			const TextSpan(
				text: "Flurdle is a slide puzzle game with a unique twist: you don't know what order the tiles go in.\n\nIn order to see if your guess is right or not you have to press the check button below. This will turn tiles in the correct location green and tiles in the correct row/column yellow. But be warned: you can only press the check button 3 times (at least at first) so make them count.\n\nNote that once you press the check button you do not have to memorize the results from the check. They are automatically saved and you can view them by pressing and holding on the tiles.\n\nOne more thing: if you don't know how to solve a 4x4 slide puzzle it's very simple once you know how. You solve the topmost row, then the second topmost row, and then the left most column, and then the second leftmost column. "),
		);
		spans.add(
			TextSpan(
				text: "Here's",
				style: const TextStyle(
					decoration: TextDecoration.underline,
					decorationThickness: 2,
				),
				recognizer: TapGestureRecognizer()..onTap = () => launch("https://andrewzuo.com/how-to-solve-a-slide-puzzle-3fe533f76232?sk=dcd1f5500484386196d1133b9fc5461a"),
			),
		);
		spans.add(
			const TextSpan(text: " a post I made on how to do it. Good luck."),
		);

		return spans;
	}

	@override
	Widget build(BuildContext context) {
		final bool restrictWidth = MediaQuery.of(context).size.width > 500;
		return AlertDialog(
			title: const Center(
				child: Text("How To Play"),
			),
			content: !restrictWidth ? SingleChildScrollView(
				controller: _controller,
				child: RichText(
					text: TextSpan(
						style: TextStyle(color: Theme.of(context).textTheme.bodyText1!.color),
						children: makeText(),
					),
				),
			) : SizedBox(
				width: 500,
				child: SingleChildScrollView(
					controller: _controller,
					child: RichText(
						text: TextSpan(
							style: TextStyle(color: Theme.of(context).textTheme.bodyText1!.color),
							children: makeText(),
						),
					),
				),
			),
			actions: <Widget>[
				TextButton(
					child: Text("DISMISS", style: Theme.of(context).textTheme.bodyText1),
					onPressed: () {
						if (_controller.offset < _controller.position.maxScrollExtent * 0.9) {
							_controller.animateTo(
								_controller.position.maxScrollExtent,
								duration: const Duration(milliseconds: 200),
								curve: Curves.easeOut,
							);
						} else {
							Navigator.pop(context);
						}
					},
				),
			],
		);
	}
}
