import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_cartesian_plane/cartesian_widget.dart';
import 'package:flutter_cartesian_plane/cartesian_utils.dart';

void main() {
  runApp(Example());
}

class Example extends StatefulWidget {
  @override
  _ExampleState createState() => _ExampleState();
}

Map<ThemeMode, IconData> themeIconMap = {
  ThemeMode.system: Icons.brightness_auto,
  ThemeMode.dark: Icons.brightness_3,
  ThemeMode.light: Icons.brightness_high
};

class _ExampleState extends State<Example> {
  ThemeMode themeMode = ThemeMode.system;

  Widget buildThemeSwitcher() => Builder(
      builder: (BuildContext context) => IconButton(
          icon: Icon(themeIconMap[themeMode]),
          onPressed: () => setState(() => themeMode =
              themeMode.index + 1 < ThemeMode.values.length
                  ? ThemeMode.values[themeMode.index + 1]
                  : ThemeMode.values.first)));

  static List<U> mapWithI<U, T>(List<T> list, U Function(int, T) map) {
    final tgt = List<U>(list.length);
    for (var i = 0; i < list.length; i++) {
      tgt[i] = map(i, list[i]);
    }
    return tgt;
  }

  Widget wrapFunction(String name, {MathFunc func, List<MathFunc> funcs}) =>
      FractionallySizedBox(
        heightFactor: 0.95,
        widthFactor: 0.95,
        child: Card(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            widthFactor: 0.9,
            child: Column(
              children: <Widget>[
                Text(name),
                Spacer(),
                CartesianPlane(
                    aspectRatio: 2,
                    coords: Rect.fromLTRB(0, 1, 4 * pi, -1),
                    defs: func == null
                        ? mapWithI(
                            funcs,
                            (i, e) => FunctionDef(
                                color: Theme.of(context).accentColor,
                                func: e,
                                hash: Theme.of(context).hashCode +
                                    name.hashCode * (i + 3)))
                        : [
                            FunctionDef(
                                color: Theme.of(context).accentColor,
                                func: func,
                                hash: Theme.of(context).hashCode,
                                name: name)
                          ])
              ],
              mainAxisSize: MainAxisSize.min,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Cartesian Plane example'),
          actions: <Widget>[buildThemeSwitcher()],
        ),
        body: GridView(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300, childAspectRatio: 1.3),
          children: <Widget>[
            wrapFunction('Sine', func: sin),
            wrapFunction('Cosine', func: cos),
            wrapFunction('Sin & Cos', funcs: [sin, cos]),
            wrapFunction('Theta - Sin theta', func: (double x) => sin(x) - x),
            wrapFunction('Theta & Sin theta', funcs: [sin, (double x) => x]),
            wrapFunction('Sine', func: sin),
            wrapFunction('Cosine', func: cos),
            wrapFunction('Sin & Cos', funcs: [sin, cos]),
            wrapFunction('Theta - Sin theta', func: (double x) => sin(x) - x),
            wrapFunction('Theta & Sin theta', funcs: [sin, (double x) => x]),
            wrapFunction('Sine', func: sin),
            wrapFunction('Cosine', func: cos),
            wrapFunction('Sin & Cos', funcs: [sin, cos]),
            wrapFunction('Theta - Sin theta', func: (double x) => sin(x) - x),
            wrapFunction('Theta & Sin theta', funcs: [sin, (double x) => x]),
            wrapFunction('Sine', func: sin),
            wrapFunction('Cosine', func: cos),
            wrapFunction('Sin & Cos', funcs: [sin, cos]),
            wrapFunction('Theta - Sin theta', func: (double x) => sin(x) - x),
            wrapFunction('Theta & Sin theta', funcs: [sin, (double x) => x]),
            wrapFunction('Sine', func: sin),
            wrapFunction('Cosine', func: cos),
            wrapFunction('Sin & Cos', funcs: [sin, cos]),
            wrapFunction('Theta - Sin theta', func: (double x) => sin(x) - x),
            wrapFunction('Theta & Sin theta', funcs: [sin, (double x) => x]),
            wrapFunction('Sine', func: sin),
            wrapFunction('Cosine', func: cos),
            wrapFunction('Sin & Cos', funcs: [sin, cos]),
            wrapFunction('Theta - Sin theta', func: (double x) => sin(x) - x),
            wrapFunction('Theta & Sin theta', funcs: [sin, (double x) => x]),
            wrapFunction('Sine', func: sin),
            wrapFunction('Cosine', func: cos),
            wrapFunction('Sin & Cos', funcs: [sin, cos]),
            wrapFunction('Theta - Sin theta', func: (double x) => sin(x) - x),
            wrapFunction('Theta & Sin theta', funcs: [sin, (double x) => x]),
            wrapFunction('Sine', func: sin),
            wrapFunction('Cosine', func: cos),
            wrapFunction('Sin & Cos', funcs: [sin, cos]),
            wrapFunction('Theta - Sin theta', func: (double x) => sin(x) - x),
            wrapFunction('Theta & Sin theta', funcs: [sin, (double x) => x]),
            wrapFunction('Sine', func: sin),
            wrapFunction('Cosine', func: cos),
            wrapFunction('Sin & Cos', funcs: [sin, cos]),
            wrapFunction('Theta - Sin theta', func: (double x) => sin(x) - x),
            wrapFunction('Theta & Sin theta', funcs: [sin, (double x) => x]),
          ],
        ),
      ),
    );
  }
}
