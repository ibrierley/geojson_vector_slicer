# geojson_vector_slicer

A flutter_map plugin to display fast geojson by slicing into tiles.
Slicing based off https://github.com/mapbox/geojson-vt

THIS IS VERY MUCH AN ALPHA/PROOF OF CONCEPT VERSION

## Getting Started

See the example main.dart, will create specific examples later. 

Click on the US map and tap on the states to see which state was tapped (check console)
Should cluster US state points, and display a plane when no clusters.
Should display a basic vector map with not much styling.

Main features:

Display GeoJSON by splitting them into tiles. Includes line simplification as an option.
Polyline/polygon hit detection as well (see example main.dart).
Display Vector tiles (no mapbox styling works on this or is intended to).
Basic tile clustering on markers.

Example GeoJsonWidget
drawClusters: true to erm draw clusters instead of raw features.
drawFeatures: true to erm draw the features
You probably only want one of these enabled, but you can have both enabled for testing.
featuresHaveSameStyle: true if all geometry has the same color. This may give a performance tweak as we can batch draw calls up

For Markers, we may want a Canvas element (eg draw some lines or icon), or a Widget (eg a tappable icon). Hence there are two types for this. It will try and create the correct layer.

Available  GeoJSONOptions are:
Function? lineStringFunc;
Function? lineStringStyle;
Function? polygonFunc;
Function? polygonStyle;
Function? pointFunc;
Function? pointWidgetFunc;
Function? pointStyle;
Function? overallStyleFunc;
Function? clusterFunc;
bool featuresHaveSameStyle;

```dart
                GeoJSONWidget(
                  drawClusters: true,
                  drawFeatures: false,
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
                    polygonFunc: null,
                    polygonStyle: (feature) {
                      var paint = Paint()
                        ..style = PaintingStyle.fill
                        ..color = Colors.red
                        ..strokeWidth = 5
                        ..isAntiAlias = false;

                      if(feature.tags != null && "${feature.tags['NAME']}_${feature.tags['COUNTY']}" == featureSelected) {
                        return paint;
                      }
                      paint.color = Colors.lightBlueAccent;
                      return paint;
                    }
                  ),
```

Example Vector Tile Widget
```dart

      VectorTileWidgetStream(size: 256.0, index: vectorTileIndex,
                  options:   const {
                  'urlTemplate': 'https://api.mapbox.com/v4/mapbox.mapbox-streets-v8/{z}/{x}/{y}.mvt?mapbox://styles/<name>/<key/',
                  'subdomains': ['a', 'b', 'c']},
      ),

```

onTap for polygons

```dart
              onTap: (tapPosition, point) {
                featureSelected = null;
                // figure which tile we're on, then grab that tiles features to loop through
                // to find which feature the tap was on. Zoom 14 is kinda arbitrary here
                var pt = const Epsg3857().latLngToPoint(point, mapController.zoom.floorToDouble());
                var x = (pt.x / tileSize).floor();
                var y = (pt.y / tileSize).floor();
                var tile = geoJsonIndex.getTile(mapController.zoom.floor(), x, y);

                if(tile != null) {
                  for (var feature in tile.features) {
                    var polygonList = feature.geometry;

                    if (feature.type != 1) {
                      if(geoJSON.isGeoPointInPoly(pt, polygonList, size: tileSize)) {
                         infoText = "${feature.tags['NAME']}, ${feature.tags['NAME']} tapped";
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

```