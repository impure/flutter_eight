
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_eight/Data/Data.dart';
import 'package:flutter_eight/Logic/Puzzle.dart';
import 'package:state_groups/state_groups.dart';
import 'package:tools/BasicExtensions.dart';

StateGroup<Set<int>> highlightBackgroundGroup = StateGroup<Set<int>>();

class HighlightBackground extends StatefulWidget {

  const HighlightBackground(this.size, {Key? key}) : super(key: key);

  final double size;

	@override
	HighlightBackgroundState createState() => HighlightBackgroundState();
}

class HighlightBackgroundState extends SyncState<Set<int>, HighlightBackground> {

	HighlightBackgroundState() : super(highlightBackgroundGroup);

	Set<int>? highlightedTiles;

	@override
	void update(Set<int>? message) {
		highlightedTiles = message;
		if (mounted) {
			setState(() {});
		}
  }

	@override
	Widget build(BuildContext context) {
		final List<Widget> cells = <Widget>[];
		final bool darkModeEnabled = Theme.of(context).darkModeEnabled;

		for (int i = 0; i <= PUZZLE_WIDTH * PUZZLE_HEIGHT; i++) {
			final int x = i % PUZZLE_WIDTH;
			final int y = i ~/ PUZZLE_WIDTH;
			final double shapeWidth = (widget.size / PUZZLE_WIDTH) - PADDING_SIZE;
			final double shapeHeight = (widget.size / PUZZLE_HEIGHT) - PADDING_SIZE;
			cells.add(
				Transform.translate(
					offset: Offset(x * (shapeWidth + PADDING_SIZE) + PADDING_SIZE * 0.5, y * (shapeHeight + PADDING_SIZE) + PADDING_SIZE * 0.5),
					child: Container(
						width: shapeWidth,
						height: shapeHeight,
						decoration: highlightedTiles != null && highlightedTiles!.contains(i) ? BoxDecoration(
							color: Theme.of(context).canvasColor,
							boxShadow: <BoxShadow>[
								BoxShadow(
									color: !darkModeEnabled ? Colors.black : Colors.white,
									spreadRadius: PADDING_SIZE * 0.5,
								),
							],
						) : null,
					)
				)
			);
		}

		return Column(
			children: <Widget>[
				SizedBox(
					height: widget.size,
					width: widget.size,
					child: Stack(
						children: cells,
					),
				),
			],
		);
	}
}
