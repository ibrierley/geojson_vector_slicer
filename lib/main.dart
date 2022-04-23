import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tile_state/tile_state.dart';
import 'package:geojson_vt_dart/index.dart';
import 'package:flutter_map/plugin_api.dart';
import 'dart:ui' as dartui;
import 'dart:math';
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

class  Epsg3857Infinite extends Epsg3857 {
  @override
  final infinite = true;
}


class _MyHomePageState extends State<MyHomePage> {

  late final MapController mapController;
  GeoJSONVT? geoJson;
  var infoText = 'No Info';
  var tileSize = 256.0;
  // Guessing best val here depends on a zoom level where there aren't many polys in display
  var tilePointCheckZoom = 14;

  @override
  void initState() async {
    super.initState();
    mapController = MapController();

    WidgetsBinding.instance!.addPostFrameCallback((_) async {

      //https://raw.githubusercontent.com/Azure-Samples/AzureMapsCodeSamples/master/AzureMapsCodeSamples/Common/data/geojson/US_County_Boundaries.json
      // https://www.mapchart.net/usa-counties.html
      var json = jsonDecode(await rootBundle.loadString('assets/US_County_Boundaries.json'));

      geoJson = GeoJSONVT(json, {
        'debug' : 0,
        'buffer' : 64,
        'indexMaxZoom': 14,
        'indexMaxPoints': 10000000,
        'tolerance' : 0, // 1 is probably ok, 2+ may be odd if you have adjacent polys lined up and gets simplified
        'extent': tileSize});
      setState(() { });
    });

  }

  @override
  Widget build(BuildContext context) {

    return Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              //crs:  Epsg3857Infinite as Crs,
             // center: LatLng(51.5, -0.09),
              //center: LatLng(32.033638,	-84.398224), // us
              onTap: (tapPosition, point) {
                var pt = const Epsg3857().latLngToPoint(point, 14);

                var x = (pt.x / tileSize).floor();
                var y = (pt.y / tileSize).floor();
                var tile = geoJson!.getTile(14, x, y);

                if(tile != null) {
                  for (var feature in tile.features) {
                    var polygonList = feature['geometry'];

                    if (feature['type'] != 1) {
                      if(isGeoPointInPoly(pt, polygonList, size: tileSize)) {
                         infoText = "${feature['tags']['NAME']}, ${feature['tags']['COUNTY']} tapped";
                      }
                    }
                  }
                }
                setState(() {});
                },
              center: LatLng(-2.219988165689301, 56.870017401753529),
              zoom: 2.0,
              maxZoom: 15.0,
              minZoom: 0.0,
              //interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate
            ),
            children: <Widget>[
              TileLayerWidget(
                options: TileLayerOptions(
                    opacity: 0.8,
                    urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c']),
              ),
              SliceLayerWidget(index: geoJson, markerFunc: (feature, count) {
                return Container(
                child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text("$count")
                    ),
                    decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red[500]!
                    //color: ,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20))
                  )
                );
              })
            ],
            ),
    ]);
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
    ..strokeWidth = 0.9
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = false;

  VectorPainter({ required this.mapState, this.index, this.stream });

  @override
  void paint(Canvas canvas, Size size) {
    tileState = TileState(mapState, const CustomPoint(256.0, 256.0));

    tileState!.loopOverTiles( (i,j, pos, matrix) {
      var tile = index?.getTile(tileState!.getTileZoom().toInt(), i, j);

      final featuresInTile = [];

      if (tile != null && tile.features.isNotEmpty) {
        featuresInTile.addAll(tile.features);
      }

      canvas.save();
      canvas.transform(matrix.storage);
      var myRect = const Offset(0, 0) & const Size(256.0, 256.0);
      canvas.clipRect(myRect);
      //FeatureDraw().draw(featuresInTile, pos, canvas, {});
      FeatureDraw().batchCallsDraw(featuresInTile, pos, canvas, {});
      canvas.restore();

    });
  }

  @override
  bool shouldRepaint(VectorPainter oldDelegate) => true;
}

class SliceLayerWidget extends StatefulWidget {
  final GeoJSONVT? index;
  final Function? markerFunc;

  const SliceLayerWidget({Key? key, this.index, this.markerFunc}) : super(key: key); // : super(key: key);

  @override
  _SliceLayerWidgetState createState() => _SliceLayerWidgetState();
}

class _SliceLayerWidgetState extends State<SliceLayerWidget> {

  @override
  Widget build(BuildContext context) {

    final mapState = MapState.maybeOf(context)!;

    var width = MediaQuery.of(context).size.width * 2.0;
    var height = MediaQuery.of(context).size.height;

    return StreamBuilder<void>(
        stream: mapState.onMoved,
        builder: (BuildContext context, _) {

          var box = SizedBox(
              width: width*1.25, /// calculate this properly depending on rotation and mobile orientation
              height: height*1.25,
              child: RepaintBoundary (
                  child: CustomPaint(
                      child: FeatureDraw().drawClusters(mapState, widget.index, mapState.onMoved, widget.markerFunc),
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


class FeatureDraw {
  Widget drawClusters(MapState mapState, index, stream, markerFunc) {

    List<Positioned> markers = [];

    var clusterZoom = 1;
    var clusterFactor = pow(2,clusterZoom);

    var tileState = TileState(mapState, const CustomPoint(256.0, 256.0));
    var clusterPixels = 256 / clusterFactor; /// how much do we want to split the tilesize into, 32 = 8 chunks by 8
    var center = clusterPixels / 2.0;

    if(index != null) {

      tileState.loopOverTiles( (i,j, pos, matrix) {

        for( var clusterTileX = 0; clusterTileX < clusterFactor ; clusterTileX++) {

          for( var clusterTileY = 0; clusterTileY < clusterFactor ; clusterTileY++) {

            var innerTileFeatures = index.getTile(
                tileState.getTileZoom().toInt() + clusterZoom, i * clusterFactor + clusterTileX, j * clusterFactor + clusterTileY);
            if(innerTileFeatures != null) {
              var count = innerTileFeatures.features.length;

              if(count > 0) {
                var tp = MatrixUtils.transformPoint(matrix,
                    Offset((clusterTileX * clusterPixels + center).toDouble(), (clusterTileY * clusterPixels + center).toDouble()));

                markers.add(
                    Positioned(
                        width: 30,
                        height: 30,
                        left: tp.dx, // + zoomTileX*32,
                        top: tp.dy, // +zoomTileY*32,
                        child: Transform.rotate(
                            alignment: FractionalOffset.center,
                            angle: -mapState.rotationRad,
                            child: markerFunc == null ? FittedBox(
                                fit: BoxFit.contain,
                                child: Text("$count", style: const TextStyle(fontSize: 20))
                            ) :  markerFunc( innerTileFeatures, count ),
                        )
                    )
                );
              }
            }
          }
        }
      });
    }

    return Stack(children: markers);
  }

  Widget drawMarkers(MapState mapState, index, stream, markerFunc) {

    var tileState = TileState(mapState, const CustomPoint(256.0, 256.0));

    List<Widget> markers = [];

    tileState.loopOverTiles( (i,j, pos, matrix) {
      if (index != null) {
        var tile = index.getTile(tileState.getTileZoom().toInt(), i, j);

        final featuresInTile = [];

        if (tile != null && tile.features.isNotEmpty) {
          featuresInTile.addAll(tile.features);
        }

        outerloop: for (var feature in featuresInTile) {
          innerloop: for( var geom in feature['geometry'] ) {
            if (feature['type'] != 1) {
              break innerloop;
            }
            geomloop: for (var c = 0; c < geom.length; c++) {
              var pt = geom[c] is List ? geom[c] : geom;
              var tp = MatrixUtils.transformPoint(matrix,
                  Offset(pt[0].toDouble() - 0.0, pt[1].toDouble() - 0.0));

              markers.add(
                Positioned(
                    width: 60,
                    height: 60,
                    left: tp.dx - 20,
                    top: tp.dy - 20,
                    child: markerFunc == null ? Text("Missing") : markerFunc(
                        feature, geom)),
                //),
              );
            }
          }
        }
      }
    });

    return Container(
      child: Stack(
        children: markers,
      ),
    );
  }

  void draw(List<dynamic> featuresInTile, PositionInfo pos, Canvas canvas, [ Map options = const {} ]) {

    var delayedDrawHash = { 'anyOrderPaths': dartui.Path() };

    for (var feature in featuresInTile) {
      if (feature['type'] == 3) {
        if (options.containsKey('polyDrawFunc')) {
          options['polyDrawFunc'](canvas, feature, pos, featuresInTile, delayedDrawHash);
        } else {
          drawPolylineDefault(canvas, feature, pos);
        }
      } else if( feature['type'] == 1 ) {
        var style = Paint()
          ..strokeWidth = 0.5 / pos.scale
          ..color = Colors.blue
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(feature['geometry'][0][0].toDouble(),feature['geometry'][0][1].toDouble()),20,style);
      }
    }
  }

  Paint defaultStyle = Paint()
    ..strokeWidth = 0.9
    ..color = Colors.red
    ..style = PaintingStyle.stroke;

  void drawPolylineDefault( canvas, feature, PositionInfo pos ) {
    var style = Paint()
      ..strokeWidth = 0.5 / pos.scale
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    var p = dartui.Path();

    for( var item in feature['geometry'] ) {
      List<Offset> offsets = [];
      for (var c = 0; c < item.length; c++) {
        offsets.add(Offset(item[c][0].toDouble(), item[c][1].toDouble()));
      }
      p.addPolygon(offsets, false);
    }

    canvas.drawPath(p, style);
  }

  void batchCallsDraw(List<dynamic> featuresInTile, PositionInfo pos, Canvas canvas, [ Map options = const {} ]) {
    var superPath = dartui.Path();
    for (var feature in featuresInTile) {
      if (feature['type'] == 3) {
        for( var item in feature['geometry'] ) {
          List<Offset> offsets = [];
          for (var c = 0; c < item.length; c++) {
            offsets.add(Offset(item[c][0].toDouble(), item[c][1].toDouble()));
          }
          superPath.addPolygon(offsets, false);
        }
      }

    }
    canvas.drawPath(superPath, defaultStyle);
  }
}

bool isGeoPointInPoly(CustomPoint pt, List polygonList, {size = 256.0}) {
  var x = (pt.x / size).floor();
  var y = (pt.y / size).floor();

  int lat = 0;
  int lon = 1;
  bool isInPoly = false;

  num ax = pt.x - size * x;
  num ay = pt.y - size * y;

  for (var polygon in polygonList) {
    for (int i = 0, j = polygon.length - 1; i < polygon.length;

    j = i++) {

      if ((((polygon[i][lat] <= ax) &&
          (ax < polygon[j][lat])) ||
          ((polygon[j][lat] <= ax) &&
              (ax < polygon[i][lat]))) &&
          (ay <
              (polygon[j][lon] - polygon[i][lon]) *
                  (ax - polygon[i][lat]) /
                  (polygon[j][lat] - polygon[i][lat]) +
                  polygon[i][lon])) {

        isInPoly = true;
      }
    }
  }
  return isInPoly;
}