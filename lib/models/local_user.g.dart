// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalUserAdapter extends TypeAdapter<LocalUser> {
  @override
  final int typeId = 0;

  @override
  LocalUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalUser()
      ..uid = fields[0] as String
      ..email = fields[1] as String
      ..firstName = fields[2] as String
      ..lastName = fields[3] as String
      ..dateOfBirth = fields[4] as String
      ..cachedIdToken = fields[5] as String?
      ..tokenCachedAt = fields[6] as DateTime?
      ..hasCompletedDiagnostic = fields[7] as bool
      ..startingLevel = fields[8] as String?
      ..createdAt = fields[9] as DateTime
      ..lastSeenAt = fields[10] as DateTime;
  }

  @override
  void write(BinaryWriter writer, LocalUser obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.lastName)
      ..writeByte(4)
      ..write(obj.dateOfBirth)
      ..writeByte(5)
      ..write(obj.cachedIdToken)
      ..writeByte(6)
      ..write(obj.tokenCachedAt)
      ..writeByte(7)
      ..write(obj.hasCompletedDiagnostic)
      ..writeByte(8)
      ..write(obj.startingLevel)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.lastSeenAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
