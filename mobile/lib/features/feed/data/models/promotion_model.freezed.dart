// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promotion_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PromotionModel _$PromotionModelFromJson(Map<String, dynamic> json) {
  return _PromotionModel.fromJson(json);
}

/// @nodoc
mixin _$PromotionModel {
  String get id => throw _privateConstructorUsedError;
  String get restaurantId => throw _privateConstructorUsedError;
  String get restaurantName => throw _privateConstructorUsedError;
  String? get restaurantLogoUrl => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  double? get discountPercent => throw _privateConstructorUsedError;
  int get totalTickets => throw _privateConstructorUsedError;
  int get remainingTickets => throw _privateConstructorUsedError;
  String get scope => throw _privateConstructorUsedError;
  DateTime get claimStartsAt => throw _privateConstructorUsedError;
  DateTime get claimEndsAt => throw _privateConstructorUsedError;
  int get ticketValidityDays => throw _privateConstructorUsedError;
  bool get canClaim => throw _privateConstructorUsedError;
  String? get pixKey => throw _privateConstructorUsedError;
  List<String>? get targetDishNames => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PromotionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PromotionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PromotionModelCopyWith<PromotionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromotionModelCopyWith<$Res> {
  factory $PromotionModelCopyWith(
          PromotionModel value, $Res Function(PromotionModel) then) =
      _$PromotionModelCopyWithImpl<$Res, PromotionModel>;
  @useResult
  $Res call(
      {String id,
      String restaurantId,
      String restaurantName,
      String? restaurantLogoUrl,
      String title,
      String? description,
      String? imageUrl,
      double? discountPercent,
      int totalTickets,
      int remainingTickets,
      String scope,
      DateTime claimStartsAt,
      DateTime claimEndsAt,
      int ticketValidityDays,
      bool canClaim,
      String? pixKey,
      List<String>? targetDishNames,
      DateTime? expiresAt,
      DateTime createdAt});
}

/// @nodoc
class _$PromotionModelCopyWithImpl<$Res, $Val extends PromotionModel>
    implements $PromotionModelCopyWith<$Res> {
  _$PromotionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PromotionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? restaurantName = null,
    Object? restaurantLogoUrl = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? discountPercent = freezed,
    Object? totalTickets = null,
    Object? remainingTickets = null,
    Object? scope = null,
    Object? claimStartsAt = null,
    Object? claimEndsAt = null,
    Object? ticketValidityDays = null,
    Object? canClaim = null,
    Object? pixKey = freezed,
    Object? targetDishNames = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = null,
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
      restaurantName: null == restaurantName
          ? _value.restaurantName
          : restaurantName // ignore: cast_nullable_to_non_nullable
              as String,
      restaurantLogoUrl: freezed == restaurantLogoUrl
          ? _value.restaurantLogoUrl
          : restaurantLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      discountPercent: freezed == discountPercent
          ? _value.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as double?,
      totalTickets: null == totalTickets
          ? _value.totalTickets
          : totalTickets // ignore: cast_nullable_to_non_nullable
              as int,
      remainingTickets: null == remainingTickets
          ? _value.remainingTickets
          : remainingTickets // ignore: cast_nullable_to_non_nullable
              as int,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String,
      claimStartsAt: null == claimStartsAt
          ? _value.claimStartsAt
          : claimStartsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      claimEndsAt: null == claimEndsAt
          ? _value.claimEndsAt
          : claimEndsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      ticketValidityDays: null == ticketValidityDays
          ? _value.ticketValidityDays
          : ticketValidityDays // ignore: cast_nullable_to_non_nullable
              as int,
      canClaim: null == canClaim
          ? _value.canClaim
          : canClaim // ignore: cast_nullable_to_non_nullable
              as bool,
      pixKey: freezed == pixKey
          ? _value.pixKey
          : pixKey // ignore: cast_nullable_to_non_nullable
              as String?,
      targetDishNames: freezed == targetDishNames
          ? _value.targetDishNames
          : targetDishNames // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PromotionModelImplCopyWith<$Res>
    implements $PromotionModelCopyWith<$Res> {
  factory _$$PromotionModelImplCopyWith(_$PromotionModelImpl value,
          $Res Function(_$PromotionModelImpl) then) =
      __$$PromotionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String restaurantId,
      String restaurantName,
      String? restaurantLogoUrl,
      String title,
      String? description,
      String? imageUrl,
      double? discountPercent,
      int totalTickets,
      int remainingTickets,
      String scope,
      DateTime claimStartsAt,
      DateTime claimEndsAt,
      int ticketValidityDays,
      bool canClaim,
      String? pixKey,
      List<String>? targetDishNames,
      DateTime? expiresAt,
      DateTime createdAt});
}

/// @nodoc
class __$$PromotionModelImplCopyWithImpl<$Res>
    extends _$PromotionModelCopyWithImpl<$Res, _$PromotionModelImpl>
    implements _$$PromotionModelImplCopyWith<$Res> {
  __$$PromotionModelImplCopyWithImpl(
      _$PromotionModelImpl _value, $Res Function(_$PromotionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PromotionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? restaurantId = null,
    Object? restaurantName = null,
    Object? restaurantLogoUrl = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? imageUrl = freezed,
    Object? discountPercent = freezed,
    Object? totalTickets = null,
    Object? remainingTickets = null,
    Object? scope = null,
    Object? claimStartsAt = null,
    Object? claimEndsAt = null,
    Object? ticketValidityDays = null,
    Object? canClaim = null,
    Object? pixKey = freezed,
    Object? targetDishNames = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$PromotionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      restaurantId: null == restaurantId
          ? _value.restaurantId
          : restaurantId // ignore: cast_nullable_to_non_nullable
              as String,
      restaurantName: null == restaurantName
          ? _value.restaurantName
          : restaurantName // ignore: cast_nullable_to_non_nullable
              as String,
      restaurantLogoUrl: freezed == restaurantLogoUrl
          ? _value.restaurantLogoUrl
          : restaurantLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      discountPercent: freezed == discountPercent
          ? _value.discountPercent
          : discountPercent // ignore: cast_nullable_to_non_nullable
              as double?,
      totalTickets: null == totalTickets
          ? _value.totalTickets
          : totalTickets // ignore: cast_nullable_to_non_nullable
              as int,
      remainingTickets: null == remainingTickets
          ? _value.remainingTickets
          : remainingTickets // ignore: cast_nullable_to_non_nullable
              as int,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String,
      claimStartsAt: null == claimStartsAt
          ? _value.claimStartsAt
          : claimStartsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      claimEndsAt: null == claimEndsAt
          ? _value.claimEndsAt
          : claimEndsAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      ticketValidityDays: null == ticketValidityDays
          ? _value.ticketValidityDays
          : ticketValidityDays // ignore: cast_nullable_to_non_nullable
              as int,
      canClaim: null == canClaim
          ? _value.canClaim
          : canClaim // ignore: cast_nullable_to_non_nullable
              as bool,
      pixKey: freezed == pixKey
          ? _value.pixKey
          : pixKey // ignore: cast_nullable_to_non_nullable
              as String?,
      targetDishNames: freezed == targetDishNames
          ? _value._targetDishNames
          : targetDishNames // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PromotionModelImpl implements _PromotionModel {
  const _$PromotionModelImpl(
      {required this.id,
      required this.restaurantId,
      required this.restaurantName,
      this.restaurantLogoUrl,
      required this.title,
      this.description,
      this.imageUrl,
      this.discountPercent,
      required this.totalTickets,
      required this.remainingTickets,
      required this.scope,
      required this.claimStartsAt,
      required this.claimEndsAt,
      required this.ticketValidityDays,
      required this.canClaim,
      this.pixKey,
      final List<String>? targetDishNames,
      this.expiresAt,
      required this.createdAt})
      : _targetDishNames = targetDishNames;

  factory _$PromotionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PromotionModelImplFromJson(json);

  @override
  final String id;
  @override
  final String restaurantId;
  @override
  final String restaurantName;
  @override
  final String? restaurantLogoUrl;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? imageUrl;
  @override
  final double? discountPercent;
  @override
  final int totalTickets;
  @override
  final int remainingTickets;
  @override
  final String scope;
  @override
  final DateTime claimStartsAt;
  @override
  final DateTime claimEndsAt;
  @override
  final int ticketValidityDays;
  @override
  final bool canClaim;
  @override
  final String? pixKey;
  final List<String>? _targetDishNames;
  @override
  List<String>? get targetDishNames {
    final value = _targetDishNames;
    if (value == null) return null;
    if (_targetDishNames is EqualUnmodifiableListView) return _targetDishNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final DateTime? expiresAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'PromotionModel(id: $id, restaurantId: $restaurantId, restaurantName: $restaurantName, restaurantLogoUrl: $restaurantLogoUrl, title: $title, description: $description, imageUrl: $imageUrl, discountPercent: $discountPercent, totalTickets: $totalTickets, remainingTickets: $remainingTickets, scope: $scope, claimStartsAt: $claimStartsAt, claimEndsAt: $claimEndsAt, ticketValidityDays: $ticketValidityDays, canClaim: $canClaim, pixKey: $pixKey, targetDishNames: $targetDishNames, expiresAt: $expiresAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromotionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.restaurantId, restaurantId) ||
                other.restaurantId == restaurantId) &&
            (identical(other.restaurantName, restaurantName) ||
                other.restaurantName == restaurantName) &&
            (identical(other.restaurantLogoUrl, restaurantLogoUrl) ||
                other.restaurantLogoUrl == restaurantLogoUrl) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.discountPercent, discountPercent) ||
                other.discountPercent == discountPercent) &&
            (identical(other.totalTickets, totalTickets) ||
                other.totalTickets == totalTickets) &&
            (identical(other.remainingTickets, remainingTickets) ||
                other.remainingTickets == remainingTickets) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.claimStartsAt, claimStartsAt) ||
                other.claimStartsAt == claimStartsAt) &&
            (identical(other.claimEndsAt, claimEndsAt) ||
                other.claimEndsAt == claimEndsAt) &&
            (identical(other.ticketValidityDays, ticketValidityDays) ||
                other.ticketValidityDays == ticketValidityDays) &&
            (identical(other.canClaim, canClaim) ||
                other.canClaim == canClaim) &&
            (identical(other.pixKey, pixKey) || other.pixKey == pixKey) &&
            const DeepCollectionEquality()
                .equals(other._targetDishNames, _targetDishNames) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        restaurantId,
        restaurantName,
        restaurantLogoUrl,
        title,
        description,
        imageUrl,
        discountPercent,
        totalTickets,
        remainingTickets,
        scope,
        claimStartsAt,
        claimEndsAt,
        ticketValidityDays,
        canClaim,
        pixKey,
        const DeepCollectionEquality().hash(_targetDishNames),
        expiresAt,
        createdAt
      ]);

  /// Create a copy of PromotionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PromotionModelImplCopyWith<_$PromotionModelImpl> get copyWith =>
      __$$PromotionModelImplCopyWithImpl<_$PromotionModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PromotionModelImplToJson(
      this,
    );
  }
}

abstract class _PromotionModel implements PromotionModel {
  const factory _PromotionModel(
      {required final String id,
      required final String restaurantId,
      required final String restaurantName,
      final String? restaurantLogoUrl,
      required final String title,
      final String? description,
      final String? imageUrl,
      final double? discountPercent,
      required final int totalTickets,
      required final int remainingTickets,
      required final String scope,
      required final DateTime claimStartsAt,
      required final DateTime claimEndsAt,
      required final int ticketValidityDays,
      required final bool canClaim,
      final String? pixKey,
      final List<String>? targetDishNames,
      final DateTime? expiresAt,
      required final DateTime createdAt}) = _$PromotionModelImpl;

  factory _PromotionModel.fromJson(Map<String, dynamic> json) =
      _$PromotionModelImpl.fromJson;

  @override
  String get id;
  @override
  String get restaurantId;
  @override
  String get restaurantName;
  @override
  String? get restaurantLogoUrl;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get imageUrl;
  @override
  double? get discountPercent;
  @override
  int get totalTickets;
  @override
  int get remainingTickets;
  @override
  String get scope;
  @override
  DateTime get claimStartsAt;
  @override
  DateTime get claimEndsAt;
  @override
  int get ticketValidityDays;
  @override
  bool get canClaim;
  @override
  String? get pixKey;
  @override
  List<String>? get targetDishNames;
  @override
  DateTime? get expiresAt;
  @override
  DateTime get createdAt;

  /// Create a copy of PromotionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PromotionModelImplCopyWith<_$PromotionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
