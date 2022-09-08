# geojson_vector_slicer

A flutter_map plugin to display fast geojson by slicing into tiles.
Slicing based off https://github.com/mapbox/geojson-vt

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
