const std = @import("std");
const fmt = std.fmt;
const uefi = std.os.uefi;

pub fn print(comptime format: [:0]const u8, args: anytype) void {
    const con_out = uefi.system_table.con_out.?;

    var buf8: [256]u8 = undefined;
    const msg = fmt.bufPrintZ(buf8[0..], format, args) catch unreachable;

    var buf16: [256]u16 = undefined;
    const idx = std.unicode.utf8ToUtf16Le(buf16[0..], msg) catch unreachable;
    buf16[idx] = 0;
    _ = con_out.outputString(@ptrCast([*:0]const u16, buf16[0..]));
}

pub fn println(comptime format: [:0]const u8, args: anytype) void {
    print(format ++ "\r\n", args);
}

pub fn printIndented(indent: usize, comptime format: [:0]const u8, args: anytype) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        print(" ", .{});
    }
    print(format, args);
}

pub fn printlnIndented(indent: usize, comptime format: [:0]const u8, args: anytype) void {
    printIndented(indent, format ++ "\r\n", args);
}

pub fn printGuid(guid: uefi.Guid) void {
    print("{x:0>8}-{x:0>4}-{X:0>4}-{X:0>2}{X:0>2}-{s:0>12}", .{
        guid.time_low,
        guid.time_mid,
        guid.time_high_and_version,
        guid.clock_seq_high_and_reserved,
        guid.clock_seq_low,
        fmt.fmtSliceHexLower(guid.node[0..]),
    });
}

pub fn dumpHex(bytes: [*]const u8, count: usize) void {
    var k: usize = 0;
    while (k < count) : (k += 1) {
        if (k != 0 and @mod(k, 16) == 0) {
            println("", .{});
        }
        print("{X:0>2} ", .{bytes[k]});
    }
}
