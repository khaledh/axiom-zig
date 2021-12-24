const SystemTable = @import("std").os.uefi.tables.SystemTable;
const io = @import("../io.zig");

pub fn dumpUefiFirmwareVersion(st: *SystemTable) void {
    const con_out = st.con_out.?;

    io.println("", .{});
    io.print("UEFI Firmware Version: {}.{} (", .{
        st.hdr.revision >> 16,
        st.hdr.revision & 0xFFFF,
    });
    _ = con_out.outputString(st.firmware_vendor);
    io.println(", {}.{})", .{
        st.firmware_revision >> 16,
        st.firmware_revision & 0xFFFF,
    });
}
