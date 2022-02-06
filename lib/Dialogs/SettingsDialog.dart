
import 'package:flutter/material.dart';
import 'package:flutter_eight/Data/Data.dart';
import 'package:flutter_eight/Logic/StatsLogic.dart';
import 'package:flutter_eight/Widgets/Tile.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tools/Startup.dart';

bool get thirstyEmojis => prefs?.getBool("ThirstyEmojis") ?? false;
bool get randomHole => prefs?.getBool("RandomHole") ?? false;
bool get invertControls => prefs?.getBool("InvertControls") ?? false;
bool get colourBlindMode => prefs?.getBool("ColourBlindMode") ?? false;

class SettingsDialog extends StatefulWidget {
	const SettingsDialog({Key? key}) : super(key: key);

	@override
	SettingsDialogState createState() => SettingsDialogState();
}

class SettingsDialogState extends State<SettingsDialog> {

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			title: const Center(
				child: Text("Settings"),
			),
			content: Column(
				mainAxisSize: MainAxisSize.min,
				children: <Widget>[
					Text(puzzle.freePlay ? "Free Play" : "Daily Challenge"),
					const SizedBox(height: 20),
					SwitchListTile(
						title: const Text("Invert Keyboard Controls"),
						value: invertControls,
						onChanged: (bool? value) {
							if (value != null) {
								setState(() {
									prefs!.setBool("InvertControls", value);
								});
							}
						},
					),
					SwitchListTile(
						title: const Text("Colour Blind Mode"),
						value: colourBlindMode,
						onChanged: (bool? value) {
							if (value != null) {
								setState(() {
									prefs!.setBool("ColourBlindMode", value);
								});
								boardStateGroup.notifyAll();
							}
						},
					),
					SwitchListTile(
						title: const Text("Thirsty Emojis"),
						subtitle: const Text("Requires 10 Non-Freeplay Wins"),
						value: thirstyEmojis,
						onChanged: (bool? value) {
							if (value != null) {
								if (numWins < 10) {
									Fluttertoast.showToast(msg: "Not enough wins!");
									return;
								}
								setState(() {
									prefs!.setBool("ThirstyEmojis", value);
								});
								tilesStateGroup.notifyAll(null);
							}
						},
					),
					SwitchListTile(
						title: const Text("Random 'Hole' Location"),
						subtitle: const Text("Requires 3 Non-Freeplay Wins, Requires Restart"),
						value: randomHole,
						onChanged: (bool? value) {
							if (value != null) {
								if (numWins < 3) {
									Fluttertoast.showToast(msg: "Not enough wins!");
									return;
								}
								setState(() {
									prefs!.setBool("RandomHole", value);
								});
							}
						},
					),
					ListTile(
						title: const Text("Device ID"),
						subtitle: SelectableText(deviceID ?? "Null"),
					),
				],
			),
			actions: <Widget>[
				TextButton(
					child: Text("DISMISS", style: Theme.of(context).textTheme.bodyText1),
					onPressed: () => Navigator.pop(context),
				),
			],
		);
	}
}
