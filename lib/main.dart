//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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


  @override
  void initState() async {
    super.initState();
    mapController = MapController();
    CustomImages().loadPlane();

    WidgetsBinding.instance.addPostFrameCallback((_) async {

      //var geoPointMap = TestData().getSamplePointGeoJSON(100);
      //geoJsonIndex = await geoJSON.createIndex(null, tileSize: tileSize, geoJsonMap: geoPointMap);

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
                    subdomains: ['a', 'b', 'c']),
              ),
                const VectorTileWidget(size: 256.0),

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
  Widget getClusters(MapState mapState, index, stream, markerFunc, CustomPoint size) {

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

  Widget getClustersOnTile(tile, index, matrix, MapState mapState, size, clusterFunc, markerWidgetFunc) {

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

    final mapState = MapState.maybeOf(context)!;

    Map<String,Widget> lastTileWidgets = {};
    Map<String,Widget> currentTileWidgets = {};

    CustomPoint size = const CustomPoint(256,256);

    return StreamBuilder<void>(
        stream: mapState.onMoved,
        builder: (BuildContext context, _) {

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
              allTileStack.add(
                RepaintBoundary(child: Transform(child: newWidget, transform: matrix))
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
  MapState mapState;
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
      var type = feature.type;
      var tags = feature.tags;
      var hasJsonStyle;
      //print("${feature.tags}");

      Paint featurePaint = Styles.getPaint(feature, null, options);

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


        var path = dartui.Path()
                    ..fillType = dartui.PathFillType.evenOdd;;
        for( var ring in feature.geometry ) {

          List<Offset> offsets = [];
          for (var c = 0; c < ring.length; c++) {
            offsets.add(Offset(ring[c][0].toDouble(), ring[c][1].toDouble()));
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

    Map<String, dynamic> tags = feature.tags;
    int type = feature.type;

    featurePaint ??= getDefaultStyle(0);

    Map styleTags;
    if(tags.containsKey('style')) {
      styleTags = tags['style'];
      print("got a style $styleTags");
    } else {
      styleTags = tags;
    }

    if(styleTags.containsKey('fill') && type == 3) {
      var fill = styleTags['fill'];
      if(colorNames.containsKey(fill)) {
        featurePaint.color = colorNames[fill]!;
      } else {
        featurePaint.color = HexColor(fill);
      }
    }
    if(styleTags.containsKey('stroke') && type == 2) {
      var stroke = styleTags['stroke'];
      if(colorNames.containsKey(stroke)) {
        featurePaint.color = colorNames[stroke]!;
      } else {
        featurePaint.color = HexColor(stroke);
      }
    }
    if(styleTags.containsKey('marker-color') && type == 1) {
      var markerColor = styleTags['marker-color'];
      if(colorNames.containsKey(markerColor)) {
        featurePaint.color = colorNames[markerColor]!;
      } else {
        featurePaint.color = HexColor(markerColor);
      }
    }

    if(styleTags.containsKey('stroke-width') && type == 2) {
      featurePaint.strokeWidth = feature.tags['stroke-width'];
    }
    if(styleTags.containsKey('stroke-opacity') && type == 2) {
      featurePaint.color = featurePaint.color.withOpacity(feature.tags['stroke-opacity']);
    }
    if(styleTags.containsKey('fill-opacity') && type == 3) {
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

class VectorTileWidget extends StatefulWidget {
  final double size = 256.0;

  const VectorTileWidget({Key? key, size = 256.0}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VectorTileWidgetState();
  }
}

class _VectorTileWidgetState extends State<VectorTileWidget> {

  @override
  Widget build(BuildContext context) {

    var width = MediaQuery.of(context).size.width * 2.0;
    var height = MediaQuery.of(context).size.height;
    var dimensions = Offset(width,height);

    var mapState = MapState.maybeOf(context)!;

    var tileState = TileState(mapState, CustomPoint(widget.size, widget.size));

    var count = 0;
    tileState.loopOverTiles((i, j, pos2, matrix) {
      if(count < 1) {
        print("IJ $i,$j,$matrix");
        Coords coords = Coords(i.toDouble(), j.toDouble());
        coords.z = mapState.zoom.toInt();
        ///fetchData(coords); /// /////////////////////////////////////
        count++;
      }

    });

    var box = SizedBox(
        width: width*1.25, /// calculate this properly depending on rotation and mobile orientation
        height: height*1.25,
        child: Text("Vector Tile")
    );

    return box;
  }

  void fetchData(coords) async {
    String url = NetworkNoRetryTileProvider().getTileUrl(coords,
      TileLayerOptions( urlTemplate: 'https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/{z}/{x}/{y}.mvt?mapbox://styles/gibble/ckoe1dv003l7s17pb219opzj0&access_token=pk.eyJ1IjoiZ2liYmxlIiwiYSI6ImNqbjBlZDB6ejFrODcza3Fsa3o3eXR1MzkifQ.pC89zLnuSWrRdCkDrsmynQ',
                        subdomains: ['a', 'b', 'c']),
      );


    print("url is $url");
    DefaultCacheManager().getSingleFile(url).then( ( value ) async {
      print("$value");

      var bytes = value.readAsBytesSync();

      //late vector_tile.Tile vt;

      //if(units != null)
      //  vt = vector_tile.Tile.fromBuffer(units);
    });

  }

}
