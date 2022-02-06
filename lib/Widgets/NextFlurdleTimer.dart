
import 'package:flutter/material.dart';

class NextFlurdleTimer extends StatefulWidget {
  const NextFlurdleTimer({Key? key}) : super(key: key);

	@override
	NextFlurdleTimerState createState() => NextFlurdleTimerState();
}

class NextFlurdleTimerState extends State<NextFlurdleTimer> {

	@override
	void initState() {
    super.initState();
    update();
  }

	Future<void> update() async{
		while (mounted) {
			await Future<void>.delayed(const Duration(seconds: 1));
			if (mounted) {
				setState(() {});
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		
		final DateTime now = DateTime.now();
		final DateTime nowPlusOneDay = now.add(const Duration(hours: 24));
		final DateTime tomorrow = DateTime(nowPlusOneDay.year, nowPlusOneDay.month, nowPlusOneDay.day);
		final String time = tomorrow.difference(now).toString();
		
		return Text("Next Flurdle in: ${time.substring(0, time.length - 7)}.", style: const TextStyle(fontWeight: FontWeight.bold));
	}
}
