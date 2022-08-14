//import 'package:flutter/cupertino.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geojson_vt_dart/bak/tile.dart';
//import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tile_state/tile_state.dart' hide Coords;
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
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'vector_tile.pb.dart' as vector_tile;
import 'vector_tile.pbenum.dart';
import 'package:tuple/tuple.dart';
//import 'package:flutter_map/src/layer/tile_layer/coords.dart';

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
  VectorTileIndex vectorTileIndex = VectorTileIndex();


  @override
  void initState() async {
    //vectorTileIndex = GeoJSONVT({},GeoJSONVTOptions());
    super.initState();
    mapController = MapController();
    CustomImages().loadPlane();

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      //var geoPointMap = TestData().getSamplePointGeoJSON(100);
      //geoJsonIndex = await geoJSON.createIndex(null, tileSize: tileSize, geoJsonMap: geoPointMap);
      //geoJsonIndex = await geoJSON.createIndex('assets/test.json', tileSize: 256);
      geoJsonIndex = await geoJSON.createIndex('assets/US_County_Boundaries.json', tileSize: tileSize);
      //geoJsonIndex = await geoJSON.createIndex('assets/polygon_hole.json', tileSize: 256);
      //geoJsonIndex = await geoJSON.createIndex('assets/general.json', tileSize: 256);
      //geoJsonIndex = await geoJSON.createIndex('assets/uk.json', tileSize: 256);
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
              //allowPanningOnScrollingParent: false,
              absorbPanEventsOnScrollables: false,
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
             /// center: LatLng(-2.219988165689301, 56.870017401753529),
              center: LatLng(50.8344903, -0.186486 ),
              zoom: 2, //16.6,
              maxZoom: 17.0,
              minZoom: 0.0,
              //interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate
            ),
              children: [

              TileLayer(

               // options: TileLayer(
        //'https://maps.dabbles.info/index.php?x={x}&y={y}&z={z}&r=osm',
        //FqtZvgMGhQB-2AqzcvlpYznhg38kCt-bBx1OtvU7wLE
        //urlTemplate: "https://atlas.microsoft.com/map/tile/png?api-version=1&layer=basic&style=main&tileSize=256&view=Auto&zoom={z}&x={x}&y={y}&subscription-key=FqtZvgMGhQB-2AqzcvlpYznhg38kCt-bBx1OtvU7wLE",
    /*TileLayerOptions(
                    urlTemplate: "https://atlas.microsoft.com/map/tile/png?api-version=1&layer=basic&style=main&tileSize=256&view=Auto&zoom={z}&x={x}&y={y}&subscription-key={subscriptionKey}",
                    additionalOptions: {
                      'subscriptionKey': 'FqtZvgMGhQB-2AqzcvlpYznhg38kCt-bBx1OtvU7wLE'
                    },

                   */

                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
              ),




               /// VectorTileWidgetStream(size: 256.0, index: vectorTileIndex),


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
                        ///paint.style = PaintingStyle.fill;
                      }
                      return paint;
                    },
                    pointWidgetFunc: (TileFeature feature) {
                      //return const Text("Point!", style: TextStyle(fontSize: 10));
                      return const Icon(Icons.airplanemode_on);
                    },
                    pointStyle: (TileFeature feature) { return Paint(); },
                    pointFunc: (TileFeature feature, Canvas canvas) {
                      if(CustomImages.imageLoaded) {
                        canvas.drawImage(CustomImages.plane, const Offset(0.0, 0.0), Paint());
                      }
                    },
                    ///clusterFunc: () { return Text("Cluster"); },
                    ///lineStringFunc: () { if(CustomImages.imageLoaded) return CustomImages.plane;},
                      ///
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

])


            //]),
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
  Future<GeoJSONVT> createIndex(String? jsonString, { GeoJSONVTOptions? options, num tileSize = 256, geoJsonMap }) async  {
    Map geoMap;
    if(geoJsonMap != null) {
      geoMap = geoJsonMap;
    } else {
      geoMap = jsonDecode(await rootBundle.loadString(jsonString!));
    }

    //var json = jsonDecode(await rootBundle.loadString(jsonString));

    options ??= GeoJSONVTOptions(
          debug : 0,
          buffer : 0,
          maxZoom: 22,
          indexMaxZoom: 22,
          indexMaxPoints: 10000000,
          tolerance : 0, // 1 is probably ok, 2+ may be odd if you have adjacent polys lined up and gets simplified
          extent: tileSize.toInt());
    
    GeoJSONVT geoJsonIndex = GeoJSONVT(geoMap, options);

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
  Widget getClusters(FlutterMapState mapState, index, stream, markerFunc, CustomPoint size) {

    List<Positioned> markers = [];

    var clusterZoom = 2;
    var clusterFactor = pow(2,clusterZoom);

    var tileState = TileState(mapState, size);
    var clusterPixels = size.x / clusterFactor; /// how much do we want to split the tilesize into, 32 = 8 chunks by 8

    if(index != null) {

      tileState.loopOverTiles( (i,j, pos, matrix) {

        for( var clusterTileX = 0; clusterTileX < clusterFactor ; clusterTileX++) {

          for( var clusterTileY = 0; clusterTileY < clusterFactor ; clusterTileY++) {

            var innerTileFeatures = index.getTile(
                tileState.getTileZoom().toInt() + clusterZoom, i * clusterFactor + clusterTileX, j * clusterFactor + clusterTileY);

            if(innerTileFeatures != null && innerTileFeatures.features.length > 0) {

              var count = innerTileFeatures.features.length;

              var bMin = transformPoint(innerTileFeatures.minX,innerTileFeatures.minY,size.x,1 << tileState.getTileZoom().toInt() + clusterZoom,innerTileFeatures.x,innerTileFeatures.y);
              var bMax = transformPoint(innerTileFeatures.maxX,innerTileFeatures.maxY,size.x,1 << tileState.getTileZoom().toInt() + clusterZoom,innerTileFeatures.x,innerTileFeatures.y);

              var bbX = ((bMax[0] - bMin[0]) / 2 + bMin[0]);
              var bbY = ((bMax[1] - bMin[1]) / 2 + bMin[1]);


              if(count > 1) {
                var tp = MatrixUtils.transformPoint(matrix,
                    Offset((clusterTileX * clusterPixels + bbX / clusterFactor).toDouble(), (clusterTileY * clusterPixels + bbY / clusterFactor).toDouble()));

                markers.add(
                    Positioned(
                        width: 35,
                        height: 35,
                        left: tp.dx, // + zoomTileX*32,
                        top: tp.dy, // +zoomTileY*32,
                        child: Transform.rotate(
                          alignment: FractionalOffset.center,
                          angle: -mapState.rotationRad,
                          child: markerFunc == null ? FittedBox(
                              fit: BoxFit.contain,
                              //child: Text("$count ", style: const TextStyle(fontSize: 10))
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 2),
                                  shape: BoxShape.circle,
                                  color: Colors.amber,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text("$count ", style: const TextStyle(fontSize: 50)),
                                  ],
                                ),
                              )
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

  Widget getClustersOnTile(tile, index, matrix, FlutterMapState mapState, size, clusterFunc, markerWidgetFunc) {

    List<Positioned> markers = [];

    var clusterZoom = 1;
    var clusterFactor = pow(2,clusterZoom);

    var tileState = TileState(mapState, size);
    var clusterPixels = size.x / clusterFactor; /// how much do we want to split the tilesize into, 32 = 8 chunks by 8

    if(index != null) {

      //tileState.loopOverTiles( (i,j, pos, matrix) {

        for( var clusterTileX = 0; clusterTileX < clusterFactor ; clusterTileX++) {

          for( var clusterTileY = 0; clusterTileY < clusterFactor ; clusterTileY++) {

            var innerTileFeatures = index.getTile(
                tileState.getTileZoom().toInt() + clusterZoom, tile.x * clusterFactor + clusterTileX, tile.y * clusterFactor + clusterTileY);

            if(innerTileFeatures != null && innerTileFeatures.features.length > 0) {

              var count = innerTileFeatures.features.length;

              var bMin = transformPoint(innerTileFeatures.minX,innerTileFeatures.minY,size.x,1 << tileState.getTileZoom().toInt() + clusterZoom,innerTileFeatures.x,innerTileFeatures.y);
              var bMax = transformPoint(innerTileFeatures.maxX,innerTileFeatures.maxY,size.x,1 << tileState.getTileZoom().toInt() + clusterZoom,innerTileFeatures.x,innerTileFeatures.y);

              var bbX = ((bMax[0] - bMin[0]) / 2 + bMin[0]);
              var bbY = ((bMax[1] - bMin[1]) / 2 + bMin[1]);


              var tp = MatrixUtils.transformPoint(matrix,
                  Offset((clusterTileX * clusterPixels + bbX / clusterFactor).toDouble(), (clusterTileY * clusterPixels + bbY / clusterFactor).toDouble()));

              markers.add(
                  Positioned(
                      width: 35,
                      height: 35,
                      left: tp.dx, // + zoomTileX*32,
                      top: tp.dy, // +zoomTileY*32,
                      child: Transform.rotate(
                        alignment: FractionalOffset.center,
                        angle: -mapState.rotationRad,
                        child: count == 1 ? markerWidgetFunc(innerTileFeatures.features[0]) :
                          clusterFunc == null ? FittedBox(
                              fit: BoxFit.contain,
                              //child: Text("$count ", style: const TextStyle(fontSize: 10))
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 2),
                                  shape: BoxShape.circle,
                                  color: Colors.amber,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text("$count ", style: const TextStyle(fontSize: 50)),
                                  ],
                                ),
                              )
                          ) :  clusterFunc(),
                      )
                  )
              );
            }
          }
        }
      //});
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

    final mapState = FlutterMapState.maybeOf(context)!;

    Map<String,Widget> lastTileWidgets = {};
    Map<String,Widget> currentTileWidgets = {};

    CustomPoint size = const CustomPoint(256,256);


    //return StreamBuilder<void>(
    //    stream: mapState.onMoved,
    //    builder: (BuildContext context, _) {

          //var clusters = GeoJSON().getClusters(mapState, widget.index, null, null, size);
          List<Widget> clusters = [];

          TileState tileState = TileState(mapState, const CustomPoint(256.0, 256.0));

          List<Widget> allTileStack = [];
          List<Widget> allTileUpperStack = [];
          currentTileWidgets = {};

          tileState.loopOverTiles((i, j, pos, matrix) {

            List<Widget> thisTileStack = <Widget>[];

            var tile = widget.index?.getTile(
                tileState.getTileZoom().toInt(), i, j);

            if (tile != null) {

              var tileClusters = GeoJSON().getClustersOnTile(tile, widget.index, matrix, mapState, size,
                  widget.options.clusterFunc, widget.options.pointWidgetFunc);
              clusters.add(tileClusters);

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
              allTileStack.add( Transform(child: newWidget, transform: matrix)
                ///RepaintBoundary(child: Transform(child: newWidget, transform: matrix))
              );
            }
          });
          lastTileWidgets = currentTileWidgets;

          return Stack(children: [
            Stack(children: allTileStack),
            Stack(children: allTileUpperStack),
            Stack(children: clusters),
          ]);
        }
    //);
  //}
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
    Function? clusterFunc;
    bool featuresHaveSameStyle;

    GeoJSONOptions({this.lineStringFunc, this.lineStringStyle, this.polygonFunc,
      this.polygonStyle, this.pointFunc, this.pointWidgetFunc, this.pointStyle,
      this.overallStyleFunc, this.clusterFunc, this.featuresHaveSameStyle = false});

}

class FeatureVectorPainter extends CustomPainter with ChangeNotifier {

  final Stream<Null>? stream;
  final GeoJSONOptions options;
  final List features;
  FlutterMapState mapState;
  Matrix4 matrix;
  PositionInfo pos;
  Paint? singleStyle;

  FeatureVectorPainter({ required this.mapState, required this.features, this.stream, required this.options, required this.matrix, required this.pos  });
  

  @override
  void paint(Canvas canvas, Size size) {
    draw(features, pos, canvas, options);
  }


  void draw(List<dynamic> features, PositionInfo pos, Canvas canvas, GeoJSONOptions options) async  {

    // Batch paths where possible...
    var superPath = dartui.Path();

    for( var count = 0; count < features.length; count++ ) {

      var feature = features[count];
      FeatureType type = FeatureType.values[feature.type]; // convert geoson-vt 1-3 int to enum
      var tags = feature.tags;
      var hasJsonStyle;
      ///print("type ${type} ${feature.type} feature $feature");

      Paint featurePaint = Styles.getPaint(feature, null, options);

      if (type == FeatureType.Point) { // point
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

      if(type == FeatureType.LineString || type == FeatureType.Polygon) { // line = 2, poly = 3


        var path = dartui.Path()
                    ..fillType = dartui.PathFillType.evenOdd;
        for( var ring in feature.geometry ) {

          List<Offset> offsets = [];
          for (var c = 0; c < ring.length; c++) {
            offsets.add(Offset(ring[c][0].toDouble(), ring[c][1].toDouble()));
          }
          path.addPolygon(offsets,false);
        }

        featurePaint.strokeWidth = featurePaint.strokeWidth / pos.scale;
        // polygon MUST have fill type whatever
        if(type == FeatureType.Polygon) {
          featurePaint.style = PaintingStyle.fill;
        } else {
          featurePaint.style = PaintingStyle.stroke;
          ///print("got here");
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
  bool shouldRepaint(FeatureVectorPainter oldDelegate) => oldDelegate.features != features ||
      oldDelegate.mapState.zoom != mapState.zoom ||
      oldDelegate.mapState.center.latitude != mapState.center.latitude ;

}

// https://github.com/flutter/flutter/blob/0f397c08dc99c720bea06ff925106d9858547ee3/packages/flutter/lib/src/material/colors.dart
class Styles {

  static Map<String, Color> colorNames = {
    'red': Colors.red,
    'blue': Colors.blue,
    'yellow': Colors.yellow,
    'green': Colors.green,
    'amber': Colors.amber,
    'orange': Colors.orange,
    'brown': Colors.brown,
    'grey': Colors.grey,
    'bluegrey': Colors.blueGrey,
    'pink': Colors.pink,
    'purple': Colors.purple,
    'indigo': Colors.indigo,
    'lightblue': Colors.lightBlue,
    'cyan': Colors.cyan,
    'teal': Colors.teal,
    'lime': Colors.lime,
  };

  static Paint getDefaultStyle(int type) {
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

  static dartui.Paint getPaint(feature, featurePaint, options) {

    Map<dynamic, dynamic> tags = feature.tags;
    FeatureType type;
    if(feature.type is int) {
      type = FeatureType.values[feature.type]; // convert geojson-vt int into enum
    } else {
      type = feature.type;
    }

    //print("feature $feature");


    featurePaint ??= getDefaultStyle(0);

    Map styleTags;
    if(tags.containsKey('style')) {
      styleTags = tags['style'];
    } else {
      styleTags = tags;
    }

    if(styleTags.containsKey('fill') && type == FeatureType.Polygon) {
      var fill = styleTags['fill'];
      if(colorNames.containsKey(fill)) {
        featurePaint.color = colorNames[fill]!;
      } else {
        featurePaint.color = HexColor(fill);
      }
    }
    if(styleTags.containsKey('stroke') && type == FeatureType.LineString) {
      var stroke = styleTags['stroke'];
      if(colorNames.containsKey(stroke)) {
        featurePaint.color = colorNames[stroke]!;
      } else {
        featurePaint.color = HexColor(stroke);
      }
    }
    if(styleTags.containsKey('marker-color') && type == FeatureType.Point) {
      var markerColor = styleTags['marker-color'];
      if(colorNames.containsKey(markerColor)) {
        featurePaint.color = colorNames[markerColor]!;
      } else {
        featurePaint.color = HexColor(markerColor);
      }
    }

    if(styleTags.containsKey('stroke-width') && type == FeatureType.LineString) {
      featurePaint.strokeWidth = feature.tags['stroke-width'];
    }
    if(styleTags.containsKey('stroke-opacity') && type == FeatureType.LineString) {
      featurePaint.color = featurePaint.color.withOpacity(feature.tags['stroke-opacity']);
    }
    if(styleTags.containsKey('fill-opacity') && type == FeatureType.Polygon) {
      featurePaint.color = featurePaint.color.withOpacity(feature.tags['fill-opacity']);
    }

    return featurePaint;

  }
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class TestData {
  final _random = Random();
  //int next(int min, int max) => min + _random.nextInt(max - min);
  double doubleInRange(num start, num end) =>
      _random.nextDouble() * (end - start) + start;

  Map getSamplePointGeoJSON(count) {
    var latGeo = {"type": "FeatureCollection", "features": []};

    List features = latGeo['features'] as List;

    for (var c = 0; c < count; c++) {
      //var feature = {"type": "feature", "properties": {}, "geometry": {"type": "point", "coordinates": [doubleInRange(-90,90),doubleInRange(-180,180) ]}};
      var feature = {
        "type": "Feature",
        "properties": {'val': doubleInRange(0, 20)},
        "geometry": {
          "type": "Point",
          "coordinates": [doubleInRange(-180, 180), doubleInRange(-90, 90)]
        }
      };
      features.add(feature);
    }
    return latGeo;
  }

}

class VectorTileWidgetStream extends StatelessWidget {
  final double size = 256.0;
  final VectorTileIndex? index;

  const VectorTileWidgetStream({Key? key, size = 256.0, this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    var mapState = FlutterMapState.maybeOf(context)!;
    return VectorTileWidget(size: 256.0, index: index);
    /*return StreamBuilder(
      stream: mapState.onMoved,
      builder: (context, AsyncSnapshot snapshot) {
          return VectorTileWidget(size: 256.0, index: index);
      }
    );

     */
  }
}

class VectorTileWidget extends StatefulWidget {
  final double size = 256.0;
  final VectorTileIndex? index;

  const VectorTileWidget({Key? key, size = 256.0, this.index}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VectorTileWidgetState();
  }
}

enum VectorTileProcessingStatus {
  notStarted,
  isLoading,
  isLoaded,
}

class VectorLayer {
  String layerName = "";
  List<ProcessedFeature> features = [];

  VectorLayer(this.layerName,this.features);
}

class VectorTileStatus {
  List<VectorLayer> layers = [];
  VectorTileProcessingStatus status = VectorTileProcessingStatus.notStarted;

  VectorTileStatus();
}

class VectorTileIndex {
  Map<String, VectorTileStatus> tile = {};
}

class ProcessedFeature {
  FeatureType type;
  Map? tags;
  Offset? point;
  dartui.Path? path;
  List<Offset> polyOffsets = [];

  ProcessedFeature({this.type = FeatureType.Point, this.tags = const {}, this.path, this.point, this.polyOffsets = const []});

}

class _VectorTileWidgetState extends State<VectorTileWidget> {
  VectorTileIndex? index;

  @override
  void initState() {
    index = widget.index;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    var vectorTileIndex = widget.index;
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var dimensions = Offset(width,height);

    var mapState = FlutterMapState.maybeOf(context)!;

    var tileState = TileState(mapState, CustomPoint(widget.size, widget.size));

    List<Widget> stack = [];

    var count = 0;
    tileState.loopOverTiles((i, j, pos, matrix) {
      if(true || count < 1) {

        Coords coords = Coords(i.toDouble(), j.toDouble());
        coords.z = mapState.zoom.round();
        var tileKey = "${coords.x}:${coords.y}:${coords.z}";

        if( !vectorTileIndex!.tile.containsKey(tileKey) ) {
          vectorTileIndex.tile[tileKey] = VectorTileStatus();
        }

        var vectorTileStatus = vectorTileIndex.tile[tileKey];

        if( vectorTileStatus!.status == VectorTileProcessingStatus.isLoaded ) {
          var processedLayers = vectorTileStatus.layers;


            stack.add(
                Transform(transform: matrix,
                    child: CustomPaint(
                        size: const Size(256.0, 256.0),
                        isComplex: true,
                        //Tells flutter to cache the painter, although it probably won't!
                        painter: FeatureVectorTilePainter(
                            layers: processedLayers,
                            options: GeoJSONOptions(),
                            pos: pos,
                          mapState: mapState
                        )
                    )
                )
            );

        } else if( vectorTileStatus.status == VectorTileProcessingStatus.notStarted ) {
          vectorTileStatus.status = VectorTileProcessingStatus.isLoading;

          fetchData(coords, vectorTileIndex, mapState).then((_) {
            vectorTileStatus.status = VectorTileProcessingStatus.isLoaded;
          });
        }
        count++;
      }

    });

    return SizedBox(
        width: width*1.25, /// calculate this properly depending on rotation and mobile orientation
        height: height*1.25,
        child: Stack(children: stack),
    );

  }

  Future<void> fetchData(coords, VectorTileIndex? vectorTileIndex, FlutterMapState mapState) async {

    String tileCoordsKey = tileCoordsToKey(coords);
    String url;

    if(isValidTile(coords, mapState)) {
      try {
        url = NetworkNoRetryTileProvider().getTileUrl(coords,
          TileLayer(
              urlTemplate: 'https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/{z}/{x}/{y}.mvt?mapbox://styles/gibble/ckoe1dv003l7s17pb219opzj0&access_token=pk.eyJ1IjoiZ2liYmxlIiwiYSI6ImNqbjBlZDB6ejFrODcza3Fsa3o3eXR1MzkifQ.pC89zLnuSWrRdCkDrsmynQ',
              subdomains: ['a', 'b', 'c']),
        );

        DefaultCacheManager().getSingleFile(url).then( ( value ) async {

          var bytes = value.readAsBytesSync();
          var vt = vector_tile.Tile.fromBuffer(bytes);

          List<ProcessedFeature> tileFeatureList = [];

          int reps = 0;

          Map stats = {};

          for(var layer in vt.layers) {
            var layerString = layer.name.toString();
            ///print("$tileCoordsKey layerString $layerString");

            for (vector_tile.Tile_Feature feature in layer.features) {

              var featureInfo = {};
              List<Offset> pointList = [];
              var command = '';
              var point;
              dartui.Path? path;

              for (var tagIndex = 0; tagIndex < feature.tags.length; tagIndex += 2) {
                var valIndex = feature.tags[tagIndex + 1];
                var layerObj = layer.values[valIndex];
                var val;

                if (layerObj.hasIntValue()) {
                  val = layerObj.intValue.toString();
                } else if (layerObj.hasStringValue()) {
                  val = layerObj.stringValue;
                } else {
                  val = layerObj.boolValue.toString();
                }

                featureInfo[layer.keys[feature.tags[tagIndex]]] = val;
              }
              var tags = featureInfo;
List<Offset> polyOffsets = [];
              List<Offset> polyPoints = [];

              var tileGeomType = feature.type;

              FeatureType featureType = FeatureType.LineString;

              var geometry = feature.geometry;

              var gIndex = 0;
              int cx = 0; int cy = 0;

              while(gIndex < geometry.length) {
                var commandByte = geometry[ gIndex ];

                if(reps == 0) {
                  command = 'M';
                  var checkCom = commandByte & 0x7;
                  reps = commandByte >> 3;
                  if(checkCom == 1) {
                    command = 'M';
                  } else if (checkCom == 2) {
                    command = 'L';
                  } else if (checkCom == 7) {
                    command = 'C';
                    reps = 0;

                    path ??= dartui.Path();
                    if(tileGeomType == Tile_GeomType.POLYGON) {
                      path.addPolygon(polyPoints, true);
                      featureType = FeatureType.Polygon;
                    } else {
                      path.addPolygon(polyPoints, false);
                      featureType = FeatureType.LineString;
                    }
           ///polyOffsets = polyPoints;
                    polyPoints = [];
                  } else {
                    print("Shouldn't have got here, some command unknown");
                  }
                  gIndex++;
                } else {
                  cx += decodeZigZag(geometry[ gIndex ]);
                  cy += decodeZigZag(geometry[ gIndex + 1]);

                  double? ncx, ncy;
                  if (command == 'M' || (command == 'L')) {

                    path ??= dartui.Path();
                    ncx = (cx.toDouble() / 16); // Change /16 to a tileRatio passed in..
                    ncy = (cy.toDouble() / 16);
                  }

                  ///var type = feature.type.toString();
                  if (command == 'C') { // CLOSE
                    if(path != null) {
                      print("IS THIS EVER USED ? IF SO< CLOSE MAY BE WRONG>>>>>");
     ///polyOffsets = polyPoints;
                      path.addPolygon(polyPoints, false); /// ////////////////// true/false if used
                    }
                    polyPoints = [];

                  } else if (command == 'M') { // MOVETO
                    //if (type == 'POLYGON') {
                    path ??= dartui.Path();
                    if (tileGeomType == Tile_GeomType.POLYGON) {
                      if(polyPoints.isNotEmpty) {
                        path.addPolygon(polyPoints, true);
                      }
      ///polyOffsets = polyPoints;
      polyOffsets.add(Offset(ncx!, ncy!))  ;
                      polyPoints = [];
                      polyPoints.add(Offset(ncx, ncy));

                      featureType = FeatureType.Polygon;

                    } else if (tileGeomType == Tile_GeomType.LINESTRING) {

                      if(polyPoints.isNotEmpty) {
                        path.addPolygon(polyPoints, false);
                      }
       ///polyOffsets = polyPoints;
       polyOffsets.add(Offset(ncx!, ncy!))  ;
                      polyPoints = [];
                      polyPoints.add(Offset(ncx, ncy));
                      featureType = FeatureType.LineString;

                    } else if (tileGeomType == Tile_GeomType.POINT) {

                      point = Offset(ncx!, ncy!);
                      pointList.add(point);

                      var dedupeKey = featureInfo['name'] ?? point.toString();
                      dedupeKey += '_' + tileCoordsKey;
                      var priority = 1; // 1 is best priority

                      /// We want a poi or a shop label to appear rather than a housenum if poss
                      if(layer.name == "housenum_label") {
                        featureInfo['name'] = featureInfo['house_num'];
                        dedupeKey = "${featureInfo['name']}|$point";
                        priority = 9;
                      }

                      //labelPointlist.add([ point, layer.name, featureInfo, dedupeKey, priority ]);  /// May want to add a style here, to draw last thing..., move into a class

                      featureType = FeatureType.Point;


                    }

                  } else if (command == 'L') { // LINETO

                    if (tileGeomType == Tile_GeomType.POLYGON) {
polyOffsets.add(Offset(ncx!, ncy!));
                      polyPoints.add(Offset(ncx, ncy));

                      featureType = FeatureType.Polygon;

                    } else if (tileGeomType == Tile_GeomType.LINESTRING) {


                      polyOffsets.add(Offset(ncx!, ncy!));


                      polyPoints.add(Offset(ncx, ncy));
                      featureType = FeatureType.LineString;
                    }
                  } else {
                    print("Incorrect command string");
                  }

                  gIndex += 2;
                  reps--;
                }
              }

              if(polyPoints.isNotEmpty) {
                path ??= dartui.Path();

                if(tileGeomType == Tile_GeomType.POLYGON) {
                  path.addPolygon(polyPoints, true);
                } else {
                  path.addPolygon(polyPoints, false);
                }
              }

              if(featureType == FeatureType.Polygon || featureType == FeatureType.LineString) {
                tileFeatureList.add(ProcessedFeature(type: featureType, tags: featureInfo, path: path, polyOffsets: polyOffsets));
    polyOffsets = [];
              } else {
                tileFeatureList.add(ProcessedFeature(type: featureType, tags: featureInfo, point: point));
              }

              path = null;
            } // end feature


            vectorTileIndex!.tile[tileCoordsKey]!.layers.add(VectorLayer(layerString, tileFeatureList));
            tileFeatureList = [];

          } // end layer

        });
      } catch (e) {
        print("ERROR LOADING URL $e $coords");
        return;
      }
    }
  }
}

class FeatureVectorTilePainter extends CustomPainter with ChangeNotifier {

  //final Stream<Null>? stream;
  final GeoJSONOptions options;
  final List<VectorLayer> layers;
  FlutterMapState mapState;
  PositionInfo pos;
  Paint? singleStyle;

  FeatureVectorTilePainter({ required this.layers, required this.pos, required this.options,  required this.mapState });


  @override
  void paint(Canvas canvas, Size size) {
    Rect myRect = const Offset(0,0) & const Size(257,257); // hmm some other rounding errer gone astray, shouldn't need this .5...
    canvas.clipRect(myRect);
    draw(layers, pos, canvas, mapState.zoom, options);
  }


  void draw(List<VectorLayer> layers, PositionInfo pos, Canvas canvas, zoom, GeoJSONOptions options) async {
    // Batch paths where possible...
    var superPath = dartui.Path();

    Map<String, int> layerOrderMap = VectorLayerStyles.defaultLayerOrder();

    layers.sort((a, b) {
      return (layerOrderMap[ a.layerName ] ?? 15).compareTo(
          layerOrderMap[ b.layerName ] ?? 15);
    });

    for (var layer in layers) {
      var features = layer.features;
      var layerName = layer.layerName;

      var lastType;
      for (var count = 0; count < features.length; count++) {

        var feature = features[count];
        var type = feature.type;
        lastType ??= type;
        var tags = feature.tags;

        Paint featurePaint = Styles.getPaint(feature, null, options);

        if (type == FeatureType.Point) { // point
          canvas.save();

          canvas.translate(feature.point!.dx, feature.point!.dy);
          canvas.scale(1 / pos.scale);
          if (options.pointFunc != null) {
            options.pointFunc!(feature, canvas);
          } else {
            canvas.drawCircle(const Offset(0, 0), 3, featurePaint);
          }
          canvas.restore();
        }

        if (type == FeatureType.LineString ||
            type == FeatureType.Polygon) { // line = 2, poly = 3

          var paint = VectorLayerStyles.getStyle(VectorLayerStyles.mapBoxClassColorStyles, tags,
              layerName, type, zoom,
              pos.scale, 2);

          paint.strokeWidth = featurePaint.strokeWidth / pos.scale * 5;
          // polygon MUST have fill type whatever
          if (type == FeatureType.Polygon) {
            paint.style = PaintingStyle.fill;
          } else {
            paint.style = PaintingStyle.stroke;
          }

          paint.isAntiAlias = false;

          if (options.featuresHaveSameStyle && type == lastType && lastType == FeatureType.Polygon) {
            ///print("superpath");
            superPath.addPath(feature.path!, const Offset(0, 0));
          } else {
            ///if(layerName == "building"  || layerName == "road") {
            ///print("$layerName");
            ///if(layerName == "road" || layerName == "building" || layerName == "landuse" || layerName == "structure") {
            ///if(layerName == "building" || layerName == "landuse") {
            ///  print("drawing feature ${featurePaint.style} ${featurePaint
             ///     .color} $tags");
              ///print("drawing path");
              ///canvas.drawPath(feature.path!, featurePaint);
              // vectorStyle, layerString, type, featureInfo, zoom
              if( VectorLayerStyles.includeFeature(VectorLayerStyles.mapBoxClassColorStyles,
                  layerName, type, tags, zoom) ) {
                ///if (tags['type'] == 'residential') {
                if(feature.type == FeatureType.LineString) {
                  ///print("linestring ${feature.polyOffsets}");
                  canvas.drawPath(feature.path!, paint);
                  ///canvas.drawPoints(
                  ///    dartui.PointMode.polygon, feature.polyOffsets, paint);
                } else {
                  canvas.drawPath(feature.path!, paint);
                }
              }
            ///}
          }

          lastType = type;

          // We may get a mixed polgon followed by a point or line, so we want to
          // draw now to preserve order, but if all the same style may as well batch


          if (feature.type == FeatureType.Polygon && (count < features.length - 1 &&
              (features[count + 1].type != type)) ||
              (count == features.length - 1)) {
            //print("drawing superpath");
            if( VectorLayerStyles.includeFeature(VectorLayerStyles.mapBoxClassColorStyles, layerName, type,
                tags, zoom) ) {
              ///print("superpath");
            canvas.drawPath(superPath, paint);
            superPath = dartui.Path();
            }
          }




        }
      }
    }
  }

  @override
  bool shouldRepaint(FeatureVectorTilePainter oldDelegate) => oldDelegate.layers != layers  || true ||
      oldDelegate.mapState.zoom != mapState.zoom ||
      oldDelegate.mapState.center.latitude != mapState.center.latitude ;

}

int decodeZigZag( int byte ) { /// decodes from mapbox small int style
  if(kIsWeb) {
    var bigInt = BigInt.from(byte);
    return ((bigInt >> 1) ^ -(bigInt & BigInt.from(1))).toInt();
  } else {
    return ((byte >> 1) ^ -(byte & 1)).toInt();
  }
}

String tileCoordsToKey(Coords coords) {
  return '${coords.x}:${coords.y}:${coords.z}';
}

bool isValidTile(Coords coords, FlutterMapState mapState) {
  final crs = mapState.options.crs;

  if (!crs.infinite) {
    // don't load tile if it's out of bounds and not wrapped
    var bounds = mapState.getPixelWorldBounds(mapState.zoom);
    bounds = pxBoundsToTileRange(bounds!, const CustomPoint(256.0,256.0));
    if ((crs.wrapLng == null &&
        (coords.x < bounds.min.x || coords.x > bounds.max.x)) ||
        (crs.wrapLat == null &&
            (coords.y < bounds.min.y || coords.y > bounds.max.y))) {
      return false;
    }
  }

  return true;
}

Bounds pxBoundsToTileRange(Bounds bounds, CustomPoint tileSize ) {
  return Bounds(
    bounds.min.unscaleBy(tileSize).floor(),
    bounds.max.unscaleBy(tileSize).ceil() - const CustomPoint(1, 1),
  );
}

class VectorLayerStyles {

  static bool includeFeature(vectorStyle, layerString, type, featureInfo, zoom) { //reduce code...

    var thisClass = featureInfo['class'] ?? 'default';
    var paramsMap = { 'layer': layerString, 'type': type, 'class': thisClass, 'zoom': zoom, 'featureInfo': featureInfo };

    var style = funcCheck( vectorStyle, paramsMap);
    var includeFeature = funcCheck( style['default'], paramsMap )['include'];

    if(!vectorStyle.containsKey(layerString)) layerString = 'default';

    if(vectorStyle.containsKey(layerString)) {
      var layerStyle = funcCheck( vectorStyle[layerString], paramsMap );

      includeFeature = funcCheck( layerStyle!['include'], paramsMap );
      var classOptions = funcCheck( layerStyle!['default'], paramsMap );

      if( layerStyle!.containsKey('types') && layerStyle!['types'].containsKey(type)) { // types match in styling
        classOptions = funcCheck( layerStyle!['types'][type], paramsMap );

      } else if( layerStyle!.containsKey(thisClass) ) { // normal class match in styling
        classOptions = funcCheck( layerStyle![thisClass], paramsMap );
      }

      if( includeFeature && classOptions is List ) {
        var listIncludes = false;

        for( var entry in classOptions ) {
          var minZoom = funcCheck( entry[0], paramsMap );
          var maxZoom = funcCheck( entry[1], paramsMap );

          if( zoom >= minZoom && zoom <= maxZoom ) {
            listIncludes = true; // we have at least one entry for this zoom
            break;
          }
        }
        if( listIncludes == false ) {
          includeFeature = false;
        }
      }
    }

    return funcCheck( includeFeature, paramsMap );
  }

  static Paint getStyle(style, featureInfo, layerString, type, tileZoom, scale, diffRatio) {
    var paramsMap = { 'layer': layerString, 'type': type, 'zoom': tileZoom, 'diffRatio': diffRatio, 'featureInfo': featureInfo };

    var className = featureInfo['class'] ?? 'default';

    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = false;

    if(type == 'LINESTRING' || type == 'line') paint.style = PaintingStyle.stroke; // are roads filled ?
    if(type == 'POLYGON'    || type == 'fill') paint.style = PaintingStyle.fill;

    bool matchedFeature = false;
    Map vectorStyle = funcCheck(style, paramsMap);

    if(!vectorStyle.containsKey(layerString)) layerString = 'default';

    if(vectorStyle.containsKey(layerString)) {
      Map<String, dynamic>? layerClass = funcCheck(vectorStyle[layerString],paramsMap) ?? funcCheck(vectorStyle['default'], paramsMap);
      List<List<dynamic>>? featureClass = funcCheck(vectorStyle['default'],paramsMap)?['default'];

      if (layerClass != null) {
        if (layerClass.containsKey('types') &&
            layerClass['types'].containsKey(className)) {
          featureClass = funcCheck(layerClass['types'][className], paramsMap);
          matchedFeature = true;
        }
      }

      if (layerClass != null && layerClass.containsKey(className)) {
        featureClass = funcCheck(layerClass[className], paramsMap);
        matchedFeature = true;
      }

      if (featureClass is List) {
        if( featureClass != null) {
          for (var entry in featureClass) {
            var minZoom = funcCheck(entry[0], paramsMap);
            var maxZoom = funcCheck(entry[1], paramsMap);
            var styleOptions = funcCheck(entry[2], paramsMap);

            if (tileZoom >= minZoom && tileZoom <= maxZoom && styleOptions is Map) {
              if (styleOptions.containsKey('color')) {
                paint.color = funcCheck(styleOptions['color'], paramsMap);
              }
              if (styleOptions.containsKey('strokeWidth')) {
                paint.strokeWidth =
                    funcCheck(styleOptions['strokeWidth'], paramsMap);
              }
            }
          }
        }
      }
    }

    ///if(!matchedFeature && debugOptions.missingFeatures) print ("$layerString $type $className $tileZoom not found");

    paint.strokeWidth =  (paint.strokeWidth / scale); ///.ceilToDouble();
    return paint;
  }

  /// We want to give the option of any var being a func to call..
  static dynamic funcCheck( dynamic checkVar, Map paramMap ) {
    if(checkVar is Function) return checkVar( paramMap );
    return checkVar;
  }

  static Map<String, int> defaultLayerOrder() {
    return {
      'landuse': 1,
      'waterway' : 3,
      'water' : 2,
      'aeroway': 7,
      'data': 9,
      'barrierline': 11,
      'building' : 13,
      'landuse_overlay': 15,
      'tunnel': 17,
      'structure': 19,
      'road': 21,
      'bridge': 23,
      'motorway_junction': 25,
      'airport_label': 27,
      'natural_label' : 29,
      'water_label': 30,
      'poi_label' : 31,
      'transit_stop_label' : 33,
      'place_label' : 35,
      'house_num_label': 37,
    };
  }

  static Map<String, Map<String, dynamic>> mapBoxClassColorStyles = {

    "default": {
      'include': true,
      'default':  [ [0, 22, { 'color': Colors.purple, 'strokeWidth': 0.0}],
      ],
    },

    "admin": {
      'include': true,
      'default':  [ [0, 22, { 'color': Colors.deepPurple, 'strokeWidth': 0.0}],
      ],
    },

    ///mapbox streets
    ///hairline = switch to a hairline width of 0 for optimisation at low zoom levels where we dont care
    "road": {
      'include': true,
      'default':      [
        [0, 22, { 'color': Colors.orange, 'strokeWidth' : 0.0  }     ],
        [16,22, { 'color': Colors.orange, 'strokeWidth' : 2.0 }     ],
      ],
      'service':      [
        [12, 22, { 'color': Colors.blueGrey.shade600, 'strokeWidth' : 0.0  }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'street':       [
        [15, 22, { 'color': Colors.blueGrey.shade600, 'strokeWidth' : 0.0  }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'pedestrian':   [
        [15, 22, { 'color': Colors.blueGrey.shade600, 'strokeWidth' : 0.0  }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'street_limited':[[15, 22, { 'color': Colors.blueGrey.shade600, 'strokeWidth' : 0.0  }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'motorway':     [
        [0, 11, { 'color': Colors.orange,          'strokeWidth' : 0.0 }     ],
        [11,14, { 'color': Colors.orange.shade200, 'strokeWidth' : 3.0 }     ],
        [14,22, { 'color': Colors.orange.shade100, 'strokeWidth' : 8.0 }     ],
      ],
      'motorway_link':  [
        [0, 11, { 'color': Colors.orange,          'strokeWidth' : 0.0 }     ],
        [11,13, { 'color': Colors.orange.shade200, 'strokeWidth' : 3.0 }     ],
        [13,22, { 'color': Colors.orange.shade100, 'strokeWidth' : 8.0 }     ],
      ],
      'trunk':        [
        [0, 11, { 'color': Colors.orangeAccent,    'strokeWidth' : 0.0  }     ],
        [11,16, { 'color': Colors.orange.shade200, 'strokeWidth' : 3.0 }     ],
        [16,22, { 'color': Colors.orange.shade100, 'strokeWidth' : 8.0 }     ],
      ],
      'trunk_link':    [
        [0, 12, { 'color': Colors.orangeAccent,     'strokeWidth' : 0.0  }   ],
        [12,16, { 'color': Colors.orange.shade100, 'strokeWidth' : 3.0 }     ],
        [16,22, { 'color': Colors.orange.shade100, 'strokeWidth' : 8.0 }     ],
      ],
      'primary':     [
        [11, 17, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 0.0  }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'primary_link': [
        [11,17, { 'color': Colors.blueGrey.shade400, 'strokeWidth' : 0.0  }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'secondary':   [
        [11,17, { 'color': Colors.blueGrey.shade400, 'strokeWidth' : 0.0  }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'secondary_link':[
        [11, 17, { 'color': Colors.blueGrey.shade400, 'strokeWidth' : 0.0  }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'tertiary':     [
        [14,17, { 'color': Colors.blueGrey.shade400, 'strokeWidth' : 0.0  }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'tertiary_link': [
        [14,22, { 'color': Colors.blueGrey.shade400, 'strokeWidth' : 0.0  }   ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 8.0 }     ],
      ],
      'residential':  [
        [14,16, { 'color': Colors.blueGrey.shade600, 'strokeWidth' : 0.0  }   ],
        [16,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 5.0 }     ],
        [17,22, { 'color': Colors.blueGrey.shade300, 'strokeWidth' : 7.0 }     ],
      ],
      'path':         [ [0, 22, { 'color': Colors.brown.shade400,    'strokeWidth' : 2.0  }     ],
      ],
      'track':        [ [0, 22, { 'color': Colors.brown.shade300,    'strokeWidth' : 2.0  }     ],
      ],
      'major_rail':   [ [12, 22, { 'color': Colors.blueGrey.shade800, 'strokeWidth' : 1.0  }     ],
      ],
      'minor_rail':   [ [12, 22, { 'color': Colors.blueGrey.shade800, 'strokeWidth' : 1.0  }     ],
      ],
      'service_rail': [ [12, 22, { 'color': Colors.blueGrey.shade800, 'strokeWidth' : 1.0  }     ],
      ],
      'construction': [ [14, 22, { 'color': Colors.brown,              'strokeWidth' : 0.0  }     ],
      ],
      'ferry':        [ [0, 22, { 'color': Colors.blue.shade800,      'strokeWidth' : 0.0  }     ],
      ],
      'golf':         [ [15, 22, { 'color': Colors.brown.shade400,    'strokeWidth' : 2.0  }     ],
      ],
      'aerialway':    [ [14, 22, { 'color': Colors.brown.shade400,    'strokeWidth' : 2.0  }     ],
      ],
    },

    "motorway_junction": {
      'include': true,
      'default':  [ [0, 22, { 'color': Colors.deepPurple, 'strokeWidth': 5.0}],
      ],
    },

    "landuse": {
      'include': true,
      'residential': [ [13, 21, { 'color': Colors.grey,        'strokeWidth': 0.0 } ],
      ],
      'default':  [ [14, 22, { 'color': Colors.lightGreen,   'strokeWidth': 0.0 } ],
      ],
      'airport':  [ [13, 21, { 'color': Colors.grey,        'strokeWidth': 0.0 } ],
      ],
      'hospital':  [ [15, 21, { 'color': Colors.grey,        'strokeWidth': 0.0 } ],
      ],
      'sand':     [ [12, 21, { 'color': Colors.amber,       'strokeWidth': 0.0 } ],
      ],
      'playground':[[14, 22, { 'color': Colors.green.shade400, 'strokeWidth': 0.0 } ],
      ],
      'grass':    [ [13, 22, { 'color': Colors.lightGreen, 'strokeWidth': 0.0 } ],
      ],
      'park':     [ [13, 22,  { 'color': Colors.lightGreen, 'strokeWidth': 0.0 } ],
      ],
      'pitch':     [ [13, 22,  { 'color': Colors.green,     'strokeWidth': 0.0 } ],
      ],
      'parking':     [ [14, 22,  { 'color': Colors.green.shade100, 'strokeWidth': 0.0 } ],
      ],
      'wood':       [ [10, 22,  { 'color': Colors.green.shade800,   'strokeWidth': 0.0 } ],
      ],
      'agriculture':  [ [13, 22,  { 'color': Colors.green.shade700,   'strokeWidth': 0.0 } ],
      ],
      'school':     [ [14, 22,  { 'color': Colors.grey,             'strokeWidth': 0.0 } ],
      ],
      'scrub':     [ [10, 22,  { 'color': Colors.green.shade600,   'strokeWidth': 0.0 } ],
      ],
      'cemetery':   [ [15, 22,  { 'color': Colors.green.shade700,   'strokeWidth': 0.0 } ],
      ],
      'rock':       [ [12, 22,  { 'color': Colors.grey,   'strokeWidth': 0.0 } ],
      ],
      'glacier':   [ [12, 22,  { 'color': Colors.grey,   'strokeWidth': 0.0 } ],
      ],
    },

    "landuse_overlay": {
      'include': true,
      'default': [ [12, 22, { 'color': Colors.green, 'strokeWidth': 0.0}],
      ],
      'national_park': [ [12, 22, { 'color': Colors.green, 'strokeWidth': 0.0}],
      ],
      'wetland_noveg': [ [11, 22, { 'color': Colors.blueGrey, 'strokeWidth': 0.0}],
      ],
      'wetland': [ [12, 22, { 'color': Colors.blue.shade700, 'strokeWidth': 0.0}],
      ],
    },

    "water": {
      'include': true,
      'default': [ [0, 22, { 'color': Colors.blue.shade500, 'strokeWidth': 0.0}],
      ],
    },

    "waterway": {
      'include': true,
      'default': [ [13, 22, { 'color': Colors.blue.shade700, 'strokeWidth': 0.0}],
      ],
      'river': [ [12, 22, { 'color': Colors.blue.shade600, 'strokeWidth': 0.0}],
      ],
      'canal': [ [12, 22, { 'color': Colors.blue.shade600, 'strokeWidth': 0.0}],
      ],
      'stream': [ [14, 22, { 'color': Colors.blue.shade900, 'strokeWidth': 0.0}],
      ],
      'stream_intermittent': [ [13, 22, { 'color': Colors.blue.shade900, 'strokeWidth': 0.0}],
      ],
      'ditch': [ [12, 22, { 'color': Colors.blue.shade600, 'strokeWidth': 0.0}],
      ],
      'drain': [ [13, 22, { 'color': Colors.blue.shade600, 'strokeWidth': 0.0}],
      ],
    },

    "transit_stop": {
      'include': true,
      'default': [ [14, 22, { 'color': Colors.deepOrange, 'strokeWidth': 0.0}],
      ],
    },

    "building": {
      'include': true,
      'default': [ [15, 22, { 'color': Colors.grey.shade600, 'strokeWidth': 0.0}],
      ],
    },

    "structure": {
      'include': true,
      'default': [ [15, 22, { 'color': Colors.grey.shade600, 'strokeWidth': 0.0}],
      ],
      'fence':  [ [15, 22, { 'color': Colors.brown.shade300, 'strokeWidth': 0.0}],
      ],
      'hedge':  [ [15, 22, { 'color': Colors.brown.shade300, 'strokeWidth': 0.0}],
      ],
      'gate':  [ [16, 22, { 'color': Colors.brown.shade600, 'strokeWidth': 0.0}],
      ],
      'land':  [ [16, 22, { 'color': Colors.brown.shade300, 'strokeWidth': 0.0}], // eg pier
      ],
      'cliff':  [ [16, 22, { 'color': Colors.grey, 'strokeWidth': 0.0}], // eg pier
      ],
    },

    "barrierline": {
      'include': true,
      'default': [ [12, 22, { 'color': Colors.purple, 'strokeWidth': 0.0}],
      ],
    },

    "aeroway": {
      'include': true,
      'default': [ [12, 22, { 'color': Colors.orange, 'strokeWidth': 0.0}],
      ],
    },

    "waterway_label": {
      'include': true,
      'default': [ [15, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "poi_label": {
      'include': true,
      'default':        [ [15, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
      'food_and_drink': [ [16, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
      'religion':      [ [15, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
      'sport_and_leisure':[ [15, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
      'food_and_drink_stores': [ [16, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
      'park_like': [ [16, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
      'education': [ [16, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
      'public_facilities': [ [15, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
      'commercial_services ': [ [16, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "transit_stop_label": {
      'include': true,
      'default': [ [14, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "road_point": {
      'include': true,
      'default': [ [14, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "road_label": {
      'include': true,
      'default': [ [14, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "rail_station_label": {
      'include': true,
      'default': [ [14, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "natural_label": {
      'include': true,
      'default': [ [14, 22, { 'color': Colors.brown, 'strokeWidth': 0.0}],
      ],
      'landform':  [ [12, 22, { 'color': Colors.brown, 'strokeWidth': 0.0}],
      ],
      'sea':  [ [12, 22, { 'color': Colors.black, 'strokeWidth': 0.0}],
      ],
      'stream':  [ [12, 22, { 'color': Colors.black, 'strokeWidth': 0.0}],
      ],
      'water':  [ [12, 22, { 'color': Colors.black, 'strokeWidth': 0.0}],
      ],
      'canal':  [ [15, 22, { 'color': Colors.black, 'strokeWidth': 0.0}],
      ],
      'river':  [ [15, 22, { 'color': Colors.black, 'strokeWidth': 0.0}],
      ],
      'dock':  [ [15, 22, { 'color': Colors.blueGrey, 'strokeWidth': 0.0}],
      ],
    },

    "place_label": {
      'include': true,
      'default': [ [0, 22, { 'color': Colors.black, 'strokeWidth': 0.0}],
      ],
      'settlement':  [ [0, 22, { 'color': Colors.black, 'strokeWidth': 0.0}],
      ],
      'settlement_subdivision':  [ [14, 22, { 'color': Colors.black, 'strokeWidth': 0.0}],
      ],
      'park_like':  [ [14, 22, { 'color': Colors.black, 'strokeWidth': 0.0}],
      ],
      'types' : {
        'village':  [ [14, 22, { 'color': Colors.black, 'strokeWidth': 0.0}] ], //15
        'suburb':   [ [14, 22, { 'color': Colors.black, 'strokeWidth': 0.0}] ], //15
        'hamlet':   [ [14, 22, { 'color': Colors.black, 'strokeWidth': 0.0}] ], //15
        'city':     [ [6, 22, { 'color': Colors.black, 'strokeWidth': 0.0}] ], //6
        'town':     [ [10, 22, { 'color': Colors.black, 'strokeWidth': 0.0}] ], //12
      }
    },

    "airport_label": {
      'include': true,
      'default': [ [0, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "housenum_label": {
      'include': true,
      'default': [ [17, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "mountain_peak_label": {
      'include': true,
      'default': [ [16, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "state_label": {
      'include': true,
      'default': [ [13, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "marine_label": {
      'include': true,
      'default': [ [0, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    "country_label": {
      'include': true,
      'default': [ [0, 22, { 'color': Colors.black, 'strokeWidth': 2}],
      ],
    },

    /*
      ///traffic mapbox
      'traffic': {
        'include': true,
        'default': { 'color': Colors.blueGrey, 'min': 15, 'max': 21},
        'primary': { 'color': Colors.blue, 'min': 15, 'max': 21},
        'secondary': { 'color': Colors.blue, 'min': 15, 'max': 21},
        'tertiary': { 'color': Colors.grey, 'min': 15, 'max': 21},
        'street': { 'color': Colors.grey, 'min': 15, 'max': 21},
      },
      ///mapbox terrain
      'contour': {
        'include': false,
        'default': { 'color': Colors.grey, 'min': 0, 'max': 21},
      },
      'hillshade': {
        'include': false,
        'default': { 'color': Colors.grey, 'min': 0, 'max': 21 },
        'shadow': { 'color': Colors.grey, 'min': 0, 'max': 21 },
      },
      ///tegola   https://tegola.io/styles/hot-osm.json
     'buildings': {
        'include': false,
        'default': { 'color': Colors.grey , 'min': 0, 'max': 21},
      },
      'land': {
        'include': false,
        'default': { 'color': Colors.green , 'min': 0, 'max': 21},
      },
      'landuse_areas' : {
        'include': false,
        'default': { 'color': Colors.green.shade400, 'min': 0, 'max': 21},
        'leisure': { 'color': Colors.green , 'min': 0, 'max': 21},
      },
      'landcover': {
        'include': false,
        'default': { 'color': Colors.green.shade50, 'min': 0, 'max': 21},
        'grass': { 'color': Colors.green, 'min': 0, 'max': 21},
        'crop': { 'color': Colors.green.shade700, 'min': 0, 'max': 21},
      },
      'hillshade': {
        'include': false,
        'default': { 'color': Colors.green.shade100, 'min': 0, 'max': 21},
        'shadow': { 'color': Colors.grey, 'min': 0, 'max': 21},
      },
      'transport_lines': {
        'include': true,
        'default': { 'color': Colors.grey, 'min': 0, 'max': 21},
      },
     'amenity_points' : {
        'include': true,
        'default': { 'color': Colors.grey, 'min': 0, 'max': 21},
      },
      */


  };

}



