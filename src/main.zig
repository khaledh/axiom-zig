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

    getConfigurationTable();
    getMemoryMap(bs);

    halt();
}

fn getConfigurationTable() void {
    const st = uefi.system_table;

    println("num_table_entries = {}", .{st.number_of_table_entries});

    var i: usize = 0;
    while (i < st.number_of_table_entries) : (i += 1) {
        const CT = uefi.tables.ConfigurationTable;
        const guid = st.configuration_table[i].vendor_guid;

        const name: []const u8 =
            if (guid.eql(CT.acpi_20_table_guid)) "ACPI 2.0 Table" else
            if (guid.eql(CT.acpi_10_table_guid)) "ACPI 1.0 Table" else
            if (guid.eql(CT.sal_system_table_guid)) "SAL System Table" else
            if (guid.eql(CT.smbios_table_guid)) "SMBIOS Table" else
            if (guid.eql(CT.smbios3_table_guid)) "SMBIOS 3 Table" else
            if (guid.eql(CT.mps_table_guid)) "MPS Table" else
            if (guid.eql(CT.json_config_data_table_guid)) "JSON Config Data Table" else
            if (guid.eql(CT.json_capsule_data_table_guid)) "JSON Capsule Data Table" else
            if (guid.eql(CT.json_capsule_result_table_guid)) "JSON Capsule Result Table" else
            // ee4e5898-3914-4259-9D6E-dc7bd79403cf: LZMA_CUSTOM_DECOMPRESS
            // 05ad34ba-6f02-4214-952E-4da0398e2bb9: DXE_SERVICES_TABLE
            // 7739f24c-93d7-11D4-9A3A-0090273fc14d: HOB_LIST
            // 4c19049f-4137-4DD3-9C10-8b97a83ffdfa: MEMORY_TYPE_INFORMATION
            // 49152e77-1ada-4764-B7A2-7afefed95e8b: DEBUG_IMAGE_INFO_TABLE
            // 060cc026-4c0d-4DDA-8F41-595fef00a502: MemoryStatusCodeRecord
            // dcfa911d-26eb-469F-A220-38b7dc461220: MemoryAttributesTable
            // d719b2cb-3d3a-4596-A3BC-dad00e67656f: ImageSecurityDatabase

            "Unknown";

        println("config table @ [{X: >16}] {x:0>8}-{x:0>4}-{X:0>4}-{X:0>2}{X:0>2}-{s:0>12} {s}", .{
            @ptrToInt(st.configuration_table[i].vendor_table),
            guid.time_low,
            guid.time_mid,
            guid.time_high_and_version,
            guid.clock_seq_high_and_reserved,
            guid.clock_seq_low,
            fmt.fmtSliceHexLower(guid.node[0..]),
            name,
        });

        if (guid.eql(CT.acpi_20_table_guid)) {
            const sig = @ptrCast([*]const u8, st.configuration_table[i].vendor_table);
            println("RSDP Descriptor Signature: \"{s: <8}\"", .{sig[0..8]});
        }
    }
}

fn getMemoryMap(bs: *uefi.tables.BootServices) void {
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
    println("memory descriptor count = {}", .{n_descriptors});

    var i: usize = 0;
    var max_memory: usize = 0;
    while (i < n_descriptors) : (i += 1) {
        const desc = @intToPtr(*MemoryDescriptor, @ptrToInt(memory_map) + i * descriptor_size);
        const size_kb: usize = desc.number_of_pages * 4;
        if (desc.physical_start + size_kb * 1024 > max_memory) {
            max_memory = desc.physical_start + size_kb * 1024;
        }
        // println("{:03}: [{X: >16}] [{: >8} KB] {s}", .{i, desc.physical_start, size_kb, @tagName(desc.type)});
    }
    println("Total Memory: {s} ({})", .{fmt.fmtIntSizeBin(max_memory), max_memory});
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
