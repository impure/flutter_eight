
import 'dart:math';

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

		final MediaQueryData data = MediaQuery.of(context);

		return Scaffold(
			body: SafeArea(
				child: /* data.size.height < 850 && */ data.size.width > data.size.height && data.size.width > 1200 ? buildPortrait(darkModeEnabled) : buildLandScape(darkModeEnabled),
			)
		);
	}

	Widget buildLandScape(bool darkModeEnabled) {

		final double gridSize = min(500, MediaQuery.of(context).size.width * 0.75);
		final double paddingValue = min(20, MediaQuery.of(context).size.height * 0.02);

		return Column(
			children: <Widget>[
				Flexible(
					flex: 2,
					child: Center(
						child: Align(
							alignment: const Alignment(0.5, 0.25),
							child: header(paddingValue),
						),
					),
				),
				gameBoard(gridSize),
				Flexible(
					flex: 1,
					child: Center(
						child: BottomButton(gridSize * (1.5 / 4)),
					),
				),
			],
		);
	}

	Widget buildPortrait(bool darkModeEnabled) {

		final double gridSize = min(500, MediaQuery.of(context).size.width * 0.75);
		final double paddingValue = min(20, MediaQuery.of(context).size.height * 0.02);

		return Row(
			children: <Widget>[
				const Flexible(
					flex: 3,
					fit: FlexFit.tight,
					child: SizedBox(),
				),
				Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: <Widget>[
						header(paddingValue),
						const SizedBox(height: 25),
						Transform.scale(
							scale: 0.9,
							child: BottomButton(gridSize * (1.5 / 4)),
						),
						const SizedBox(height: 20),
					],
				),
				const Flexible(
					flex: 3,
					fit: FlexFit.tight,
					child: SizedBox(),
				),
				Column(
					mainAxisSize: MainAxisSize.min,
					children: <Widget>[ gameBoard(gridSize) ],
				),
				const Flexible(
					flex: 2,
					fit: FlexFit.tight,
					child: SizedBox(),
				),
			],
		);
	}

	Widget gameBoard(double gridSize) {
		return Container(
			padding: const EdgeInsets.only(left: 50, top: 25, bottom: 25, right: 25),
			decoration: const BoxDecoration(
				borderRadius: BorderRadius.all(Radius.circular(100)),
				image: DecorationImage(
					fit: BoxFit.cover, // I don't know what this does but we need it
					image: AssetImage("assets/board.png")
				),
				boxShadow: <BoxShadow>[
					BoxShadow(
						color: Colors.black38,
						blurRadius: 25,
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					Row(
						crossAxisAlignment: CrossAxisAlignment.end,
						children: <Widget>[
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
							Column(
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

	Widget header(double paddingValue) {
		return Column(
			mainAxisAlignment: MainAxisAlignment.start,
			mainAxisSize: MainAxisSize.min,
			children: <Widget>[
				const Text("F8", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2)),
				SizedBox(height: paddingValue),
				const StatsDisplay(),
				SizedBox(height: paddingValue),
				Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: <Widget>[
						IconButton(
							icon: const Icon(Icons.help_outline),
							iconSize: 40,
							tooltip: "Instructions",
							onPressed: () {
								displayHelp();
							},
						),
						IconButton(
							icon: const Icon(Icons.military_tech),
							tooltip: "Score info",
							iconSize: 40,
							onPressed: () {
								showDialog(
									context: context,
									builder: (_) {
										return const StatsDialog();
									},
								);
							},
						),
						IconButton(
							icon: const Icon(Icons.settings),
							tooltip: "Settings",
							iconSize: 40,
							onPressed: () {
								showDialog(
									context: context,
									builder: (BuildContext context) {
										return const SettingsDialog();
									},
								);
							},
						),
					],
				),
			],
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
