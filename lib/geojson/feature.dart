import 'dart:math' as math;
import 'classes.dart';

Feature createFeature(id, type, List geometry, tags) {

  Feature feature = Feature(
    geometry: geometry,
    id: id == null ? null : id,
    type: type,
    tags: tags,
  );

  if (type == FeatureType.Point || type == FeatureType.MultiPoint || type == FeatureType.LineString) {
    calcLineBBox(feature, geometry);

  } else if (type == FeatureType.Polygon) {
    // the outer ring (ie [0]) contains all inner rings
    calcLineBBox(feature, geometry[0]);

  } else if (type == FeatureType.MultiLineString) {
    for (final line in geometry) {
      calcLineBBox(feature, line);
    }

  } else if (type == FeatureType.MultiPolygon) {
    for (final polygon in geometry) {
      // the outer ring (ie [0]) contains all inner rings
      calcLineBBox(feature, polygon[0]);
    }
  }

  return feature;
}

void calcLineBBox(Feature feature, List geom) {
  for (var i = 0; i < geom.length; i += 3) {
    if(feature.minX > geom[i]) feature.minX = geom[i];
    if(feature.minY > geom[i + 1]) feature.minY = geom[i + 1];
    if(feature.maxX < geom[i]) feature.maxX = geom[i];
    if(feature.maxY < geom[i + 1]) feature.maxY = geom[i + 1];
  }
}
