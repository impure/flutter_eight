
import 'package:flutter/material.dart';
import 'package:state_groups/state_groups.dart';

StateGroup<void> counterGroup = StateGroup<void>();

class Counter extends StatefulWidget {
	const Counter(this.size, this.numberGenerator, {Key? key}) : super(key: key);

	final double size;
	final int Function() numberGenerator;

	@override
	CounterState createState() => CounterState();
}

class CounterState extends SyncState<void, Counter> {
  CounterState() : super(counterGroup);

  @override
  Widget build(BuildContext context) {
		return SizedBox(
			height: widget.size,
			width: widget.size,
			child: Center(
				child: Container(
					height: widget.size * 0.5,
					width: widget.size * 0.5,
					color: Colors.black54,
					child: Center(
						child: Text(widget.numberGenerator().toString())
					),
				),
			),
		);
  }

}
