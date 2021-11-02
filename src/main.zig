const std = @import("std");
const uefi = std.os.uefi;
const W = std.unicode.utf8ToUtf16LeStringLiteral;

pub fn main() void {
    const con_out = uefi.system_table.con_out.?;

    _ = con_out.reset(false);
    _ = con_out.outputString(W("Hello, World!"));

    while (true) {
        asm volatile (
            "hlt"
        );
    }
}
