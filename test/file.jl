module FileTest

using Avro
using Avro.File
using Avro.Generic

using Base.Test

const TEST_RECORD_SCHEMA = Schemas.RecordSchema(
    Schemas.FullName("test"),
    [
        Schemas.Field("a", 0, Schemas.LONG),
        Schemas.Field("b", 1, Schemas.STRING)
        ]
    )

records = [
    GenericRecord(TEST_RECORD_SCHEMA, [Int64(26), "foo"])
    GenericRecord(TEST_RECORD_SCHEMA, [Int64(27), "foo"])
]

buffer = IOBuffer()
file_writer = File.create(TEST_RECORD_SCHEMA, buffer)
for record in records
    File.append(file_writer, record)
end
File.write_block(file_writer)

contents = takebuf_array(buffer)
@test contents[1:4] == Avro.File.OBJECT_CONTAINER_FILE_MAGIC
# This block should have 2 records with 10 bytes of data
@test contents[end - 27] == 0x04 # 2 records
@test contents[end - 26] == 0x14 # 10 bytes
@test contents[end - 25:end - 21] == [0x34, 0x06, 0x66, 0x6f, 0x6f]
@test contents[end - 20:end - 16] == [0x36, 0x06, 0x66, 0x6f, 0x6f]
@test contents[end - 15:end] == file_writer.sync_marker

end
