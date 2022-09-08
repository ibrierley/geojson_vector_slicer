import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'index.dart';
import 'geojson_options.dart';
import 'geojson.dart';
import 'package:flutter_map/plugin_api.dart';
import '../tile/tile_state.dart' hide Coords;
import '../vector_tile/vector_tile.dart';

class GeoJSONWidget extends StatefulWidget {
  final GeoJSONVT? index;
  final Function? drawFunc;
  final bool drawClusters;
  final bool drawFeatures;
  final bool markers;
  final bool noSlice;
  final GeoJSONOptions options;

  const GeoJSONWidget({Key? key, this.index, this.drawFunc, this.drawClusters = false, this.drawFeatures = true,
    this.markers = false, this.noSlice = false, required this.options }) : super(key: key); // : super(key: key)
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
        if (widget.drawClusters) {
          var tileClusters = GeoJSON().getClustersOnTile(
              tile,
              widget.index,
              matrix,
              mapState,
              size,
              widget.options.clusterFunc,
              widget.options.pointWidgetFunc);
          clusters.add(tileClusters);
        }

        if (widget.drawFeatures) {
          int startRange = 0;
          int endRange = 0;
          for (int c = 0; c < tile.features.length; c++) {
            var feature = tile.features[c];
            var type = feature.type;

            if (type == 1 && widget.options.pointWidgetFunc != null) {
              var tp = MatrixUtils.transformPoint(matrix, Offset(
                  feature.geometry[0][0].toDouble(),
                  feature.geometry[0][1].toDouble()));

              allTileUpperStack.add(
                  Positioned(
                      left: tp.dx,
                      top: tp.dy,
                      child: widget.options.pointWidgetFunc!(feature)
                  )
              );
              startRange++;
            } else {
              if (c == tile.features.length - 1 || (tile.features[c + 1] == 1 &&
                  widget.options.pointWidgetFunc != null)) {
                var subList = tile.features.sublist(startRange, endRange + 1);

                FeatureVectorPainter painterWidget = FeatureVectorPainter(
                    mapState: mapState,
                    features: subList,
                    options: widget.options,
                    matrix: matrix,
                    pos: pos);
                thisTileStack.add(CustomPaint(
                    size: const Size(256.0, 256.0),
                    isComplex: true,
                    //Tells flutter to cache the painter, although it probably won't!
                    painter: painterWidget));
              } else {
                // deferring
              }
            }
            endRange++;
          }
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
}
