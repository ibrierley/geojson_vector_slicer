library geojson_vt_dart;

import 'convert.dart';
import 'tile.dart';
import 'clip.dart';
import 'dart:convert';
import 'transform.dart';
import 'wrap.dart';
import 'classes.dart';
import 'dart:io';

Map defaultOptions = {
  'maxZoom': 14,            // max zoom to preserve detail on
  'indexMaxZoom': 5,        // max zoom in the tile index
  'indexMaxPoints': 100000, // max number of points per tile in the tile index
  'tolerance': 3,           // simplification tolerance (higher means simpler)
  'extent': 4096,           // tile extent
  'buffer': 64,             // tile buffer on each side
  'lineMetrics': false,     // whether to calculate line metrics
  'promoteId': null,        // name of a feature property to be promoted to feature.id
  'generateId': false,      // whether to generate feature ids. Cannot be used with promoteId
  'debug': 2                // logging level (0, 1 or 2)
};

class GeoJSONVT {
  GeoJSONVTOptions options;
  Map tiles = {};
  List tileCoords = [];
  Map stats = {};
  int total = 0;

  GeoJSONVT(data, this.options)  {

    if(data.isEmpty) {
      data = {};
      return;
    }

    var debug = options.debug;

    if (options.maxZoom < 0 || options.maxZoom > 24) throw Exception('maxZoom should be in the 0-24 range');
    if (options.promoteId != null && options.generateId) throw Exception('promoteId and generateId cannot be used together.');

    // projects and adds simplification info
    var features = convert(data, options);

    List t = features[0].geometry;

    tiles = {};
    List tileCoords = [];

    if( debug > 0 ) {
      //stats = {};
      //total = 0;
    }

    // wraps features (ie extreme west and extreme east)
    features = wrap(features, options);

    if (features.length > 0) splitTile(features, 0, 0, 0, null, null, null);
  }

  @override toString() {
    var out = "Index: ";
    tiles.forEach((tile,index) {
      out += "Index: $index, Tile:" + tile.toString();
    });
    return out;
  }

  // splits features from a parent tile to sub-tiles.
  // z, x, and y are the coordinates of the parent tile
  // cz, cx, and cy are the coordinates of the target tile
  //
  // If no target tile is specified, splitting stops when we reach the maximum
  // zoom or the number of points is low as specified in the options.
  splitTile(List features, z, x, y, cz, cx, cy) {
    final List stack = [features, z, x, y];
    final options = this.options;
    final debug = options.debug;

    // avoid recursion by using a processing queue

    while (stack.length > 0) {
      y = stack.removeLast();
      x = stack.removeLast();
      z = stack.removeLast();

      features = stack.removeLast();

      final z2 = 1 << z;
      final id = toID(z, x, y);
      var tile = this.tiles[id];

      if (tile == null) {

        if(features.isNotEmpty ) {
          //print("Creating tile from Index.dart $z $x $y $features ${features[0]!['geometry']}");
        } else {
          //print("features is empty ");
        }
        tile = this.tiles[id] = createTile(features, z, x, y, options);

        if( options.debug > 1 ) {
          print("tile z$z-$x-$y (features: ${tile.numFeatures}, points: ${tile.numPoints}, simplified: ${tile.numSimplified})");
        }

        this.tileCoords.add({z, x, y});


        if (debug > 0) {
          if (debug > 1) {
            //print("tile $z-$x-$y (features: ${tile.numFeatures}, ${tile.numPoints}, ${tile.numSimplified})");
          }
          final key = "z${z}";
          this.stats[key] = (this.stats[key] ?? 0) + 1;
          this.total++;
        }
      }

      // save reference to original geometry in tile so that we can drill down later if we stop now
      tile.source = features;

      // if it's the first-pass tiling
      if (cz == null) {
        // stop tiling if we reached max zoom, or if the tile is too simple
        if (z == options.indexMaxZoom || tile.numPoints <= options.indexMaxPoints) continue;
        // if a drilldown to a specific tile
      } else if (z == options.maxZoom || z == cz) {
        // stop tiling if we reached base zoom or our target tile zoom
        continue;
      } else if (cz != null) {
        // stop tiling if it's not an ancestor of the target tile
        final zoomSteps = cz - z;
        if (x != cx >> zoomSteps || y != cy >> zoomSteps) continue;
      }

      // if we slice further down, no need to keep source geometry
      tile.source = null;

      if (features.length == 0) continue;

      if (debug > 1) print('clipping');

      // values we'll use for clipping
      final k1 = 0.5 * options.buffer / options.extent;
      final k2 = 0.5 - k1;
      final k3 = 0.5 + k1;
      final k4 = 1 + k1;

      List? tl = [];
      List? bl = [];
      List? tr = [];
      List? br = [];

      List? left  = clip(features, z2, x - k1, x + k3, 0, tile.minX, tile.maxX, options);
      List? right = clip(features, z2, x + k2, x + k4, 0, tile.minX, tile.maxX, options);
      features = [];

      if (left != null && left.isNotEmpty) {
        tl = clip(left, z2, y - k1, y + k3, 1, tile.minY, tile.maxY, options);
        bl = clip(left, z2, y + k2, y + k4, 1, tile.minY, tile.maxY, options);
        left = null;
      }

      if (right != null && right.isNotEmpty) {
        tr = clip(right, z2, y - k1, y + k3, 1, tile.minY, tile.maxY, options);
        br = clip(right, z2, y + k2, y + k4, 1, tile.minY, tile.maxY, options);
        right = null;
      }

      if (debug > 1) print('finished clipping');

      stack.addAll([tl, z + 1, x * 2,     y * 2]);
      stack.addAll([bl, z + 1, x * 2,     y * 2 + 1]);
      stack.addAll([tr, z + 1, x * 2 + 1, y * 2]);
      stack.addAll([br, z + 1, x * 2 + 1, y * 2 + 1]);
    }

    if( debug > 1 ) print("total ${this.total}, stats ${this.stats}");

  }

  num toID(z, x, y) {
    return (((1 << z) * y + x) * 32) + z;
  }

  SimpTile? getTile(z, x, y) {

    GeoJSONVTOptions options = this.options;
    final extent = options.extent;
    final debug = options.debug;

    if (z < 0 || z > 24) return null;

    final z2 = 1 << z;
    x = (x + z2) & (z2 - 1); // wrap tile x coordinate

    final id = toID(z, x, y);

    //print("here $z $x $y ${this.tiles.keys}");
    //print("ID is $id");

    if (this.tiles[id] != null) return transformTile(this.tiles[id], extent);

    if (debug > 1) print('Drilling down to $z-$x-$y');

    var z0 = z;
    var x0 = x;
    var y0 = y;
    SimpTile? parent;

    while (parent == null && z0 > 0) {
      z0--;
      x0 = x0 >> 1;
      y0 = y0 >> 1;
      parent = this.tiles[toID(z0, x0, y0)];
    }

    if (parent == null || parent.source == null) return null;

    // if we found a parent tile containing the original geometry, we can drill down from it
    if (debug > 1) {
      print('drilling down, splitting $z0, $x0, $y0, $z, $x, $y');
    }

    this.splitTile(parent.source, z0, x0, y0, z, x, y);

    if (debug > 1) print('drilling down');

    return (this.tiles[id] != null ? transformTile(this.tiles[id], extent) : null);
  }

}

void main () async {}


Map extend(Map dest, Map src) {
  src.forEach((key, value) {
    dest[key] = src[key];
  });
  return dest;
}

