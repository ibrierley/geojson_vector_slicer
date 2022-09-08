///
//  Generated code. Do not modify.
//  source: vector_tile.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Tile_GeomType extends $pb.ProtobufEnum {
  static const Tile_GeomType UNKNOWN = Tile_GeomType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UNKNOWN');
  static const Tile_GeomType POINT = Tile_GeomType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'POINT');
  static const Tile_GeomType LINESTRING = Tile_GeomType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'LINESTRING');
  static const Tile_GeomType POLYGON = Tile_GeomType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'POLYGON');

  static const $core.List<Tile_GeomType> values = <Tile_GeomType> [
    UNKNOWN,
    POINT,
    LINESTRING,
    POLYGON,
  ];

  static final $core.Map<$core.int, Tile_GeomType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Tile_GeomType? valueOf($core.int value) => _byValue[value];

  const Tile_GeomType._($core.int v, $core.String n) : super(v, n);
}

