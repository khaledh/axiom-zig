const std = @import("std");
const fmt = std.fmt;
const uefi = std.os.uefi;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const MemoryType = uefi.tables.MemoryType;
const W = std.unicode.utf8ToUtf16LeStringLiteral;

const acpi = @import("acpi/acpi.zig");
const io = @import("io.zig");
const print = io.print;
const println = io.println;
const printGuid = io.printGuid;
const dumpHex = io.dumpHex;
const aml = @import("acpi/amlparser.zig");


pub fn main() usize {
    const con_out = uefi.system_table.con_out.?;
    _ = con_out.reset(false);

    println("Axiom OS", .{});

    const bs = uefi.system_table.boot_services.?;

    getMemoryMap(bs);
    getConfigurationTable();

    shutdown();
    // halt();
}

fn getConfigurationTable() void {
    const st = uefi.system_table;

    println("UEFI Configuration Tables [{}]", .{st.number_of_table_entries});

    var rdsp: *align(1) acpi.RSDP = undefined;

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

        if (guid.eql(CT.acpi_20_table_guid)) {
            rdsp = @ptrCast(*align(1) acpi.RSDP, st.configuration_table[i].vendor_table);
        }
    }

    // ACPI 2.0

    if (rdsp != undefined) {

        println("", .{});
        println("### ACPI 2.0 Tables ###", .{});

        println("", .{});
        println("  ### RSDP (Root System Description Pointer) ###", .{});
        println("", .{});
        println("  - Signature:         \"{s}\"", .{rdsp.signature});
        println("  - Checksum:          {}", .{rdsp.checksum});
        println("  - OEM ID:            \"{s}\"", .{rdsp.oem_id});
        println("  - Revision:          {}", .{rdsp.revision});
        println("  - RSDT Address:      [{X: >16}]", .{rdsp.rsdt_address});
        println("  - Length:            {}", .{rdsp.length});
        println("  - XSDT Address:      [{X: >16}]", .{rdsp.xsdt_address});
        println("  - Extended Checksum: {}", .{rdsp.extended_checksum});

        const xdst = @intToPtr(*acpi.XSDT, rdsp.xsdt_address);

        println("", .{});
        println("  ### XDST (eXtended System Description Table) ###", .{});
        println("", .{});

        printTableDescHeader(@ptrCast(*acpi.TableDescriptionHeader, &xdst.hdr));

        const n_entries: usize = @divExact(xdst.hdr.length - @bitSizeOf(acpi.TableDescriptionHeader) / 8, 8);
        println("  - Entries: [{}]", .{n_entries});

        var j: usize = 0;
        var fadt: *align(1) const acpi.FADT = undefined;
        var madt: *align(1) const acpi.MADT = undefined;
        var bgrt: *align(1) const acpi.BGRT = undefined;

        while (j < n_entries) : (j += 1) {
            const entry = xdst.entry(j);
            print("    [{X: >16}]", .{@ptrToInt(entry)});
            println(" \"{s}\"", .{entry.signature});

            if (std.mem.eql(u8, entry.signature[0..], "FACP")) {
                fadt = @ptrCast(*align(1) const acpi.FADT, entry);
            }
            else if (std.mem.eql(u8, entry.signature[0..], "APIC")) {
                madt = @ptrCast(*align(1) const acpi.MADT, entry);
            }
            else if (std.mem.eql(u8, entry.signature[0..], "BGRT")) {
                bgrt = @ptrCast(*align(1) const acpi.BGRT, entry);
            }
        }

        println("", .{});
        println("  ### FADT (Fixed ACPI Description Table) ###", .{});
        println("", .{});

        printTableDescHeader(@ptrCast(*const acpi.TableDescriptionHeader, &fadt.hdr));
        println("  - FIRMWARE_CTRL (FACS): 0x{x: >8}", .{fadt.firmware_ctrl});
        println("  - DSDT:                 0x{x: >8}", .{fadt.dsdt});
        println("  - Preferred PM Profile: {}", .{fadt.preferred_pm_profile});
        println("  - SCI_INT:              {}", .{fadt.sci_int});
        println("  - SMI_CMD:              0x{x}", .{fadt.smi_cmd});
        println("  - ACPI_ENABLE:          0x{x}", .{fadt.acpi_enable});
        println("  - ACPI_DISABLE:         0x{x}", .{fadt.acpi_disable});
        println("  - S4BIOS_REQ:           0x{x:0>2}", .{fadt.s4bios_req});
        println("  - PSTATE_CNT:           0x{x:0>2}", .{fadt.pstate_cnt});
        println("  - PM1a_EVT_BLK:         0x{x: >8}", .{fadt.pm1a_evt_blk});
        println("  - PM1b_EVT_BLK:         0x{x: >8}", .{fadt.pm1b_evt_blk});
        println("  - PM1a_CNT_BLK:         0x{x: >8}", .{fadt.pm1a_cnt_blk});
        println("  - PM1b_CNT_BLK:         0x{x: >8}", .{fadt.pm1b_cnt_blk});
        println("  - PM2_CNT_BLK:          0x{x: >8}", .{fadt.pm2_cnt_blk});
        println("  - PM_TMR_BLK:           0x{x: >8}", .{fadt.pm_tmr_blk});
        println("  - GPE0_BLK:             0x{x: >8}", .{fadt.gpe0_blk});
        println("  - GPE1_BLK:             0x{x: >8}", .{fadt.gpe1_blk});
        println("  - PM1_EVT_LEN:          {}", .{fadt.pm1_evt_len});
        println("  - PM1_CNT_LEN:          {}", .{fadt.pm1_cnt_len});
        println("  - PM2_CNT_LEN:          {}", .{fadt.pm2_cnt_len});
        println("  - PM_TMR_LEN:           {}", .{fadt.pm_tmr_len});
        println("  - GPE0_BLK_LEN:         {}", .{fadt.gpe0_blk_len});
        println("  - GPE1_BLK_LEN:         {}", .{fadt.gpe1_blk_len});
        println("  - GPE1_BASE:            {}", .{fadt.gpe1_base});
        println("  - CST_CNT:              0x{x}", .{fadt.cst_cnt});
        println("  - P_LVL2_LAT:           0x{x:0>4}", .{fadt.p_lvl2_lat});
        println("  - P_LVL3_LAT:           0x{x:0>4}", .{fadt.p_lvl3_lat});
        println("  - FLUSH_SIZE:           {}", .{fadt.flush_size});
        println("  - FLUSH_STRIDE:         {}", .{fadt.flush_stride});
        println("  - DUTY_OFFSET:          {}", .{fadt.duty_offset});
        println("  - DUTY_WIDTH:           {}", .{fadt.duty_width});
        println("  - DAY_ALRM:             {}", .{fadt.day_alarm});
        println("  - MON_ALRM:             {}", .{fadt.mon_alarm});
        println("  - CENTURY:              {}", .{fadt.century});
        println("  - IAPC_BOOT_ARCH:       0b{b: >16}", .{fadt.iapc_boot_arch});
        println("  - Flags:                0b{b: >32}", .{fadt.flags});
        // println("  - RESET_REG:            {s}", .{formatGenericAddress(fadt.reset_reg)});
        // println("  - RESET_VALUE:          {}", .{fadt.reset_value});

        println("", .{});
        println("  ### FACS (Firmware ACPI Control Structure) ###", .{});
        println("", .{});

        const facs = @ptrCast(*align(1) const acpi.FACS, @intToPtr([*]const u8, fadt.firmware_ctrl & 0x00000000ffffffff));
        println("  | Signature:          \"{s}\"", .{facs.signature});
        println("  | Length:             {}", .{facs.length});
        println("  - HW Signature:       0x{x:0>8}", .{facs.hw_signature});
        println("  - FW Waking Vector:   0x{x:0>8}", .{facs.fw_walking_vector});
        println("  - Global Lock:        0x{x:0>8}", .{facs.global_lock});
        println("  - Flags:              0x{x:0>8}", .{facs.flags});
        println("  - X FW Waking Vector: 0x{x:0>16}", .{facs.x_fw_walking_vector});
        println("  - Version:            {}", .{facs.version});
        println("  - OSPM Flags:         0x{x:0>8}", .{facs.ospm_flags});

        println("", .{});
        println("  ### DSDT (Differentiated System Description Table) ###", .{});
        println("", .{});

        const dsdt = @ptrCast(*const acpi.TableDescriptionHeader, @intToPtr([*]align(4) const u8, fadt.dsdt & 0x00000000ffffffff));
        printTableDescHeader(@ptrCast(*const acpi.TableDescriptionHeader, dsdt));
        const aml_block_len = dsdt.length - 36;
        println("  - Definition Block: {} bytes (AML encoded)", .{aml_block_len});

        const aml_block = @intToPtr([*]const u8, @ptrToInt(dsdt) + 36);
        var aml_parser = aml.AmlParser().init();
        aml_parser.parse(aml_block[0..aml_block_len]);

        // println("", .{});
        // println("  ### MADT (Multiple APIC Description Table) ###", .{});
        // println("", .{});

        // printTableDescHeader(@ptrCast(*const acpi.TableDescriptionHeader, &madt.hdr));
        // println("  - Local APIC Address:  0x{x:0>8}", .{madt.local_apic_addr});
        // println("  - Flags:               0x{x:0>8}", .{madt.flags});
        // // var p: usize = @ptrToInt(madt) + 36 + 8;
        // var int_ctrl = @intToPtr(*const acpi.InterruptControllerHdr, (@ptrToInt(madt) + 36 + 8));
        // while (@ptrToInt(int_ctrl) - @ptrToInt(madt) < madt.hdr.length) {
        //     println("  - Interrupt Ctrl Type: {}", .{int_ctrl.type});
        //     println("  - Interrupt Ctrl Len:  {}", .{int_ctrl.len});
        //     switch (int_ctrl.type) {
        //         0 => {
        //             const lapic = @ptrCast(*align(1) const acpi.LAPIC, int_ctrl);
        //             println("    [Local APIC]", .{});
        //             println("      - ACPI Processor UID: {}", .{lapic.processor_uid});
        //             println("      - LAPIC ID:           {}", .{lapic.lapic_id});
        //             println("      - Flags:              0x{x:0>8}", .{lapic.flags});
        //         },
        //         1 => {
        //             const ioapic = @ptrCast(*align(1) const acpi.IOAPIC, int_ctrl);
        //             println("    [I/O APIC]", .{});
        //             println("      - IOAPIC ID:          {}", .{ioapic.ioapic_id});
        //             println("      - Address:            0x{x: >8}", .{ioapic.ioapic_addr});
        //             println("      - GSI Base:           {}", .{ioapic.gsi_base});

        //             const ioregsel = @intToPtr(*u32, ioapic.ioapic_addr);
        //             const iowin = @intToPtr(*u32, ioapic.ioapic_addr + 0x10);

        //             ioregsel.* = 0;
        //             println("      - IOAPICID:           0x{x:0>8}", .{iowin.*});
        //             ioregsel.* = 1;
        //             println("      - IOAPICVER:          0x{x:0>8}", .{iowin.*});
        //             ioregsel.* = 2;
        //             println("      - IOAPICARB:          0x{x:0>8}", .{iowin.*});

        //         },
        //         2 => {
        //             const int_src_override = @ptrCast(*align(1) const acpi.InterruptSourceOverride, int_ctrl);
        //             println("    [Interrupt Source Override]", .{});
        //             println("      - Bus:                {}", .{int_src_override.bus});
        //             println("      - Source:             {}", .{int_src_override.source});
        //             println("      - GSI:                {}", .{int_src_override.gsi});
        //             println("      - Flags:              0b{b:0>4}", .{int_src_override.flags});
        //         },
        //         4 => {
        //             const lapic = @ptrCast(*align(1) const acpi.LAPIC_NMI, int_ctrl);
        //             println("    [Local APIC NMI]", .{});
        //             println("      - ACPI Processor UID: 0x{x: >2}", .{lapic.processor_uid});
        //             println("      - Flags:              0x{x:0>4}", .{lapic.flags});
        //             println("      - LINT#:              {}", .{lapic.lapic_lint_n});
        //         },
        //         else => {},
        //     }
        //     int_ctrl = @intToPtr(*const acpi.InterruptControllerHdr, @ptrToInt(int_ctrl) + int_ctrl.len);
        // }

        // println("", .{});
        // println("  ### BGRT (Boot Graphics Resource Table) ###", .{});
        // println("", .{});

        // printTableDescHeader(@ptrCast(*const acpi.TableDescriptionHeader, &bgrt.hdr));
        // println("  - Version:        {}", .{bgrt.version});
        // println("  - Status:         0x{x:0>8}", .{bgrt.status});
        // println("  - Image Type:     {}", .{bgrt.image_type});
        // println("  - Image Address:  0x{x: >16}", .{bgrt.image_addr});
        // println("  - Image Offset X: {}", .{bgrt.image_offset_x});
        // println("  - Image Offset Y: {}", .{bgrt.image_offset_y});

        println("", .{});
        // dumpHex(@intToPtr([*]const u8, (fadt.dsdt + 36)), (dsdt.length - 36));
        // println("", .{});
        // dumpHex(@intToPtr([*]const u8, (@ptrToInt(madt) + 36 + 8)), 76);
    }
}

fn printTableDescHeader(hdr: *const acpi.TableDescriptionHeader) void {
    println("  | Signature:        \"{s}\"", .{hdr.signature});
    println("  | Length:           {}", .{hdr.length});
    println("  | Revision:         {}", .{hdr.revision});
    println("  | Checksum:         {}", .{hdr.checksum});
    println("  | OEM ID:           \"{s}\"", .{hdr.oem_id});
    println("  | OEM Table ID:     \"{s}\"", .{hdr.oem_table_id});
    println("  | OEM REvision:     {}", .{hdr.oem_revision});
    println("  | Creator ID:       \"{s}\"", .{hdr.creator_id});
    println("  | Creator Revision: 0x{x}", .{hdr.creator_revision});
}

fn formatGenericAddressImpl() type {
    return struct {
        pub fn f(
            gen_addr: acpi.GenericAddress,
            comptime _format: []const u8,
            _options: fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = _format;
            _ = _options;

            try fmt.format(writer, "[{}] 0x{x: >16} [offset: {}, width: {}, access_size: {}]", .{
                gen_addr.addr_space_id,
                gen_addr.address,
                gen_addr.reg_bit_offset,
                gen_addr.reg_bit_width,
                gen_addr.access_size,
            });
       }
    };
}

fn formatGenericAddress(gen_addr: acpi.GenericAddress) std.fmt.Formatter(formatGenericAddressImpl().f) {
    return .{ .data = gen_addr };
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

fn halt() noreturn {
    while (true) {
        asm volatile (
            "hlt"
        );
    }
}

fn shutdown() noreturn {
    println("\nShutdown", .{});
    out16(0x604, 0x2000);
    unreachable;
}

fn out16(port: u16, value: u16) void {
    asm volatile (
        "out %[value], %[port]"
        :
        : [port] "{dx}" (port),
          [value] "{ax}" (value)
        : "dx", "ax"
    );
}
