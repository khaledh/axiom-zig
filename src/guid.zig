const fmt = @import("std").fmt;
const uefi = @import("std").os.uefi;

pub fn parseGuid(comptime str: []const u8) uefi.Guid {
    @setEvalBranchQuota(4000);
    const p1 = fmt.parseUnsigned(u32, str[0..8], 16) catch unreachable;
    const p2 = fmt.parseUnsigned(u16, str[9..13], 16) catch unreachable;
    const p3 = fmt.parseUnsigned(u16, str[14..18], 16) catch unreachable;
    const p4 = fmt.parseUnsigned(u8, str[19..21], 16) catch unreachable;
    const p5 = fmt.parseUnsigned(u8, str[21..23], 16) catch unreachable;
    const p6a = fmt.parseUnsigned(u8, str[24..26], 16) catch unreachable;
    const p6b = fmt.parseUnsigned(u8, str[26..28], 16) catch unreachable;
    const p6c = fmt.parseUnsigned(u8, str[28..30], 16) catch unreachable;
    const p6d = fmt.parseUnsigned(u8, str[30..32], 16) catch unreachable;
    const p6e = fmt.parseUnsigned(u8, str[32..34], 16) catch unreachable;
    const p6f = fmt.parseUnsigned(u8, str[34..36], 16) catch unreachable;
    const p6 = .{ p6a, p6b, p6c, p6d, p6e, p6f };
    // const p6 = arr: {
    //     var bytes: [6]u8 = undefined;
    //     for (bytes) |*b, i| {
    //         if (i == 5) break;
    //         b.* = fmt.parseUnsigned(u8, str[(24+i*2)..(24+i*2)+2], 16) catch unreachable;
    //     }
    //     break :arr bytes;
    // };

    return uefi.Guid{
        .time_low = p1,
        .time_mid = p2,
        .time_high_and_version = p3,
        .clock_seq_high_and_reserved = p4,
        .clock_seq_low = p5,
        // .node = arr: {
        //     var bytes: [6]u8 = undefined;
        //     for (bytes) |*b, i| {
        //         b.* = fmt.parseUnsigned(u8, str[(24+i*2)..(24+i*2)+2], 16) catch unreachable;
        //     }
        //     break :arr bytes;
        // },
        .node = p6,
    };
}
