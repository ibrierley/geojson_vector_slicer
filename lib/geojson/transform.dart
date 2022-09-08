import 'dart:math' as math;
import 'tile.dart';
import 'classes.dart';

// Transforms the coordinates of each feature in the given tile from
// mercator-projected space into (extent x extent) tile space.
SimpTile transformTile(tile, extent) {

  if (tile.transformed) return tile;

  final z2 = 1 << tile.z;
  final tx = tile.x;
  final ty = tile.y;

  for (var feature in tile.features) {
    final geom = feature.geometry;
    final type = feature.type;

    feature.geometry = [];

    if (type == 1) {
      for (int j = 0; j < geom.length; j += 2) {
        feature.geometry.add(transformPoint(geom[j], geom[j + 1], extent, z2, tx, ty));
      }
    } else {
      for (int j = 0; j < geom.length; j++) {
        final ring = [];
        for (int k = 0; k < geom[j].length; k += 2) {
          ring.add(transformPoint(geom[j][k], geom[j][k + 1], extent, z2, tx, ty));
        }
        feature.geometry.add(ring);
      }
    }
  }

  tile.transformed = true;

  return tile;
}

List transformPoint(x, y, extent, z2, tx, ty) {

  return [
    (extent * (x * z2 - tx)).round(),
    (extent * (y * z2 - ty)).round()];
}