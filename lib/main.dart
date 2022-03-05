import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tile_state/tile_state.dart';
import 'package:geojson_vt_dart/index.dart';
import 'package:flutter_map/plugin_api.dart';
import 'dart:ui' as dartui;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late final MapController mapController;
  GeoJSONVT? geoJson;

  @override
  void initState() async {
    super.initState();
    mapController = MapController();

    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      var json = jsonDecode(await rootBundle.loadString('assets/us-states.json'));
      print("JSON IS $json");

      geoJson = GeoJSONVT(json, {
        'debug' : 0,
        'buffer' : 64,
        'indexMaxZoom': 20,
        'indexMaxPoints': 10000000,
        'tolerance' : 0,
        'extent': 256.0});
      print("VT DONE $geoJson");
      print("gt ${geoJson?.getTile(0,0,0)}");
      print("gt2 ${geoJson?.getTile(5,9,15)}");
      setState(() { });
    });

  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: LatLng(51.5, -0.09),
        zoom: 5.0,
        maxZoom: 15.0,
        minZoom: 0.0,
        //interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate
      ),
      children: <Widget>[
        TileLayerWidget(
          options: TileLayerOptions(
              opacity: 0.3,
              urlTemplate:
              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c']),
        ),
        SliceLayerWidget(index: geoJson)
      ],
    );
  }
}

class VectorPainter extends CustomPainter with ChangeNotifier {

  final Stream<Null>? stream;
  GeoJSONVT? index;
  MapState mapState;
  TileState? tileState;
  Paint defaultStyle = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.red
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = false;

  VectorPainter({ required this.mapState, this.index, this.stream });

  @override
  void paint(Canvas canvas, Size size) {

    Bounds _tileRange;

    tileState = TileState(mapState, CustomPoint(256.0, 256.0));

    _tileRange = tileState!.getTileRange();

    for (var j = _tileRange.min.y; j <= _tileRange.max.y; j++) {
      for (var i = _tileRange.min.x; i <= _tileRange.max.x; i++) {

        var tile = index?.getTile(tileState!.getTileZoom().toInt(), i, j);

        final featuresInView = [];

        if(tile != null && tile.features.isNotEmpty) {
          featuresInView.addAll(tile.features);
        }

        var pos = tileState!.getTilePositionInfo(tileState!.getTileZoom(), i.toDouble(), j.toDouble());

        var matrix = Matrix4.identity();
        matrix
          ..translate(pos.point.x.toDouble(), pos.point.y.toDouble())
          ..scale(pos.scale);

        canvas.save();
        canvas.transform(matrix.storage);
        var myRect = Offset(0,0) & Size(256.0,256.0);
        canvas.clipRect(myRect);

        var p = dartui.Path();

        for (var feature in featuresInView) {
          if( feature['type'] == 3) {
            for( var item in feature['geometry'] ) {
              p.moveTo(item[0][0].toDouble(), item[0][1].toDouble());
              for (var c = 1; c < item.length; c++) {
                p.lineTo(item[c][0].toDouble(), item[c][1].toDouble());
              }
            }
          }
        }

        var style = defaultStyle..strokeWidth = 4 / pos.scale;
        canvas.drawPath(p, style);
        canvas.restore();

      }
    }
  }

  @override
  bool shouldRepaint(VectorPainter oldDelegate) => true;
}

class SliceLayerWidget extends StatefulWidget {
  final GeoJSONVT? index;

  SliceLayerWidget({Key? key, this.index}) : super(key: key); // : super(key: key);

  @override
  _SliceLayerWidgetState createState() => _SliceLayerWidgetState();
}

class _SliceLayerWidgetState extends State<SliceLayerWidget> {

  @override
  Widget build(BuildContext context) {

    final mapState = MapState.maybeOf(context)!;

    var width = MediaQuery.of(context).size.width * 2.0;
    var height = MediaQuery.of(context).size.height;
    var dimensions = Offset(width,height);

    return StreamBuilder<void>(
        stream: mapState.onMoved,
        builder: (BuildContext context, _) {

          var box = SizedBox(
              width: width*1.25, /// calculate this properly depending on rotation and mobile orientation
              height: height*1.25,
              child: RepaintBoundary (
                  child: CustomPaint(
                      isComplex: true, //Tells flutter to cache the painter.
                      painter: VectorPainter(mapState: mapState, index: widget.index, stream: mapState.onMoved)
                  )
              )
          );
          return box;
        }
    );
  }
}
