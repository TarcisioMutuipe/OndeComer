// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dish_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DishModel _$DishModelFromJson(Map<String, dynamic> json) {
  return _DishModel.fromJson(json);
}

/// @nodoc
mixin _$DishModel {
  String get id => throw _privateConstructorUsedError;
  String get restaurantId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String? get subcategory => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  bool get showInFeed => throw _privateConstructorUsedError;
  DateTime? get availabilityStart => throw _privateConstructorUsedError;
  DateTime? get availabilityEnd => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime? get deactivatedAt => throw _privateConstructorUsedError;
  double get ratingAverage => throw _privateConstructorUsedError;
  int get ratingCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this DishModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DishModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DishModelCopyWith<DishModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DishModelCopyWith<$Res> {
  factory $DishModelCopyWith(DishModel value, $Res Function(DishModel) then) =
      _$DishModelCopyWithImpl<$Res, DishModel>;
  @useResult
  $Res call(
      {String id,
      String restaurantId,
      String name,
      String? description,
      double price,
      String category,
      String? subcategory,
      String? imageUrl,
      bool showInFeed,
      DateTime? availabilityStart,
      DateTime? availabilityEnd,
      bool isActive,
      DateTime? deactivatedAt,
      double ratingAverage,
      int ratingCount,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$DishModelCopyWithImpl<$Res, $Val extends DishModel>
    implements $DishModelCopyWith<$Res> {
  _$DishModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DishModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? name = null,
    Object? description = freezed,
    Object? price = null,
    Object? category = null,
    Object? subcategory = freezed,
    Object? imageUrl = freezed,
    Object? showInFeed = null,
    Object? availabilityStart = freezed,
    Object? availabilityEnd = freezed,
    Object? isActive = null,
    Object? deactivatedAt = freezed,
    Object? ratingAverage = null,
    Object? ratingCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      restaurantId: null == restaurantId
          ? _value.restaurantId
          : restaurantId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      subcategory: freezed == subcategory
          ? _value.subcategory
          : subcategory // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      showInFeed: null == showInFeed
          ? _value.showInFeed
          : showInFeed // ignore: cast_nullable_to_non_nullable
              as bool,
      availabilityStart: freezed == availabilityStart
          ? _value.availabilityStart
          : availabilityStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      availabilityEnd: freezed == availabilityEnd
          ? _value.availabilityEnd
          : availabilityEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      deactivatedAt: freezed == deactivatedAt
          ? _value.deactivatedAt
          : deactivatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      ratingAverage: null == ratingAverage
          ? _value.ratingAverage
          : ratingAverage // ignore: cast_nullable_to_non_nullable
              as double,
      ratingCount: null == ratingCount
          ? _value.ratingCount
          : ratingCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DishModelImplCopyWith<$Res>
    implements $DishModelCopyWith<$Res> {
  factory _$$DishModelImplCopyWith(
          _$DishModelImpl value, $Res Function(_$DishModelImpl) then) =
      __$$DishModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String restaurantId,
      String name,
      String? description,
      double price,
      String category,
      String? subcategory,
      String? imageUrl,
      bool showInFeed,
      DateTime? availabilityStart,
      DateTime? availabilityEnd,
      bool isActive,
      DateTime? deactivatedAt,
      double ratingAverage,
      int ratingCount,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$DishModelImplCopyWithImpl<$Res>
    extends _$DishModelCopyWithImpl<$Res, _$DishModelImpl>
    implements _$$DishModelImplCopyWith<$Res> {
  __$$DishModelImplCopyWithImpl(
      _$DishModelImpl _value, $Res Function(_$DishModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DishModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? name = null,
    Object? description = freezed,
    Object? price = null,
    Object? category = null,
    Object? subcategory = freezed,
    Object? imageUrl = freezed,
    Object? showInFeed = null,
    Object? availabilityStart = freezed,
    Object? availabilityEnd = freezed,
    Object? isActive = null,
    Object? deactivatedAt = freezed,
    Object? ratingAverage = null,
    Object? ratingCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$DishModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      restaurantId: null == restaurantId
          ? _value.restaurantId
          : restaurantId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      subcategory: freezed == subcategory
          ? _value.subcategory
          : subcategory // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      showInFeed: null == showInFeed
          ? _value.showInFeed
          : showInFeed // ignore: cast_nullable_to_non_nullable
              as bool,
      availabilityStart: freezed == availabilityStart
          ? _value.availabilityStart
          : availabilityStart // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      availabilityEnd: freezed == availabilityEnd
          ? _value.availabilityEnd
          : availabilityEnd // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      deactivatedAt: freezed == deactivatedAt
          ? _value.deactivatedAt
          : deactivatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      ratingAverage: null == ratingAverage
          ? _value.ratingAverage
          : ratingAverage // ignore: cast_nullable_to_non_nullable
              as double,
      ratingCount: null == ratingCount
          ? _value.ratingCount
          : ratingCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DishModelImpl implements _DishModel {
  const _$DishModelImpl(
      {required this.id,
      required this.restaurantId,
      required this.name,
      this.description,
      required this.price,
      required this.category,
      this.subcategory,
      this.imageUrl,
      this.showInFeed = true,
      this.availabilityStart,
      this.availabilityEnd,
      required this.isActive,
      this.deactivatedAt,
      required this.ratingAverage,
      required this.ratingCount,
      required this.createdAt,
      required this.updatedAt});

  factory _$DishModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DishModelImplFromJson(json);

  @override
  final String id;
  @override
  final String restaurantId;
  @override
  final String name;
  @override
  final String? description;
  @override
  final double price;
  @override
  final String category;
  @override
  final String? subcategory;
  @override
  final String? imageUrl;
  @override
  @JsonKey()
  final bool showInFeed;
  @override
  final DateTime? availabilityStart;
  @override
  final DateTime? availabilityEnd;
  @override
  final bool isActive;
  @override
  final DateTime? deactivatedAt;
  @override
  final double ratingAverage;
  @override
  final int ratingCount;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'DishModel(id: $id, restaurantId: $restaurantId, name: $name, description: $description, price: $price, category: $category, subcategory: $subcategory, imageUrl: $imageUrl, showInFeed: $showInFeed, availabilityStart: $availabilityStart, availabilityEnd: $availabilityEnd, isActive: $isActive, deactivatedAt: $deactivatedAt, ratingAverage: $ratingAverage, ratingCount: $ratingCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DishModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.restaurantId, restaurantId) ||
                other.restaurantId == restaurantId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.subcategory, subcategory) ||
                other.subcategory == subcategory) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.showInFeed, showInFeed) ||
                other.showInFeed == showInFeed) &&
            (identical(other.availabilityStart, availabilityStart) ||
                other.availabilityStart == availabilityStart) &&
            (identical(other.availabilityEnd, availabilityEnd) ||
                other.availabilityEnd == availabilityEnd) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.deactivatedAt, deactivatedAt) ||
                other.deactivatedAt == deactivatedAt) &&
            (identical(other.ratingAverage, ratingAverage) ||
                other.ratingAverage == ratingAverage) &&
            (identical(other.ratingCount, ratingCount) ||
                other.ratingCount == ratingCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      restaurantId,
      name,
      description,
      price,
      category,
      subcategory,
      imageUrl,
      showInFeed,
      availabilityStart,
      availabilityEnd,
      isActive,
      deactivatedAt,
      ratingAverage,
      ratingCount,
      createdAt,
      updatedAt);

  /// Create a copy of DishModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DishModelImplCopyWith<_$DishModelImpl> get copyWith =>
      __$$DishModelImplCopyWithImpl<_$DishModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DishModelImplToJson(
      this,
    );
  }
}

abstract class _DishModel implements DishModel {
  const factory _DishModel(
      {required final String id,
      required final String restaurantId,
      required final String name,
      final String? description,
      required final double price,
      required final String category,
      final String? subcategory,
      final String? imageUrl,
      final bool showInFeed,
      final DateTime? availabilityStart,
      final DateTime? availabilityEnd,
      required final bool isActive,
      final DateTime? deactivatedAt,
      required final double ratingAverage,
      required final int ratingCount,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$DishModelImpl;

  factory _DishModel.fromJson(Map<String, dynamic> json) =
      _$DishModelImpl.fromJson;

  @override
  String get id;
  @override
  String get restaurantId;
  @override
  String get name;
  @override
  String? get description;
  @override
  double get price;
  @override
  String get category;
  @override
  String? get subcategory;
  @override
  String? get imageUrl;
  @override
  bool get showInFeed;
  @override
  DateTime? get availabilityStart;
  @override
  DateTime? get availabilityEnd;
  @override
  bool get isActive;
  @override
  DateTime? get deactivatedAt;
  @override
  double get ratingAverage;
  @override
  int get ratingCount;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of DishModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DishModelImplCopyWith<_$DishModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
