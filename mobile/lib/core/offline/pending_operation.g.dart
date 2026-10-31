part of 'pending_operation.dart';

class PendingOperationAdapter extends TypeAdapter<PendingOperation> {
  @override
  final int typeId = 0;

  @override
  PendingOperation read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++)
        reader.readByte(): reader.read(),
    };

    return PendingOperation(
      clientId: fields[0] as String,
      operationType: fields[1] as String,
      entityType: fields[2] as String,
      entityId: fields[3] as String?,
      payload: fields[4] as String,
      retryCount: fields[5] as int,
      timestamp: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PendingOperation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.clientId)
      ..writeByte(1)
      ..write(obj.operationType)
      ..writeByte(2)
      ..write(obj.entityType)
      ..writeByte(3)
      ..write(obj.entityId)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.timestamp);
  }
}
