const std = @import("std");
const fmt = std.fmt;
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const MemoryType = uefi.tables.MemoryType;
const W = std.unicode.utf8ToUtf16LeStringLiteral;

pub fn main() usize {
    const con_out = uefi.system_table.con_out.?;
    _ = con_out.reset(false);

    println("Hello, world!", .{});

    const bs = uefi.system_table.boot_services.?;

    getMemoryMap(bs);

    halt();
}

fn getMemoryMap(bs: *uefi.tables.BootServices) void {
    var memory_map_size: usize = 0;
    var memory_map: [*]MemoryDescriptor = undefined;
    var memory_map_key: usize = undefined;
    var descriptor_size: usize = undefined;
    var descriptor_version: u32 = undefined;

    var status: uefi.Status = undefined;
    
    status = bs.getMemoryMap(&memory_map_size, memory_map, &memory_map_key, &descriptor_size, &descriptor_version);
    println("getMemoryMap() => {s}", .{@tagName(status)});
    println("memory_map_size = {}", .{memory_map_size});

    memory_map_size += 2 * @sizeOf(MemoryDescriptor);
    status = bs.allocatePool(MemoryType.LoaderData, memory_map_size, @ptrCast(*[*]align(8) u8, &memory_map));
    println("allocatePool() => {s}", .{@tagName(status)});

    status = bs.getMemoryMap(&memory_map_size, memory_map, &memory_map_key, &descriptor_size, &descriptor_version);
    println("getMemoryMap() => {s}", .{@tagName(status)});
    println("memory_map_key = {}", .{memory_map_key});
    println("memory_map_size = {}", .{memory_map_size});
    println("descriptor_size = {}", .{descriptor_size});
    println("descriptor_version = {}", .{descriptor_version});

    const n_descriptors = @divExact(memory_map_size, descriptor_size);
    println("descriptor count = {}", .{n_descriptors});

    var i: usize = 0;
    while (i < n_descriptors) : (i += 1) {
        const desc = @intToPtr(*MemoryDescriptor, @ptrToInt(memory_map) + i * descriptor_size);
        const size_kb: usize = desc.number_of_pages * 4;
        println("{:02}: [{X: >16}] [{: >8} KB] {s}", .{i, desc.physical_start, size_kb, @tagName(desc.type)});
    }
}

fn println(comptime format: [:0]const u8, args: anytype) void {
    const con_out = uefi.system_table.con_out.?;

    var buf8: [256]u8 = undefined;
    const msg = fmt.bufPrintZ(buf8[0..], format, args) catch unreachable;

    var buf16: [256]u16 = undefined;
    const idx = std.unicode.utf8ToUtf16Le(buf16[0..], msg) catch unreachable;
    buf16[idx + 0] = @as(u16, '\r');
    buf16[idx + 1] = @as(u16, '\n');
    buf16[idx + 2] = 0;
    _ = con_out.outputString(@ptrCast([*:0]const u16, buf16[0..]));
}

fn halt() noreturn {
    while (true) {
        asm volatile (
            "hlt"
        );
    }
}
