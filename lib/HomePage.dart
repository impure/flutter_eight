
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_eight/Data/Data.dart';
import 'package:flutter_eight/Dialogs/InstructionsDialog.dart';
import 'package:flutter_eight/Dialogs/SettingsDialog.dart';
import 'package:flutter_eight/Dialogs/StatsDialog.dart';
import 'package:flutter_eight/Widgets/BoardDisplay.dart';
import 'package:flutter_eight/Widgets/BottomButton.dart';
import 'package:flutter_eight/Widgets/Counter.dart';
import 'package:flutter_eight/Widgets/StatsDisplay.dart';
import 'package:tools/BasicExtensions.dart';
import 'package:tools/Startup.dart';

class HomePage extends StatefulWidget {
	const HomePage({Key? key}) : super(key: key);

	@override
	State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

	@override
	Widget build(BuildContext context) {

		SystemChrome.setPreferredOrientations(<DeviceOrientation>[
			DeviceOrientation.portraitUp,
			DeviceOrientation.portraitDown,
		]);


		WidgetsBinding.instance!.addPostFrameCallback((_) {
			if (!prefs!.containsKey("DisplayHelp")) {
				displayHelp();
				prefs!.setBool("DisplayHelp", true);
			}
		});
		WidgetsBinding.instance!.scheduleFrame();

		final bool darkModeEnabled = Theme.of(context).darkModeEnabled;

		SystemChrome.setSystemUIOverlayStyle(darkModeEnabled ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

		final double gridSize = min(500, MediaQuery.of(context).size.width * 3 / 5);

		return Scaffold(
			body: SafeArea(
				child: Center(
					child: SingleChildScrollView(
						scrollDirection: Axis.horizontal,
						child: SingleChildScrollView(
							child: gameBoard(gridSize),
						),
					)
				),
			)
		);
	}

	Widget gameBoard(double gridSize) {
		return Container(
			padding: EdgeInsets.only(left: gridSize * 0.1, top: gridSize * 0.05, bottom: gridSize * 0.05, right: gridSize * 0.05),
			decoration: BoxDecoration(
				borderRadius: BorderRadius.all(Radius.circular(gridSize / 5)),
				image: const DecorationImage(
					fit: BoxFit.cover, // I don't know what this does but we need it
					image: AssetImage("assets/board.png")
				),
				boxShadow: <BoxShadow>[
					BoxShadow(
						color: Colors.black38,
						blurRadius: gridSize * 0.05,
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				mainAxisSize: MainAxisSize.min,
				children: <Widget>[
					Row(
						mainAxisSize: MainAxisSize.min,
						crossAxisAlignment: CrossAxisAlignment.end,
						children: <Widget>[
							Column(
								children: <Widget>[
									SizedBox(
										height: gridSize * 0.33,
										width: gridSize,
										child: SingleChildScrollView(
											scrollDirection: Axis.horizontal,
											child: Row(
												mainAxisSize: MainAxisSize.min,
												mainAxisAlignment: MainAxisAlignment.center,
												children: <Widget>[
													AutoSizeText("F8", style: TextStyle(fontSize: gridSize * 0.12, fontWeight: FontWeight.bold, letterSpacing: 2)),
													VerticalDivider(
														thickness: gridSize / 50,
														width: gridSize / 5,
														indent: gridSize * 0.1,
														endIndent: gridSize * 0.08,
														color: Colors.white,
													),
													Padding(
														padding: EdgeInsets.only(top: gridSize / 50, left: gridSize / 50),
														child: IconButton(
															visualDensity: VisualDensity.compact,
															icon: const Icon(Icons.help_outline),
															iconSize: gridSize / 10,
															tooltip: "Instructions",
															onPressed: () {
																displayHelp();
															},
														),
													),
													Padding(
														padding: EdgeInsets.only(top: gridSize / 50, left: gridSize / 50),
														child: IconButton(
															visualDensity: VisualDensity.compact,
															icon: const Icon(Icons.restart_alt),
															iconSize: gridSize / 10,
															tooltip: "Restart",
															onPressed: () {
																displayHelp();
															},
														),
													),
													Padding(
														padding: EdgeInsets.only(top: gridSize / 50, left: gridSize / 50),
														child: IconButton(
															visualDensity: VisualDensity.compact,
															icon: const Icon(Icons.settings),
															iconSize: gridSize / 10,
															tooltip: "Settings",
															onPressed: () {
																showDialog(
																	context: context,
																	builder: (BuildContext context) {
																		return const SettingsDialog();
																	},
																);
															},
														),
													),
												],
											),
										),
									),
									Container(
										decoration: BoxDecoration(
											color: Colors.orange.withOpacity(0.2),
											boxShadow: const <BoxShadow>[
												BoxShadow(
													color: Colors.black54,
													blurRadius: 10,
													blurStyle: BlurStyle.inner,
												)
											],
										),
										child: BoardDisplay(gridSize),
									),
								],
							),
							Column(
								mainAxisSize: MainAxisSize.min,
								children: <Widget>[
									Counter(
										gridSize / 3,
										() => (puzzle.puzzlePieces[6] ?? 0) + (puzzle.puzzlePieces[4] ?? 0) + (puzzle.puzzlePieces[2] ?? 0),
									),
									Counter(
										gridSize / 3,
										() => (puzzle.puzzlePieces[0] ?? 0) + (puzzle.puzzlePieces[1] ?? 0) + (puzzle.puzzlePieces[2] ?? 0),
									),
									Counter(
										gridSize / 3,
										() => (puzzle.puzzlePieces[3] ?? 0) + (puzzle.puzzlePieces[4] ?? 0) + (puzzle.puzzlePieces[5] ?? 0),
									),
									Counter(
										gridSize / 3,
										() => (puzzle.puzzlePieces[6] ?? 0) + (puzzle.puzzlePieces[7] ?? 0) + (puzzle.puzzlePieces[8] ?? 0),
									),
								],
							),
						],
					),
					Row(
						mainAxisSize: MainAxisSize.min,
						children: <Widget>[
							Counter(
								gridSize / 3,
								() => (puzzle.puzzlePieces[0] ?? 0) + (puzzle.puzzlePieces[3] ?? 0) + (puzzle.puzzlePieces[6] ?? 0),
							),
							Counter(
								gridSize / 3,
								() => (puzzle.puzzlePieces[1] ?? 0) + (puzzle.puzzlePieces[4] ?? 0) + (puzzle.puzzlePieces[7] ?? 0),
							),
							Counter(
								gridSize / 3,
								() => (puzzle.puzzlePieces[2] ?? 0) + (puzzle.puzzlePieces[5] ?? 0) + (puzzle.puzzlePieces[8] ?? 0),
							),
							Counter(
								gridSize / 3,
								() => (puzzle.puzzlePieces[0] ?? 0) + (puzzle.puzzlePieces[4] ?? 0) + (puzzle.puzzlePieces[8] ?? 0),
							),
						],
					),
				],
			),
		);
	}

	void displayHelp() {
		showDialog(
			context: context,
			builder: (BuildContext context) {
				return const InstructionsDialog();
			}
		);
	}
}
