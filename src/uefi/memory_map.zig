const std = @import("std");
const fmt = std.fmt;
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const MemoryType = uefi.tables.MemoryType;

const io = @import("../io.zig");
const print = io.print;
const println = io.println;

pub fn dumpUefiMemoryMap(bs: *uefi.tables.BootServices) void {
    var memory_map_size: usize = 0;
    var memory_map: [*]MemoryDescriptor = undefined;
    var memory_map_key: usize = undefined;
    var descriptor_size: usize = undefined;
    var descriptor_version: u32 = undefined;

    var status: uefi.Status = undefined;
    
    status = bs.getMemoryMap(&memory_map_size, memory_map, &memory_map_key, &descriptor_size, &descriptor_version);
    // println("getMemoryMap() => {s}", .{@tagName(status)});
    // println("memory_map_size = {}", .{memory_map_size});

    memory_map_size += 2 * @sizeOf(MemoryDescriptor);
    status = bs.allocatePool(MemoryType.LoaderData, memory_map_size, @ptrCast(*[*]align(8) u8, &memory_map));
    // println("allocatePool() => {s}", .{@tagName(status)});

    status = bs.getMemoryMap(&memory_map_size, memory_map, &memory_map_key, &descriptor_size, &descriptor_version);
    // println("getMemoryMap() => {s}", .{@tagName(status)});
    // println("memory_map_key = {}", .{memory_map_key});
    // println("memory_map_size = {}", .{memory_map_size});
    // println("descriptor_size = {}", .{descriptor_size});
    // println("descriptor_version = {}", .{descriptor_version});

    const n_descriptors = @divExact(memory_map_size, descriptor_size);

    println("", .{});
    println("UEFI Memory Descriptors [{}]", .{n_descriptors});

    var i: usize = 0;
    var max_memory: usize = 0;
    var usable_memory: usize = 0;
    var physical_memory: usize = 0;
    var previous_end: usize = 0;
    while (i < n_descriptors) : (i += 1) {
        const desc = @intToPtr(*MemoryDescriptor, @ptrToInt(memory_map) + i * descriptor_size);
        const size_kb: usize = desc.number_of_pages * 4;

        if (previous_end != desc.physical_start) {
            println("gap found", .{});            
        }
        previous_end = desc.physical_start + size_kb * 1024;

        if (desc.physical_start + size_kb * 1024 > max_memory) {
            max_memory = desc.physical_start + size_kb * 1024;
        }
        switch (desc.type) {
            .LoaderCode,
            .LoaderData,
            .BootServicesCode,
            .BootServicesData,
            .ConventionalMemory,
            .ACPIReclaimMemory,
                => usable_memory += desc.number_of_pages * 4 * 1024,
            else => {},
        }
        if (@bitCast(u64, desc.attribute) & 0xF == 0xF) {
            physical_memory += desc.number_of_pages * 4 * 1024;
        }
        print("{:03}: [{X: >16}] [{: >8} KB] {s}", .{i, desc.physical_start, size_kb, @tagName(desc.type)});
        println("[0x{x:0>16}]", .{@bitCast(u64, desc.attribute)});
    }
    println("  Total Memory: {s}", .{fmt.fmtIntSizeBin(physical_memory)});
    // println("  Total Usable Memory: {s}", .{fmt.fmtIntSizeBin(usable_memory)});
}
