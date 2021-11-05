const std = @import("std");
const fmt = std.fmt;
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const MemoryType = uefi.tables.MemoryType;
const W = std.unicode.utf8ToUtf16LeStringLiteral;

pub fn main() usize {
    const con_out = uefi.system_table.con_out.?;
    _ = con_out.reset(false);

    println("Axiom OS", .{});

    const bs = uefi.system_table.boot_services.?;

    getMemoryMap(bs);
    getConfigurationTable();

    halt();
}

// Root System Description Pointer
pub const RSDP = extern struct {
    signature: [8]u8,
    checksum: u8,
    oem_id: [6]u8,
    revision: u8,
    rsdt_address: u32,
    length: u32,
    xsdt_address: u64,
    extended_checksum: u8,
    reserved: [3]u8,
};

// Root System Description Table
pub const TableDescriptionHeader = extern struct {
    signature: [4]u8,
    length: u32,
    revision: u8,
    checksum: u8,
    oem_id: [6]u8,
    oem_table_id: [8]u8,
    oem_revision: u32,
    creator_id: [4]u8,
    creator_revision: u32,
};

// Extended System Description Table
pub const XSDT = extern struct {
    hdr: TableDescriptionHeader,

    pub fn entry(self: @This(), i: usize) *const TableDescriptionHeader {
        const ptr_loc = @ptrToInt(&self) + 36 + (i * 8);
        const u64_ptr = @intToPtr(*align(1) u64, ptr_loc);
        const hdr_ptr = @intToPtr(*TableDescriptionHeader, u64_ptr.*);
        return hdr_ptr;
    }
};

// Fixed ACPI Description Table
pub const FADT = extern struct {
    hdr: TableDescriptionHeader,
    firmware_ctrl: u32,
    dsdt: u32,
    reserved: u8,
    preferred_pm_profile: u8,
};

fn getConfigurationTable() void {
    const st = uefi.system_table;

    println("", .{});
    println("UEFI Configuration Tables [{}]", .{st.number_of_table_entries});

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

            "";

        print("{:02} [{X: >16}]", .{i, @ptrToInt(st.configuration_table[i].vendor_table)});
        if (std.mem.eql(u8, name, "")) {
            print(" Unknown {{", .{});
            printGuid(guid);
            print("}}", .{});
        }
        println(" {s}", .{name});

        // ACPI 2.0

        if (guid.eql(CT.acpi_20_table_guid)) {

            // RSDP

            const rdsp = @ptrCast(*align(1) RSDP, st.configuration_table[i].vendor_table);
            println("                      RSDP Descriptor:", .{});
            println("                      - Signature:         \"{s}\"", .{rdsp.signature});
            println("                      - Checksum:          {}", .{rdsp.checksum});
            println("                      - OEM ID:            \"{s}\"", .{rdsp.oem_id});
            println("                      - Revision:          {}", .{rdsp.revision});
            println("                      - RSDT Address:      [{X: >16}]", .{rdsp.rsdt_address});
            println("                      - Length:            {}", .{rdsp.length});
            println("                      - XSDT Address:      [{X: >16}]", .{rdsp.xsdt_address});
            println("                      - Extended Checksum: {}", .{rdsp.extended_checksum});
            println("", .{});

            // XDST

            const xdst = @intToPtr(*XSDT, rdsp.xsdt_address);
            println("                      XSDT Descriptor:", .{});
            printTableDescHeader(@ptrCast(*TableDescriptionHeader, &xdst.hdr));

            const n_entries: usize = @divExact(xdst.hdr.length - @bitSizeOf(TableDescriptionHeader) / 8, 8);
            println("                      - Entries: [{}]", .{n_entries});

            var j: usize = 0;
            while (j < n_entries) : (j += 1) {
                const entry = xdst.entry(j);
                print("                        [{X: >16}]", .{@ptrToInt(entry)});
                println(" \"{s}\"", .{entry.signature});

                // FADT

                if (std.mem.eql(u8, entry.signature[0..], "FACP")) {
                    const fadt = @ptrCast(*const FADT, entry);
                    printTableDescHeader(@ptrCast(*const TableDescriptionHeader, &fadt.hdr));
                    println("                      - Firmware Ctrl:        0x{x}", .{fadt.firmware_ctrl});
                    println("                      - DSDT:                 0x{x}", .{fadt.dsdt});
                    println("                      - Preferred PM Profile: {}", .{fadt.preferred_pm_profile});
                }
            }
        }
    }
}

fn printTableDescHeader(hdr: *const TableDescriptionHeader) void {
    println("                      - Signature:        \"{s}\"", .{hdr.signature});
    println("                      - Length:           {}", .{hdr.length});
    println("                      - Revision:         {}", .{hdr.revision});
    println("                      - Checksum:         {}", .{hdr.checksum});
    println("                      - OEM ID:           \"{s}\"", .{hdr.oem_id});
    println("                      - OEM Table ID:     \"{s}\"", .{hdr.oem_table_id});
    println("                      - OEM REvision:     {}", .{hdr.oem_revision});
    println("                      - Creator ID:       \"{s}\"", .{hdr.creator_id});
    println("                      - Creator Revision: 0x{x}", .{hdr.creator_revision});
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

    println("", .{});
    println("UEFI Memory Descriptors [{}]", .{n_descriptors});

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
    println("  Total Memory: {s}", .{fmt.fmtIntSizeBin(max_memory)});
}

fn println(comptime format: [:0]const u8, args: anytype) void {
    print(format ++ "\r\n", args);
}

fn print(comptime format: [:0]const u8, args: anytype) void {
    const con_out = uefi.system_table.con_out.?;

    var buf8: [256]u8 = undefined;
    const msg = fmt.bufPrintZ(buf8[0..], format, args) catch unreachable;

    var buf16: [256]u16 = undefined;
    const idx = std.unicode.utf8ToUtf16Le(buf16[0..], msg) catch unreachable;
    buf16[idx] = 0;
    _ = con_out.outputString(@ptrCast([*:0]const u16, buf16[0..]));
}

fn printGuid(guid: uefi.Guid) void {
    print("{x:0>8}-{x:0>4}-{X:0>4}-{X:0>2}{X:0>2}-{s:0>12}", .{
        guid.time_low,
        guid.time_mid,
        guid.time_high_and_version,
        guid.clock_seq_high_and_reserved,
        guid.clock_seq_low,
        fmt.fmtSliceHexLower(guid.node[0..]),
    });
}

fn dumpHex(bytes: [*]const u8, count: usize) void {
    var k: usize = 0;
    while (k < count) : (k += 1) {
        if (k != 0 and @mod(k, 16) == 0) {
            println("", .{});
        }
        print("{X:0>2} ", .{bytes[k]});
    }
}

fn halt() noreturn {
    while (true) {
        asm volatile (
            "hlt"
        );
    }
}
