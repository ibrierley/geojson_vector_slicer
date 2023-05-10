import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'dart:async';
import 'dart:ui' as dartui;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../tile/tile_state.dart' ;
import '../geojson/classes.dart';
import '../geojson/geojson_options.dart';
import '../vector_tile/vector_tile.pb.dart' as vector_tile;
import '../vector_tile/vector_tile.pbenum.dart';
import '../styles/styles.dart';


class VectorTileWidgetStream extends StatelessWidget {
  final double size = 256.0;
  final VectorTileIndex? index;
  final Map options;

  const VectorTileWidgetStream({Key? key, size = 256.0, this.index, this.options = const {}}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return VectorTileWidget(size: 256.0, index: index, options: options);
  }
}

class VectorTileWidget extends StatefulWidget {
  final double size = 256.0;
  final VectorTileIndex? index;
  final Map options;

  const VectorTileWidget({Key? key, size = 256.0, this.index, this.options = const {}}) : super(key: key);

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
  Map options = {};

  _VectorTileWidgetState();

  @override
  void initState() {
    index = widget.index;
    options = widget.options;
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
            urlTemplate: options['urlTemplate'],
              subdomains: options['subdomains'],
          )
        );

        DefaultCacheManager().getSingleFile(url).then( ( value ) async {

          var bytes = value.readAsBytesSync();
          var vt = vector_tile.Tile.fromBuffer(bytes);

          List<ProcessedFeature> tileFeatureList = [];

          int reps = 0;

          for(var layer in vt.layers) {
            var layerString = layer.name.toString();

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

                  if (command == 'C') { // CLOSE
                    if(path != null) {
                      print("IS THIS EVER USED ? IF SO< CLOSE MAY BE WRONG>>>>>");
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
                      polyOffsets.add(Offset(ncx!, ncy!))  ;
                      polyPoints = [];
                      polyPoints.add(Offset(ncx, ncy));

                      featureType = FeatureType.Polygon;

                    } else if (tileGeomType == Tile_GeomType.LINESTRING) {

                      if(polyPoints.isNotEmpty) {
                        path.addPolygon(polyPoints, false);
                      }
                      polyOffsets.add(Offset(ncx!, ncy!))  ;
                      polyPoints = [];
                      polyPoints.add(Offset(ncx, ncy));
                      featureType = FeatureType.LineString;

                    } else if (tileGeomType == Tile_GeomType.POINT) {

                      point = Offset(ncx!, ncy!);
                      pointList.add(point);

                      if(layer.name == "housenum_label") {
                        featureInfo['name'] = featureInfo['house_num'];
                      }

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

            superPath.addPath(feature.path!, const Offset(0, 0));
          } else {
            if( VectorLayerStyles.includeFeature(VectorLayerStyles.mapBoxClassColorStyles,
                layerName, type, tags, zoom) ) {
              if(feature.type == FeatureType.LineString) {
                canvas.drawPath(feature.path!, paint);
              } else {
                canvas.drawPath(feature.path!, paint);
              }
            }
          }

          lastType = type;

          // We may get a mixed polgon followed by a point or line, so we want to
          // draw now to preserve order, but if all the same style may as well batch

          if (feature.type == FeatureType.Polygon && (count < features.length - 1 &&
              (features[count + 1].type != type)) ||
              (count == features.length - 1)) {

            if( VectorLayerStyles.includeFeature(VectorLayerStyles.mapBoxClassColorStyles, layerName, type,
                tags, zoom) ) {
            canvas.drawPath(superPath, paint);
            superPath = dartui.Path();
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(FeatureVectorTilePainter oldDelegate) => oldDelegate.layers != layers  ||
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

    // experimental to remove internal borders
    canvas.save();
    var myRect = const Offset(0, 0) & const Size(257.0, 257.0);
    canvas.clipRect(myRect);

    for( var count = 0; count < features.length; count++ ) {

      var feature = features[count];
      FeatureType type = FeatureType.values[feature.type]; // convert geoson-vt 1-3 int to enum

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

    // experimental remove including top save and clip if nec
    canvas.restore();
  }

  @override
  bool shouldRepaint(FeatureVectorPainter oldDelegate) => oldDelegate.features != features ||
      oldDelegate.mapState.zoom != mapState.zoom ||
      oldDelegate.mapState.center.latitude != mapState.center.latitude ;

}
