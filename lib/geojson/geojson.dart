library geojson;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'transform.dart';
import 'classes.dart';
import "index.dart";
import '../tile/tile_state.dart' hide Coords;
import 'dart:developer' as dev;


class GeoJSON {
  Future<GeoJSONVT> createIndex(String? jsonString, { GeoJSONVTOptions? options, num tileSize = 256, geoJsonMap, keepSource = false, buffer = 32, tolerance = 0 }) async  {
    Map geoMap;
    if(geoJsonMap != null) {
      geoMap = geoJsonMap;
    } else {
      geoMap = jsonDecode(await rootBundle.loadString(jsonString!));
    }

    //var json = jsonDecode(await rootBundle.loadString(jsonString));

    options ??= GeoJSONVTOptions(
          debug : 0,
          buffer : buffer,
          maxZoom: 22,
          indexMaxZoom: 22,
          indexMaxPoints: 10000000,
          keepSource: keepSource,
          tolerance : tolerance, // 1 is probably ok, 2+ may be odd if you have adjacent polys lined up and gets simplified
          extent: tileSize.toInt());
    
    GeoJSONVT geoJsonIndex = GeoJSONVT(geoMap, options);

    return geoJsonIndex;
  }


  // https://stackoverflow.com/questions/22521982/check-if-point-is-inside-a-polygon
  bool isGeoPointInPoly(CustomPoint pt, List polygonList, {size = 256.0}) {
    var x = (pt.x / size).floor();
    var y = (pt.y / size).floor();

    int lat = 0;
    int lon = 1;

    num ax = pt.x - size * x;
    num ay = pt.y - size * y;

    var inside = false;
    for (var polygon in polygonList) {
      for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {

        var xi = polygon[i][lat];
        var yi = polygon[i][lon];
        var xj = polygon[j][lat];
        var yj = polygon[j][lon];

        var intersect = ((yi > ay) != (yj > ay))
            && (ax < (xj - xi) * (ay - yi) / (yj - yi) + xi);
        if (intersect) inside = !inside;
      }

      if(inside) return true;
    }

    return inside;
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
