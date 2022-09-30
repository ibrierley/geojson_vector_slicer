extension JSList<T> on List<T> {
  static final _startValues = Expando<num>();
  static final _sizeValues = Expando<num>();
  static final _endValues = Expando<num>();


  num get start => _startValues[this] ?? 0;
  set start(num x) => _startValues[this] = x;

  num get size => _sizeValues[this] ?? 0;
  set size(num x) => _sizeValues[this] = x;

  num get end => _endValues[this] ?? 0;
  set end(num x) => _endValues[this] = x;

}

enum FeatureType {
  Unknown,
  Point,
  LineString,
  Polygon,
  MultiPoint,
  MultiLineString,
  Feature,
  FeatureCollection,
  MultiPolygon,
  GeometryCollection, // not really a feature type, but helps here...
}



class TileFeature {
  List geometry;
  int type;
  Map tags;
  String? id;

  TileFeature({this.geometry = const [], required this.type, this.tags = const {}, this.id});

  @override
  String toString() {
    return "$geometry, $type, $tags, $id";
  }
}

class Feature {
  List geometry;
  String? id;
  FeatureType type;
  Map? tags;
  double minX;
  double maxX;
  double minY;
  double maxY;

  // Prob a better way of doing this...
  static const Map typeLookup = {
    "PT": FeatureType.Point,
    "Point": FeatureType.Point,
    "point": FeatureType.Point,
    "MP": FeatureType.MultiPoint,
    "MultiPoint": FeatureType.MultiPoint,
    "multipoint": FeatureType.MultiPoint,
    "L": FeatureType.LineString,
    "LineString": FeatureType.LineString,
    "linestring": FeatureType.LineString,
    "ML" : FeatureType.MultiLineString,
    "MultiLineString" : FeatureType.MultiLineString,
    "multilinestring" : FeatureType.MultiLineString,
    "P": FeatureType.Polygon,
    "Polygon": FeatureType.Polygon,
    "polygon": FeatureType.Polygon,
    "MG": FeatureType.MultiPolygon,
    "MultiPolygon": FeatureType.MultiPolygon,
    "multipolygon": FeatureType.MultiPolygon,
    "F": FeatureType.Feature,
    "Feature": FeatureType.Feature,
    "feature": FeatureType.Feature,
    "FC": FeatureType.FeatureCollection,
    "FeatureCollection": FeatureType.FeatureCollection,
    "featurecollection": FeatureType.FeatureCollection,
    "GC": FeatureType.GeometryCollection,
    "GeometryCollection": FeatureType.GeometryCollection, // bit naught, not really a feature type..
    "geometrycollection": FeatureType.GeometryCollection,
  };

  Feature({ this.geometry = const [], this.id, this.type = FeatureType.Feature, this.tags,
    this.minX = double.infinity, this.maxX = -double.infinity, this.minY = double.infinity, this.maxY = -double.infinity});

  static FeatureType stringToFeatureType(String type) {
    FeatureType fullType = typeLookup[type];
    if(fullType == null) {
      fullType = typeLookup[type.toLowerCase()];
    }
    return fullType;
  }

  static final stringMap = {
    'type': 't',
    'coordinates': 'c',
    'properties': 'pr',
    'FeatureCollection' : 'FC',
    'feature': 'f',
    'Feature': 'F',
    'features' : 'fs',
    'geometry': 'g',
    'geometries': 'gs',
  };

  static String keyLookupString(string, shortKeys) {
    return shortKeys ? stringMap[string] : string;
  }

  @override
  String toString() {
    return "$geometry, $type, $tags, $id, $minX, $maxX, $minY, $maxY";
  }
}

class SimpTile {
  List features = [];
  int numPoints = 0;
  int numSimplified = 0;
  int numFeatures = -1; // = features.length;
  var source = null;
  num x = 0;
  num y = 0;
  num z;
  bool transformed = false;
  num minX = 2;
  num minY = 1;
  num maxX = -1;
  num maxY = 0;

  SimpTile(this.features, this.z, tx, ty) { x = tx; y = ty; }

  @override String toString() {
    return "SimpTile:    numPoints: $numPoints numSimplified: $numSimplified numFeatures: $numFeatures source: $source xyz $x,$y,$z transformed: $transformed minX: $minX minY $minY maxX: $maxX maxY: $maxY features: $features";
  }
}

class GeoJSONVTOptions {
  int maxZoom; // max zoom to preserve detail on
  int indexMaxZoom; // max zoom in the tile index
  int indexMaxPoints; // max number of points per tile in the tile index
  int tolerance; // simplification tolerance (higher means simpler)
  int extent; // tile extent (pixels)
  int buffer; // tile buffer on each side
  bool lineMetrics; // whether to calculate line metrics
  String? promoteId; // name of a feature property to be promoted to feature.id
  bool generateId; // whether to generate feature ids. Cannot be used with promoteId
  int debug; // logging level (0, 1 or 2)
  bool shortKeys;
  bool keepSource;

  GeoJSONVTOptions({this.maxZoom = 14, this.indexMaxZoom = 5, this.indexMaxPoints = 100000,
    this.tolerance = 3, this.extent = 4096, this.buffer = 64, this.lineMetrics = false, this.promoteId = null,
    this.generateId = false, this.debug = 2, this.shortKeys = false, this.keepSource = false
  });
}
