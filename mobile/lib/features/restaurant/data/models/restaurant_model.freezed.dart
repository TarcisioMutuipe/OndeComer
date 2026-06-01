// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'restaurant_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RestaurantModel _$RestaurantModelFromJson(Map<String, dynamic> json) {
  return _RestaurantModel.fromJson(json);
}

/// @nodoc
mixin _$RestaurantModel {
  String get id => throw _privateConstructorUsedError;
  String get ownerUserId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String? get logoUrl => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;
  String? get instagramUrl => throw _privateConstructorUsedError;
  String? get youTubeVideoUrl => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String get openingHours => throw _privateConstructorUsedError;
  int get dishCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RestaurantModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RestaurantModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RestaurantModelCopyWith<RestaurantModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestaurantModelCopyWith<$Res> {
  factory $RestaurantModelCopyWith(
          RestaurantModel value, $Res Function(RestaurantModel) then) =
      _$RestaurantModelCopyWithImpl<$Res, RestaurantModel>;
  @useResult
  $Res call(
      {String id,
      String ownerUserId,
      String name,
      String? description,
      String address,
      String city,
      double latitude,
      double longitude,
      String category,
      String? logoUrl,
      String? coverUrl,
      String? instagramUrl,
      String? youTubeVideoUrl,
      bool isActive,
      String openingHours,
      int dishCount,
      DateTime createdAt});
}

/// @nodoc
class _$RestaurantModelCopyWithImpl<$Res, $Val extends RestaurantModel>
    implements $RestaurantModelCopyWith<$Res> {
  _$RestaurantModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RestaurantModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerUserId = null,
    Object? name = null,
    Object? description = freezed,
    Object? address = null,
    Object? city = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? category = null,
    Object? logoUrl = freezed,
    Object? coverUrl = freezed,
    Object? instagramUrl = freezed,
    Object? youTubeVideoUrl = freezed,
    Object? isActive = null,
    Object? openingHours = null,
    Object? dishCount = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerUserId: null == ownerUserId
          ? _value.ownerUserId
          : ownerUserId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      coverUrl: freezed == coverUrl
          ? _value.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramUrl: freezed == instagramUrl
          ? _value.instagramUrl
          : instagramUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      youTubeVideoUrl: freezed == youTubeVideoUrl
          ? _value.youTubeVideoUrl
          : youTubeVideoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      openingHours: null == openingHours
          ? _value.openingHours
          : openingHours // ignore: cast_nullable_to_non_nullable
              as String,
      dishCount: null == dishCount
          ? _value.dishCount
          : dishCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RestaurantModelImplCopyWith<$Res>
    implements $RestaurantModelCopyWith<$Res> {
  factory _$$RestaurantModelImplCopyWith(_$RestaurantModelImpl value,
          $Res Function(_$RestaurantModelImpl) then) =
      __$$RestaurantModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String ownerUserId,
      String name,
      String? description,
      String address,
      String city,
      double latitude,
      double longitude,
      String category,
      String? logoUrl,
      String? coverUrl,
      String? instagramUrl,
      String? youTubeVideoUrl,
      bool isActive,
      String openingHours,
      int dishCount,
      DateTime createdAt});
}

/// @nodoc
class __$$RestaurantModelImplCopyWithImpl<$Res>
    extends _$RestaurantModelCopyWithImpl<$Res, _$RestaurantModelImpl>
    implements _$$RestaurantModelImplCopyWith<$Res> {
  __$$RestaurantModelImplCopyWithImpl(
      _$RestaurantModelImpl _value, $Res Function(_$RestaurantModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of RestaurantModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? ownerUserId = null,
    Object? name = null,
    Object? description = freezed,
    Object? address = null,
    Object? city = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? category = null,
    Object? logoUrl = freezed,
    Object? coverUrl = freezed,
    Object? instagramUrl = freezed,
    Object? youTubeVideoUrl = freezed,
    Object? isActive = null,
    Object? openingHours = null,
    Object? dishCount = null,
    Object? createdAt = null,
  }) {
    return _then(_$RestaurantModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      ownerUserId: null == ownerUserId
          ? _value.ownerUserId
          : ownerUserId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      coverUrl: freezed == coverUrl
          ? _value.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramUrl: freezed == instagramUrl
          ? _value.instagramUrl
          : instagramUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      youTubeVideoUrl: freezed == youTubeVideoUrl
          ? _value.youTubeVideoUrl
          : youTubeVideoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      openingHours: null == openingHours
          ? _value.openingHours
          : openingHours // ignore: cast_nullable_to_non_nullable
              as String,
      dishCount: null == dishCount
          ? _value.dishCount
          : dishCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RestaurantModelImpl implements _RestaurantModel {
  const _$RestaurantModelImpl(
      {required this.id,
      required this.ownerUserId,
      required this.name,
      this.description,
      required this.address,
      this.city = 'Salvador',
      required this.latitude,
      required this.longitude,
      required this.category,
      this.logoUrl,
      this.coverUrl,
      this.instagramUrl,
      this.youTubeVideoUrl,
      required this.isActive,
      required this.openingHours,
      this.dishCount = 0,
      required this.createdAt});

  factory _$RestaurantModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RestaurantModelImplFromJson(json);

  @override
  final String id;
  @override
  final String ownerUserId;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String address;
  @override
  @JsonKey()
  final String city;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String category;
  @override
  final String? logoUrl;
  @override
  final String? coverUrl;
  @override
  final String? instagramUrl;
  @override
  final String? youTubeVideoUrl;
  @override
  final bool isActive;
  @override
  final String openingHours;
  @override
  @JsonKey()
  final int dishCount;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'RestaurantModel(id: $id, ownerUserId: $ownerUserId, name: $name, description: $description, address: $address, city: $city, latitude: $latitude, longitude: $longitude, category: $category, logoUrl: $logoUrl, coverUrl: $coverUrl, instagramUrl: $instagramUrl, youTubeVideoUrl: $youTubeVideoUrl, isActive: $isActive, openingHours: $openingHours, dishCount: $dishCount, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestaurantModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.ownerUserId, ownerUserId) ||
                other.ownerUserId == ownerUserId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.instagramUrl, instagramUrl) ||
                other.instagramUrl == instagramUrl) &&
            (identical(other.youTubeVideoUrl, youTubeVideoUrl) ||
                other.youTubeVideoUrl == youTubeVideoUrl) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.openingHours, openingHours) ||
                other.openingHours == openingHours) &&
            (identical(other.dishCount, dishCount) ||
                other.dishCount == dishCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      ownerUserId,
      name,
      description,
      address,
      city,
      latitude,
      longitude,
      category,
      logoUrl,
      coverUrl,
      instagramUrl,
      youTubeVideoUrl,
      isActive,
      openingHours,
      dishCount,
      createdAt);

  /// Create a copy of RestaurantModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RestaurantModelImplCopyWith<_$RestaurantModelImpl> get copyWith =>
      __$$RestaurantModelImplCopyWithImpl<_$RestaurantModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RestaurantModelImplToJson(
      this,
    );
  }
}

abstract class _RestaurantModel implements RestaurantModel {
  const factory _RestaurantModel(
      {required final String id,
      required final String ownerUserId,
      required final String name,
      final String? description,
      required final String address,
      final String city,
      required final double latitude,
      required final double longitude,
      required final String category,
      final String? logoUrl,
      final String? coverUrl,
      final String? instagramUrl,
      final String? youTubeVideoUrl,
      required final bool isActive,
      required final String openingHours,
      final int dishCount,
      required final DateTime createdAt}) = _$RestaurantModelImpl;

  factory _RestaurantModel.fromJson(Map<String, dynamic> json) =
      _$RestaurantModelImpl.fromJson;

  @override
  String get id;
  @override
  String get ownerUserId;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get address;
  @override
  String get city;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get category;
  @override
  String? get logoUrl;
  @override
  String? get coverUrl;
  @override
  String? get instagramUrl;
  @override
  String? get youTubeVideoUrl;
  @override
  bool get isActive;
  @override
  String get openingHours;
  @override
  int get dishCount;
  @override
  DateTime get createdAt;

  /// Create a copy of RestaurantModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RestaurantModelImplCopyWith<_$RestaurantModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
