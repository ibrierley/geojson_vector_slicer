import 'dart:math' as math;
import 'dart:io';
import 'classes.dart';
import 'clip.dart';
import 'simplify.dart';
import 'feature.dart';


List convert( Map data, GeoJSONVTOptions options ) {
  List features = [];
  final shortKeys = options.shortKeys;
  final type = data["type"];

  if(type == "FeatureCollection") {
    final f = data["features"];
    for (int i = 0; i < f.length; i++) {
      convertFeature(features, f[i], options, i);
    }
  } else if (type == "Feature") {
    convertFeature(features, data, options, null);

  } else {

    // single geometry or a geometry collection
    convertFeature(features, {"geometry": data}, options, null);
  }

  return features;
}

void convertFeature( List featureCollection, geojson, options, index ) {
  final shortKeys = options.shortKeys;

  final geomString = "geometry";
  final propString = "properties";

  if (geomString == null || geomString.isEmpty) return;
  var type = geojson[geomString]["type"];

  var featureType = Feature.stringToFeatureType(type);

  var coords = geojson[geomString]["coordinates"];

  var tolerance = math.pow(options.tolerance / ((1 << options.maxZoom) * options.extent), 2);

  List geometry = [];
  var id = geojson['id'];

  print("${options.keepSource}");
  if(options.keepSource) {

    geojson[propString]['source'] = geojson;
  }

  if (options.promoteId != null) {
    id = geojson[propString][options.promoteId];
  } else if (options.generateId) {
    id = index == null ? 0 : index;
  }

  if (featureType == FeatureType.Point) {
    convertPoint(coords, geometry);

  } else if (featureType == FeatureType.MultiPoint) {
    for (var p in coords) {
      convertPoint(p, geometry);
    }

  } else if (featureType == FeatureType.LineString) {
    convertLine(coords, geometry, tolerance, false);

  } else if (featureType == FeatureType.MultiLineString) {
    if (options.lineMetrics != null && options.lineMetrics) {
      // explode into linestrings to be able to track metrics
      for (var line in coords) {
        geometry = [];
        convertLine(line, geometry, tolerance, false);

        featureCollection.add(createFeature(id, FeatureType.LineString, geometry, geojson[propString]));
      }
      return;
    } else {
      convertLines(coords, geometry, tolerance, false);
    }

  } else if (featureType ==  FeatureType.Polygon) {
    convertLines(coords, geometry, tolerance, true);

  } else if (featureType ==  FeatureType.MultiPolygon) {
    for (var polygon in coords) {
      var newPolygon = [];
      convertLines(polygon, newPolygon, tolerance, true);
      geometry.add(newPolygon);
    }

  } else if (featureType == FeatureType.GeometryCollection) {
    for (final singleGeometry in geojson[geomString][Feature.keyLookupString("geometries", shortKeys)]) {
      convertFeature(featureCollection, {
        'id': id, // to do
        geomString: singleGeometry,
        propString: geojson[propString]
      }, options, index);

    }
    return;
  } else {
    print('Input data is not a valid GeoJSON object.');
  }

  featureCollection.add(createFeature(id, featureType, geometry, geojson[propString]));

  return;
}

void convertPoint(coords, out) {
  out.addAll([projectX(coords[0]), projectY(coords[1]), 0]);
}

double projectX(x) {
  return x / 360 + 0.5;
}

double projectY(y) {
  double sin = math.sin(y * math.pi / 180);
  double y2 = 0.5 - 0.25 * math.log((1 + sin) / (1 - sin)) / math.pi;
  return (y2 < 0) ? 0 : (y2 > 1 ? 1 : y2);
}

void convertLines(rings, out, tolerance, isPolygon) {
  for (var i = 0; i < rings.length; i++) {
    List geom = [];
    convertLine(rings[i], geom, tolerance, isPolygon);
    out.add(geom);
  }
}

void convertLine(ring, List out, tolerance, bool isPolygon) {
  var x0, y0;
  var size = 0.0;

  for (var j = 0; j < ring.length; j++) {
    var x = projectX(ring[j][0]);
    var y = projectY(ring[j][1]);

    out.addAll([x, y, 0.999]); // maybe wrong...

    if (j > 0) {
      if (isPolygon) {
        size += (x0 * y - x * y0) / 2; // area
      } else {
        size += math.sqrt(math.pow(x - x0, 2.0) + math.pow(y - y0, 2.0)); // length
      }
    }
    x0 = x;
    y0 = y;
  }

  final last = out.length - 3;
  out[2] = 1;

  simplify(out, 0, last, tolerance);

  out[last + 2] = 1;
  out.size = size.abs();
  out.start = 0;
  out.end = out.size;

}
