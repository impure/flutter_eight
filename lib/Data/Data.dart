
import 'package:flutter/material.dart';
import 'package:flutter_eight/Dialogs/SettingsDialog.dart';
import 'package:flutter_eight/Logic/Puzzle.dart';
import 'package:state_groups/state_groups.dart';

late Puzzle puzzle;
const double PADDING_SIZE = 10;

enum Swap {
	LEFT, UP, DOWN, RIGHT,
}

void notifyGame() {
	boardStateGroup.notifyAll();
	statDisplayStateGroup.notifyAll();
	bottomButtonStateGroup.notifyAll();
}

StateGroup<void> boardStateGroup = StateGroup<void>();
StateGroup<void> statDisplayStateGroup = StateGroup<void>();
StateGroup<void> bottomButtonStateGroup = StateGroup<void>();

Color greyTileBackground = const Color(0xff22262a);
Color get greenColourBackground => colourBlindMode ? const Color(0xFF7FFF00) : const Color(0xff72ad52);
Color get yellowTileBackground => colourBlindMode ? const Color(0xFFE1BE6A) : const Color(0xffbe973f);

Color get greenSymbolHighlight => colourBlindMode ? const Color(0xFF009805) : const Color(0xFF7FFF00);
Color blueSymbolHighlight = const Color(0xFF60CFFF);
