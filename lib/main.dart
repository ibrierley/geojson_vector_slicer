import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart';
import 'dart:ui' as dartui;
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:typed_data';
import 'geojson/index.dart';
import 'geojson/geojson.dart';
import 'geojson/classes.dart';
import 'geojson/geojson_widget.dart';
import 'geojson/geojson_options.dart';
import 'vector_tile/vector_tile.dart';

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
  late GeoJSONVT geoJsonIndex = GeoJSONVT({},GeoJSONVTOptions(buffer: 32));
  late GeoJSONVT? highlightedIndex = GeoJSONVT({},GeoJSONVTOptions(buffer: 32));
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
      geoJsonIndex = await geoJSON.createIndex('assets/US_County_Boundaries.json', tileSize: tileSize, keepSource: true, buffer: 32);
      //geoJsonIndex = await geoJSON.createIndex('assets/us_test.json', tileSize: tileSize);
      //geoJsonIndex = await geoJSON.createIndex('assets/ids.json', tileSize: tileSize);
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

              onTap: (tapPosition, point) async {
                featureSelected = null;
                // figure which tile we're on, then grab that tiles features to loop through
                // to find which feature the tap was on. Zoom 14 is kinda arbitrary here
                var pt = const Epsg3857().latLngToPoint(point, mapController.zoom.floorToDouble());
                var x = (pt.x / tileSize).floor();
                var y = (pt.y / tileSize).floor();
                var tile = geoJsonIndex.getTile(mapController.zoom.floor(), x, y);
                print("$x, $y  $point $pt  tile ${tile!.x} ${tile!.y} ${tile!.z}");


                if(tile != null) {
                  for (var feature in tile.features) {
                    var polygonList = feature.geometry;

                    if (feature.type != 1) {
                      if(geoJSON.isGeoPointInPoly(pt, polygonList, size: tileSize)) {
                         infoText = "${feature.tags['NAME']}, ${feature.tags['COUNTY']} tapped";
                         print("$infoText");
                         print("source IS ${feature.tags['source']}");

                         highlightedIndex = await GeoJSON().createIndex(null,geoJsonMap: feature.tags['source'], tolerance: 0);

                         if(feature.tags.containsKey('NAME')) {
                           featureSelected = "${feature.tags['NAME']}_${feature.tags['COUNTY']}";
                         }

                      }
                    }
                  }
                  if(featureSelected != null) {
                    print("Tapped $infoText $featureSelected");
                  }
                }
                setState(() {});
                },
              center: LatLng(-2.219988165689301, 56.870017401753529),
              ///center: LatLng(50.8344903, -0.186486 ),
              zoom: 2, //16.6,
              maxZoom: 17.0,
              minZoom: 0.0,
              //interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate
            ),
              children: [

              TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
              ),

                /*
                VectorTileWidgetStream(size: 256.0, index: vectorTileIndex,
                  options:   const {
                  'urlTemplate': '<vector tile server url>',
                  'subdomains': ['a', 'b', 'c']},
                ),

                 */

                GeoJSONWidget(
                  drawClusters: false,
                  drawFeatures: true,
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
                    ///lineStringFunc: () { if(CustomImages.imageLoaded) return CustomImages.plane;}
                      lineStringStyle: (feature) {
                        return Paint()
                          ..style = PaintingStyle.stroke
                          ..color = Colors.red
                          ..strokeWidth = 2
                          ..isAntiAlias = true;
                      },
                    polygonFunc: null,
                    polygonStyle: (feature) {
                      var paint = Paint()
                        ..style = PaintingStyle.fill
                        ..color = Colors.red
                        ..strokeWidth = 5
                        ..isAntiAlias = true;

                      if(feature.tags != null && "${feature.tags['NAME']}_${feature.tags['COUNTY']}" == featureSelected) {
                        paint.strokeWidth = 15;
                        return paint;
                      }
                      paint.color = Colors.lightBlueAccent;
                      paint.isAntiAlias = false;
                      return paint;
                    }
                  ),
                ),
                GeoJSONWidget(
                  index: highlightedIndex,
                  drawFeatures: true,
                  options: GeoJSONOptions(
                  polygonStyle: (feature) {
                    return Paint()
                      ..style = PaintingStyle.stroke
                      ..color = Colors.yellow
                      ..strokeWidth = 8
                      ..isAntiAlias = true;
                  }
                  ),
                ),
                GeoJSONWidget(
                  index: highlightedIndex,
                  drawFeatures: true,
                  options: GeoJSONOptions(
                      polygonStyle: (feature) {
                        return Paint()
                          ..style = PaintingStyle.stroke
                          ..color = Colors.purple
                          ..strokeWidth = 5
                          ..isAntiAlias = true;
                      }
                  ),

                ),
              ])
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
