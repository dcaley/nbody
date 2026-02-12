import 'package:flutter/material.dart';
import 'package:nbody/model.dart';

import 'screen_painter.dart';

class Home extends StatefulWidget{

  const Home({super.key});

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> with SingleTickerProviderStateMixin{

  final model = Model();
  late final AnimationController animationController;

  @override
  initState(){

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20),
    )..repeat();

    // defer because we need screen size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      model.create();
      model.startTimer();
    });
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: CustomPaint(
          painter: ScreenPainter(model, repaint: animationController),
          // the empty child is needed to give the canvas a non-zero height
          child: GestureDetector(onPanUpdate: (d) => model.drag(d.delta)),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(8.0),
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            getSlider(
              title: "Galaxies",
              value: model.galaxyCount.toDouble(),
              min: 2,
              max: 5,
              divisions: 3,
              ticks: 4,
              labels: [2, 3, 4, 5].map((v) => Text(v.toStringAsFixed(0))).toList(),
              callback: (v) => setState(() => model.galaxyCount = v.toInt()),
            ),
            SizedBox(height: 10),
            getSlider(
              title: "Galaxy Radius",
              value: model.galaxyRadius.toDouble(),
              min: 50,
              max: 200,
              divisions: 3,
              labels: [50, 100, 150, 200].map((v) => Text(v.toStringAsFixed(0))).toList(),
              callback: (v) => setState(() => model.galaxyRadius = v.toInt()),
            ),
            SizedBox(height: 10),
            getSlider(
              title: "Stars",
              value: model.starCount.toDouble(),
              min: 20,
              max: 100,
              divisions: 8,
              labels: [20, 100].map((v) => Text(v.toStringAsFixed(0))).toList(),
              callback: (v) => setState(() => model.starCount = v.toInt()),
            ),
            SizedBox(height: 10),
            getSlider(
              title: "Core Mass",
              value: model.coreMass,
              min: 100,
              max: 10000,
              divisions: 99,
              labels: [2, 4].map((v) => Text("10^${v.toStringAsFixed(0)}")).toList(),
              callback: (v) => setState(() => model.coreMass = v),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Follow"),
                Switch(value: model.follow, onChanged: (v) => setState(() => model.follow = v)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Flatten"),
                Switch(value: model.flatten, onChanged: (v) => setState(() => model.flatten = v)),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  model.timer.isActive ? model.timer.cancel() : model.startTimer();
                  setState(() {});
                },
                child: Text(model.timer.isActive ? "Pause" : "Resume"),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: model.timer.isActive ? null : model.calc, child: Text("Step")),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: model.create, child: Text("Restart")),
            ),
          ],
        ),
      ),
    ],
  );

  Widget getSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    int ticks = 16,
    required List<Widget> labels,
    required Function(double) callback
  }){
    return InputDecorator(
      decoration: InputDecoration(
        labelText: "$title: ${value.toStringAsFixed(0)}",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Column(
        children: [
          Theme(
            data: ThemeData(sliderTheme: SliderTheme.of(context).copyWith(overlayShape: SliderComponentShape.noThumb)),
            child: Slider(
              divisions: divisions,
              min: min,
              max: max,
              value: value,
              onChanged: callback,
              label: value.toStringAsFixed(0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(ticks, (index) => SizedBox(
                    height: 5,
                    child: VerticalDivider(width: 8),
                  )),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: labels,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}