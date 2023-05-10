import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:tuple/tuple.dart';


class Level {
  List children = [];
  double? zIndex;
  CustomPoint? origin;
  double? zoom;
  CustomPoint? translatePoint;
  double? scale;
}

class PositionInfo {
  CustomPoint point;
  double width;
  double height;
  String coordsKey;
  double scale;
  PositionInfo({required this.point, required this.width, required this.height, required this.coordsKey, required this.scale});

  @override
  String toString() {
    return 'point:$point width:$width height:$height coordsKey:$coordsKey scale:$scale';
  }

}

class Coords<T extends num> extends CustomPoint<T> {
  late T z;

  Coords(T x, T y) : super(x, y);

  @override
  String toString() => 'Coords($x, $y, $z)';

  @override
  bool operator ==(dynamic other) {
    if (other is Coords) {
      return x == other.x && y == other.y && z == other.z;
    }
    return false;
  }

  @override
  int get hashCode => hashValues(x.hashCode, y.hashCode, z.hashCode);
}

class TileState {

  final Map<double, Level> _levels = {};
  //Level _level = Level();
  final mapState;
  double _tileZoom = 12;
  double maxZoom = 20;
  CustomPoint<double> tileSize;

  Tuple2<double, double>? _wrapX;
  Tuple2<double, double>? _wrapY;

  TileState(this.mapState, this.tileSize) {
    _updateLevels();
    _setView(mapState.center, mapState.zoom);
  }

  double getZoomScale(double zoom, [crs]) {
    crs ??= const Epsg3857();
    return crs.scale(zoom) / crs.scale(zoom);
  }

  Bounds getTiledPixelBounds(FlutterMapState mapState) {
    var scale = mapState.getZoomScale(mapState.zoom, _tileZoom);
    var pixelCenter = mapState.project(mapState.center, _tileZoom);
    var halfSize = mapState.size / (scale * 2);
    return Bounds(pixelCenter - halfSize, pixelCenter + halfSize);
  }

  Bounds pxBoundsToTileRange(Bounds bounds,[num tileSize = 256]) {
    final tsPoint = CustomPoint(tileSize,tileSize);

    return Bounds(
      bounds.min.unscaleBy(tsPoint).floor(),
      bounds.max.unscaleBy(tsPoint).ceil() - const CustomPoint(1, 1),
    );
  }

  CustomPoint _getTilePos(Coords coords, tileSize) {

    if(_levels[coords.z] == null) {
      _updateLevels();
    }
    var level = _levels[coords.z];
    return coords.scaleBy(tileSize) - level!.origin!;
  }

  Bounds getBounds() => getTiledPixelBounds(mapState);

  Bounds getTileRange() => pxBoundsToTileRange(getBounds(),256);

  void _setView(LatLng center, double zoom) {
    var tileZoom = zoom.roundToDouble();
    //if (_tileZoom != tileZoom) {
    _tileZoom = tileZoom;
    //_updateLevels();
    _resetGrid();
    _setZoomTransforms(center, zoom);
  }

  void _resetGrid() {
    var map = mapState;
    var crs = map.options.crs;
    var tileSize = getTileSize();
    var tileZoom = _tileZoom;

    _wrapX = crs.wrapLng;
    if (_wrapX != null) {
      var first = (map.project(LatLng(0.0, crs.wrapLng!.item1), tileZoom).x /
          tileSize.x)
          .floorToDouble();
      var second = (map.project(LatLng(0.0, crs.wrapLng!.item2), tileZoom).x /
          tileSize.y)
          .ceilToDouble();
      _wrapX = Tuple2(first, second);
    }

    _wrapY = crs.wrapLat;
    if (_wrapY != null) {
      var first = (map.project(LatLng(crs.wrapLat!.item1, 0.0), tileZoom).y /
          tileSize.x)
          .floorToDouble();
      var second = (map.project(LatLng(crs.wrapLat!.item2, 0.0), tileZoom).y /
          tileSize.y)
          .ceilToDouble();
      _wrapY = Tuple2(first, second);
    }
  }



  void _setZoomTransforms(LatLng center, double zoom) {
    for (var i in _levels.keys) {
      _setZoomTransform(_levels[i]!, center, zoom);
    }
  }

  void _setZoomTransform(Level level, LatLng center, double zoom) {
    var scale = mapState.getZoomScale(zoom, level.zoom);
    var pixelOrigin = mapState.getNewPixelOrigin(center, zoom).round();
    if (level.origin == null) {
      return;
    }
    var origin = level.origin;
    if (origin != null) {
      var translate = origin.multiplyBy(scale) - pixelOrigin;
      level.translatePoint = translate;
      level.scale = scale;
    }
  }

  void _updateLevels() {
    var zoom = _tileZoom;

    for (var z in _levels.keys) {
      var levelZ = _levels[z];
      if(levelZ != null) {
        if (z == zoom) { // recheck here.....
          var levelZi = _levels[z];
          if (levelZi != null) {
            levelZi.zIndex = maxZoom = (zoom - z).abs();
          }
        }
      }
    }

    var max = maxZoom + 2; // arbitrary, was originally for overzoom

    for(var tempZoom in [for(var i=0.0; i<max; i+=1.0) i]) {

      var level = _levels[tempZoom];
      var map = mapState;

      if (level == null) {
        level = _levels[tempZoom.toDouble()] = Level();
        level.zIndex = maxZoom;
        var newOrigin = map.project(map.unproject(map.pixelOrigin), tempZoom);
        level.origin = newOrigin;
        level.zoom = tempZoom;
        _setZoomTransform(level, map.center, map.zoom);
      }

    }

    var levelZoom = _levels[zoom];
    //if(levelZoom != null)
    //  _level = levelZoom;

  }

  PositionInfo getTilePositionInfo( double z, double x, double y ) {
    var coords = Coords(x,y);
    coords.z = z.floorToDouble();

    var tilePos = _getTilePos(coords, tileSize);
    var level = _levels[coords.z];

    var scale = level?.scale ?? 1;
    var pos = (tilePos).multiplyBy(scale) + level!.translatePoint!;
    var width = (tileSize.x * scale);
    var height = tileSize.y * scale;
    var coordsKey = tileCoordsToKey(coords);

    return PositionInfo(point: pos, width: width, height: height, coordsKey: coordsKey, scale: width / tileSize.x );
  }

  String tileCoordsToKey(Coords coords) {
    return '${coords.x}:${coords.y}:${coords.z}';
  }

  CustomPoint getTileSize() {
    return tileSize;
  }

  double getTileZoom() {
    return _tileZoom;
  }

  void loopOverTiles(  myFunction(num i,j, pos2, matrix3) ) {
    Bounds _tileRange = getTileRange();

    outerloop: for (var j = _tileRange.min.y; j <= _tileRange.max.y; j++) {
      innerloop: for (var i = _tileRange.min.x; i <= _tileRange.max.x; i++) {

        var pos = getTilePositionInfo(
            getTileZoom(), i.toDouble(), j.toDouble());

        var matrix = Matrix4.identity()
          ..translate(pos.point.x.toDouble(), pos.point.y.toDouble())
          ..scale(pos.scale);

        myFunction( i, j, pos, matrix );
      }
    }

  }
}
