import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_cartesian_plane/cartesian_widget.dart';
import 'package:flutter_cartesian_plane/cartesian_utils.dart';
import 'package:flutter_cartesian_plane/cartesian_computation.dart' as def;
import 'package:flutter_cartesian_plane/computation/sdk/process_image.dart' as sdk;
import 'package:efficient_uint8_list/efficient_uint8_list.dart';

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
  bool usingFfi = true;
  bool usingIsolate = false;
  int lastTimeTaken = 0;
  int seed = 0;

  Future<PackedUint8List> timedConversor(def.PixelDataMessage msg) async {
    final ImageConversor conversor = usingFfi ? def.asyncProcessImage : usingIsolate ? def.parallelProcessImage : sdk.asyncProcessImage;
    final timer = Stopwatch()..start();
    final img = await conversor(msg);
    timer.stop();
    setState(() {
      lastTimeTaken = timer.elapsedMicroseconds;
    });
    return img;
  }

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
                Expanded(
                                  child: CartesianPlane(
                      coords: Rect.fromLTRB(0, 1, 4 * pi, -1).toCoords(),
                      customConversor: timedConversor,
                      defs: func == null
                          ? mapWithI<FunctionDef, MathFunc>(
                              funcs,
                              (i, e) => FunctionDef(
                                  color: Theme.of(context).accentColor.value,
                                  func: e,
                                  hash: Theme.of(context).hashCode +
                                      name.hashCode * (i + 3) * usingFfi.hashCode * usingIsolate.hashCode * seed))
                          : [
                              FunctionDef(
                                  color: Theme.of(context).accentColor.value,
                                  func: func,
                                  hash: Theme.of(context).hashCode * usingFfi.hashCode * usingIsolate.hashCode * seed,
                                  name: name)
                            ]),
                )
              ],
              mainAxisSize: MainAxisSize.min,
            ),
          ),
        ),
      );
    
  List<Widget> buildImplSwitcher() => [Text('Ffi'),Checkbox(value: usingFfi, onChanged: (b) => setState(() => usingFfi = b))];
  List<Widget> buildIsolateSwitcher() => [Text('Isolate'),Checkbox(value: usingIsolate && !usingFfi, onChanged: !usingFfi ? (b) => setState(() => usingIsolate = b) : null)];

  void refresh() {
    setState(() {
      seed = DateTime.now().hashCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Cartesian Plane example'),
          actions: <Widget>[buildThemeSwitcher(), ...buildImplSwitcher(), ...buildIsolateSwitcher()],
        ),
        floatingActionButton: FloatingActionButton(onPressed: refresh, child: Icon(Icons.refresh)),
        body: Column(
          children: <Widget>[
            Text('Last img took ${lastTimeTaken}us'),
            Expanded(child: wrapFunction('sine & theta', funcs: [sin, (double x) => x])),
          ],
        ),
      ),
    );
  }
}
