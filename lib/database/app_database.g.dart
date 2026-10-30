// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FinancialProfilesTable extends FinancialProfiles
    with TableInfo<$FinancialProfilesTable, FinancialProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _avatarPathMeta =
      const VerificationMeta('avatarPath');
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
      'avatar_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _relationshipMeta =
      const VerificationMeta('relationship');
  @override
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
      'relationship', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('self'));
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 4, maxTextLength: 9),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#10B981'));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        avatarPath,
        description,
        relationship,
        colorHex,
        isDefault,
        isArchived,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<FinancialProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
          _avatarPathMeta,
          avatarPath.isAcceptableOrUnknown(
              data['avatar_path']!, _avatarPathMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('relationship')) {
      context.handle(
          _relationshipMeta,
          relationship.isAcceptableOrUnknown(
              data['relationship']!, _relationshipMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinancialProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      avatarPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_path']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      relationship: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relationship'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FinancialProfilesTable createAlias(String alias) {
    return $FinancialProfilesTable(attachedDatabase, alias);
  }
}

class FinancialProfile extends DataClass
    implements Insertable<FinancialProfile> {
  final int id;

  /// Display name of the profile (e.g. "My Profile", "Father", "Priya")
  final String name;

  /// Optional relative or custom avatar icon identifier/path
  final String? avatarPath;

  /// Optional notes or description
  final String? description;

  /// Relationship to primary user: 'self', 'father', 'mother', 'spouse', 'child', 'other'
  final String relationship;

  /// Color accent hex string for UI chips and avatars (e.g. '#10B981')
  final String colorHex;

  /// Whether this is the default profile chosen on launch
  final bool isDefault;

  /// Whether the profile is archived (hidden from everyday dashboard, but records preserved)
  final bool isArchived;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last updated timestamp
  final DateTime updatedAt;
  const FinancialProfile(
      {required this.id,
      required this.name,
      this.avatarPath,
      this.description,
      required this.relationship,
      required this.colorHex,
      required this.isDefault,
      required this.isArchived,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['relationship'] = Variable<String>(relationship);
    map['color_hex'] = Variable<String>(colorHex);
    map['is_default'] = Variable<bool>(isDefault);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FinancialProfilesCompanion toCompanion(bool nullToAbsent) {
    return FinancialProfilesCompanion(
      id: Value(id),
      name: Value(name),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      relationship: Value(relationship),
      colorHex: Value(colorHex),
      isDefault: Value(isDefault),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FinancialProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialProfile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      description: serializer.fromJson<String?>(json['description']),
      relationship: serializer.fromJson<String>(json['relationship']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'description': serializer.toJson<String?>(description),
      'relationship': serializer.toJson<String>(relationship),
      'colorHex': serializer.toJson<String>(colorHex),
      'isDefault': serializer.toJson<bool>(isDefault),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FinancialProfile copyWith(
          {int? id,
          String? name,
          Value<String?> avatarPath = const Value.absent(),
          Value<String?> description = const Value.absent(),
          String? relationship,
          String? colorHex,
          bool? isDefault,
          bool? isArchived,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      FinancialProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
        description: description.present ? description.value : this.description,
        relationship: relationship ?? this.relationship,
        colorHex: colorHex ?? this.colorHex,
        isDefault: isDefault ?? this.isDefault,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FinancialProfile copyWithCompanion(FinancialProfilesCompanion data) {
    return FinancialProfile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarPath:
          data.avatarPath.present ? data.avatarPath.value : this.avatarPath,
      description:
          data.description.present ? data.description.value : this.description,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('description: $description, ')
          ..write('relationship: $relationship, ')
          ..write('colorHex: $colorHex, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, avatarPath, description,
      relationship, colorHex, isDefault, isArchived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarPath == this.avatarPath &&
          other.description == this.description &&
          other.relationship == this.relationship &&
          other.colorHex == this.colorHex &&
          other.isDefault == this.isDefault &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FinancialProfilesCompanion extends UpdateCompanion<FinancialProfile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> avatarPath;
  final Value<String?> description;
  final Value<String> relationship;
  final Value<String> colorHex;
  final Value<bool> isDefault;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FinancialProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.description = const Value.absent(),
    this.relationship = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FinancialProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.avatarPath = const Value.absent(),
    this.description = const Value.absent(),
    this.relationship = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FinancialProfile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? avatarPath,
    Expression<String>? description,
    Expression<String>? relationship,
    Expression<String>? colorHex,
    Expression<bool>? isDefault,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (description != null) 'description': description,
      if (relationship != null) 'relationship': relationship,
      if (colorHex != null) 'color_hex': colorHex,
      if (isDefault != null) 'is_default': isDefault,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FinancialProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? avatarPath,
      Value<String?>? description,
      Value<String>? relationship,
      Value<String>? colorHex,
      Value<bool>? isDefault,
      Value<bool>? isArchived,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return FinancialProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      description: description ?? this.description,
      relationship: relationship ?? this.relationship,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('description: $description, ')
          ..write('relationship: $relationship, ')
          ..write('colorHex: $colorHex, ')
          ..write('isDefault: $isDefault, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FinancialCategoriesTable extends FinancialCategories
    with TableInfo<$FinancialCategoriesTable, FinancialCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
      'profile_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'REFERENCES financial_profiles(id) ON DELETE CASCADE');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _classificationMeta =
      const VerificationMeta('classification');
  @override
  late final GeneratedColumn<String> classification = GeneratedColumn<String>(
      'classification', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'REFERENCES financial_categories(id) ON DELETE SET NULL');
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCustomMeta =
      const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
      'is_custom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        name,
        classification,
        parentId,
        icon,
        colorHex,
        isCustom,
        isArchived,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_categories';
  @override
  VerificationContext validateIntegrity(Insertable<FinancialCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('classification')) {
      context.handle(
          _classificationMeta,
          classification.isAcceptableOrUnknown(
              data['classification']!, _classificationMeta));
    } else if (isInserting) {
      context.missing(_classificationMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta,
          isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinancialCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      classification: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}classification'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_id']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex']),
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FinancialCategoriesTable createAlias(String alias) {
    return $FinancialCategoriesTable(attachedDatabase, alias);
  }
}

class FinancialCategory extends DataClass
    implements Insertable<FinancialCategory> {
  final int id;

  /// Profile scoping: NULL for system/global categories; non-null for profile-custom categories.
  final int? profileId;
  final String name;

  /// Classification: 'asset', 'liability', 'income', 'expense'
  final String classification;
  final int? parentId;
  final String? icon;
  final String? colorHex;
  final bool isCustom;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FinancialCategory(
      {required this.id,
      this.profileId,
      required this.name,
      required this.classification,
      this.parentId,
      this.icon,
      this.colorHex,
      required this.isCustom,
      required this.isArchived,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<int>(profileId);
    }
    map['name'] = Variable<String>(name);
    map['classification'] = Variable<String>(classification);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FinancialCategoriesCompanion toCompanion(bool nullToAbsent) {
    return FinancialCategoriesCompanion(
      id: Value(id),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      name: Value(name),
      classification: Value(classification),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      isCustom: Value(isCustom),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FinancialCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialCategory(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int?>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      classification: serializer.fromJson<String>(json['classification']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      icon: serializer.fromJson<String?>(json['icon']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int?>(profileId),
      'name': serializer.toJson<String>(name),
      'classification': serializer.toJson<String>(classification),
      'parentId': serializer.toJson<int?>(parentId),
      'icon': serializer.toJson<String?>(icon),
      'colorHex': serializer.toJson<String?>(colorHex),
      'isCustom': serializer.toJson<bool>(isCustom),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FinancialCategory copyWith(
          {int? id,
          Value<int?> profileId = const Value.absent(),
          String? name,
          String? classification,
          Value<int?> parentId = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          Value<String?> colorHex = const Value.absent(),
          bool? isCustom,
          bool? isArchived,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      FinancialCategory(
        id: id ?? this.id,
        profileId: profileId.present ? profileId.value : this.profileId,
        name: name ?? this.name,
        classification: classification ?? this.classification,
        parentId: parentId.present ? parentId.value : this.parentId,
        icon: icon.present ? icon.value : this.icon,
        colorHex: colorHex.present ? colorHex.value : this.colorHex,
        isCustom: isCustom ?? this.isCustom,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FinancialCategory copyWithCompanion(FinancialCategoriesCompanion data) {
    return FinancialCategory(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      classification: data.classification.present
          ? data.classification.value
          : this.classification,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      icon: data.icon.present ? data.icon.value : this.icon,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialCategory(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('classification: $classification, ')
          ..write('parentId: $parentId, ')
          ..write('icon: $icon, ')
          ..write('colorHex: $colorHex, ')
          ..write('isCustom: $isCustom, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, name, classification, parentId,
      icon, colorHex, isCustom, isArchived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialCategory &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.classification == this.classification &&
          other.parentId == this.parentId &&
          other.icon == this.icon &&
          other.colorHex == this.colorHex &&
          other.isCustom == this.isCustom &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FinancialCategoriesCompanion extends UpdateCompanion<FinancialCategory> {
  final Value<int> id;
  final Value<int?> profileId;
  final Value<String> name;
  final Value<String> classification;
  final Value<int?> parentId;
  final Value<String?> icon;
  final Value<String?> colorHex;
  final Value<bool> isCustom;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FinancialCategoriesCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.classification = const Value.absent(),
    this.parentId = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FinancialCategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    required String name,
    required String classification,
    this.parentId = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        classification = Value(classification);
  static Insertable<FinancialCategory> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? name,
    Expression<String>? classification,
    Expression<int>? parentId,
    Expression<String>? icon,
    Expression<String>? colorHex,
    Expression<bool>? isCustom,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (classification != null) 'classification': classification,
      if (parentId != null) 'parent_id': parentId,
      if (icon != null) 'icon': icon,
      if (colorHex != null) 'color_hex': colorHex,
      if (isCustom != null) 'is_custom': isCustom,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FinancialCategoriesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? profileId,
      Value<String>? name,
      Value<String>? classification,
      Value<int?>? parentId,
      Value<String?>? icon,
      Value<String?>? colorHex,
      Value<bool>? isCustom,
      Value<bool>? isArchived,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return FinancialCategoriesCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      classification: classification ?? this.classification,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isCustom: isCustom ?? this.isCustom,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (classification.present) {
      map['classification'] = Variable<String>(classification.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('classification: $classification, ')
          ..write('parentId: $parentId, ')
          ..write('icon: $icon, ')
          ..write('colorHex: $colorHex, ')
          ..write('isCustom: $isCustom, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FinancialAccountsTable extends FinancialAccounts
    with TableInfo<$FinancialAccountsTable, FinancialAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _accountTypeMeta =
      const VerificationMeta('accountType');
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
      'account_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountNumberMaskedMeta =
      const VerificationMeta('accountNumberMasked');
  @override
  late final GeneratedColumn<String> accountNumberMasked =
      GeneratedColumn<String>('account_number_masked', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _institutionNameMeta =
      const VerificationMeta('institutionName');
  @override
  late final GeneratedColumn<String> institutionName = GeneratedColumn<String>(
      'institution_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currencyCodeMeta =
      const VerificationMeta('currencyCode');
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
      'currency_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('INR'));
  static const VerificationMeta _openingBalancePaiseMeta =
      const VerificationMeta('openingBalancePaise');
  @override
  late final GeneratedColumn<int> openingBalancePaise = GeneratedColumn<int>(
      'opening_balance_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentBalancePaiseMeta =
      const VerificationMeta('currentBalancePaise');
  @override
  late final GeneratedColumn<int> currentBalancePaise = GeneratedColumn<int>(
      'current_balance_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        name,
        accountType,
        accountNumberMasked,
        institutionName,
        currencyCode,
        openingBalancePaise,
        currentBalancePaise,
        isArchived,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_accounts';
  @override
  VerificationContext validateIntegrity(Insertable<FinancialAccount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
          _accountTypeMeta,
          accountType.isAcceptableOrUnknown(
              data['account_type']!, _accountTypeMeta));
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('account_number_masked')) {
      context.handle(
          _accountNumberMaskedMeta,
          accountNumberMasked.isAcceptableOrUnknown(
              data['account_number_masked']!, _accountNumberMaskedMeta));
    }
    if (data.containsKey('institution_name')) {
      context.handle(
          _institutionNameMeta,
          institutionName.isAcceptableOrUnknown(
              data['institution_name']!, _institutionNameMeta));
    }
    if (data.containsKey('currency_code')) {
      context.handle(
          _currencyCodeMeta,
          currencyCode.isAcceptableOrUnknown(
              data['currency_code']!, _currencyCodeMeta));
    }
    if (data.containsKey('opening_balance_paise')) {
      context.handle(
          _openingBalancePaiseMeta,
          openingBalancePaise.isAcceptableOrUnknown(
              data['opening_balance_paise']!, _openingBalancePaiseMeta));
    }
    if (data.containsKey('current_balance_paise')) {
      context.handle(
          _currentBalancePaiseMeta,
          currentBalancePaise.isAcceptableOrUnknown(
              data['current_balance_paise']!, _currentBalancePaiseMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinancialAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialAccount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      accountType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_type'])!,
      accountNumberMasked: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}account_number_masked']),
      institutionName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}institution_name']),
      currencyCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_code'])!,
      openingBalancePaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}opening_balance_paise'])!,
      currentBalancePaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_balance_paise'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FinancialAccountsTable createAlias(String alias) {
    return $FinancialAccountsTable(attachedDatabase, alias);
  }
}

class FinancialAccount extends DataClass
    implements Insertable<FinancialAccount> {
  final int id;

  /// Profile scoping: Every account belongs to an individual profile
  final int profileId;
  final String name;

  /// Account type: 'bank', 'cash', 'demat', 'wallet', 'loan_account', 'credit_card'
  final String accountType;
  final String? accountNumberMasked;
  final String? institutionName;
  final String currencyCode;

  /// Opening balance in integer minor units (paise)
  final int openingBalancePaise;

  /// Cached current balance in integer minor units (paise)
  final int currentBalancePaise;
  final bool isArchived;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FinancialAccount(
      {required this.id,
      required this.profileId,
      required this.name,
      required this.accountType,
      this.accountNumberMasked,
      this.institutionName,
      required this.currencyCode,
      required this.openingBalancePaise,
      required this.currentBalancePaise,
      required this.isArchived,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['name'] = Variable<String>(name);
    map['account_type'] = Variable<String>(accountType);
    if (!nullToAbsent || accountNumberMasked != null) {
      map['account_number_masked'] = Variable<String>(accountNumberMasked);
    }
    if (!nullToAbsent || institutionName != null) {
      map['institution_name'] = Variable<String>(institutionName);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['opening_balance_paise'] = Variable<int>(openingBalancePaise);
    map['current_balance_paise'] = Variable<int>(currentBalancePaise);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FinancialAccountsCompanion toCompanion(bool nullToAbsent) {
    return FinancialAccountsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      accountType: Value(accountType),
      accountNumberMasked: accountNumberMasked == null && nullToAbsent
          ? const Value.absent()
          : Value(accountNumberMasked),
      institutionName: institutionName == null && nullToAbsent
          ? const Value.absent()
          : Value(institutionName),
      currencyCode: Value(currencyCode),
      openingBalancePaise: Value(openingBalancePaise),
      currentBalancePaise: Value(currentBalancePaise),
      isArchived: Value(isArchived),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FinancialAccount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialAccount(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      accountType: serializer.fromJson<String>(json['accountType']),
      accountNumberMasked:
          serializer.fromJson<String?>(json['accountNumberMasked']),
      institutionName: serializer.fromJson<String?>(json['institutionName']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      openingBalancePaise:
          serializer.fromJson<int>(json['openingBalancePaise']),
      currentBalancePaise:
          serializer.fromJson<int>(json['currentBalancePaise']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'name': serializer.toJson<String>(name),
      'accountType': serializer.toJson<String>(accountType),
      'accountNumberMasked': serializer.toJson<String?>(accountNumberMasked),
      'institutionName': serializer.toJson<String?>(institutionName),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'openingBalancePaise': serializer.toJson<int>(openingBalancePaise),
      'currentBalancePaise': serializer.toJson<int>(currentBalancePaise),
      'isArchived': serializer.toJson<bool>(isArchived),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FinancialAccount copyWith(
          {int? id,
          int? profileId,
          String? name,
          String? accountType,
          Value<String?> accountNumberMasked = const Value.absent(),
          Value<String?> institutionName = const Value.absent(),
          String? currencyCode,
          int? openingBalancePaise,
          int? currentBalancePaise,
          bool? isArchived,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      FinancialAccount(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        name: name ?? this.name,
        accountType: accountType ?? this.accountType,
        accountNumberMasked: accountNumberMasked.present
            ? accountNumberMasked.value
            : this.accountNumberMasked,
        institutionName: institutionName.present
            ? institutionName.value
            : this.institutionName,
        currencyCode: currencyCode ?? this.currencyCode,
        openingBalancePaise: openingBalancePaise ?? this.openingBalancePaise,
        currentBalancePaise: currentBalancePaise ?? this.currentBalancePaise,
        isArchived: isArchived ?? this.isArchived,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FinancialAccount copyWithCompanion(FinancialAccountsCompanion data) {
    return FinancialAccount(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      accountType:
          data.accountType.present ? data.accountType.value : this.accountType,
      accountNumberMasked: data.accountNumberMasked.present
          ? data.accountNumberMasked.value
          : this.accountNumberMasked,
      institutionName: data.institutionName.present
          ? data.institutionName.value
          : this.institutionName,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      openingBalancePaise: data.openingBalancePaise.present
          ? data.openingBalancePaise.value
          : this.openingBalancePaise,
      currentBalancePaise: data.currentBalancePaise.present
          ? data.currentBalancePaise.value
          : this.currentBalancePaise,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialAccount(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('accountNumberMasked: $accountNumberMasked, ')
          ..write('institutionName: $institutionName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('openingBalancePaise: $openingBalancePaise, ')
          ..write('currentBalancePaise: $currentBalancePaise, ')
          ..write('isArchived: $isArchived, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      name,
      accountType,
      accountNumberMasked,
      institutionName,
      currencyCode,
      openingBalancePaise,
      currentBalancePaise,
      isArchived,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialAccount &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.accountType == this.accountType &&
          other.accountNumberMasked == this.accountNumberMasked &&
          other.institutionName == this.institutionName &&
          other.currencyCode == this.currencyCode &&
          other.openingBalancePaise == this.openingBalancePaise &&
          other.currentBalancePaise == this.currentBalancePaise &&
          other.isArchived == this.isArchived &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FinancialAccountsCompanion extends UpdateCompanion<FinancialAccount> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> name;
  final Value<String> accountType;
  final Value<String?> accountNumberMasked;
  final Value<String?> institutionName;
  final Value<String> currencyCode;
  final Value<int> openingBalancePaise;
  final Value<int> currentBalancePaise;
  final Value<bool> isArchived;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FinancialAccountsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.accountType = const Value.absent(),
    this.accountNumberMasked = const Value.absent(),
    this.institutionName = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.openingBalancePaise = const Value.absent(),
    this.currentBalancePaise = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FinancialAccountsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String name,
    required String accountType,
    this.accountNumberMasked = const Value.absent(),
    this.institutionName = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.openingBalancePaise = const Value.absent(),
    this.currentBalancePaise = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : profileId = Value(profileId),
        name = Value(name),
        accountType = Value(accountType);
  static Insertable<FinancialAccount> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? name,
    Expression<String>? accountType,
    Expression<String>? accountNumberMasked,
    Expression<String>? institutionName,
    Expression<String>? currencyCode,
    Expression<int>? openingBalancePaise,
    Expression<int>? currentBalancePaise,
    Expression<bool>? isArchived,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (accountType != null) 'account_type': accountType,
      if (accountNumberMasked != null)
        'account_number_masked': accountNumberMasked,
      if (institutionName != null) 'institution_name': institutionName,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (openingBalancePaise != null)
        'opening_balance_paise': openingBalancePaise,
      if (currentBalancePaise != null)
        'current_balance_paise': currentBalancePaise,
      if (isArchived != null) 'is_archived': isArchived,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FinancialAccountsCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? name,
      Value<String>? accountType,
      Value<String?>? accountNumberMasked,
      Value<String?>? institutionName,
      Value<String>? currencyCode,
      Value<int>? openingBalancePaise,
      Value<int>? currentBalancePaise,
      Value<bool>? isArchived,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return FinancialAccountsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      accountNumberMasked: accountNumberMasked ?? this.accountNumberMasked,
      institutionName: institutionName ?? this.institutionName,
      currencyCode: currencyCode ?? this.currencyCode,
      openingBalancePaise: openingBalancePaise ?? this.openingBalancePaise,
      currentBalancePaise: currentBalancePaise ?? this.currentBalancePaise,
      isArchived: isArchived ?? this.isArchived,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (accountNumberMasked.present) {
      map['account_number_masked'] =
          Variable<String>(accountNumberMasked.value);
    }
    if (institutionName.present) {
      map['institution_name'] = Variable<String>(institutionName.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (openingBalancePaise.present) {
      map['opening_balance_paise'] = Variable<int>(openingBalancePaise.value);
    }
    if (currentBalancePaise.present) {
      map['current_balance_paise'] = Variable<int>(currentBalancePaise.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialAccountsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('accountType: $accountType, ')
          ..write('accountNumberMasked: $accountNumberMasked, ')
          ..write('institutionName: $institutionName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('openingBalancePaise: $openingBalancePaise, ')
          ..write('currentBalancePaise: $currentBalancePaise, ')
          ..write('isArchived: $isArchived, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FinancialItemsTable extends FinancialItems
    with TableInfo<$FinancialItemsTable, FinancialItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subTypeMeta =
      const VerificationMeta('subType');
  @override
  late final GeneratedColumn<String> subType = GeneratedColumn<String>(
      'sub_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES financial_categories(id) ON DELETE RESTRICT');
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'REFERENCES financial_accounts(id) ON DELETE SET NULL');
  static const VerificationMeta _externalCodeMeta =
      const VerificationMeta('externalCode');
  @override
  late final GeneratedColumn<String> externalCode = GeneratedColumn<String>(
      'external_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _initialValuePaiseMeta =
      const VerificationMeta('initialValuePaise');
  @override
  late final GeneratedColumn<int> initialValuePaise = GeneratedColumn<int>(
      'initial_value_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentValuationPaiseMeta =
      const VerificationMeta('currentValuationPaise');
  @override
  late final GeneratedColumn<int> currentValuationPaise = GeneratedColumn<int>(
      'current_valuation_paise', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _unitCountMicroUnitsMeta =
      const VerificationMeta('unitCountMicroUnits');
  @override
  late final GeneratedColumn<int> unitCountMicroUnits = GeneratedColumn<int>(
      'unit_count_micro_units', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _interestRateBasisPointsMeta =
      const VerificationMeta('interestRateBasisPoints');
  @override
  late final GeneratedColumn<int> interestRateBasisPoints =
      GeneratedColumn<int>('interest_rate_basis_points', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _maturityDateMeta =
      const VerificationMeta('maturityDate');
  @override
  late final GeneratedColumn<DateTime> maturityDate = GeneratedColumn<DateTime>(
      'maturity_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        name,
        itemType,
        subType,
        categoryId,
        accountId,
        externalCode,
        status,
        initialValuePaise,
        currentValuationPaise,
        unitCountMicroUnits,
        interestRateBasisPoints,
        startDate,
        maturityDate,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_items';
  @override
  VerificationContext validateIntegrity(Insertable<FinancialItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('sub_type')) {
      context.handle(_subTypeMeta,
          subType.isAcceptableOrUnknown(data['sub_type']!, _subTypeMeta));
    } else if (isInserting) {
      context.missing(_subTypeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('external_code')) {
      context.handle(
          _externalCodeMeta,
          externalCode.isAcceptableOrUnknown(
              data['external_code']!, _externalCodeMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('initial_value_paise')) {
      context.handle(
          _initialValuePaiseMeta,
          initialValuePaise.isAcceptableOrUnknown(
              data['initial_value_paise']!, _initialValuePaiseMeta));
    }
    if (data.containsKey('current_valuation_paise')) {
      context.handle(
          _currentValuationPaiseMeta,
          currentValuationPaise.isAcceptableOrUnknown(
              data['current_valuation_paise']!, _currentValuationPaiseMeta));
    }
    if (data.containsKey('unit_count_micro_units')) {
      context.handle(
          _unitCountMicroUnitsMeta,
          unitCountMicroUnits.isAcceptableOrUnknown(
              data['unit_count_micro_units']!, _unitCountMicroUnitsMeta));
    }
    if (data.containsKey('interest_rate_basis_points')) {
      context.handle(
          _interestRateBasisPointsMeta,
          interestRateBasisPoints.isAcceptableOrUnknown(
              data['interest_rate_basis_points']!,
              _interestRateBasisPointsMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    }
    if (data.containsKey('maturity_date')) {
      context.handle(
          _maturityDateMeta,
          maturityDate.isAcceptableOrUnknown(
              data['maturity_date']!, _maturityDateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinancialItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinancialItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      subType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sub_type'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id']),
      externalCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_code']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      initialValuePaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}initial_value_paise'])!,
      currentValuationPaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_valuation_paise'])!,
      unitCountMicroUnits: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}unit_count_micro_units'])!,
      interestRateBasisPoints: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}interest_rate_basis_points']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date']),
      maturityDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}maturity_date']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FinancialItemsTable createAlias(String alias) {
    return $FinancialItemsTable(attachedDatabase, alias);
  }
}

class FinancialItem extends DataClass implements Insertable<FinancialItem> {
  final int id;

  /// Profile scoping: Every financial asset or liability belongs to a profile
  final int profileId;
  final String name;

  /// Primary type: 'asset' or 'liability'
  final String itemType;

  /// Specific sub-type:
  /// Assets: 'mutual_fund', 'stock', 'fixed_deposit', 'gold', 'ppf', 'epf', 'nps', 'bond', 'cash', 'other_asset'
  /// Liabilities: 'home_loan', 'personal_loan', 'vehicle_loan', 'education_loan', 'credit_card', 'other_liability'
  final String subType;
  final int categoryId;
  final int? accountId;

  /// External scheme or account code (e.g. AMFI Scheme Code for mutual funds, ISIN, Loan No.)
  final String? externalCode;

  /// Status: 'active', 'inactive', 'archived', 'closed'
  final String status;

  /// Initial or principal value in Paise
  final int initialValuePaise;

  /// Latest valuation or outstanding debt balance in Paise
  final int currentValuationPaise;

  /// Total units held for unitized investments (1 unit = 1,000,000 micro-units, 0 if not unitized)
  final int unitCountMicroUnits;

  /// Annual interest rate in basis points (e.g. 850 = 8.50% p.a., 710 = 7.10% for PPF)
  final int? interestRateBasisPoints;
  final DateTime? startDate;
  final DateTime? maturityDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FinancialItem(
      {required this.id,
      required this.profileId,
      required this.name,
      required this.itemType,
      required this.subType,
      required this.categoryId,
      this.accountId,
      this.externalCode,
      required this.status,
      required this.initialValuePaise,
      required this.currentValuationPaise,
      required this.unitCountMicroUnits,
      this.interestRateBasisPoints,
      this.startDate,
      this.maturityDate,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['name'] = Variable<String>(name);
    map['item_type'] = Variable<String>(itemType);
    map['sub_type'] = Variable<String>(subType);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || externalCode != null) {
      map['external_code'] = Variable<String>(externalCode);
    }
    map['status'] = Variable<String>(status);
    map['initial_value_paise'] = Variable<int>(initialValuePaise);
    map['current_valuation_paise'] = Variable<int>(currentValuationPaise);
    map['unit_count_micro_units'] = Variable<int>(unitCountMicroUnits);
    if (!nullToAbsent || interestRateBasisPoints != null) {
      map['interest_rate_basis_points'] =
          Variable<int>(interestRateBasisPoints);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || maturityDate != null) {
      map['maturity_date'] = Variable<DateTime>(maturityDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FinancialItemsCompanion toCompanion(bool nullToAbsent) {
    return FinancialItemsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      itemType: Value(itemType),
      subType: Value(subType),
      categoryId: Value(categoryId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      externalCode: externalCode == null && nullToAbsent
          ? const Value.absent()
          : Value(externalCode),
      status: Value(status),
      initialValuePaise: Value(initialValuePaise),
      currentValuationPaise: Value(currentValuationPaise),
      unitCountMicroUnits: Value(unitCountMicroUnits),
      interestRateBasisPoints: interestRateBasisPoints == null && nullToAbsent
          ? const Value.absent()
          : Value(interestRateBasisPoints),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      maturityDate: maturityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(maturityDate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FinancialItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinancialItem(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      itemType: serializer.fromJson<String>(json['itemType']),
      subType: serializer.fromJson<String>(json['subType']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      externalCode: serializer.fromJson<String?>(json['externalCode']),
      status: serializer.fromJson<String>(json['status']),
      initialValuePaise: serializer.fromJson<int>(json['initialValuePaise']),
      currentValuationPaise:
          serializer.fromJson<int>(json['currentValuationPaise']),
      unitCountMicroUnits:
          serializer.fromJson<int>(json['unitCountMicroUnits']),
      interestRateBasisPoints:
          serializer.fromJson<int?>(json['interestRateBasisPoints']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      maturityDate: serializer.fromJson<DateTime?>(json['maturityDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'name': serializer.toJson<String>(name),
      'itemType': serializer.toJson<String>(itemType),
      'subType': serializer.toJson<String>(subType),
      'categoryId': serializer.toJson<int>(categoryId),
      'accountId': serializer.toJson<int?>(accountId),
      'externalCode': serializer.toJson<String?>(externalCode),
      'status': serializer.toJson<String>(status),
      'initialValuePaise': serializer.toJson<int>(initialValuePaise),
      'currentValuationPaise': serializer.toJson<int>(currentValuationPaise),
      'unitCountMicroUnits': serializer.toJson<int>(unitCountMicroUnits),
      'interestRateBasisPoints':
          serializer.toJson<int?>(interestRateBasisPoints),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'maturityDate': serializer.toJson<DateTime?>(maturityDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FinancialItem copyWith(
          {int? id,
          int? profileId,
          String? name,
          String? itemType,
          String? subType,
          int? categoryId,
          Value<int?> accountId = const Value.absent(),
          Value<String?> externalCode = const Value.absent(),
          String? status,
          int? initialValuePaise,
          int? currentValuationPaise,
          int? unitCountMicroUnits,
          Value<int?> interestRateBasisPoints = const Value.absent(),
          Value<DateTime?> startDate = const Value.absent(),
          Value<DateTime?> maturityDate = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      FinancialItem(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        name: name ?? this.name,
        itemType: itemType ?? this.itemType,
        subType: subType ?? this.subType,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId.present ? accountId.value : this.accountId,
        externalCode:
            externalCode.present ? externalCode.value : this.externalCode,
        status: status ?? this.status,
        initialValuePaise: initialValuePaise ?? this.initialValuePaise,
        currentValuationPaise:
            currentValuationPaise ?? this.currentValuationPaise,
        unitCountMicroUnits: unitCountMicroUnits ?? this.unitCountMicroUnits,
        interestRateBasisPoints: interestRateBasisPoints.present
            ? interestRateBasisPoints.value
            : this.interestRateBasisPoints,
        startDate: startDate.present ? startDate.value : this.startDate,
        maturityDate:
            maturityDate.present ? maturityDate.value : this.maturityDate,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FinancialItem copyWithCompanion(FinancialItemsCompanion data) {
    return FinancialItem(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      subType: data.subType.present ? data.subType.value : this.subType,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      externalCode: data.externalCode.present
          ? data.externalCode.value
          : this.externalCode,
      status: data.status.present ? data.status.value : this.status,
      initialValuePaise: data.initialValuePaise.present
          ? data.initialValuePaise.value
          : this.initialValuePaise,
      currentValuationPaise: data.currentValuationPaise.present
          ? data.currentValuationPaise.value
          : this.currentValuationPaise,
      unitCountMicroUnits: data.unitCountMicroUnits.present
          ? data.unitCountMicroUnits.value
          : this.unitCountMicroUnits,
      interestRateBasisPoints: data.interestRateBasisPoints.present
          ? data.interestRateBasisPoints.value
          : this.interestRateBasisPoints,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      maturityDate: data.maturityDate.present
          ? data.maturityDate.value
          : this.maturityDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinancialItem(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('itemType: $itemType, ')
          ..write('subType: $subType, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('externalCode: $externalCode, ')
          ..write('status: $status, ')
          ..write('initialValuePaise: $initialValuePaise, ')
          ..write('currentValuationPaise: $currentValuationPaise, ')
          ..write('unitCountMicroUnits: $unitCountMicroUnits, ')
          ..write('interestRateBasisPoints: $interestRateBasisPoints, ')
          ..write('startDate: $startDate, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      name,
      itemType,
      subType,
      categoryId,
      accountId,
      externalCode,
      status,
      initialValuePaise,
      currentValuationPaise,
      unitCountMicroUnits,
      interestRateBasisPoints,
      startDate,
      maturityDate,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialItem &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.itemType == this.itemType &&
          other.subType == this.subType &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.externalCode == this.externalCode &&
          other.status == this.status &&
          other.initialValuePaise == this.initialValuePaise &&
          other.currentValuationPaise == this.currentValuationPaise &&
          other.unitCountMicroUnits == this.unitCountMicroUnits &&
          other.interestRateBasisPoints == this.interestRateBasisPoints &&
          other.startDate == this.startDate &&
          other.maturityDate == this.maturityDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FinancialItemsCompanion extends UpdateCompanion<FinancialItem> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> name;
  final Value<String> itemType;
  final Value<String> subType;
  final Value<int> categoryId;
  final Value<int?> accountId;
  final Value<String?> externalCode;
  final Value<String> status;
  final Value<int> initialValuePaise;
  final Value<int> currentValuationPaise;
  final Value<int> unitCountMicroUnits;
  final Value<int?> interestRateBasisPoints;
  final Value<DateTime?> startDate;
  final Value<DateTime?> maturityDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FinancialItemsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.itemType = const Value.absent(),
    this.subType = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.externalCode = const Value.absent(),
    this.status = const Value.absent(),
    this.initialValuePaise = const Value.absent(),
    this.currentValuationPaise = const Value.absent(),
    this.unitCountMicroUnits = const Value.absent(),
    this.interestRateBasisPoints = const Value.absent(),
    this.startDate = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FinancialItemsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String name,
    required String itemType,
    required String subType,
    required int categoryId,
    this.accountId = const Value.absent(),
    this.externalCode = const Value.absent(),
    this.status = const Value.absent(),
    this.initialValuePaise = const Value.absent(),
    this.currentValuationPaise = const Value.absent(),
    this.unitCountMicroUnits = const Value.absent(),
    this.interestRateBasisPoints = const Value.absent(),
    this.startDate = const Value.absent(),
    this.maturityDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : profileId = Value(profileId),
        name = Value(name),
        itemType = Value(itemType),
        subType = Value(subType),
        categoryId = Value(categoryId);
  static Insertable<FinancialItem> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? name,
    Expression<String>? itemType,
    Expression<String>? subType,
    Expression<int>? categoryId,
    Expression<int>? accountId,
    Expression<String>? externalCode,
    Expression<String>? status,
    Expression<int>? initialValuePaise,
    Expression<int>? currentValuationPaise,
    Expression<int>? unitCountMicroUnits,
    Expression<int>? interestRateBasisPoints,
    Expression<DateTime>? startDate,
    Expression<DateTime>? maturityDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (itemType != null) 'item_type': itemType,
      if (subType != null) 'sub_type': subType,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (externalCode != null) 'external_code': externalCode,
      if (status != null) 'status': status,
      if (initialValuePaise != null) 'initial_value_paise': initialValuePaise,
      if (currentValuationPaise != null)
        'current_valuation_paise': currentValuationPaise,
      if (unitCountMicroUnits != null)
        'unit_count_micro_units': unitCountMicroUnits,
      if (interestRateBasisPoints != null)
        'interest_rate_basis_points': interestRateBasisPoints,
      if (startDate != null) 'start_date': startDate,
      if (maturityDate != null) 'maturity_date': maturityDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FinancialItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? name,
      Value<String>? itemType,
      Value<String>? subType,
      Value<int>? categoryId,
      Value<int?>? accountId,
      Value<String?>? externalCode,
      Value<String>? status,
      Value<int>? initialValuePaise,
      Value<int>? currentValuationPaise,
      Value<int>? unitCountMicroUnits,
      Value<int?>? interestRateBasisPoints,
      Value<DateTime?>? startDate,
      Value<DateTime?>? maturityDate,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return FinancialItemsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      itemType: itemType ?? this.itemType,
      subType: subType ?? this.subType,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      externalCode: externalCode ?? this.externalCode,
      status: status ?? this.status,
      initialValuePaise: initialValuePaise ?? this.initialValuePaise,
      currentValuationPaise:
          currentValuationPaise ?? this.currentValuationPaise,
      unitCountMicroUnits: unitCountMicroUnits ?? this.unitCountMicroUnits,
      interestRateBasisPoints:
          interestRateBasisPoints ?? this.interestRateBasisPoints,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (subType.present) {
      map['sub_type'] = Variable<String>(subType.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (externalCode.present) {
      map['external_code'] = Variable<String>(externalCode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (initialValuePaise.present) {
      map['initial_value_paise'] = Variable<int>(initialValuePaise.value);
    }
    if (currentValuationPaise.present) {
      map['current_valuation_paise'] =
          Variable<int>(currentValuationPaise.value);
    }
    if (unitCountMicroUnits.present) {
      map['unit_count_micro_units'] = Variable<int>(unitCountMicroUnits.value);
    }
    if (interestRateBasisPoints.present) {
      map['interest_rate_basis_points'] =
          Variable<int>(interestRateBasisPoints.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (maturityDate.present) {
      map['maturity_date'] = Variable<DateTime>(maturityDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialItemsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('itemType: $itemType, ')
          ..write('subType: $subType, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('externalCode: $externalCode, ')
          ..write('status: $status, ')
          ..write('initialValuePaise: $initialValuePaise, ')
          ..write('currentValuationPaise: $currentValuationPaise, ')
          ..write('unitCountMicroUnits: $unitCountMicroUnits, ')
          ..write('interestRateBasisPoints: $interestRateBasisPoints, ')
          ..write('startDate: $startDate, ')
          ..write('maturityDate: $maturityDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE');
  static const VerificationMeta _transactionTypeMeta =
      const VerificationMeta('transactionType');
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
      'transaction_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES financial_categories(id) ON DELETE RESTRICT');
  static const VerificationMeta _financialItemIdMeta =
      const VerificationMeta('financialItemId');
  @override
  late final GeneratedColumn<int> financialItemId = GeneratedColumn<int>(
      'financial_item_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES financial_items(id) ON DELETE SET NULL');
  static const VerificationMeta _fromAccountIdMeta =
      const VerificationMeta('fromAccountId');
  @override
  late final GeneratedColumn<int> fromAccountId = GeneratedColumn<int>(
      'from_account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'REFERENCES financial_accounts(id) ON DELETE SET NULL');
  static const VerificationMeta _toAccountIdMeta =
      const VerificationMeta('toAccountId');
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
      'to_account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'REFERENCES financial_accounts(id) ON DELETE SET NULL');
  static const VerificationMeta _transactionDateMeta =
      const VerificationMeta('transactionDate');
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>('transaction_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unitsMicroUnitsMeta =
      const VerificationMeta('unitsMicroUnits');
  @override
  late final GeneratedColumn<int> unitsMicroUnits = GeneratedColumn<int>(
      'units_micro_units', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _unitPriceMicroPaiseMeta =
      const VerificationMeta('unitPriceMicroPaise');
  @override
  late final GeneratedColumn<int> unitPriceMicroPaise = GeneratedColumn<int>(
      'unit_price_micro_paise', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        transactionType,
        categoryId,
        financialItemId,
        fromAccountId,
        toAccountId,
        transactionDate,
        amountPaise,
        unitsMicroUnits,
        unitPriceMicroPaise,
        source,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
          _transactionTypeMeta,
          transactionType.isAcceptableOrUnknown(
              data['transaction_type']!, _transactionTypeMeta));
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('financial_item_id')) {
      context.handle(
          _financialItemIdMeta,
          financialItemId.isAcceptableOrUnknown(
              data['financial_item_id']!, _financialItemIdMeta));
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
          _fromAccountIdMeta,
          fromAccountId.isAcceptableOrUnknown(
              data['from_account_id']!, _fromAccountIdMeta));
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
          _toAccountIdMeta,
          toAccountId.isAcceptableOrUnknown(
              data['to_account_id']!, _toAccountIdMeta));
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
          _transactionDateMeta,
          transactionDate.isAcceptableOrUnknown(
              data['transaction_date']!, _transactionDateMeta));
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('units_micro_units')) {
      context.handle(
          _unitsMicroUnitsMeta,
          unitsMicroUnits.isAcceptableOrUnknown(
              data['units_micro_units']!, _unitsMicroUnitsMeta));
    }
    if (data.containsKey('unit_price_micro_paise')) {
      context.handle(
          _unitPriceMicroPaiseMeta,
          unitPriceMicroPaise.isAcceptableOrUnknown(
              data['unit_price_micro_paise']!, _unitPriceMicroPaiseMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      transactionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}transaction_type'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      financialItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}financial_item_id']),
      fromAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_account_id']),
      toAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_account_id']),
      transactionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}transaction_date'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
      unitsMicroUnits: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}units_micro_units']),
      unitPriceMicroPaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}unit_price_micro_paise']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;

  /// Profile scoping: Every transaction belongs to an individual profile
  final int profileId;

  /// Transaction type:
  /// 'income', 'expense', 'transfer', 'investment_purchase', 'investment_redemption', 'debt_repayment', 'adjustment'
  final String transactionType;
  final int categoryId;
  final int? financialItemId;
  final int? fromAccountId;
  final int? toAccountId;
  final DateTime transactionDate;

  /// Cash transaction value in Paise (e.g., ₹5,000.00 = 500,000 paise)
  final int amountPaise;

  /// Units transacted for investments (in micro-units: 1.0 unit = 1,000,000 micro-units)
  final int? unitsMicroUnits;

  /// NAV or unit price in micro-paise (1 Rupee = 100 paise = 1,000,000 micro-paise)
  final int? unitPriceMicroPaise;

  /// Source identifier: 'manual', 'simulated_sip', 'loan_schedule', 'imported', 'correction'
  final String source;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Transaction(
      {required this.id,
      required this.profileId,
      required this.transactionType,
      required this.categoryId,
      this.financialItemId,
      this.fromAccountId,
      this.toAccountId,
      required this.transactionDate,
      required this.amountPaise,
      this.unitsMicroUnits,
      this.unitPriceMicroPaise,
      required this.source,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['transaction_type'] = Variable<String>(transactionType);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || financialItemId != null) {
      map['financial_item_id'] = Variable<int>(financialItemId);
    }
    if (!nullToAbsent || fromAccountId != null) {
      map['from_account_id'] = Variable<int>(fromAccountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<int>(toAccountId);
    }
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    map['amount_paise'] = Variable<int>(amountPaise);
    if (!nullToAbsent || unitsMicroUnits != null) {
      map['units_micro_units'] = Variable<int>(unitsMicroUnits);
    }
    if (!nullToAbsent || unitPriceMicroPaise != null) {
      map['unit_price_micro_paise'] = Variable<int>(unitPriceMicroPaise);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      transactionType: Value(transactionType),
      categoryId: Value(categoryId),
      financialItemId: financialItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(financialItemId),
      fromAccountId: fromAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAccountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      transactionDate: Value(transactionDate),
      amountPaise: Value(amountPaise),
      unitsMicroUnits: unitsMicroUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(unitsMicroUnits),
      unitPriceMicroPaise: unitPriceMicroPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPriceMicroPaise),
      source: Value(source),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      financialItemId: serializer.fromJson<int?>(json['financialItemId']),
      fromAccountId: serializer.fromJson<int?>(json['fromAccountId']),
      toAccountId: serializer.fromJson<int?>(json['toAccountId']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      unitsMicroUnits: serializer.fromJson<int?>(json['unitsMicroUnits']),
      unitPriceMicroPaise:
          serializer.fromJson<int?>(json['unitPriceMicroPaise']),
      source: serializer.fromJson<String>(json['source']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'transactionType': serializer.toJson<String>(transactionType),
      'categoryId': serializer.toJson<int>(categoryId),
      'financialItemId': serializer.toJson<int?>(financialItemId),
      'fromAccountId': serializer.toJson<int?>(fromAccountId),
      'toAccountId': serializer.toJson<int?>(toAccountId),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'unitsMicroUnits': serializer.toJson<int?>(unitsMicroUnits),
      'unitPriceMicroPaise': serializer.toJson<int?>(unitPriceMicroPaise),
      'source': serializer.toJson<String>(source),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Transaction copyWith(
          {int? id,
          int? profileId,
          String? transactionType,
          int? categoryId,
          Value<int?> financialItemId = const Value.absent(),
          Value<int?> fromAccountId = const Value.absent(),
          Value<int?> toAccountId = const Value.absent(),
          DateTime? transactionDate,
          int? amountPaise,
          Value<int?> unitsMicroUnits = const Value.absent(),
          Value<int?> unitPriceMicroPaise = const Value.absent(),
          String? source,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Transaction(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        transactionType: transactionType ?? this.transactionType,
        categoryId: categoryId ?? this.categoryId,
        financialItemId: financialItemId.present
            ? financialItemId.value
            : this.financialItemId,
        fromAccountId:
            fromAccountId.present ? fromAccountId.value : this.fromAccountId,
        toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
        transactionDate: transactionDate ?? this.transactionDate,
        amountPaise: amountPaise ?? this.amountPaise,
        unitsMicroUnits: unitsMicroUnits.present
            ? unitsMicroUnits.value
            : this.unitsMicroUnits,
        unitPriceMicroPaise: unitPriceMicroPaise.present
            ? unitPriceMicroPaise.value
            : this.unitPriceMicroPaise,
        source: source ?? this.source,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      financialItemId: data.financialItemId.present
          ? data.financialItemId.value
          : this.financialItemId,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId:
          data.toAccountId.present ? data.toAccountId.value : this.toAccountId,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
      unitsMicroUnits: data.unitsMicroUnits.present
          ? data.unitsMicroUnits.value
          : this.unitsMicroUnits,
      unitPriceMicroPaise: data.unitPriceMicroPaise.present
          ? data.unitPriceMicroPaise.value
          : this.unitPriceMicroPaise,
      source: data.source.present ? data.source.value : this.source,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('transactionType: $transactionType, ')
          ..write('categoryId: $categoryId, ')
          ..write('financialItemId: $financialItemId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('unitsMicroUnits: $unitsMicroUnits, ')
          ..write('unitPriceMicroPaise: $unitPriceMicroPaise, ')
          ..write('source: $source, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      transactionType,
      categoryId,
      financialItemId,
      fromAccountId,
      toAccountId,
      transactionDate,
      amountPaise,
      unitsMicroUnits,
      unitPriceMicroPaise,
      source,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.transactionType == this.transactionType &&
          other.categoryId == this.categoryId &&
          other.financialItemId == this.financialItemId &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.transactionDate == this.transactionDate &&
          other.amountPaise == this.amountPaise &&
          other.unitsMicroUnits == this.unitsMicroUnits &&
          other.unitPriceMicroPaise == this.unitPriceMicroPaise &&
          other.source == this.source &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> transactionType;
  final Value<int> categoryId;
  final Value<int?> financialItemId;
  final Value<int?> fromAccountId;
  final Value<int?> toAccountId;
  final Value<DateTime> transactionDate;
  final Value<int> amountPaise;
  final Value<int?> unitsMicroUnits;
  final Value<int?> unitPriceMicroPaise;
  final Value<String> source;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.financialItemId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.unitsMicroUnits = const Value.absent(),
    this.unitPriceMicroPaise = const Value.absent(),
    this.source = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String transactionType,
    required int categoryId,
    this.financialItemId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    required DateTime transactionDate,
    required int amountPaise,
    this.unitsMicroUnits = const Value.absent(),
    this.unitPriceMicroPaise = const Value.absent(),
    this.source = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : profileId = Value(profileId),
        transactionType = Value(transactionType),
        categoryId = Value(categoryId),
        transactionDate = Value(transactionDate),
        amountPaise = Value(amountPaise);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? transactionType,
    Expression<int>? categoryId,
    Expression<int>? financialItemId,
    Expression<int>? fromAccountId,
    Expression<int>? toAccountId,
    Expression<DateTime>? transactionDate,
    Expression<int>? amountPaise,
    Expression<int>? unitsMicroUnits,
    Expression<int>? unitPriceMicroPaise,
    Expression<String>? source,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (transactionType != null) 'transaction_type': transactionType,
      if (categoryId != null) 'category_id': categoryId,
      if (financialItemId != null) 'financial_item_id': financialItemId,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (unitsMicroUnits != null) 'units_micro_units': unitsMicroUnits,
      if (unitPriceMicroPaise != null)
        'unit_price_micro_paise': unitPriceMicroPaise,
      if (source != null) 'source': source,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TransactionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? transactionType,
      Value<int>? categoryId,
      Value<int?>? financialItemId,
      Value<int?>? fromAccountId,
      Value<int?>? toAccountId,
      Value<DateTime>? transactionDate,
      Value<int>? amountPaise,
      Value<int?>? unitsMicroUnits,
      Value<int?>? unitPriceMicroPaise,
      Value<String>? source,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      transactionType: transactionType ?? this.transactionType,
      categoryId: categoryId ?? this.categoryId,
      financialItemId: financialItemId ?? this.financialItemId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      transactionDate: transactionDate ?? this.transactionDate,
      amountPaise: amountPaise ?? this.amountPaise,
      unitsMicroUnits: unitsMicroUnits ?? this.unitsMicroUnits,
      unitPriceMicroPaise: unitPriceMicroPaise ?? this.unitPriceMicroPaise,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (financialItemId.present) {
      map['financial_item_id'] = Variable<int>(financialItemId.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<int>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (unitsMicroUnits.present) {
      map['units_micro_units'] = Variable<int>(unitsMicroUnits.value);
    }
    if (unitPriceMicroPaise.present) {
      map['unit_price_micro_paise'] = Variable<int>(unitPriceMicroPaise.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('transactionType: $transactionType, ')
          ..write('categoryId: $categoryId, ')
          ..write('financialItemId: $financialItemId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('unitsMicroUnits: $unitsMicroUnits, ')
          ..write('unitPriceMicroPaise: $unitPriceMicroPaise, ')
          ..write('source: $source, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ValuationHistoryTable extends ValuationHistory
    with TableInfo<$ValuationHistoryTable, ValuationHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ValuationHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _financialItemIdMeta =
      const VerificationMeta('financialItemId');
  @override
  late final GeneratedColumn<int> financialItemId = GeneratedColumn<int>(
      'financial_item_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES financial_items(id) ON DELETE CASCADE');
  static const VerificationMeta _valuationDateMeta =
      const VerificationMeta('valuationDate');
  @override
  late final GeneratedColumn<DateTime> valuationDate =
      GeneratedColumn<DateTime>('valuation_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _valuationPaiseMeta =
      const VerificationMeta('valuationPaise');
  @override
  late final GeneratedColumn<int> valuationPaise = GeneratedColumn<int>(
      'valuation_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceMicroPaiseMeta =
      const VerificationMeta('unitPriceMicroPaise');
  @override
  late final GeneratedColumn<int> unitPriceMicroPaise = GeneratedColumn<int>(
      'unit_price_micro_paise', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sourceProviderMeta =
      const VerificationMeta('sourceProvider');
  @override
  late final GeneratedColumn<String> sourceProvider = GeneratedColumn<String>(
      'source_provider', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('manual'));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        financialItemId,
        valuationDate,
        valuationPaise,
        unitPriceMicroPaise,
        sourceProvider,
        recordedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'valuation_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<ValuationHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('financial_item_id')) {
      context.handle(
          _financialItemIdMeta,
          financialItemId.isAcceptableOrUnknown(
              data['financial_item_id']!, _financialItemIdMeta));
    } else if (isInserting) {
      context.missing(_financialItemIdMeta);
    }
    if (data.containsKey('valuation_date')) {
      context.handle(
          _valuationDateMeta,
          valuationDate.isAcceptableOrUnknown(
              data['valuation_date']!, _valuationDateMeta));
    } else if (isInserting) {
      context.missing(_valuationDateMeta);
    }
    if (data.containsKey('valuation_paise')) {
      context.handle(
          _valuationPaiseMeta,
          valuationPaise.isAcceptableOrUnknown(
              data['valuation_paise']!, _valuationPaiseMeta));
    } else if (isInserting) {
      context.missing(_valuationPaiseMeta);
    }
    if (data.containsKey('unit_price_micro_paise')) {
      context.handle(
          _unitPriceMicroPaiseMeta,
          unitPriceMicroPaise.isAcceptableOrUnknown(
              data['unit_price_micro_paise']!, _unitPriceMicroPaiseMeta));
    }
    if (data.containsKey('source_provider')) {
      context.handle(
          _sourceProviderMeta,
          sourceProvider.isAcceptableOrUnknown(
              data['source_provider']!, _sourceProviderMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {financialItemId, valuationDate},
      ];
  @override
  ValuationHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ValuationHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      financialItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}financial_item_id'])!,
      valuationDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}valuation_date'])!,
      valuationPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}valuation_paise'])!,
      unitPriceMicroPaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}unit_price_micro_paise']),
      sourceProvider: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_provider'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
    );
  }

  @override
  $ValuationHistoryTable createAlias(String alias) {
    return $ValuationHistoryTable(attachedDatabase, alias);
  }
}

class ValuationHistoryData extends DataClass
    implements Insertable<ValuationHistoryData> {
  final int id;
  final int financialItemId;
  final DateTime valuationDate;

  /// Total valuation or outstanding debt balance on valuationDate in Paise
  final int valuationPaise;

  /// NAV or unit price in micro-paise, if applicable
  final int? unitPriceMicroPaise;

  /// Provider: 'mfapi', 'tigzig', 'amfi', 'manual', 'imported'
  final String sourceProvider;
  final DateTime recordedAt;
  const ValuationHistoryData(
      {required this.id,
      required this.financialItemId,
      required this.valuationDate,
      required this.valuationPaise,
      this.unitPriceMicroPaise,
      required this.sourceProvider,
      required this.recordedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['financial_item_id'] = Variable<int>(financialItemId);
    map['valuation_date'] = Variable<DateTime>(valuationDate);
    map['valuation_paise'] = Variable<int>(valuationPaise);
    if (!nullToAbsent || unitPriceMicroPaise != null) {
      map['unit_price_micro_paise'] = Variable<int>(unitPriceMicroPaise);
    }
    map['source_provider'] = Variable<String>(sourceProvider);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  ValuationHistoryCompanion toCompanion(bool nullToAbsent) {
    return ValuationHistoryCompanion(
      id: Value(id),
      financialItemId: Value(financialItemId),
      valuationDate: Value(valuationDate),
      valuationPaise: Value(valuationPaise),
      unitPriceMicroPaise: unitPriceMicroPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPriceMicroPaise),
      sourceProvider: Value(sourceProvider),
      recordedAt: Value(recordedAt),
    );
  }

  factory ValuationHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ValuationHistoryData(
      id: serializer.fromJson<int>(json['id']),
      financialItemId: serializer.fromJson<int>(json['financialItemId']),
      valuationDate: serializer.fromJson<DateTime>(json['valuationDate']),
      valuationPaise: serializer.fromJson<int>(json['valuationPaise']),
      unitPriceMicroPaise:
          serializer.fromJson<int?>(json['unitPriceMicroPaise']),
      sourceProvider: serializer.fromJson<String>(json['sourceProvider']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'financialItemId': serializer.toJson<int>(financialItemId),
      'valuationDate': serializer.toJson<DateTime>(valuationDate),
      'valuationPaise': serializer.toJson<int>(valuationPaise),
      'unitPriceMicroPaise': serializer.toJson<int?>(unitPriceMicroPaise),
      'sourceProvider': serializer.toJson<String>(sourceProvider),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  ValuationHistoryData copyWith(
          {int? id,
          int? financialItemId,
          DateTime? valuationDate,
          int? valuationPaise,
          Value<int?> unitPriceMicroPaise = const Value.absent(),
          String? sourceProvider,
          DateTime? recordedAt}) =>
      ValuationHistoryData(
        id: id ?? this.id,
        financialItemId: financialItemId ?? this.financialItemId,
        valuationDate: valuationDate ?? this.valuationDate,
        valuationPaise: valuationPaise ?? this.valuationPaise,
        unitPriceMicroPaise: unitPriceMicroPaise.present
            ? unitPriceMicroPaise.value
            : this.unitPriceMicroPaise,
        sourceProvider: sourceProvider ?? this.sourceProvider,
        recordedAt: recordedAt ?? this.recordedAt,
      );
  ValuationHistoryData copyWithCompanion(ValuationHistoryCompanion data) {
    return ValuationHistoryData(
      id: data.id.present ? data.id.value : this.id,
      financialItemId: data.financialItemId.present
          ? data.financialItemId.value
          : this.financialItemId,
      valuationDate: data.valuationDate.present
          ? data.valuationDate.value
          : this.valuationDate,
      valuationPaise: data.valuationPaise.present
          ? data.valuationPaise.value
          : this.valuationPaise,
      unitPriceMicroPaise: data.unitPriceMicroPaise.present
          ? data.unitPriceMicroPaise.value
          : this.unitPriceMicroPaise,
      sourceProvider: data.sourceProvider.present
          ? data.sourceProvider.value
          : this.sourceProvider,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ValuationHistoryData(')
          ..write('id: $id, ')
          ..write('financialItemId: $financialItemId, ')
          ..write('valuationDate: $valuationDate, ')
          ..write('valuationPaise: $valuationPaise, ')
          ..write('unitPriceMicroPaise: $unitPriceMicroPaise, ')
          ..write('sourceProvider: $sourceProvider, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, financialItemId, valuationDate,
      valuationPaise, unitPriceMicroPaise, sourceProvider, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValuationHistoryData &&
          other.id == this.id &&
          other.financialItemId == this.financialItemId &&
          other.valuationDate == this.valuationDate &&
          other.valuationPaise == this.valuationPaise &&
          other.unitPriceMicroPaise == this.unitPriceMicroPaise &&
          other.sourceProvider == this.sourceProvider &&
          other.recordedAt == this.recordedAt);
}

class ValuationHistoryCompanion extends UpdateCompanion<ValuationHistoryData> {
  final Value<int> id;
  final Value<int> financialItemId;
  final Value<DateTime> valuationDate;
  final Value<int> valuationPaise;
  final Value<int?> unitPriceMicroPaise;
  final Value<String> sourceProvider;
  final Value<DateTime> recordedAt;
  const ValuationHistoryCompanion({
    this.id = const Value.absent(),
    this.financialItemId = const Value.absent(),
    this.valuationDate = const Value.absent(),
    this.valuationPaise = const Value.absent(),
    this.unitPriceMicroPaise = const Value.absent(),
    this.sourceProvider = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  ValuationHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int financialItemId,
    required DateTime valuationDate,
    required int valuationPaise,
    this.unitPriceMicroPaise = const Value.absent(),
    this.sourceProvider = const Value.absent(),
    this.recordedAt = const Value.absent(),
  })  : financialItemId = Value(financialItemId),
        valuationDate = Value(valuationDate),
        valuationPaise = Value(valuationPaise);
  static Insertable<ValuationHistoryData> custom({
    Expression<int>? id,
    Expression<int>? financialItemId,
    Expression<DateTime>? valuationDate,
    Expression<int>? valuationPaise,
    Expression<int>? unitPriceMicroPaise,
    Expression<String>? sourceProvider,
    Expression<DateTime>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (financialItemId != null) 'financial_item_id': financialItemId,
      if (valuationDate != null) 'valuation_date': valuationDate,
      if (valuationPaise != null) 'valuation_paise': valuationPaise,
      if (unitPriceMicroPaise != null)
        'unit_price_micro_paise': unitPriceMicroPaise,
      if (sourceProvider != null) 'source_provider': sourceProvider,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  ValuationHistoryCompanion copyWith(
      {Value<int>? id,
      Value<int>? financialItemId,
      Value<DateTime>? valuationDate,
      Value<int>? valuationPaise,
      Value<int?>? unitPriceMicroPaise,
      Value<String>? sourceProvider,
      Value<DateTime>? recordedAt}) {
    return ValuationHistoryCompanion(
      id: id ?? this.id,
      financialItemId: financialItemId ?? this.financialItemId,
      valuationDate: valuationDate ?? this.valuationDate,
      valuationPaise: valuationPaise ?? this.valuationPaise,
      unitPriceMicroPaise: unitPriceMicroPaise ?? this.unitPriceMicroPaise,
      sourceProvider: sourceProvider ?? this.sourceProvider,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (financialItemId.present) {
      map['financial_item_id'] = Variable<int>(financialItemId.value);
    }
    if (valuationDate.present) {
      map['valuation_date'] = Variable<DateTime>(valuationDate.value);
    }
    if (valuationPaise.present) {
      map['valuation_paise'] = Variable<int>(valuationPaise.value);
    }
    if (unitPriceMicroPaise.present) {
      map['unit_price_micro_paise'] = Variable<int>(unitPriceMicroPaise.value);
    }
    if (sourceProvider.present) {
      map['source_provider'] = Variable<String>(sourceProvider.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ValuationHistoryCompanion(')
          ..write('id: $id, ')
          ..write('financialItemId: $financialItemId, ')
          ..write('valuationDate: $valuationDate, ')
          ..write('valuationPaise: $valuationPaise, ')
          ..write('unitPriceMicroPaise: $unitPriceMicroPaise, ')
          ..write('sourceProvider: $sourceProvider, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }
}

class $RecurringTransactionsTable extends RecurringTransactions
    with TableInfo<$RecurringTransactionsTable, RecurringTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 150),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _recurringTypeMeta =
      const VerificationMeta('recurringType');
  @override
  late final GeneratedColumn<String> recurringType = GeneratedColumn<String>(
      'recurring_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _financialItemIdMeta =
      const VerificationMeta('financialItemId');
  @override
  late final GeneratedColumn<int> financialItemId = GeneratedColumn<int>(
      'financial_item_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES financial_items(id) ON DELETE SET NULL');
  static const VerificationMeta _fromAccountIdMeta =
      const VerificationMeta('fromAccountId');
  @override
  late final GeneratedColumn<int> fromAccountId = GeneratedColumn<int>(
      'from_account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'REFERENCES financial_accounts(id) ON DELETE SET NULL');
  static const VerificationMeta _toAccountIdMeta =
      const VerificationMeta('toAccountId');
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
      'to_account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints:
          'REFERENCES financial_accounts(id) ON DELETE SET NULL');
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES financial_categories(id) ON DELETE RESTRICT');
  static const VerificationMeta _amountPaiseMeta =
      const VerificationMeta('amountPaise');
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
      'amount_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scheduledDayMeta =
      const VerificationMeta('scheduledDay');
  @override
  late final GeneratedColumn<int> scheduledDay = GeneratedColumn<int>(
      'scheduled_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _lastProcessedDateMeta =
      const VerificationMeta('lastProcessedDate');
  @override
  late final GeneratedColumn<DateTime> lastProcessedDate =
      GeneratedColumn<DateTime>('last_processed_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextDueDateMeta =
      const VerificationMeta('nextDueDate');
  @override
  late final GeneratedColumn<DateTime> nextDueDate = GeneratedColumn<DateTime>(
      'next_due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        name,
        recurringType,
        financialItemId,
        fromAccountId,
        toAccountId,
        categoryId,
        amountPaise,
        frequency,
        scheduledDay,
        startDate,
        endDate,
        status,
        lastProcessedDate,
        nextDueDate,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_transactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecurringTransaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('recurring_type')) {
      context.handle(
          _recurringTypeMeta,
          recurringType.isAcceptableOrUnknown(
              data['recurring_type']!, _recurringTypeMeta));
    } else if (isInserting) {
      context.missing(_recurringTypeMeta);
    }
    if (data.containsKey('financial_item_id')) {
      context.handle(
          _financialItemIdMeta,
          financialItemId.isAcceptableOrUnknown(
              data['financial_item_id']!, _financialItemIdMeta));
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
          _fromAccountIdMeta,
          fromAccountId.isAcceptableOrUnknown(
              data['from_account_id']!, _fromAccountIdMeta));
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
          _toAccountIdMeta,
          toAccountId.isAcceptableOrUnknown(
              data['to_account_id']!, _toAccountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
          _amountPaiseMeta,
          amountPaise.isAcceptableOrUnknown(
              data['amount_paise']!, _amountPaiseMeta));
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('scheduled_day')) {
      context.handle(
          _scheduledDayMeta,
          scheduledDay.isAcceptableOrUnknown(
              data['scheduled_day']!, _scheduledDayMeta));
    } else if (isInserting) {
      context.missing(_scheduledDayMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('last_processed_date')) {
      context.handle(
          _lastProcessedDateMeta,
          lastProcessedDate.isAcceptableOrUnknown(
              data['last_processed_date']!, _lastProcessedDateMeta));
    }
    if (data.containsKey('next_due_date')) {
      context.handle(
          _nextDueDateMeta,
          nextDueDate.isAcceptableOrUnknown(
              data['next_due_date']!, _nextDueDateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTransaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}profile_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      recurringType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurring_type'])!,
      financialItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}financial_item_id']),
      fromAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_account_id']),
      toAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      amountPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_paise'])!,
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      scheduledDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scheduled_day'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      lastProcessedDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_processed_date']),
      nextDueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_due_date']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RecurringTransactionsTable createAlias(String alias) {
    return $RecurringTransactionsTable(attachedDatabase, alias);
  }
}

class RecurringTransaction extends DataClass
    implements Insertable<RecurringTransaction> {
  final int id;

  /// Profile scoping: Every recurring schedule belongs to an individual profile
  final int profileId;
  final String name;

  /// Recurring type: 'sip_investment', 'loan_emi', 'recurring_income', 'recurring_expense'
  final String recurringType;
  final int? financialItemId;
  final int? fromAccountId;
  final int? toAccountId;
  final int categoryId;

  /// Scheduled cash amount in Paise
  final int amountPaise;

  /// Frequency: 'weekly', 'monthly', 'quarterly', 'yearly'
  final String frequency;

  /// Scheduled day: 1-31 for monthly/quarterly, 1-7 for weekly
  final int scheduledDay;
  final DateTime startDate;
  final DateTime? endDate;

  /// Status: 'active', 'paused', 'completed', 'cancelled'
  final String status;
  final DateTime? lastProcessedDate;
  final DateTime? nextDueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RecurringTransaction(
      {required this.id,
      required this.profileId,
      required this.name,
      required this.recurringType,
      this.financialItemId,
      this.fromAccountId,
      this.toAccountId,
      required this.categoryId,
      required this.amountPaise,
      required this.frequency,
      required this.scheduledDay,
      required this.startDate,
      this.endDate,
      required this.status,
      this.lastProcessedDate,
      this.nextDueDate,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['name'] = Variable<String>(name);
    map['recurring_type'] = Variable<String>(recurringType);
    if (!nullToAbsent || financialItemId != null) {
      map['financial_item_id'] = Variable<int>(financialItemId);
    }
    if (!nullToAbsent || fromAccountId != null) {
      map['from_account_id'] = Variable<int>(fromAccountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<int>(toAccountId);
    }
    map['category_id'] = Variable<int>(categoryId);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['frequency'] = Variable<String>(frequency);
    map['scheduled_day'] = Variable<int>(scheduledDay);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastProcessedDate != null) {
      map['last_processed_date'] = Variable<DateTime>(lastProcessedDate);
    }
    if (!nullToAbsent || nextDueDate != null) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RecurringTransactionsCompanion toCompanion(bool nullToAbsent) {
    return RecurringTransactionsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      recurringType: Value(recurringType),
      financialItemId: financialItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(financialItemId),
      fromAccountId: fromAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAccountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      categoryId: Value(categoryId),
      amountPaise: Value(amountPaise),
      frequency: Value(frequency),
      scheduledDay: Value(scheduledDay),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      status: Value(status),
      lastProcessedDate: lastProcessedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastProcessedDate),
      nextDueDate: nextDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueDate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTransaction(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      recurringType: serializer.fromJson<String>(json['recurringType']),
      financialItemId: serializer.fromJson<int?>(json['financialItemId']),
      fromAccountId: serializer.fromJson<int?>(json['fromAccountId']),
      toAccountId: serializer.fromJson<int?>(json['toAccountId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      frequency: serializer.fromJson<String>(json['frequency']),
      scheduledDay: serializer.fromJson<int>(json['scheduledDay']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      status: serializer.fromJson<String>(json['status']),
      lastProcessedDate:
          serializer.fromJson<DateTime?>(json['lastProcessedDate']),
      nextDueDate: serializer.fromJson<DateTime?>(json['nextDueDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'name': serializer.toJson<String>(name),
      'recurringType': serializer.toJson<String>(recurringType),
      'financialItemId': serializer.toJson<int?>(financialItemId),
      'fromAccountId': serializer.toJson<int?>(fromAccountId),
      'toAccountId': serializer.toJson<int?>(toAccountId),
      'categoryId': serializer.toJson<int>(categoryId),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'frequency': serializer.toJson<String>(frequency),
      'scheduledDay': serializer.toJson<int>(scheduledDay),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'status': serializer.toJson<String>(status),
      'lastProcessedDate': serializer.toJson<DateTime?>(lastProcessedDate),
      'nextDueDate': serializer.toJson<DateTime?>(nextDueDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RecurringTransaction copyWith(
          {int? id,
          int? profileId,
          String? name,
          String? recurringType,
          Value<int?> financialItemId = const Value.absent(),
          Value<int?> fromAccountId = const Value.absent(),
          Value<int?> toAccountId = const Value.absent(),
          int? categoryId,
          int? amountPaise,
          String? frequency,
          int? scheduledDay,
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          String? status,
          Value<DateTime?> lastProcessedDate = const Value.absent(),
          Value<DateTime?> nextDueDate = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      RecurringTransaction(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        name: name ?? this.name,
        recurringType: recurringType ?? this.recurringType,
        financialItemId: financialItemId.present
            ? financialItemId.value
            : this.financialItemId,
        fromAccountId:
            fromAccountId.present ? fromAccountId.value : this.fromAccountId,
        toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
        categoryId: categoryId ?? this.categoryId,
        amountPaise: amountPaise ?? this.amountPaise,
        frequency: frequency ?? this.frequency,
        scheduledDay: scheduledDay ?? this.scheduledDay,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        status: status ?? this.status,
        lastProcessedDate: lastProcessedDate.present
            ? lastProcessedDate.value
            : this.lastProcessedDate,
        nextDueDate: nextDueDate.present ? nextDueDate.value : this.nextDueDate,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  RecurringTransaction copyWithCompanion(RecurringTransactionsCompanion data) {
    return RecurringTransaction(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      recurringType: data.recurringType.present
          ? data.recurringType.value
          : this.recurringType,
      financialItemId: data.financialItemId.present
          ? data.financialItemId.value
          : this.financialItemId,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId:
          data.toAccountId.present ? data.toAccountId.value : this.toAccountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amountPaise:
          data.amountPaise.present ? data.amountPaise.value : this.amountPaise,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      scheduledDay: data.scheduledDay.present
          ? data.scheduledDay.value
          : this.scheduledDay,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      status: data.status.present ? data.status.value : this.status,
      lastProcessedDate: data.lastProcessedDate.present
          ? data.lastProcessedDate.value
          : this.lastProcessedDate,
      nextDueDate:
          data.nextDueDate.present ? data.nextDueDate.value : this.nextDueDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTransaction(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('recurringType: $recurringType, ')
          ..write('financialItemId: $financialItemId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('frequency: $frequency, ')
          ..write('scheduledDay: $scheduledDay, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('lastProcessedDate: $lastProcessedDate, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileId,
      name,
      recurringType,
      financialItemId,
      fromAccountId,
      toAccountId,
      categoryId,
      amountPaise,
      frequency,
      scheduledDay,
      startDate,
      endDate,
      status,
      lastProcessedDate,
      nextDueDate,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTransaction &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.recurringType == this.recurringType &&
          other.financialItemId == this.financialItemId &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.categoryId == this.categoryId &&
          other.amountPaise == this.amountPaise &&
          other.frequency == this.frequency &&
          other.scheduledDay == this.scheduledDay &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.status == this.status &&
          other.lastProcessedDate == this.lastProcessedDate &&
          other.nextDueDate == this.nextDueDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecurringTransactionsCompanion
    extends UpdateCompanion<RecurringTransaction> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> name;
  final Value<String> recurringType;
  final Value<int?> financialItemId;
  final Value<int?> fromAccountId;
  final Value<int?> toAccountId;
  final Value<int> categoryId;
  final Value<int> amountPaise;
  final Value<String> frequency;
  final Value<int> scheduledDay;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<String> status;
  final Value<DateTime?> lastProcessedDate;
  final Value<DateTime?> nextDueDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const RecurringTransactionsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.recurringType = const Value.absent(),
    this.financialItemId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.frequency = const Value.absent(),
    this.scheduledDay = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.status = const Value.absent(),
    this.lastProcessedDate = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RecurringTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String name,
    required String recurringType,
    this.financialItemId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    required int categoryId,
    required int amountPaise,
    required String frequency,
    required int scheduledDay,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.status = const Value.absent(),
    this.lastProcessedDate = const Value.absent(),
    this.nextDueDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : profileId = Value(profileId),
        name = Value(name),
        recurringType = Value(recurringType),
        categoryId = Value(categoryId),
        amountPaise = Value(amountPaise),
        frequency = Value(frequency),
        scheduledDay = Value(scheduledDay),
        startDate = Value(startDate);
  static Insertable<RecurringTransaction> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? name,
    Expression<String>? recurringType,
    Expression<int>? financialItemId,
    Expression<int>? fromAccountId,
    Expression<int>? toAccountId,
    Expression<int>? categoryId,
    Expression<int>? amountPaise,
    Expression<String>? frequency,
    Expression<int>? scheduledDay,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? status,
    Expression<DateTime>? lastProcessedDate,
    Expression<DateTime>? nextDueDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (recurringType != null) 'recurring_type': recurringType,
      if (financialItemId != null) 'financial_item_id': financialItemId,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (frequency != null) 'frequency': frequency,
      if (scheduledDay != null) 'scheduled_day': scheduledDay,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (status != null) 'status': status,
      if (lastProcessedDate != null) 'last_processed_date': lastProcessedDate,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RecurringTransactionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? profileId,
      Value<String>? name,
      Value<String>? recurringType,
      Value<int?>? financialItemId,
      Value<int?>? fromAccountId,
      Value<int?>? toAccountId,
      Value<int>? categoryId,
      Value<int>? amountPaise,
      Value<String>? frequency,
      Value<int>? scheduledDay,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<String>? status,
      Value<DateTime?>? lastProcessedDate,
      Value<DateTime?>? nextDueDate,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return RecurringTransactionsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      recurringType: recurringType ?? this.recurringType,
      financialItemId: financialItemId ?? this.financialItemId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      amountPaise: amountPaise ?? this.amountPaise,
      frequency: frequency ?? this.frequency,
      scheduledDay: scheduledDay ?? this.scheduledDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (recurringType.present) {
      map['recurring_type'] = Variable<String>(recurringType.value);
    }
    if (financialItemId.present) {
      map['financial_item_id'] = Variable<int>(financialItemId.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<int>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (scheduledDay.present) {
      map['scheduled_day'] = Variable<int>(scheduledDay.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastProcessedDate.present) {
      map['last_processed_date'] = Variable<DateTime>(lastProcessedDate.value);
    }
    if (nextDueDate.present) {
      map['next_due_date'] = Variable<DateTime>(nextDueDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('recurringType: $recurringType, ')
          ..write('financialItemId: $financialItemId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('frequency: $frequency, ')
          ..write('scheduledDay: $scheduledDay, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('status: $status, ')
          ..write('lastProcessedDate: $lastProcessedDate, ')
          ..write('nextDueDate: $nextDueDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MutualFundSchemesTable extends MutualFundSchemes
    with TableInfo<$MutualFundSchemesTable, MutualFundScheme> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MutualFundSchemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _schemeCodeMeta =
      const VerificationMeta('schemeCode');
  @override
  late final GeneratedColumn<int> schemeCode = GeneratedColumn<int>(
      'scheme_code', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _schemeNameMeta =
      const VerificationMeta('schemeName');
  @override
  late final GeneratedColumn<String> schemeName = GeneratedColumn<String>(
      'scheme_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 300),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _fundHouseMeta =
      const VerificationMeta('fundHouse');
  @override
  late final GeneratedColumn<String> fundHouse = GeneratedColumn<String>(
      'fund_house', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _schemeTypeMeta =
      const VerificationMeta('schemeType');
  @override
  late final GeneratedColumn<String> schemeType = GeneratedColumn<String>(
      'scheme_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _schemeCategoryMeta =
      const VerificationMeta('schemeCategory');
  @override
  late final GeneratedColumn<String> schemeCategory = GeneratedColumn<String>(
      'scheme_category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _planTypeMeta =
      const VerificationMeta('planType');
  @override
  late final GeneratedColumn<String> planType = GeneratedColumn<String>(
      'plan_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _optionTypeMeta =
      const VerificationMeta('optionType');
  @override
  late final GeneratedColumn<String> optionType = GeneratedColumn<String>(
      'option_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isinMeta = const VerificationMeta('isin');
  @override
  late final GeneratedColumn<String> isin = GeneratedColumn<String>(
      'isin', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latestNavMicroPaiseMeta =
      const VerificationMeta('latestNavMicroPaise');
  @override
  late final GeneratedColumn<int> latestNavMicroPaise = GeneratedColumn<int>(
      'latest_nav_micro_paise', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _latestNavDateMeta =
      const VerificationMeta('latestNavDate');
  @override
  late final GeneratedColumn<DateTime> latestNavDate =
      GeneratedColumn<DateTime>('latest_nav_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
      'last_synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        schemeCode,
        schemeName,
        fundHouse,
        schemeType,
        schemeCategory,
        planType,
        optionType,
        isin,
        latestNavMicroPaise,
        latestNavDate,
        isFavorite,
        lastSyncedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mutual_fund_schemes';
  @override
  VerificationContext validateIntegrity(Insertable<MutualFundScheme> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scheme_code')) {
      context.handle(
          _schemeCodeMeta,
          schemeCode.isAcceptableOrUnknown(
              data['scheme_code']!, _schemeCodeMeta));
    }
    if (data.containsKey('scheme_name')) {
      context.handle(
          _schemeNameMeta,
          schemeName.isAcceptableOrUnknown(
              data['scheme_name']!, _schemeNameMeta));
    } else if (isInserting) {
      context.missing(_schemeNameMeta);
    }
    if (data.containsKey('fund_house')) {
      context.handle(_fundHouseMeta,
          fundHouse.isAcceptableOrUnknown(data['fund_house']!, _fundHouseMeta));
    }
    if (data.containsKey('scheme_type')) {
      context.handle(
          _schemeTypeMeta,
          schemeType.isAcceptableOrUnknown(
              data['scheme_type']!, _schemeTypeMeta));
    }
    if (data.containsKey('scheme_category')) {
      context.handle(
          _schemeCategoryMeta,
          schemeCategory.isAcceptableOrUnknown(
              data['scheme_category']!, _schemeCategoryMeta));
    }
    if (data.containsKey('plan_type')) {
      context.handle(_planTypeMeta,
          planType.isAcceptableOrUnknown(data['plan_type']!, _planTypeMeta));
    }
    if (data.containsKey('option_type')) {
      context.handle(
          _optionTypeMeta,
          optionType.isAcceptableOrUnknown(
              data['option_type']!, _optionTypeMeta));
    }
    if (data.containsKey('isin')) {
      context.handle(
          _isinMeta, isin.isAcceptableOrUnknown(data['isin']!, _isinMeta));
    }
    if (data.containsKey('latest_nav_micro_paise')) {
      context.handle(
          _latestNavMicroPaiseMeta,
          latestNavMicroPaise.isAcceptableOrUnknown(
              data['latest_nav_micro_paise']!, _latestNavMicroPaiseMeta));
    }
    if (data.containsKey('latest_nav_date')) {
      context.handle(
          _latestNavDateMeta,
          latestNavDate.isAcceptableOrUnknown(
              data['latest_nav_date']!, _latestNavDateMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {schemeCode};
  @override
  MutualFundScheme map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MutualFundScheme(
      schemeCode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scheme_code'])!,
      schemeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scheme_name'])!,
      fundHouse: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fund_house']),
      schemeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scheme_type']),
      schemeCategory: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scheme_category']),
      planType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_type']),
      optionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}option_type']),
      isin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}isin']),
      latestNavMicroPaise: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}latest_nav_micro_paise']),
      latestNavDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}latest_nav_date']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_synced_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MutualFundSchemesTable createAlias(String alias) {
    return $MutualFundSchemesTable(attachedDatabase, alias);
  }
}

class MutualFundScheme extends DataClass
    implements Insertable<MutualFundScheme> {
  /// AMFI unique scheme code (primary key)
  final int schemeCode;

  /// Full scheme display name
  final String schemeName;

  /// Asset Management Company / Fund House (e.g. "HDFC Mutual Fund", "SBI Mutual Fund")
  final String? fundHouse;

  /// Scheme Type (e.g. "Open Ended Schemes", "Close Ended")
  final String? schemeType;

  /// Scheme Category (e.g. "Equity Scheme - Small Cap Fund", "Debt Scheme - Liquid Fund")
  final String? schemeCategory;

  /// Plan Type: 'Direct' or 'Regular'
  final String? planType;

  /// Option Type: 'Growth' or 'IDCW' (Dividend)
  final String? optionType;

  /// International Securities Identification Number (ISIN)
  final String? isin;

  /// Latest known NAV in micro-paise (1 Rupee = 1,000,000 micro-paise)
  final int? latestNavMicroPaise;

  /// Date of the latest NAV record
  final DateTime? latestNavDate;

  /// Whether user bookmarked this fund in their favourites/watchlist
  final bool isFavorite;

  /// Timestamp of the last successful synchronization from remote provider
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MutualFundScheme(
      {required this.schemeCode,
      required this.schemeName,
      this.fundHouse,
      this.schemeType,
      this.schemeCategory,
      this.planType,
      this.optionType,
      this.isin,
      this.latestNavMicroPaise,
      this.latestNavDate,
      required this.isFavorite,
      this.lastSyncedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scheme_code'] = Variable<int>(schemeCode);
    map['scheme_name'] = Variable<String>(schemeName);
    if (!nullToAbsent || fundHouse != null) {
      map['fund_house'] = Variable<String>(fundHouse);
    }
    if (!nullToAbsent || schemeType != null) {
      map['scheme_type'] = Variable<String>(schemeType);
    }
    if (!nullToAbsent || schemeCategory != null) {
      map['scheme_category'] = Variable<String>(schemeCategory);
    }
    if (!nullToAbsent || planType != null) {
      map['plan_type'] = Variable<String>(planType);
    }
    if (!nullToAbsent || optionType != null) {
      map['option_type'] = Variable<String>(optionType);
    }
    if (!nullToAbsent || isin != null) {
      map['isin'] = Variable<String>(isin);
    }
    if (!nullToAbsent || latestNavMicroPaise != null) {
      map['latest_nav_micro_paise'] = Variable<int>(latestNavMicroPaise);
    }
    if (!nullToAbsent || latestNavDate != null) {
      map['latest_nav_date'] = Variable<DateTime>(latestNavDate);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MutualFundSchemesCompanion toCompanion(bool nullToAbsent) {
    return MutualFundSchemesCompanion(
      schemeCode: Value(schemeCode),
      schemeName: Value(schemeName),
      fundHouse: fundHouse == null && nullToAbsent
          ? const Value.absent()
          : Value(fundHouse),
      schemeType: schemeType == null && nullToAbsent
          ? const Value.absent()
          : Value(schemeType),
      schemeCategory: schemeCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(schemeCategory),
      planType: planType == null && nullToAbsent
          ? const Value.absent()
          : Value(planType),
      optionType: optionType == null && nullToAbsent
          ? const Value.absent()
          : Value(optionType),
      isin: isin == null && nullToAbsent ? const Value.absent() : Value(isin),
      latestNavMicroPaise: latestNavMicroPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(latestNavMicroPaise),
      latestNavDate: latestNavDate == null && nullToAbsent
          ? const Value.absent()
          : Value(latestNavDate),
      isFavorite: Value(isFavorite),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MutualFundScheme.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MutualFundScheme(
      schemeCode: serializer.fromJson<int>(json['schemeCode']),
      schemeName: serializer.fromJson<String>(json['schemeName']),
      fundHouse: serializer.fromJson<String?>(json['fundHouse']),
      schemeType: serializer.fromJson<String?>(json['schemeType']),
      schemeCategory: serializer.fromJson<String?>(json['schemeCategory']),
      planType: serializer.fromJson<String?>(json['planType']),
      optionType: serializer.fromJson<String?>(json['optionType']),
      isin: serializer.fromJson<String?>(json['isin']),
      latestNavMicroPaise:
          serializer.fromJson<int?>(json['latestNavMicroPaise']),
      latestNavDate: serializer.fromJson<DateTime?>(json['latestNavDate']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'schemeCode': serializer.toJson<int>(schemeCode),
      'schemeName': serializer.toJson<String>(schemeName),
      'fundHouse': serializer.toJson<String?>(fundHouse),
      'schemeType': serializer.toJson<String?>(schemeType),
      'schemeCategory': serializer.toJson<String?>(schemeCategory),
      'planType': serializer.toJson<String?>(planType),
      'optionType': serializer.toJson<String?>(optionType),
      'isin': serializer.toJson<String?>(isin),
      'latestNavMicroPaise': serializer.toJson<int?>(latestNavMicroPaise),
      'latestNavDate': serializer.toJson<DateTime?>(latestNavDate),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MutualFundScheme copyWith(
          {int? schemeCode,
          String? schemeName,
          Value<String?> fundHouse = const Value.absent(),
          Value<String?> schemeType = const Value.absent(),
          Value<String?> schemeCategory = const Value.absent(),
          Value<String?> planType = const Value.absent(),
          Value<String?> optionType = const Value.absent(),
          Value<String?> isin = const Value.absent(),
          Value<int?> latestNavMicroPaise = const Value.absent(),
          Value<DateTime?> latestNavDate = const Value.absent(),
          bool? isFavorite,
          Value<DateTime?> lastSyncedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      MutualFundScheme(
        schemeCode: schemeCode ?? this.schemeCode,
        schemeName: schemeName ?? this.schemeName,
        fundHouse: fundHouse.present ? fundHouse.value : this.fundHouse,
        schemeType: schemeType.present ? schemeType.value : this.schemeType,
        schemeCategory:
            schemeCategory.present ? schemeCategory.value : this.schemeCategory,
        planType: planType.present ? planType.value : this.planType,
        optionType: optionType.present ? optionType.value : this.optionType,
        isin: isin.present ? isin.value : this.isin,
        latestNavMicroPaise: latestNavMicroPaise.present
            ? latestNavMicroPaise.value
            : this.latestNavMicroPaise,
        latestNavDate:
            latestNavDate.present ? latestNavDate.value : this.latestNavDate,
        isFavorite: isFavorite ?? this.isFavorite,
        lastSyncedAt:
            lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MutualFundScheme copyWithCompanion(MutualFundSchemesCompanion data) {
    return MutualFundScheme(
      schemeCode:
          data.schemeCode.present ? data.schemeCode.value : this.schemeCode,
      schemeName:
          data.schemeName.present ? data.schemeName.value : this.schemeName,
      fundHouse: data.fundHouse.present ? data.fundHouse.value : this.fundHouse,
      schemeType:
          data.schemeType.present ? data.schemeType.value : this.schemeType,
      schemeCategory: data.schemeCategory.present
          ? data.schemeCategory.value
          : this.schemeCategory,
      planType: data.planType.present ? data.planType.value : this.planType,
      optionType:
          data.optionType.present ? data.optionType.value : this.optionType,
      isin: data.isin.present ? data.isin.value : this.isin,
      latestNavMicroPaise: data.latestNavMicroPaise.present
          ? data.latestNavMicroPaise.value
          : this.latestNavMicroPaise,
      latestNavDate: data.latestNavDate.present
          ? data.latestNavDate.value
          : this.latestNavDate,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MutualFundScheme(')
          ..write('schemeCode: $schemeCode, ')
          ..write('schemeName: $schemeName, ')
          ..write('fundHouse: $fundHouse, ')
          ..write('schemeType: $schemeType, ')
          ..write('schemeCategory: $schemeCategory, ')
          ..write('planType: $planType, ')
          ..write('optionType: $optionType, ')
          ..write('isin: $isin, ')
          ..write('latestNavMicroPaise: $latestNavMicroPaise, ')
          ..write('latestNavDate: $latestNavDate, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      schemeCode,
      schemeName,
      fundHouse,
      schemeType,
      schemeCategory,
      planType,
      optionType,
      isin,
      latestNavMicroPaise,
      latestNavDate,
      isFavorite,
      lastSyncedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MutualFundScheme &&
          other.schemeCode == this.schemeCode &&
          other.schemeName == this.schemeName &&
          other.fundHouse == this.fundHouse &&
          other.schemeType == this.schemeType &&
          other.schemeCategory == this.schemeCategory &&
          other.planType == this.planType &&
          other.optionType == this.optionType &&
          other.isin == this.isin &&
          other.latestNavMicroPaise == this.latestNavMicroPaise &&
          other.latestNavDate == this.latestNavDate &&
          other.isFavorite == this.isFavorite &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MutualFundSchemesCompanion extends UpdateCompanion<MutualFundScheme> {
  final Value<int> schemeCode;
  final Value<String> schemeName;
  final Value<String?> fundHouse;
  final Value<String?> schemeType;
  final Value<String?> schemeCategory;
  final Value<String?> planType;
  final Value<String?> optionType;
  final Value<String?> isin;
  final Value<int?> latestNavMicroPaise;
  final Value<DateTime?> latestNavDate;
  final Value<bool> isFavorite;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MutualFundSchemesCompanion({
    this.schemeCode = const Value.absent(),
    this.schemeName = const Value.absent(),
    this.fundHouse = const Value.absent(),
    this.schemeType = const Value.absent(),
    this.schemeCategory = const Value.absent(),
    this.planType = const Value.absent(),
    this.optionType = const Value.absent(),
    this.isin = const Value.absent(),
    this.latestNavMicroPaise = const Value.absent(),
    this.latestNavDate = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MutualFundSchemesCompanion.insert({
    this.schemeCode = const Value.absent(),
    required String schemeName,
    this.fundHouse = const Value.absent(),
    this.schemeType = const Value.absent(),
    this.schemeCategory = const Value.absent(),
    this.planType = const Value.absent(),
    this.optionType = const Value.absent(),
    this.isin = const Value.absent(),
    this.latestNavMicroPaise = const Value.absent(),
    this.latestNavDate = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : schemeName = Value(schemeName);
  static Insertable<MutualFundScheme> custom({
    Expression<int>? schemeCode,
    Expression<String>? schemeName,
    Expression<String>? fundHouse,
    Expression<String>? schemeType,
    Expression<String>? schemeCategory,
    Expression<String>? planType,
    Expression<String>? optionType,
    Expression<String>? isin,
    Expression<int>? latestNavMicroPaise,
    Expression<DateTime>? latestNavDate,
    Expression<bool>? isFavorite,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (schemeCode != null) 'scheme_code': schemeCode,
      if (schemeName != null) 'scheme_name': schemeName,
      if (fundHouse != null) 'fund_house': fundHouse,
      if (schemeType != null) 'scheme_type': schemeType,
      if (schemeCategory != null) 'scheme_category': schemeCategory,
      if (planType != null) 'plan_type': planType,
      if (optionType != null) 'option_type': optionType,
      if (isin != null) 'isin': isin,
      if (latestNavMicroPaise != null)
        'latest_nav_micro_paise': latestNavMicroPaise,
      if (latestNavDate != null) 'latest_nav_date': latestNavDate,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MutualFundSchemesCompanion copyWith(
      {Value<int>? schemeCode,
      Value<String>? schemeName,
      Value<String?>? fundHouse,
      Value<String?>? schemeType,
      Value<String?>? schemeCategory,
      Value<String?>? planType,
      Value<String?>? optionType,
      Value<String?>? isin,
      Value<int?>? latestNavMicroPaise,
      Value<DateTime?>? latestNavDate,
      Value<bool>? isFavorite,
      Value<DateTime?>? lastSyncedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return MutualFundSchemesCompanion(
      schemeCode: schemeCode ?? this.schemeCode,
      schemeName: schemeName ?? this.schemeName,
      fundHouse: fundHouse ?? this.fundHouse,
      schemeType: schemeType ?? this.schemeType,
      schemeCategory: schemeCategory ?? this.schemeCategory,
      planType: planType ?? this.planType,
      optionType: optionType ?? this.optionType,
      isin: isin ?? this.isin,
      latestNavMicroPaise: latestNavMicroPaise ?? this.latestNavMicroPaise,
      latestNavDate: latestNavDate ?? this.latestNavDate,
      isFavorite: isFavorite ?? this.isFavorite,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (schemeCode.present) {
      map['scheme_code'] = Variable<int>(schemeCode.value);
    }
    if (schemeName.present) {
      map['scheme_name'] = Variable<String>(schemeName.value);
    }
    if (fundHouse.present) {
      map['fund_house'] = Variable<String>(fundHouse.value);
    }
    if (schemeType.present) {
      map['scheme_type'] = Variable<String>(schemeType.value);
    }
    if (schemeCategory.present) {
      map['scheme_category'] = Variable<String>(schemeCategory.value);
    }
    if (planType.present) {
      map['plan_type'] = Variable<String>(planType.value);
    }
    if (optionType.present) {
      map['option_type'] = Variable<String>(optionType.value);
    }
    if (isin.present) {
      map['isin'] = Variable<String>(isin.value);
    }
    if (latestNavMicroPaise.present) {
      map['latest_nav_micro_paise'] = Variable<int>(latestNavMicroPaise.value);
    }
    if (latestNavDate.present) {
      map['latest_nav_date'] = Variable<DateTime>(latestNavDate.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MutualFundSchemesCompanion(')
          ..write('schemeCode: $schemeCode, ')
          ..write('schemeName: $schemeName, ')
          ..write('fundHouse: $fundHouse, ')
          ..write('schemeType: $schemeType, ')
          ..write('schemeCategory: $schemeCategory, ')
          ..write('planType: $planType, ')
          ..write('optionType: $optionType, ')
          ..write('isin: $isin, ')
          ..write('latestNavMicroPaise: $latestNavMicroPaise, ')
          ..write('latestNavDate: $latestNavDate, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NavHistoryTable extends NavHistory
    with TableInfo<$NavHistoryTable, NavHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NavHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _schemeCodeMeta =
      const VerificationMeta('schemeCode');
  @override
  late final GeneratedColumn<int> schemeCode = GeneratedColumn<int>(
      'scheme_code', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES mutual_fund_schemes(scheme_code) ON DELETE CASCADE');
  static const VerificationMeta _navDateMeta =
      const VerificationMeta('navDate');
  @override
  late final GeneratedColumn<DateTime> navDate = GeneratedColumn<DateTime>(
      'nav_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _navMicroPaiseMeta =
      const VerificationMeta('navMicroPaise');
  @override
  late final GeneratedColumn<int> navMicroPaise = GeneratedColumn<int>(
      'nav_micro_paise', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sourceProviderMeta =
      const VerificationMeta('sourceProvider');
  @override
  late final GeneratedColumn<String> sourceProvider = GeneratedColumn<String>(
      'source_provider', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('mfapi'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, schemeCode, navDate, navMicroPaise, sourceProvider, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nav_history';
  @override
  VerificationContext validateIntegrity(Insertable<NavHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scheme_code')) {
      context.handle(
          _schemeCodeMeta,
          schemeCode.isAcceptableOrUnknown(
              data['scheme_code']!, _schemeCodeMeta));
    } else if (isInserting) {
      context.missing(_schemeCodeMeta);
    }
    if (data.containsKey('nav_date')) {
      context.handle(_navDateMeta,
          navDate.isAcceptableOrUnknown(data['nav_date']!, _navDateMeta));
    } else if (isInserting) {
      context.missing(_navDateMeta);
    }
    if (data.containsKey('nav_micro_paise')) {
      context.handle(
          _navMicroPaiseMeta,
          navMicroPaise.isAcceptableOrUnknown(
              data['nav_micro_paise']!, _navMicroPaiseMeta));
    } else if (isInserting) {
      context.missing(_navMicroPaiseMeta);
    }
    if (data.containsKey('source_provider')) {
      context.handle(
          _sourceProviderMeta,
          sourceProvider.isAcceptableOrUnknown(
              data['source_provider']!, _sourceProviderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {schemeCode, navDate},
      ];
  @override
  NavHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NavHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      schemeCode: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scheme_code'])!,
      navDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}nav_date'])!,
      navMicroPaise: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}nav_micro_paise'])!,
      sourceProvider: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_provider'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NavHistoryTable createAlias(String alias) {
    return $NavHistoryTable(attachedDatabase, alias);
  }
}

class NavHistoryData extends DataClass implements Insertable<NavHistoryData> {
  final int id;
  final int schemeCode;

  /// Normalized date of NAV valuation (UTC midnight)
  final DateTime navDate;

  /// NAV in micro-paise (1 Rupee = 1,000,000 micro-paise, 4-6 decimal places)
  final int navMicroPaise;

  /// Data source: 'mfapi', 'tigzig', 'amfi', 'manual'
  final String sourceProvider;
  final DateTime createdAt;
  const NavHistoryData(
      {required this.id,
      required this.schemeCode,
      required this.navDate,
      required this.navMicroPaise,
      required this.sourceProvider,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scheme_code'] = Variable<int>(schemeCode);
    map['nav_date'] = Variable<DateTime>(navDate);
    map['nav_micro_paise'] = Variable<int>(navMicroPaise);
    map['source_provider'] = Variable<String>(sourceProvider);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NavHistoryCompanion toCompanion(bool nullToAbsent) {
    return NavHistoryCompanion(
      id: Value(id),
      schemeCode: Value(schemeCode),
      navDate: Value(navDate),
      navMicroPaise: Value(navMicroPaise),
      sourceProvider: Value(sourceProvider),
      createdAt: Value(createdAt),
    );
  }

  factory NavHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NavHistoryData(
      id: serializer.fromJson<int>(json['id']),
      schemeCode: serializer.fromJson<int>(json['schemeCode']),
      navDate: serializer.fromJson<DateTime>(json['navDate']),
      navMicroPaise: serializer.fromJson<int>(json['navMicroPaise']),
      sourceProvider: serializer.fromJson<String>(json['sourceProvider']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'schemeCode': serializer.toJson<int>(schemeCode),
      'navDate': serializer.toJson<DateTime>(navDate),
      'navMicroPaise': serializer.toJson<int>(navMicroPaise),
      'sourceProvider': serializer.toJson<String>(sourceProvider),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NavHistoryData copyWith(
          {int? id,
          int? schemeCode,
          DateTime? navDate,
          int? navMicroPaise,
          String? sourceProvider,
          DateTime? createdAt}) =>
      NavHistoryData(
        id: id ?? this.id,
        schemeCode: schemeCode ?? this.schemeCode,
        navDate: navDate ?? this.navDate,
        navMicroPaise: navMicroPaise ?? this.navMicroPaise,
        sourceProvider: sourceProvider ?? this.sourceProvider,
        createdAt: createdAt ?? this.createdAt,
      );
  NavHistoryData copyWithCompanion(NavHistoryCompanion data) {
    return NavHistoryData(
      id: data.id.present ? data.id.value : this.id,
      schemeCode:
          data.schemeCode.present ? data.schemeCode.value : this.schemeCode,
      navDate: data.navDate.present ? data.navDate.value : this.navDate,
      navMicroPaise: data.navMicroPaise.present
          ? data.navMicroPaise.value
          : this.navMicroPaise,
      sourceProvider: data.sourceProvider.present
          ? data.sourceProvider.value
          : this.sourceProvider,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NavHistoryData(')
          ..write('id: $id, ')
          ..write('schemeCode: $schemeCode, ')
          ..write('navDate: $navDate, ')
          ..write('navMicroPaise: $navMicroPaise, ')
          ..write('sourceProvider: $sourceProvider, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, schemeCode, navDate, navMicroPaise, sourceProvider, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NavHistoryData &&
          other.id == this.id &&
          other.schemeCode == this.schemeCode &&
          other.navDate == this.navDate &&
          other.navMicroPaise == this.navMicroPaise &&
          other.sourceProvider == this.sourceProvider &&
          other.createdAt == this.createdAt);
}

class NavHistoryCompanion extends UpdateCompanion<NavHistoryData> {
  final Value<int> id;
  final Value<int> schemeCode;
  final Value<DateTime> navDate;
  final Value<int> navMicroPaise;
  final Value<String> sourceProvider;
  final Value<DateTime> createdAt;
  const NavHistoryCompanion({
    this.id = const Value.absent(),
    this.schemeCode = const Value.absent(),
    this.navDate = const Value.absent(),
    this.navMicroPaise = const Value.absent(),
    this.sourceProvider = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NavHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int schemeCode,
    required DateTime navDate,
    required int navMicroPaise,
    this.sourceProvider = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : schemeCode = Value(schemeCode),
        navDate = Value(navDate),
        navMicroPaise = Value(navMicroPaise);
  static Insertable<NavHistoryData> custom({
    Expression<int>? id,
    Expression<int>? schemeCode,
    Expression<DateTime>? navDate,
    Expression<int>? navMicroPaise,
    Expression<String>? sourceProvider,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (schemeCode != null) 'scheme_code': schemeCode,
      if (navDate != null) 'nav_date': navDate,
      if (navMicroPaise != null) 'nav_micro_paise': navMicroPaise,
      if (sourceProvider != null) 'source_provider': sourceProvider,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NavHistoryCompanion copyWith(
      {Value<int>? id,
      Value<int>? schemeCode,
      Value<DateTime>? navDate,
      Value<int>? navMicroPaise,
      Value<String>? sourceProvider,
      Value<DateTime>? createdAt}) {
    return NavHistoryCompanion(
      id: id ?? this.id,
      schemeCode: schemeCode ?? this.schemeCode,
      navDate: navDate ?? this.navDate,
      navMicroPaise: navMicroPaise ?? this.navMicroPaise,
      sourceProvider: sourceProvider ?? this.sourceProvider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (schemeCode.present) {
      map['scheme_code'] = Variable<int>(schemeCode.value);
    }
    if (navDate.present) {
      map['nav_date'] = Variable<DateTime>(navDate.value);
    }
    if (navMicroPaise.present) {
      map['nav_micro_paise'] = Variable<int>(navMicroPaise.value);
    }
    if (sourceProvider.present) {
      map['source_provider'] = Variable<String>(sourceProvider.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NavHistoryCompanion(')
          ..write('id: $id, ')
          ..write('schemeCode: $schemeCode, ')
          ..write('navDate: $navDate, ')
          ..write('navMicroPaise: $navMicroPaise, ')
          ..write('sourceProvider: $sourceProvider, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FinancialProfilesTable financialProfiles =
      $FinancialProfilesTable(this);
  late final $FinancialCategoriesTable financialCategories =
      $FinancialCategoriesTable(this);
  late final $FinancialAccountsTable financialAccounts =
      $FinancialAccountsTable(this);
  late final $FinancialItemsTable financialItems = $FinancialItemsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $ValuationHistoryTable valuationHistory =
      $ValuationHistoryTable(this);
  late final $RecurringTransactionsTable recurringTransactions =
      $RecurringTransactionsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $MutualFundSchemesTable mutualFundSchemes =
      $MutualFundSchemesTable(this);
  late final $NavHistoryTable navHistory = $NavHistoryTable(this);
  late final Index idxCategoryClassification = Index(
      'idx_category_classification',
      'CREATE INDEX idx_category_classification ON financial_categories (classification)');
  late final Index idxCategoryProfile = Index('idx_category_profile',
      'CREATE INDEX idx_category_profile ON financial_categories (profile_id)');
  late final Index idxAccountType = Index('idx_account_type',
      'CREATE INDEX idx_account_type ON financial_accounts (account_type)');
  late final Index idxAccountProfile = Index('idx_account_profile',
      'CREATE INDEX idx_account_profile ON financial_accounts (profile_id)');
  late final Index idxItemProfile = Index('idx_item_profile',
      'CREATE INDEX idx_item_profile ON financial_items (profile_id)');
  late final Index idxItemProfileType = Index('idx_item_profile_type',
      'CREATE INDEX idx_item_profile_type ON financial_items (profile_id, item_type)');
  late final Index idxItemTypeStatus = Index('idx_item_type_status',
      'CREATE INDEX idx_item_type_status ON financial_items (item_type, status)');
  late final Index idxItemExternalCode = Index('idx_item_external_code',
      'CREATE INDEX idx_item_external_code ON financial_items (external_code)');
  late final Index idxTransactionProfile = Index('idx_transaction_profile',
      'CREATE INDEX idx_transaction_profile ON transactions (profile_id)');
  late final Index idxTransactionProfileDate = Index(
      'idx_transaction_profile_date',
      'CREATE INDEX idx_transaction_profile_date ON transactions (profile_id, transaction_date)');
  late final Index idxTransactionDate = Index('idx_transaction_date',
      'CREATE INDEX idx_transaction_date ON transactions (transaction_date)');
  late final Index idxTransactionItem = Index('idx_transaction_item',
      'CREATE INDEX idx_transaction_item ON transactions (financial_item_id)');
  late final Index idxTransactionType = Index('idx_transaction_type',
      'CREATE INDEX idx_transaction_type ON transactions (transaction_type)');
  late final Index idxValuationDate = Index('idx_valuation_date',
      'CREATE INDEX idx_valuation_date ON valuation_history (valuation_date)');
  late final Index idxRecurringProfile = Index('idx_recurring_profile',
      'CREATE INDEX idx_recurring_profile ON recurring_transactions (profile_id)');
  late final Index idxRecurringStatus = Index('idx_recurring_status',
      'CREATE INDEX idx_recurring_status ON recurring_transactions (status)');
  late final Index idxRecurringItem = Index('idx_recurring_item',
      'CREATE INDEX idx_recurring_item ON recurring_transactions (financial_item_id)');
  late final Index idxSchemeName = Index('idx_scheme_name',
      'CREATE INDEX idx_scheme_name ON mutual_fund_schemes (scheme_name)');
  late final Index idxSchemeFundHouse = Index('idx_scheme_fund_house',
      'CREATE INDEX idx_scheme_fund_house ON mutual_fund_schemes (fund_house)');
  late final Index idxSchemeFavorite = Index('idx_scheme_favorite',
      'CREATE INDEX idx_scheme_favorite ON mutual_fund_schemes (is_favorite)');
  late final Index idxNavSchemeDate = Index('idx_nav_scheme_date',
      'CREATE INDEX idx_nav_scheme_date ON nav_history (scheme_code, nav_date)');
  late final ProfilesDao profilesDao = ProfilesDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
  late final FinancialItemsDao financialItemsDao =
      FinancialItemsDao(this as AppDatabase);
  late final TransactionsDao transactionsDao =
      TransactionsDao(this as AppDatabase);
  late final ValuationsDao valuationsDao = ValuationsDao(this as AppDatabase);
  late final RecurringTransactionsDao recurringTransactionsDao =
      RecurringTransactionsDao(this as AppDatabase);
  late final AppSettingsDao appSettingsDao =
      AppSettingsDao(this as AppDatabase);
  late final MutualFundDao mutualFundDao = MutualFundDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        financialProfiles,
        financialCategories,
        financialAccounts,
        financialItems,
        transactions,
        valuationHistory,
        recurringTransactions,
        appSettings,
        mutualFundSchemes,
        navHistory,
        idxCategoryClassification,
        idxCategoryProfile,
        idxAccountType,
        idxAccountProfile,
        idxItemProfile,
        idxItemProfileType,
        idxItemTypeStatus,
        idxItemExternalCode,
        idxTransactionProfile,
        idxTransactionProfileDate,
        idxTransactionDate,
        idxTransactionItem,
        idxTransactionType,
        idxValuationDate,
        idxRecurringProfile,
        idxRecurringStatus,
        idxRecurringItem,
        idxSchemeName,
        idxSchemeFundHouse,
        idxSchemeFavorite,
        idxNavSchemeDate
      ];
}

typedef $$FinancialProfilesTableCreateCompanionBuilder
    = FinancialProfilesCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> avatarPath,
  Value<String?> description,
  Value<String> relationship,
  Value<String> colorHex,
  Value<bool> isDefault,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$FinancialProfilesTableUpdateCompanionBuilder
    = FinancialProfilesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> avatarPath,
  Value<String?> description,
  Value<String> relationship,
  Value<String> colorHex,
  Value<bool> isDefault,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$FinancialProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialProfilesTable> {
  $$FinancialProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relationship => $composableBuilder(
      column: $table.relationship, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FinancialProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialProfilesTable> {
  $$FinancialProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relationship => $composableBuilder(
      column: $table.relationship,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FinancialProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialProfilesTable> {
  $$FinancialProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get relationship => $composableBuilder(
      column: $table.relationship, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FinancialProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FinancialProfilesTable,
    FinancialProfile,
    $$FinancialProfilesTableFilterComposer,
    $$FinancialProfilesTableOrderingComposer,
    $$FinancialProfilesTableAnnotationComposer,
    $$FinancialProfilesTableCreateCompanionBuilder,
    $$FinancialProfilesTableUpdateCompanionBuilder,
    (
      FinancialProfile,
      BaseReferences<_$AppDatabase, $FinancialProfilesTable, FinancialProfile>
    ),
    FinancialProfile,
    PrefetchHooks Function()> {
  $$FinancialProfilesTableTableManager(
      _$AppDatabase db, $FinancialProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialProfilesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> relationship = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FinancialProfilesCompanion(
            id: id,
            name: name,
            avatarPath: avatarPath,
            description: description,
            relationship: relationship,
            colorHex: colorHex,
            isDefault: isDefault,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> avatarPath = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> relationship = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FinancialProfilesCompanion.insert(
            id: id,
            name: name,
            avatarPath: avatarPath,
            description: description,
            relationship: relationship,
            colorHex: colorHex,
            isDefault: isDefault,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FinancialProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FinancialProfilesTable,
    FinancialProfile,
    $$FinancialProfilesTableFilterComposer,
    $$FinancialProfilesTableOrderingComposer,
    $$FinancialProfilesTableAnnotationComposer,
    $$FinancialProfilesTableCreateCompanionBuilder,
    $$FinancialProfilesTableUpdateCompanionBuilder,
    (
      FinancialProfile,
      BaseReferences<_$AppDatabase, $FinancialProfilesTable, FinancialProfile>
    ),
    FinancialProfile,
    PrefetchHooks Function()>;
typedef $$FinancialCategoriesTableCreateCompanionBuilder
    = FinancialCategoriesCompanion Function({
  Value<int> id,
  Value<int?> profileId,
  required String name,
  required String classification,
  Value<int?> parentId,
  Value<String?> icon,
  Value<String?> colorHex,
  Value<bool> isCustom,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$FinancialCategoriesTableUpdateCompanionBuilder
    = FinancialCategoriesCompanion Function({
  Value<int> id,
  Value<int?> profileId,
  Value<String> name,
  Value<String> classification,
  Value<int?> parentId,
  Value<String?> icon,
  Value<String?> colorHex,
  Value<bool> isCustom,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$FinancialCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialCategoriesTable> {
  $$FinancialCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get classification => $composableBuilder(
      column: $table.classification,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FinancialCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialCategoriesTable> {
  $$FinancialCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get classification => $composableBuilder(
      column: $table.classification,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCustom => $composableBuilder(
      column: $table.isCustom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FinancialCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialCategoriesTable> {
  $$FinancialCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get classification => $composableBuilder(
      column: $table.classification, builder: (column) => column);

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FinancialCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FinancialCategoriesTable,
    FinancialCategory,
    $$FinancialCategoriesTableFilterComposer,
    $$FinancialCategoriesTableOrderingComposer,
    $$FinancialCategoriesTableAnnotationComposer,
    $$FinancialCategoriesTableCreateCompanionBuilder,
    $$FinancialCategoriesTableUpdateCompanionBuilder,
    (
      FinancialCategory,
      BaseReferences<_$AppDatabase, $FinancialCategoriesTable,
          FinancialCategory>
    ),
    FinancialCategory,
    PrefetchHooks Function()> {
  $$FinancialCategoriesTableTableManager(
      _$AppDatabase db, $FinancialCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialCategoriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialCategoriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> classification = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FinancialCategoriesCompanion(
            id: id,
            profileId: profileId,
            name: name,
            classification: classification,
            parentId: parentId,
            icon: icon,
            colorHex: colorHex,
            isCustom: isCustom,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> profileId = const Value.absent(),
            required String name,
            required String classification,
            Value<int?> parentId = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<bool> isCustom = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FinancialCategoriesCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            classification: classification,
            parentId: parentId,
            icon: icon,
            colorHex: colorHex,
            isCustom: isCustom,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FinancialCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FinancialCategoriesTable,
    FinancialCategory,
    $$FinancialCategoriesTableFilterComposer,
    $$FinancialCategoriesTableOrderingComposer,
    $$FinancialCategoriesTableAnnotationComposer,
    $$FinancialCategoriesTableCreateCompanionBuilder,
    $$FinancialCategoriesTableUpdateCompanionBuilder,
    (
      FinancialCategory,
      BaseReferences<_$AppDatabase, $FinancialCategoriesTable,
          FinancialCategory>
    ),
    FinancialCategory,
    PrefetchHooks Function()>;
typedef $$FinancialAccountsTableCreateCompanionBuilder
    = FinancialAccountsCompanion Function({
  Value<int> id,
  required int profileId,
  required String name,
  required String accountType,
  Value<String?> accountNumberMasked,
  Value<String?> institutionName,
  Value<String> currencyCode,
  Value<int> openingBalancePaise,
  Value<int> currentBalancePaise,
  Value<bool> isArchived,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$FinancialAccountsTableUpdateCompanionBuilder
    = FinancialAccountsCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> name,
  Value<String> accountType,
  Value<String?> accountNumberMasked,
  Value<String?> institutionName,
  Value<String> currencyCode,
  Value<int> openingBalancePaise,
  Value<int> currentBalancePaise,
  Value<bool> isArchived,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$FinancialAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialAccountsTable> {
  $$FinancialAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountNumberMasked => $composableBuilder(
      column: $table.accountNumberMasked,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get institutionName => $composableBuilder(
      column: $table.institutionName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingBalancePaise => $composableBuilder(
      column: $table.openingBalancePaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentBalancePaise => $composableBuilder(
      column: $table.currentBalancePaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FinancialAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialAccountsTable> {
  $$FinancialAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountNumberMasked => $composableBuilder(
      column: $table.accountNumberMasked,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get institutionName => $composableBuilder(
      column: $table.institutionName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingBalancePaise => $composableBuilder(
      column: $table.openingBalancePaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentBalancePaise => $composableBuilder(
      column: $table.currentBalancePaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FinancialAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialAccountsTable> {
  $$FinancialAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
      column: $table.accountType, builder: (column) => column);

  GeneratedColumn<String> get accountNumberMasked => $composableBuilder(
      column: $table.accountNumberMasked, builder: (column) => column);

  GeneratedColumn<String> get institutionName => $composableBuilder(
      column: $table.institutionName, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
      column: $table.currencyCode, builder: (column) => column);

  GeneratedColumn<int> get openingBalancePaise => $composableBuilder(
      column: $table.openingBalancePaise, builder: (column) => column);

  GeneratedColumn<int> get currentBalancePaise => $composableBuilder(
      column: $table.currentBalancePaise, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FinancialAccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FinancialAccountsTable,
    FinancialAccount,
    $$FinancialAccountsTableFilterComposer,
    $$FinancialAccountsTableOrderingComposer,
    $$FinancialAccountsTableAnnotationComposer,
    $$FinancialAccountsTableCreateCompanionBuilder,
    $$FinancialAccountsTableUpdateCompanionBuilder,
    (
      FinancialAccount,
      BaseReferences<_$AppDatabase, $FinancialAccountsTable, FinancialAccount>
    ),
    FinancialAccount,
    PrefetchHooks Function()> {
  $$FinancialAccountsTableTableManager(
      _$AppDatabase db, $FinancialAccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialAccountsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> accountType = const Value.absent(),
            Value<String?> accountNumberMasked = const Value.absent(),
            Value<String?> institutionName = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<int> openingBalancePaise = const Value.absent(),
            Value<int> currentBalancePaise = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FinancialAccountsCompanion(
            id: id,
            profileId: profileId,
            name: name,
            accountType: accountType,
            accountNumberMasked: accountNumberMasked,
            institutionName: institutionName,
            currencyCode: currencyCode,
            openingBalancePaise: openingBalancePaise,
            currentBalancePaise: currentBalancePaise,
            isArchived: isArchived,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String name,
            required String accountType,
            Value<String?> accountNumberMasked = const Value.absent(),
            Value<String?> institutionName = const Value.absent(),
            Value<String> currencyCode = const Value.absent(),
            Value<int> openingBalancePaise = const Value.absent(),
            Value<int> currentBalancePaise = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FinancialAccountsCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            accountType: accountType,
            accountNumberMasked: accountNumberMasked,
            institutionName: institutionName,
            currencyCode: currencyCode,
            openingBalancePaise: openingBalancePaise,
            currentBalancePaise: currentBalancePaise,
            isArchived: isArchived,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FinancialAccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FinancialAccountsTable,
    FinancialAccount,
    $$FinancialAccountsTableFilterComposer,
    $$FinancialAccountsTableOrderingComposer,
    $$FinancialAccountsTableAnnotationComposer,
    $$FinancialAccountsTableCreateCompanionBuilder,
    $$FinancialAccountsTableUpdateCompanionBuilder,
    (
      FinancialAccount,
      BaseReferences<_$AppDatabase, $FinancialAccountsTable, FinancialAccount>
    ),
    FinancialAccount,
    PrefetchHooks Function()>;
typedef $$FinancialItemsTableCreateCompanionBuilder = FinancialItemsCompanion
    Function({
  Value<int> id,
  required int profileId,
  required String name,
  required String itemType,
  required String subType,
  required int categoryId,
  Value<int?> accountId,
  Value<String?> externalCode,
  Value<String> status,
  Value<int> initialValuePaise,
  Value<int> currentValuationPaise,
  Value<int> unitCountMicroUnits,
  Value<int?> interestRateBasisPoints,
  Value<DateTime?> startDate,
  Value<DateTime?> maturityDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$FinancialItemsTableUpdateCompanionBuilder = FinancialItemsCompanion
    Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> name,
  Value<String> itemType,
  Value<String> subType,
  Value<int> categoryId,
  Value<int?> accountId,
  Value<String?> externalCode,
  Value<String> status,
  Value<int> initialValuePaise,
  Value<int> currentValuationPaise,
  Value<int> unitCountMicroUnits,
  Value<int?> interestRateBasisPoints,
  Value<DateTime?> startDate,
  Value<DateTime?> maturityDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$FinancialItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialItemsTable> {
  $$FinancialItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subType => $composableBuilder(
      column: $table.subType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalCode => $composableBuilder(
      column: $table.externalCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get initialValuePaise => $composableBuilder(
      column: $table.initialValuePaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentValuationPaise => $composableBuilder(
      column: $table.currentValuationPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitCountMicroUnits => $composableBuilder(
      column: $table.unitCountMicroUnits,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get interestRateBasisPoints => $composableBuilder(
      column: $table.interestRateBasisPoints,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get maturityDate => $composableBuilder(
      column: $table.maturityDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FinancialItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialItemsTable> {
  $$FinancialItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subType => $composableBuilder(
      column: $table.subType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalCode => $composableBuilder(
      column: $table.externalCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get initialValuePaise => $composableBuilder(
      column: $table.initialValuePaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentValuationPaise => $composableBuilder(
      column: $table.currentValuationPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitCountMicroUnits => $composableBuilder(
      column: $table.unitCountMicroUnits,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get interestRateBasisPoints => $composableBuilder(
      column: $table.interestRateBasisPoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get maturityDate => $composableBuilder(
      column: $table.maturityDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FinancialItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialItemsTable> {
  $$FinancialItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get subType =>
      $composableBuilder(column: $table.subType, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get externalCode => $composableBuilder(
      column: $table.externalCode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get initialValuePaise => $composableBuilder(
      column: $table.initialValuePaise, builder: (column) => column);

  GeneratedColumn<int> get currentValuationPaise => $composableBuilder(
      column: $table.currentValuationPaise, builder: (column) => column);

  GeneratedColumn<int> get unitCountMicroUnits => $composableBuilder(
      column: $table.unitCountMicroUnits, builder: (column) => column);

  GeneratedColumn<int> get interestRateBasisPoints => $composableBuilder(
      column: $table.interestRateBasisPoints, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get maturityDate => $composableBuilder(
      column: $table.maturityDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FinancialItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FinancialItemsTable,
    FinancialItem,
    $$FinancialItemsTableFilterComposer,
    $$FinancialItemsTableOrderingComposer,
    $$FinancialItemsTableAnnotationComposer,
    $$FinancialItemsTableCreateCompanionBuilder,
    $$FinancialItemsTableUpdateCompanionBuilder,
    (
      FinancialItem,
      BaseReferences<_$AppDatabase, $FinancialItemsTable, FinancialItem>
    ),
    FinancialItem,
    PrefetchHooks Function()> {
  $$FinancialItemsTableTableManager(
      _$AppDatabase db, $FinancialItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<String> subType = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<int?> accountId = const Value.absent(),
            Value<String?> externalCode = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> initialValuePaise = const Value.absent(),
            Value<int> currentValuationPaise = const Value.absent(),
            Value<int> unitCountMicroUnits = const Value.absent(),
            Value<int?> interestRateBasisPoints = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> maturityDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FinancialItemsCompanion(
            id: id,
            profileId: profileId,
            name: name,
            itemType: itemType,
            subType: subType,
            categoryId: categoryId,
            accountId: accountId,
            externalCode: externalCode,
            status: status,
            initialValuePaise: initialValuePaise,
            currentValuationPaise: currentValuationPaise,
            unitCountMicroUnits: unitCountMicroUnits,
            interestRateBasisPoints: interestRateBasisPoints,
            startDate: startDate,
            maturityDate: maturityDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String name,
            required String itemType,
            required String subType,
            required int categoryId,
            Value<int?> accountId = const Value.absent(),
            Value<String?> externalCode = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> initialValuePaise = const Value.absent(),
            Value<int> currentValuationPaise = const Value.absent(),
            Value<int> unitCountMicroUnits = const Value.absent(),
            Value<int?> interestRateBasisPoints = const Value.absent(),
            Value<DateTime?> startDate = const Value.absent(),
            Value<DateTime?> maturityDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              FinancialItemsCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            itemType: itemType,
            subType: subType,
            categoryId: categoryId,
            accountId: accountId,
            externalCode: externalCode,
            status: status,
            initialValuePaise: initialValuePaise,
            currentValuationPaise: currentValuationPaise,
            unitCountMicroUnits: unitCountMicroUnits,
            interestRateBasisPoints: interestRateBasisPoints,
            startDate: startDate,
            maturityDate: maturityDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FinancialItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FinancialItemsTable,
    FinancialItem,
    $$FinancialItemsTableFilterComposer,
    $$FinancialItemsTableOrderingComposer,
    $$FinancialItemsTableAnnotationComposer,
    $$FinancialItemsTableCreateCompanionBuilder,
    $$FinancialItemsTableUpdateCompanionBuilder,
    (
      FinancialItem,
      BaseReferences<_$AppDatabase, $FinancialItemsTable, FinancialItem>
    ),
    FinancialItem,
    PrefetchHooks Function()>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  required int profileId,
  required String transactionType,
  required int categoryId,
  Value<int?> financialItemId,
  Value<int?> fromAccountId,
  Value<int?> toAccountId,
  required DateTime transactionDate,
  required int amountPaise,
  Value<int?> unitsMicroUnits,
  Value<int?> unitPriceMicroPaise,
  Value<String> source,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> transactionType,
  Value<int> categoryId,
  Value<int?> financialItemId,
  Value<int?> fromAccountId,
  Value<int?> toAccountId,
  Value<DateTime> transactionDate,
  Value<int> amountPaise,
  Value<int?> unitsMicroUnits,
  Value<int?> unitPriceMicroPaise,
  Value<String> source,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get financialItemId => $composableBuilder(
      column: $table.financialItemId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fromAccountId => $composableBuilder(
      column: $table.fromAccountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get toAccountId => $composableBuilder(
      column: $table.toAccountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitsMicroUnits => $composableBuilder(
      column: $table.unitsMicroUnits,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitPriceMicroPaise => $composableBuilder(
      column: $table.unitPriceMicroPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transactionType => $composableBuilder(
      column: $table.transactionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get financialItemId => $composableBuilder(
      column: $table.financialItemId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fromAccountId => $composableBuilder(
      column: $table.fromAccountId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get toAccountId => $composableBuilder(
      column: $table.toAccountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitsMicroUnits => $composableBuilder(
      column: $table.unitsMicroUnits,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitPriceMicroPaise => $composableBuilder(
      column: $table.unitPriceMicroPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
      column: $table.transactionType, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get financialItemId => $composableBuilder(
      column: $table.financialItemId, builder: (column) => column);

  GeneratedColumn<int> get fromAccountId => $composableBuilder(
      column: $table.fromAccountId, builder: (column) => column);

  GeneratedColumn<int> get toAccountId => $composableBuilder(
      column: $table.toAccountId, builder: (column) => column);

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
      column: $table.transactionDate, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  GeneratedColumn<int> get unitsMicroUnits => $composableBuilder(
      column: $table.unitsMicroUnits, builder: (column) => column);

  GeneratedColumn<int> get unitPriceMicroPaise => $composableBuilder(
      column: $table.unitPriceMicroPaise, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> transactionType = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<int?> financialItemId = const Value.absent(),
            Value<int?> fromAccountId = const Value.absent(),
            Value<int?> toAccountId = const Value.absent(),
            Value<DateTime> transactionDate = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<int?> unitsMicroUnits = const Value.absent(),
            Value<int?> unitPriceMicroPaise = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            profileId: profileId,
            transactionType: transactionType,
            categoryId: categoryId,
            financialItemId: financialItemId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            transactionDate: transactionDate,
            amountPaise: amountPaise,
            unitsMicroUnits: unitsMicroUnits,
            unitPriceMicroPaise: unitPriceMicroPaise,
            source: source,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String transactionType,
            required int categoryId,
            Value<int?> financialItemId = const Value.absent(),
            Value<int?> fromAccountId = const Value.absent(),
            Value<int?> toAccountId = const Value.absent(),
            required DateTime transactionDate,
            required int amountPaise,
            Value<int?> unitsMicroUnits = const Value.absent(),
            Value<int?> unitPriceMicroPaise = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            profileId: profileId,
            transactionType: transactionType,
            categoryId: categoryId,
            financialItemId: financialItemId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            transactionDate: transactionDate,
            amountPaise: amountPaise,
            unitsMicroUnits: unitsMicroUnits,
            unitPriceMicroPaise: unitPriceMicroPaise,
            source: source,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()>;
typedef $$ValuationHistoryTableCreateCompanionBuilder
    = ValuationHistoryCompanion Function({
  Value<int> id,
  required int financialItemId,
  required DateTime valuationDate,
  required int valuationPaise,
  Value<int?> unitPriceMicroPaise,
  Value<String> sourceProvider,
  Value<DateTime> recordedAt,
});
typedef $$ValuationHistoryTableUpdateCompanionBuilder
    = ValuationHistoryCompanion Function({
  Value<int> id,
  Value<int> financialItemId,
  Value<DateTime> valuationDate,
  Value<int> valuationPaise,
  Value<int?> unitPriceMicroPaise,
  Value<String> sourceProvider,
  Value<DateTime> recordedAt,
});

class $$ValuationHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ValuationHistoryTable> {
  $$ValuationHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get financialItemId => $composableBuilder(
      column: $table.financialItemId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get valuationDate => $composableBuilder(
      column: $table.valuationDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get valuationPaise => $composableBuilder(
      column: $table.valuationPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unitPriceMicroPaise => $composableBuilder(
      column: $table.unitPriceMicroPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceProvider => $composableBuilder(
      column: $table.sourceProvider,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));
}

class $$ValuationHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ValuationHistoryTable> {
  $$ValuationHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get financialItemId => $composableBuilder(
      column: $table.financialItemId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get valuationDate => $composableBuilder(
      column: $table.valuationDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get valuationPaise => $composableBuilder(
      column: $table.valuationPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unitPriceMicroPaise => $composableBuilder(
      column: $table.unitPriceMicroPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceProvider => $composableBuilder(
      column: $table.sourceProvider,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));
}

class $$ValuationHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ValuationHistoryTable> {
  $$ValuationHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get financialItemId => $composableBuilder(
      column: $table.financialItemId, builder: (column) => column);

  GeneratedColumn<DateTime> get valuationDate => $composableBuilder(
      column: $table.valuationDate, builder: (column) => column);

  GeneratedColumn<int> get valuationPaise => $composableBuilder(
      column: $table.valuationPaise, builder: (column) => column);

  GeneratedColumn<int> get unitPriceMicroPaise => $composableBuilder(
      column: $table.unitPriceMicroPaise, builder: (column) => column);

  GeneratedColumn<String> get sourceProvider => $composableBuilder(
      column: $table.sourceProvider, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);
}

class $$ValuationHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ValuationHistoryTable,
    ValuationHistoryData,
    $$ValuationHistoryTableFilterComposer,
    $$ValuationHistoryTableOrderingComposer,
    $$ValuationHistoryTableAnnotationComposer,
    $$ValuationHistoryTableCreateCompanionBuilder,
    $$ValuationHistoryTableUpdateCompanionBuilder,
    (
      ValuationHistoryData,
      BaseReferences<_$AppDatabase, $ValuationHistoryTable,
          ValuationHistoryData>
    ),
    ValuationHistoryData,
    PrefetchHooks Function()> {
  $$ValuationHistoryTableTableManager(
      _$AppDatabase db, $ValuationHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ValuationHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ValuationHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ValuationHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> financialItemId = const Value.absent(),
            Value<DateTime> valuationDate = const Value.absent(),
            Value<int> valuationPaise = const Value.absent(),
            Value<int?> unitPriceMicroPaise = const Value.absent(),
            Value<String> sourceProvider = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
          }) =>
              ValuationHistoryCompanion(
            id: id,
            financialItemId: financialItemId,
            valuationDate: valuationDate,
            valuationPaise: valuationPaise,
            unitPriceMicroPaise: unitPriceMicroPaise,
            sourceProvider: sourceProvider,
            recordedAt: recordedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int financialItemId,
            required DateTime valuationDate,
            required int valuationPaise,
            Value<int?> unitPriceMicroPaise = const Value.absent(),
            Value<String> sourceProvider = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
          }) =>
              ValuationHistoryCompanion.insert(
            id: id,
            financialItemId: financialItemId,
            valuationDate: valuationDate,
            valuationPaise: valuationPaise,
            unitPriceMicroPaise: unitPriceMicroPaise,
            sourceProvider: sourceProvider,
            recordedAt: recordedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ValuationHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ValuationHistoryTable,
    ValuationHistoryData,
    $$ValuationHistoryTableFilterComposer,
    $$ValuationHistoryTableOrderingComposer,
    $$ValuationHistoryTableAnnotationComposer,
    $$ValuationHistoryTableCreateCompanionBuilder,
    $$ValuationHistoryTableUpdateCompanionBuilder,
    (
      ValuationHistoryData,
      BaseReferences<_$AppDatabase, $ValuationHistoryTable,
          ValuationHistoryData>
    ),
    ValuationHistoryData,
    PrefetchHooks Function()>;
typedef $$RecurringTransactionsTableCreateCompanionBuilder
    = RecurringTransactionsCompanion Function({
  Value<int> id,
  required int profileId,
  required String name,
  required String recurringType,
  Value<int?> financialItemId,
  Value<int?> fromAccountId,
  Value<int?> toAccountId,
  required int categoryId,
  required int amountPaise,
  required String frequency,
  required int scheduledDay,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<String> status,
  Value<DateTime?> lastProcessedDate,
  Value<DateTime?> nextDueDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$RecurringTransactionsTableUpdateCompanionBuilder
    = RecurringTransactionsCompanion Function({
  Value<int> id,
  Value<int> profileId,
  Value<String> name,
  Value<String> recurringType,
  Value<int?> financialItemId,
  Value<int?> fromAccountId,
  Value<int?> toAccountId,
  Value<int> categoryId,
  Value<int> amountPaise,
  Value<String> frequency,
  Value<int> scheduledDay,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<String> status,
  Value<DateTime?> lastProcessedDate,
  Value<DateTime?> nextDueDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$RecurringTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringTransactionsTable> {
  $$RecurringTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurringType => $composableBuilder(
      column: $table.recurringType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get financialItemId => $composableBuilder(
      column: $table.financialItemId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fromAccountId => $composableBuilder(
      column: $table.fromAccountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get toAccountId => $composableBuilder(
      column: $table.toAccountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduledDay => $composableBuilder(
      column: $table.scheduledDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastProcessedDate => $composableBuilder(
      column: $table.lastProcessedDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RecurringTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringTransactionsTable> {
  $$RecurringTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurringType => $composableBuilder(
      column: $table.recurringType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get financialItemId => $composableBuilder(
      column: $table.financialItemId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fromAccountId => $composableBuilder(
      column: $table.fromAccountId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get toAccountId => $composableBuilder(
      column: $table.toAccountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduledDay => $composableBuilder(
      column: $table.scheduledDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastProcessedDate => $composableBuilder(
      column: $table.lastProcessedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RecurringTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringTransactionsTable> {
  $$RecurringTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get recurringType => $composableBuilder(
      column: $table.recurringType, builder: (column) => column);

  GeneratedColumn<int> get financialItemId => $composableBuilder(
      column: $table.financialItemId, builder: (column) => column);

  GeneratedColumn<int> get fromAccountId => $composableBuilder(
      column: $table.fromAccountId, builder: (column) => column);

  GeneratedColumn<int> get toAccountId => $composableBuilder(
      column: $table.toAccountId, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
      column: $table.amountPaise, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get scheduledDay => $composableBuilder(
      column: $table.scheduledDay, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastProcessedDate => $composableBuilder(
      column: $table.lastProcessedDate, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDueDate => $composableBuilder(
      column: $table.nextDueDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RecurringTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringTransactionsTable,
    RecurringTransaction,
    $$RecurringTransactionsTableFilterComposer,
    $$RecurringTransactionsTableOrderingComposer,
    $$RecurringTransactionsTableAnnotationComposer,
    $$RecurringTransactionsTableCreateCompanionBuilder,
    $$RecurringTransactionsTableUpdateCompanionBuilder,
    (
      RecurringTransaction,
      BaseReferences<_$AppDatabase, $RecurringTransactionsTable,
          RecurringTransaction>
    ),
    RecurringTransaction,
    PrefetchHooks Function()> {
  $$RecurringTransactionsTableTableManager(
      _$AppDatabase db, $RecurringTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTransactionsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringTransactionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> profileId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> recurringType = const Value.absent(),
            Value<int?> financialItemId = const Value.absent(),
            Value<int?> fromAccountId = const Value.absent(),
            Value<int?> toAccountId = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<int> amountPaise = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<int> scheduledDay = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> lastProcessedDate = const Value.absent(),
            Value<DateTime?> nextDueDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              RecurringTransactionsCompanion(
            id: id,
            profileId: profileId,
            name: name,
            recurringType: recurringType,
            financialItemId: financialItemId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            categoryId: categoryId,
            amountPaise: amountPaise,
            frequency: frequency,
            scheduledDay: scheduledDay,
            startDate: startDate,
            endDate: endDate,
            status: status,
            lastProcessedDate: lastProcessedDate,
            nextDueDate: nextDueDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int profileId,
            required String name,
            required String recurringType,
            Value<int?> financialItemId = const Value.absent(),
            Value<int?> fromAccountId = const Value.absent(),
            Value<int?> toAccountId = const Value.absent(),
            required int categoryId,
            required int amountPaise,
            required String frequency,
            required int scheduledDay,
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> lastProcessedDate = const Value.absent(),
            Value<DateTime?> nextDueDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              RecurringTransactionsCompanion.insert(
            id: id,
            profileId: profileId,
            name: name,
            recurringType: recurringType,
            financialItemId: financialItemId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            categoryId: categoryId,
            amountPaise: amountPaise,
            frequency: frequency,
            scheduledDay: scheduledDay,
            startDate: startDate,
            endDate: endDate,
            status: status,
            lastProcessedDate: lastProcessedDate,
            nextDueDate: nextDueDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecurringTransactionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $RecurringTransactionsTable,
        RecurringTransaction,
        $$RecurringTransactionsTableFilterComposer,
        $$RecurringTransactionsTableOrderingComposer,
        $$RecurringTransactionsTableAnnotationComposer,
        $$RecurringTransactionsTableCreateCompanionBuilder,
        $$RecurringTransactionsTableUpdateCompanionBuilder,
        (
          RecurringTransaction,
          BaseReferences<_$AppDatabase, $RecurringTransactionsTable,
              RecurringTransaction>
        ),
        RecurringTransaction,
        PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$MutualFundSchemesTableCreateCompanionBuilder
    = MutualFundSchemesCompanion Function({
  Value<int> schemeCode,
  required String schemeName,
  Value<String?> fundHouse,
  Value<String?> schemeType,
  Value<String?> schemeCategory,
  Value<String?> planType,
  Value<String?> optionType,
  Value<String?> isin,
  Value<int?> latestNavMicroPaise,
  Value<DateTime?> latestNavDate,
  Value<bool> isFavorite,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$MutualFundSchemesTableUpdateCompanionBuilder
    = MutualFundSchemesCompanion Function({
  Value<int> schemeCode,
  Value<String> schemeName,
  Value<String?> fundHouse,
  Value<String?> schemeType,
  Value<String?> schemeCategory,
  Value<String?> planType,
  Value<String?> optionType,
  Value<String?> isin,
  Value<int?> latestNavMicroPaise,
  Value<DateTime?> latestNavDate,
  Value<bool> isFavorite,
  Value<DateTime?> lastSyncedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$MutualFundSchemesTableFilterComposer
    extends Composer<_$AppDatabase, $MutualFundSchemesTable> {
  $$MutualFundSchemesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get schemeCode => $composableBuilder(
      column: $table.schemeCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schemeName => $composableBuilder(
      column: $table.schemeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fundHouse => $composableBuilder(
      column: $table.fundHouse, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schemeType => $composableBuilder(
      column: $table.schemeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get schemeCategory => $composableBuilder(
      column: $table.schemeCategory,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planType => $composableBuilder(
      column: $table.planType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get optionType => $composableBuilder(
      column: $table.optionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get isin => $composableBuilder(
      column: $table.isin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get latestNavMicroPaise => $composableBuilder(
      column: $table.latestNavMicroPaise,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get latestNavDate => $composableBuilder(
      column: $table.latestNavDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MutualFundSchemesTableOrderingComposer
    extends Composer<_$AppDatabase, $MutualFundSchemesTable> {
  $$MutualFundSchemesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get schemeCode => $composableBuilder(
      column: $table.schemeCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schemeName => $composableBuilder(
      column: $table.schemeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fundHouse => $composableBuilder(
      column: $table.fundHouse, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schemeType => $composableBuilder(
      column: $table.schemeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get schemeCategory => $composableBuilder(
      column: $table.schemeCategory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planType => $composableBuilder(
      column: $table.planType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get optionType => $composableBuilder(
      column: $table.optionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get isin => $composableBuilder(
      column: $table.isin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get latestNavMicroPaise => $composableBuilder(
      column: $table.latestNavMicroPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get latestNavDate => $composableBuilder(
      column: $table.latestNavDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MutualFundSchemesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MutualFundSchemesTable> {
  $$MutualFundSchemesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get schemeCode => $composableBuilder(
      column: $table.schemeCode, builder: (column) => column);

  GeneratedColumn<String> get schemeName => $composableBuilder(
      column: $table.schemeName, builder: (column) => column);

  GeneratedColumn<String> get fundHouse =>
      $composableBuilder(column: $table.fundHouse, builder: (column) => column);

  GeneratedColumn<String> get schemeType => $composableBuilder(
      column: $table.schemeType, builder: (column) => column);

  GeneratedColumn<String> get schemeCategory => $composableBuilder(
      column: $table.schemeCategory, builder: (column) => column);

  GeneratedColumn<String> get planType =>
      $composableBuilder(column: $table.planType, builder: (column) => column);

  GeneratedColumn<String> get optionType => $composableBuilder(
      column: $table.optionType, builder: (column) => column);

  GeneratedColumn<String> get isin =>
      $composableBuilder(column: $table.isin, builder: (column) => column);

  GeneratedColumn<int> get latestNavMicroPaise => $composableBuilder(
      column: $table.latestNavMicroPaise, builder: (column) => column);

  GeneratedColumn<DateTime> get latestNavDate => $composableBuilder(
      column: $table.latestNavDate, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
      column: $table.lastSyncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MutualFundSchemesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MutualFundSchemesTable,
    MutualFundScheme,
    $$MutualFundSchemesTableFilterComposer,
    $$MutualFundSchemesTableOrderingComposer,
    $$MutualFundSchemesTableAnnotationComposer,
    $$MutualFundSchemesTableCreateCompanionBuilder,
    $$MutualFundSchemesTableUpdateCompanionBuilder,
    (
      MutualFundScheme,
      BaseReferences<_$AppDatabase, $MutualFundSchemesTable, MutualFundScheme>
    ),
    MutualFundScheme,
    PrefetchHooks Function()> {
  $$MutualFundSchemesTableTableManager(
      _$AppDatabase db, $MutualFundSchemesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MutualFundSchemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MutualFundSchemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MutualFundSchemesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> schemeCode = const Value.absent(),
            Value<String> schemeName = const Value.absent(),
            Value<String?> fundHouse = const Value.absent(),
            Value<String?> schemeType = const Value.absent(),
            Value<String?> schemeCategory = const Value.absent(),
            Value<String?> planType = const Value.absent(),
            Value<String?> optionType = const Value.absent(),
            Value<String?> isin = const Value.absent(),
            Value<int?> latestNavMicroPaise = const Value.absent(),
            Value<DateTime?> latestNavDate = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MutualFundSchemesCompanion(
            schemeCode: schemeCode,
            schemeName: schemeName,
            fundHouse: fundHouse,
            schemeType: schemeType,
            schemeCategory: schemeCategory,
            planType: planType,
            optionType: optionType,
            isin: isin,
            latestNavMicroPaise: latestNavMicroPaise,
            latestNavDate: latestNavDate,
            isFavorite: isFavorite,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> schemeCode = const Value.absent(),
            required String schemeName,
            Value<String?> fundHouse = const Value.absent(),
            Value<String?> schemeType = const Value.absent(),
            Value<String?> schemeCategory = const Value.absent(),
            Value<String?> planType = const Value.absent(),
            Value<String?> optionType = const Value.absent(),
            Value<String?> isin = const Value.absent(),
            Value<int?> latestNavMicroPaise = const Value.absent(),
            Value<DateTime?> latestNavDate = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<DateTime?> lastSyncedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MutualFundSchemesCompanion.insert(
            schemeCode: schemeCode,
            schemeName: schemeName,
            fundHouse: fundHouse,
            schemeType: schemeType,
            schemeCategory: schemeCategory,
            planType: planType,
            optionType: optionType,
            isin: isin,
            latestNavMicroPaise: latestNavMicroPaise,
            latestNavDate: latestNavDate,
            isFavorite: isFavorite,
            lastSyncedAt: lastSyncedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MutualFundSchemesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MutualFundSchemesTable,
    MutualFundScheme,
    $$MutualFundSchemesTableFilterComposer,
    $$MutualFundSchemesTableOrderingComposer,
    $$MutualFundSchemesTableAnnotationComposer,
    $$MutualFundSchemesTableCreateCompanionBuilder,
    $$MutualFundSchemesTableUpdateCompanionBuilder,
    (
      MutualFundScheme,
      BaseReferences<_$AppDatabase, $MutualFundSchemesTable, MutualFundScheme>
    ),
    MutualFundScheme,
    PrefetchHooks Function()>;
typedef $$NavHistoryTableCreateCompanionBuilder = NavHistoryCompanion Function({
  Value<int> id,
  required int schemeCode,
  required DateTime navDate,
  required int navMicroPaise,
  Value<String> sourceProvider,
  Value<DateTime> createdAt,
});
typedef $$NavHistoryTableUpdateCompanionBuilder = NavHistoryCompanion Function({
  Value<int> id,
  Value<int> schemeCode,
  Value<DateTime> navDate,
  Value<int> navMicroPaise,
  Value<String> sourceProvider,
  Value<DateTime> createdAt,
});

class $$NavHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $NavHistoryTable> {
  $$NavHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get schemeCode => $composableBuilder(
      column: $table.schemeCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get navDate => $composableBuilder(
      column: $table.navDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get navMicroPaise => $composableBuilder(
      column: $table.navMicroPaise, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceProvider => $composableBuilder(
      column: $table.sourceProvider,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$NavHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $NavHistoryTable> {
  $$NavHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get schemeCode => $composableBuilder(
      column: $table.schemeCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get navDate => $composableBuilder(
      column: $table.navDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get navMicroPaise => $composableBuilder(
      column: $table.navMicroPaise,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceProvider => $composableBuilder(
      column: $table.sourceProvider,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$NavHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $NavHistoryTable> {
  $$NavHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get schemeCode => $composableBuilder(
      column: $table.schemeCode, builder: (column) => column);

  GeneratedColumn<DateTime> get navDate =>
      $composableBuilder(column: $table.navDate, builder: (column) => column);

  GeneratedColumn<int> get navMicroPaise => $composableBuilder(
      column: $table.navMicroPaise, builder: (column) => column);

  GeneratedColumn<String> get sourceProvider => $composableBuilder(
      column: $table.sourceProvider, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NavHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NavHistoryTable,
    NavHistoryData,
    $$NavHistoryTableFilterComposer,
    $$NavHistoryTableOrderingComposer,
    $$NavHistoryTableAnnotationComposer,
    $$NavHistoryTableCreateCompanionBuilder,
    $$NavHistoryTableUpdateCompanionBuilder,
    (
      NavHistoryData,
      BaseReferences<_$AppDatabase, $NavHistoryTable, NavHistoryData>
    ),
    NavHistoryData,
    PrefetchHooks Function()> {
  $$NavHistoryTableTableManager(_$AppDatabase db, $NavHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NavHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NavHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NavHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> schemeCode = const Value.absent(),
            Value<DateTime> navDate = const Value.absent(),
            Value<int> navMicroPaise = const Value.absent(),
            Value<String> sourceProvider = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NavHistoryCompanion(
            id: id,
            schemeCode: schemeCode,
            navDate: navDate,
            navMicroPaise: navMicroPaise,
            sourceProvider: sourceProvider,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int schemeCode,
            required DateTime navDate,
            required int navMicroPaise,
            Value<String> sourceProvider = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NavHistoryCompanion.insert(
            id: id,
            schemeCode: schemeCode,
            navDate: navDate,
            navMicroPaise: navMicroPaise,
            sourceProvider: sourceProvider,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NavHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NavHistoryTable,
    NavHistoryData,
    $$NavHistoryTableFilterComposer,
    $$NavHistoryTableOrderingComposer,
    $$NavHistoryTableAnnotationComposer,
    $$NavHistoryTableCreateCompanionBuilder,
    $$NavHistoryTableUpdateCompanionBuilder,
    (
      NavHistoryData,
      BaseReferences<_$AppDatabase, $NavHistoryTable, NavHistoryData>
    ),
    NavHistoryData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FinancialProfilesTableTableManager get financialProfiles =>
      $$FinancialProfilesTableTableManager(_db, _db.financialProfiles);
  $$FinancialCategoriesTableTableManager get financialCategories =>
      $$FinancialCategoriesTableTableManager(_db, _db.financialCategories);
  $$FinancialAccountsTableTableManager get financialAccounts =>
      $$FinancialAccountsTableTableManager(_db, _db.financialAccounts);
  $$FinancialItemsTableTableManager get financialItems =>
      $$FinancialItemsTableTableManager(_db, _db.financialItems);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$ValuationHistoryTableTableManager get valuationHistory =>
      $$ValuationHistoryTableTableManager(_db, _db.valuationHistory);
  $$RecurringTransactionsTableTableManager get recurringTransactions =>
      $$RecurringTransactionsTableTableManager(_db, _db.recurringTransactions);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$MutualFundSchemesTableTableManager get mutualFundSchemes =>
      $$MutualFundSchemesTableTableManager(_db, _db.mutualFundSchemes);
  $$NavHistoryTableTableManager get navHistory =>
      $$NavHistoryTableTableManager(_db, _db.navHistory);
}
