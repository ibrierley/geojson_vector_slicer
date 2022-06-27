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

  final _random = Random();
  //int next(int min, int max) => min + _random.nextInt(max - min);
  double doubleInRange(num start, num end) =>
      _random.nextDouble() * (end - start) + start;

  late final MapController mapController;
  GeoJSONVT? geoJsonIndex;
  var infoText = 'No Info';
  var tileSize = 256.0;
  // Guessing best val here depends on a zoom level where there aren't many polys in display
  var tilePointCheckZoom = 14;
  //var latGeo = {"type": "FeatureCollection", "features" : []};
  //var latGeo = {"t": "FC", "fs" : []};

  GeoJSON geoJSON = GeoJSON();


  @override
  void initState() async {
    super.initState();
    mapController = MapController();
    CustomImages().loadPlane();


    //List features = latGeo['features'] as List;
    ///List features = latGeo['fs'] as List;
    ///for( var c = 0; c < 100000; c++) {
      //var feature = {"type": "feature", "properties": {}, "geometry": {"type": "point", "coordinates": [doubleInRange(-90,90),doubleInRange(-180,180) ]}};
      ///var feature = {"t": "f", "pr": {}, "g": {"t": "PT", "c": [doubleInRange(-90,90),doubleInRange(-180,180) ]}};
      ///features.add(feature);
      //latList.add(LatLng(next(-90,90).toDouble(), next(-180,180).toDouble()));
    ///}
    //print("$features");

    WidgetsBinding.instance!.addPostFrameCallback((_) async {

      ///geoJsonIndex = await geoJSON.createIndex('assets/US_County_Boundaries.json', tileSize: 256);
      ///geoJsonIndex = await geoJSON.createIndex('assets/polygon_hole.json', tileSize: 256);
      geoJsonIndex = await geoJSON.createIndex('assets/general.json', tileSize: 256);
      setState(() {
      });

      /*
      //https://raw.githubusercontent.com/Azure-Samples/AzureMapsCodeSamples/master/AzureMapsCodeSamples/Common/data/geojson/US_County_Boundaries.json
      // https://www.mapchart.net/usa-counties.html
      var json = jsonDecode(await rootBundle.loadString('assets/US_County_Boundaries.json'));
      ///var json = latGeo;
      //var json = jsonDecode(await rootBundle.loadString('assets/ids.json'));
      //final appDocDir = await getApplicationDocumentsDirectory();
      //var geoJson = await featuresFromGeoJsonFile(File("${appDocDir.path}/assets/ids.json"));
      //final data = await rootBundle.loadString('assets/ids.json');
      //var json = await featuresFromGeoJson( data );
      //var json = { 'pointList' : [[ -75.849253579389796, 47.6434349837781 ]] };

      //print("json is $json");
      geoJsonIndex = GeoJSONVT(json, GeoJSONVTOptions(
        ///shortKeys: true,
        debug : 0,
        buffer : 0,
        indexMaxZoom: 14,
        indexMaxPoints: 10000000,
        tolerance : 0, // 1 is probably ok, 2+ may be odd if you have adjacent polys lined up and gets simplified
        extent: tileSize.toInt()));
      setState(() { });

       */
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
                var tile = geoJsonIndex!.getTile(14, x, y);

                if(tile != null) {
                  for (var feature in tile.features) {
                    var polygonList = feature.geometry;

                    if (feature.type != 1) {
                      if(geoJSON.isGeoPointInPoly(pt, polygonList, size: tileSize)) {
                         infoText = "${feature.tags['NAME']}, ${feature.tags['COUNTY']} tapped";
                         print("Tapped $infoText");
                      }
                    }
                  }
                }
                setState(() {});
                },
              center: LatLng(-2.219988165689301, 56.870017401753529),
              zoom: 0.0,
              maxZoom: 15.0,
              minZoom: 0.0,
              //interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate
            ),
              layers: [
                /*
                TileLayerOptions(
                  urlTemplate: "https://atlas.microsoft.com/map/tile/png?api-version=1&layer=basic&style=main&tileSize=256&view=Auto&zoom={z}&x={x}&y={y}&subscription-key={subscriptionKey}",
                  additionalOptions: {
                    'subscriptionKey': 'FqtZvgMGhQB-2AqzcvlpYznhg38kCt-bBx1OtvU7wLE'
                  },
                ),

                 */
                MarkerLayerOptions(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: new LatLng(51.5, -0.09),
                      builder: (ctx) =>
                      Container(
                        child: new FlutterLogo(),
                      ),
                    ),
                  ],
                ),
              ],

            children: <Widget>[
              TileLayerWidget(
                options: TileLayerOptions(
                    opacity: 0.8,
                    //urlTemplate:
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    //'https://maps.dabbles.info/index.php?x={x}&y={y}&z={z}&r=osm',
                    //FqtZvgMGhQB-2AqzcvlpYznhg38kCt-bBx1OtvU7wLE
                    //urlTemplate: "https://atlas.microsoft.com/map/tile/png?api-version=1&layer=basic&style=main&tileSize=256&view=Auto&zoom={z}&x={x}&y={y}&subscription-key=FqtZvgMGhQB-2AqzcvlpYznhg38kCt-bBx1OtvU7wLE",
                    subdomains: ['a', 'b', 'c']),
              ),




/*
              SliceLayerWidget(
                clusters: true,
                index: geoJsonIndex,
                drawFunc: (feature, count) {
                  return Container(
                    child: FittedBox(
                        fit: BoxFit.contain,
                        child: count == 1 ? const Icon(Icons.airplanemode_active_outlined) : Text("$count", style: const TextStyle(color: Colors.deepPurple),)
                    ),
                    decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.deepPurple
                      //color: ,
                    ),)
                  );
                }),

 */
                GeoJSONWidget(
                  index: geoJsonIndex,
                  options: GeoJSONOptions(
                    pointFunc: () { return CustomImages.plane; },
                    lineStringFunc: () { return CustomImages.plane; },
                    polygonFunc: null, //() { return CustomImages.plane; },
                    polygonStyle: (feature) {
                      return Paint()
                        ..style = PaintingStyle.fill
                        ..color = Colors.deepPurple
                        ..strokeWidth = 5
                        ..isAntiAlias = false;


                      Paint p = Paint();
                      p.color=Colors.deepPurple;
                      p.style = PaintingStyle.fill;
                      return p;
                    }
                  ),
                ),

/*
              SliceLayerWidget(
                //noSlice: true,
                index: geoJsonIndex,
                markers: true,
                drawFunc: (feature, count) {
                  return const Icon(Icons.free_breakfast, color: Colors.blue, size: 20);
              }),

 */
            ]),




    ]);
  }
}

class CustomImages {
  static late dartui.Image plane;

  void loadPlane() async {
    plane = await loadUiImage('assets/aeroplane.png');
  }

  Future<dartui.Image> loadUiImage(String imageAssetPath) async {
    final ByteData data = await rootBundle.load(imageAssetPath);
    final Completer<dartui.Image> completer = Completer();
    dartui.decodeImageFromList(Uint8List.view(data.buffer), (dartui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

 // dartui.Image plane = await loadUiImage('assets/aeroplane.png');
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
      //if(tile != null)
      //  print("TILE ${tile!.minX * 256.0},${tile!.minY}   ${tile!.maxX}, ${tile!.maxY}");

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
  final Function? drawFunc;
  final bool clusters;
  final bool markers;
  final bool noSlice;

  const SliceLayerWidget({Key? key, this.index, this.drawFunc, this.clusters = false, this.markers = false, this.noSlice = false}) : super(key: key); // : super(key: key);

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
                      child: Stack(children: [
                        ///if( widget.markers == true)
                        ///  FeatureDraw().drawMarkers( mapState, widget.index, mapState.onMoved, widget.drawFunc),
                       /// if( widget.clusters == true)
                       ///   FeatureDraw().drawClusters(mapState, widget.index, mapState.onMoved, widget.drawFunc),
                      ]),
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

  Widget drawMarkers(MapState mapState, index, stream, markerFunc) {

    var tileState = TileState(mapState, const CustomPoint(256.0, 256.0));

    List<Widget> markers = [];

    var retrieveZoom = tileState.getTileZoom().toInt();

    tileState.loopOverTiles( (i,j, pos, matrix) {
      if (index != null) {
        var tile = index.getTile(retrieveZoom, i, j);

        final featuresInTile = [];

        if (tile != null && tile.features.isNotEmpty) {
          featuresInTile.addAll(tile.features);
        }

        outerloop: for (var feature in featuresInTile) {
          innerloop: for( var geom in feature.geometry ) {
            if (feature.type != 1) {
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
                    left: tp.dx - 10,
                    top: tp.dy - 10,
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
      if (feature.type == 3) {
        if (options.containsKey('polyDrawFunc')) {
          options['polyDrawFunc'](canvas, feature, pos, featuresInTile, delayedDrawHash);
        } else {
          drawPolylineDefault(canvas, feature, pos);
        }
      } else if( feature.type == 1 ) {
        var style = Paint()
          ..strokeWidth = 0.5 / pos.scale
          ..color = Colors.blue
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(feature.geometry[0][0].toDouble(),feature.geometry[0][1].toDouble()),20,style);
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

    for( var item in feature.geometry ) {
      List<Offset> offsets = [];
      for (var c = 0; c < item.length; c++) {
        offsets.add(Offset(item[c][0].toDouble(), item[c][1].toDouble()));
      }
      p.addPolygon(offsets, false);
    }

    canvas.drawPath(p, style);
  }


  final _random = Random();
  //int next(int min, int max) => min + _random.nextInt(max - min);
  double doubleInRange(num start, num end) =>
      _random.nextDouble() * (end - start) + start;

  void batchCallsDraw(List<dynamic> featuresInTile, PositionInfo pos, Canvas canvas, [ Map options = const {} ]) async  {



    //for (var a = 0; a<250; a++) {
    //  var o = Offset(doubleInRange(0,256),doubleInRange(0,256));
    //canvas.drawImage(CustomImages.plane, o, Paint());
    //}
    //return;

    var count = 0;
    var superPath = dartui.Path();
    LOOP: for (var feature in featuresInTile) {
      if (feature.type == 3) {
        for( var item in feature.geometry ) {
          List<Offset> offsets = [];
          for (var c = 0; c < item.length; c++) {
            offsets.add(Offset(item[c][0].toDouble(), item[c][1].toDouble()));
            canvas.drawImage(CustomImages.plane, Offset(item[c][0].toDouble(), item[c][1].toDouble()), Paint());
            count++;
            if(count > 250) continue LOOP;
          }
          //superPath.addPolygon(offsets, false);
        }
      }

    }
    //canvas.drawPath(superPath, defaultStyle);
  }
}
/*
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

 */

class GeoJSON {
  Future<GeoJSONVT> createIndex(String jsonString, { GeoJSONVTOptions? options, num tileSize = 256 }) async  {
    var json = jsonDecode(await rootBundle.loadString(jsonString));

    options ??= GeoJSONVTOptions(
          debug : 0,
          buffer : 0,
          indexMaxZoom: 14,
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
}

class GeoJSONWidget extends StatefulWidget {
  final GeoJSONVT? index;
  final Function? drawFunc;
  final bool clusters;
  final bool markers;
  final bool noSlice;
  final GeoJSONOptions? options;

  const GeoJSONWidget({Key? key, this.index, this.drawFunc, this.clusters = false, this.markers = false, this.noSlice = false, this.options }) : super(key: key); // : super(key: key);

  @override
  _GeoJSONWidgetState createState() => _GeoJSONWidgetState();
}

class _GeoJSONWidgetState extends State<GeoJSONWidget> {

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
                      ///child: Stack(children: [
                        ///if( widget.markers == true)
                        ///  FeatureDraw().drawMarkers( mapState, widget.index, mapState.onMoved, widget.drawFunc),
                        /// if( widget.clusters == true)
                        ///   FeatureDraw().drawClusters(mapState, widget.index, mapState.onMoved, widget.drawFunc),
                      ///]),
                      isComplex: true, //Tells flutter to cache the painter.
                      painter: GeoJSONVectorPainter(mapState: mapState, index: widget.index, stream: mapState.onMoved, options: widget.options)
                  )
              )
          );
          return box;
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
    Function? pointStyle;

    GeoJSONOptions({this.lineStringFunc, this.lineStringStyle, this.polygonFunc,
      this.polygonStyle, this.pointFunc, this.pointStyle});

}

class GeoJSONVectorPainter extends CustomPainter with ChangeNotifier {

  final Stream<Null>? stream;
  final GeoJSONOptions? options;
  GeoJSONVT? index;
  MapState mapState;
  TileState? tileState;
  Paint defaultStyle = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red
    ..strokeWidth = 0.9
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  GeoJSONVectorPainter({ required this.mapState, this.index, this.stream, this.options  });

  @override
  void paint(Canvas canvas, Size size) {
    tileState = TileState(mapState, const CustomPoint(256.0, 256.0));

    tileState!.loopOverTiles((i, j, pos, matrix) {
      var tile = index?.getTile(tileState!.getTileZoom().toInt(), i, j);

      if(tile != null && tile.features.isNotEmpty) {
        canvas.save();
        canvas.transform(matrix.storage);
        //canvas.clipRect(const Offset(0, 0) & const Size(256.0, 256.0));
        draw(tile.features, pos, canvas, options);
        canvas.restore();
      }
    });
  }

  void draw(List<dynamic> features, PositionInfo pos, Canvas canvas, [ GeoJSONOptions? options ]) async  {

    var count = 0;
    var superPath = dartui.Path();

    LOOP: for (var feature in features) {

      //print("drawing ${feature.type}");
      var paint = defaultStyle;

      if(feature.type == 1 ) { // point
        if(options!.pointFunc != null) {
          print("$feature");
          canvas.drawImage(options.pointFunc!(), Offset(feature.geometry[0][0].toDouble(), feature.geometry[0][1].toDouble()), Paint());
        }
      }
      if(feature.type == 2 || feature.type == 3) { // line = 2, poly = 3
        var path = dartui.Path();
        for( var item in feature.geometry ) {
          List<Offset> offsets = [];
          for (var c = 0; c < item.length; c++) {
            offsets.add(Offset(item[c][0].toDouble(), item[c][1].toDouble()));

            if(feature.type == 2 && options!.lineStringFunc != null) {
              canvas.drawImage(options.lineStringFunc!(), Offset(item[c][0].toDouble(), item[c][1].toDouble()), Paint());
            }
            //print("got here...$options");

            if(feature.type == 3) {
              if (options!.polygonStyle != null) {
                paint = options.polygonStyle!(feature);
                //print("really 3");

                //canvas.drawImage(options.polygonFunc!(), Offset(item[c][0].toDouble(), item[c][1].toDouble()), paint);
              } else {
                //print("Adding poly");

              }
            }

            ///path.addPolygon(offsets,false);
            count++;
            ///if(count > 250) continue LOOP;
          }

          path.addPolygon(offsets,false);
          //superPath.addPolygon(offsets, false);
          //superPath.addPolygon(offsets, false);
        }

        canvas.drawPath(path, paint);
        //superPath.addPath(path, const Offset(0,0));

        //canvas.drawPath(path, defaultStyle);

      }


    }
    //canvas.drawPath(superPath, defaultStyle);
  }


  @override
  bool shouldRepaint(GeoJSONVectorPainter oldDelegate) => true;


}



