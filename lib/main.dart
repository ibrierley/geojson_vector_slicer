import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tile_state/tile_state.dart';
import 'package:geojson_vt_dart/index.dart';
import 'package:geojson_vt_dart/transform.dart';
import 'package:geojson_vt_dart/classes.dart';
import 'package:flutter_map/plugin_api.dart';
import 'dart:ui' as dartui;
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'dart:async';
import 'dart:typed_data';
import 'package:tuple/tuple.dart';



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

  final _random = Random();
  double doubleInRange(num start, num end) =>
      _random.nextDouble() * (end - start) + start;

  late final MapController mapController;
  GeoJSONVT? geoJsonIndex;
  var infoText = 'No Info';
  var tileSize = 256.0;
  var tilePointCheckZoom = 14;

  GeoJSON geoJSON = GeoJSON();


  @override
  void initState() async {
    super.initState();
    mapController = MapController();
    CustomImages().loadPlane();

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      geoJsonIndex = await geoJSON.createIndex('assets/US_County_Boundaries.json', tileSize: tileSize);
      //geoJsonIndex = await geoJSON.createIndex('assets/polygon_hole.json', tileSize: 256);
      //geoJsonIndex = await geoJSON.createIndex('assets/general.json', tileSize: 256);
      //geoJsonIndex = await geoJSON.createIndex('assets/earthquake.geojson', tileSize: 256);
      setState(() {
      });
    });

  }

  String? featureSelected;

  @override
  Widget build(BuildContext context) {

    return Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              onTap: (tapPosition, point) {
                var pt = const Epsg3857().latLngToPoint(point, 14);

                var x = (pt.x / tileSize).floor();
                var y = (pt.y / tileSize).floor();
                var tile = geoJsonIndex!.getTile(14, x, y);

                if(tile != null) {
                  for (var feature in tile.features) {
                    var polygonList = feature.geometry;

                    if (feature.type != 1) {
                      if(geoJSON.isGeoPointInPoly(pt, polygonList, size: tileSize)) {
                         infoText = "${feature.tags['NAME']}, ${feature.tags['NAME']} tapped";
                         if(feature.tags.containsKey('NAME')) {
                           featureSelected = "${feature.tags['NAME']}_${feature.tags['COUNTY']}";
                         }
                         print("Tapped $infoText $featureSelected");
                      }
                    }
                  }
                }
                setState(() {});
                },
              center: LatLng(-2.219988165689301, 56.870017401753529),
              zoom: 2.2,
              maxZoom: 15.0,
              minZoom: 0.0,
              //interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate
            ),
              layers: [
                MarkerLayerOptions(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(51.5, -0.09),
                      builder: (ctx) =>
                      const FlutterLogo(),
                    ),
                  ],
                ),
              ],

            children: <Widget>[
              TileLayerWidget(
                options: TileLayerOptions(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c']),
              ),

                GeoJSONWidget(
                  index: geoJsonIndex,
                  options: GeoJSONOptions(
                    featuresHaveSameStyle: false,
                    overallStyleFunc: (TileFeature feature) {
                      var paint = Paint()
                        ..style = PaintingStyle.stroke
                        ..color = Colors.blue
                        ..strokeWidth = 5
                        ..isAntiAlias = false;
                      if(feature.type == 3) { // lineString
                        paint.style = PaintingStyle.fill;
                      }
                      return paint;
                    },
                    pointWidgetFunc: (TileFeature feature) {
                      return const Text("Point!", style: TextStyle(fontSize: 10));
                    },
                    pointStyle: (TileFeature feature) { return Paint(); },
                    //pointFunc: (TileFeature feature, Canvas canvas) {
                    //  if(CustomImages.imageLoaded) {
                    //    canvas.drawImage(CustomImages.plane, const Offset(0.0, 0.0), Paint());
                    //  }
                    //},
                    lineStringFunc: () { if(CustomImages.imageLoaded) return CustomImages.plane;},
                    polygonFunc: null,
                    polygonStyle: (feature) {
                      var paint = Paint()
                        ..style = PaintingStyle.fill
                        ..color = Colors.red
                        ..strokeWidth = 5
                        ..isAntiAlias = false;

                      if(feature.tags != null && "${feature.tags['NAME']}_${feature.tags['COUNTY']}" == featureSelected) {
                        return paint;
                      }
                      paint.color = Colors.lightBlueAccent;
                      return paint;
                    }
                  ),
                ),
            ]),
    ]);
  }
}


class CustomImages {
  static late dartui.Image plane;
  static late bool imageLoaded = false;

  void loadPlane() async {
    plane = await loadUiImage('assets/aeroplane.png');
    imageLoaded = true;
  }

  Future<dartui.Image> loadUiImage(String imageAssetPath) async {
    final ByteData data = await rootBundle.load(imageAssetPath);
    final Completer<dartui.Image> completer = Completer();
    dartui.decodeImageFromList(Uint8List.view(data.buffer), (dartui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }
}

class GeoJSON {
  Future<GeoJSONVT> createIndex(String jsonString, { GeoJSONVTOptions? options, num tileSize = 256 }) async  {
    var json = jsonDecode(await rootBundle.loadString(jsonString));

    options ??= GeoJSONVTOptions(
          debug : 0,
          buffer : 0,
          maxZoom: 22,
          indexMaxZoom: 22,
          indexMaxPoints: 10000000,
          tolerance : 0, // 1 is probably ok, 2+ may be odd if you have adjacent polys lined up and gets simplified
          extent: tileSize.toInt());
    
    GeoJSONVT geoJsonIndex = GeoJSONVT(json, options);

    return geoJsonIndex;
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

  // experimental, not sure this still works. rework to use with canvas, not widgets ???
  Widget drawClusters(MapState mapState, index, stream, markerFunc) {

    List<Positioned> markers = [];

    var clusterZoom = 1;
    var clusterFactor = pow(2,clusterZoom);

    var tileState = TileState(mapState, const CustomPoint(256.0, 256.0));
    var clusterPixels = 256 / clusterFactor; /// how much do we want to split the tilesize into, 32 = 8 chunks by 8

    if(index != null) {

      tileState.loopOverTiles( (i,j, pos, matrix) {

        for( var clusterTileX = 0; clusterTileX < clusterFactor ; clusterTileX++) {

          for( var clusterTileY = 0; clusterTileY < clusterFactor ; clusterTileY++) {

            var innerTileFeatures = index.getTile(
                tileState.getTileZoom().toInt() + clusterZoom, i * clusterFactor + clusterTileX, j * clusterFactor + clusterTileY);

            if(innerTileFeatures != null && innerTileFeatures.features.length > 0) {

              var count = innerTileFeatures.features.length;

              var bMin = transformPoint(innerTileFeatures.minX,innerTileFeatures.minY,256,1 << tileState.getTileZoom().toInt() + clusterZoom,innerTileFeatures.x,innerTileFeatures.y);
              var bMax = transformPoint(innerTileFeatures.maxX,innerTileFeatures.maxY,256,1 << tileState.getTileZoom().toInt() + clusterZoom,innerTileFeatures.x,innerTileFeatures.y);

              var bbX = ((bMax[0] - bMin[0]) / 2 + bMin[0]);
              var bbY = ((bMax[1] - bMin[1]) / 2 + bMin[1]);


              if(count > 0) {
                var tp = MatrixUtils.transformPoint(matrix,
                    Offset((clusterTileX * clusterPixels + bbX / clusterFactor).toDouble(), (clusterTileY * clusterPixels + bbY / clusterFactor).toDouble()));

                markers.add(
                    Positioned(
                        width: 40,
                        height: 40,
                        left: tp.dx, // + zoomTileX*32,
                        top: tp.dy, // +zoomTileY*32,
                        child: Transform.rotate(
                          alignment: FractionalOffset.center,
                          angle: -mapState.rotationRad,
                          child: markerFunc == null ? FittedBox(
                              fit: BoxFit.contain,
                              child: Text("$count, ", style: const TextStyle(fontSize: 10))
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

}

class GeoJSONWidget extends StatefulWidget {
  final GeoJSONVT? index;
  final Function? drawFunc;
  final bool clusters;
  final bool markers;
  final bool noSlice;
  final GeoJSONOptions options;

  const GeoJSONWidget({Key? key, this.index, this.drawFunc, this.clusters = false, this.markers = false, this.noSlice = false, required this.options }) : super(key: key); // : super(key: key)
  @override
  _GeoJSONWidgetState createState() => _GeoJSONWidgetState();
}


class _GeoJSONWidgetState extends State<GeoJSONWidget> {

  @override
  Widget build(BuildContext context) {

    final mapState = MapState.maybeOf(context)!;

    Map<String,Widget> lastTileWidgets = {};
    Map<String,Widget> currentTileWidgets = {};


    return StreamBuilder<void>(
        stream: mapState.onMoved,
        builder: (BuildContext context, _) {

          TileState tileState = TileState(mapState, const CustomPoint(256.0, 256.0));

          List<Widget> allTileStack = [];
          List<Widget> allTileUpperStack = [];
          currentTileWidgets = {};

          tileState.loopOverTiles((i, j, pos, matrix) {

            List<Widget> thisTileStack = <Widget>[];

            var tile = widget.index?.getTile(
                tileState.getTileZoom().toInt(), i, j);

            if (tile != null) {

              int startRange = 0;
              int endRange = 0;
              for (int c = 0; c < tile.features.length; c++) {

                var feature = tile.features[c];
                var type = feature.type;

                if( type == 1 && widget.options.pointWidgetFunc != null ) {

                  var tp = MatrixUtils.transformPoint(matrix, Offset(feature.geometry[0][0].toDouble(),feature.geometry[0][1].toDouble()));

                  allTileUpperStack.add(
                    Positioned(
                      left: tp.dx,
                       top: tp.dy,
                        child: widget.options.pointWidgetFunc!(feature)
                    )
                  );
                  startRange++;
                } else {
                  if(c == tile.features.length - 1 || (tile.features[c+1] == 1 && widget.options.pointWidgetFunc != null )) {
                    var subList = tile.features.sublist(startRange,endRange+1);

                    FeatureVectorPainter painterWidget = FeatureVectorPainter(mapState: mapState,
                        features: subList,
                         options: widget.options, matrix: matrix, pos: pos );
                    thisTileStack.add( CustomPaint(
                      size: const Size(256.0,256.0),
                        isComplex: true, //Tells flutter to cache the painter, although it probably won't!
                        painter: painterWidget));
                  } else {
                    // deferring
                  }
                }
                endRange++;
              }
            }

            var tileKey = '${tileState.getTileZoom().toInt()}_${i}_$j';

            currentTileWidgets[tileKey] = Stack(children: thisTileStack);

            Widget newWidget;
            if(lastTileWidgets.containsKey(tileKey)) {
              // this actually probably isn't optimising much, as the paint
              // will be called a lot anyway
              newWidget = lastTileWidgets[tileKey]!;
            } else {
              newWidget = Stack(children: thisTileStack);
            }

            currentTileWidgets[tileKey] = newWidget;

            // ideally for optimisation we'd put the RepaintBoundary on the newWidget
            // but this will cause hairlines between tiles sometimes.
            if(thisTileStack.isNotEmpty) {
              allTileStack.add(
                RepaintBoundary(child: Transform(child: newWidget, transform: matrix))
              );
            }
          });
          lastTileWidgets = currentTileWidgets;

          return Stack(children: [
            Stack(children: allTileStack),
            Stack(children: allTileUpperStack)
          ]);
        }
    );
  }
}

class GeoJSONOptions {
    Function? lineStringFunc;
    Function? lineStringStyle;
    Function? polygonFunc;
    Function? polygonStyle;
    Function? pointFunc;
    Function? pointWidgetFunc;
    Function? pointStyle;
    Function? overallStyleFunc;
    bool featuresHaveSameStyle;

    GeoJSONOptions({this.lineStringFunc, this.lineStringStyle, this.polygonFunc,
      this.polygonStyle, this.pointFunc, this.pointWidgetFunc, this.pointStyle,
      this.overallStyleFunc, this.featuresHaveSameStyle = false});

}

class FeatureVectorPainter extends CustomPainter with ChangeNotifier {

  final Stream<Null>? stream;
  final GeoJSONOptions options;
  final List features;
  MapState mapState;
  Matrix4 matrix;
  PositionInfo pos;
  Paint? singleStyle;

  FeatureVectorPainter({ required this.mapState, required this.features, this.stream, required this.options, required this.matrix, required this.pos  });


  Paint getDefaultStyle(int type) {
    Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = false;

    if( type == 2) {
      paint.style = PaintingStyle.stroke;
    }
    return paint;
  }

  @override
  void paint(Canvas canvas, Size size) {
    draw(features, pos, canvas, options);
  }


  void draw(List<dynamic> features, PositionInfo pos, Canvas canvas, GeoJSONOptions options) async  {

    // Batch paths where possible...
    var superPath = dartui.Path();

    for( var count = 0; count < features.length; count++ ) {

      var feature = features[count];
      var type = feature.type;

      Paint featurePaint;

      if (type == 1 && options.pointStyle != null) {
        featurePaint = options.pointStyle!(feature);
      } else if (type == 2 && options.lineStringStyle != null) {
        featurePaint = options.lineStringStyle!(feature);
      } else if (type == 3 && options.polygonStyle != null) {
        featurePaint = options.polygonStyle!(feature);
      } else if (options.overallStyleFunc != null) {
        featurePaint = options.overallStyleFunc!(feature);
      } else {
        featurePaint = getDefaultStyle(type);
      }

      if (type == 1) { // point
        canvas.save();
        canvas.translate(feature.geometry[0][0].toDouble(),
            feature.geometry[0][1].toDouble());
        canvas.scale(1 / pos.scale);
        if (options.pointFunc != null) {
          options.pointFunc!(feature, canvas);
        } else {
          canvas.drawCircle(const Offset(0,0), 5, featurePaint);
        }
        canvas.restore();
      }

      if(type == 2 || type == 3) { // line = 2, poly = 3


        var path = dartui.Path();
        for( var item in feature.geometry ) {

          List<Offset> offsets = [];
          for (var c = 0; c < item.length; c++) {
            offsets.add(Offset(item[c][0].toDouble(), item[c][1].toDouble()));
          }
          path.addPolygon(offsets,false);
        }

        featurePaint.strokeWidth = featurePaint.strokeWidth / pos.scale;
        // polygon MUST have fill type whatever
        if(type == 3) {
          featurePaint.style = PaintingStyle.fill;
        }

        if(options.featuresHaveSameStyle) {
          superPath.addPath(path, const Offset(0,0));
        } else {
          canvas.drawPath(path, featurePaint);
        }

        // We may get a mixed polgon followed by a point or line, so we want to
        // draw now to preserve order, but if all the same style may as well batch
        if((count < features.length - 1 && (features[count+1].type != type) ) ||
            (count == features.length - 1)) {
          canvas.drawPath(superPath, featurePaint);
          superPath = dartui.Path();
        }
      }
    }
  }

  @override
  bool shouldRepaint(FeatureVectorPainter oldDelegate) => oldDelegate.features != features ;

}



