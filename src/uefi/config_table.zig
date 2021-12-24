const std = @import("std");
const uefi = std.os.uefi;
const SystemTable = uefi.tables.SystemTable;
const ConfigurationTable = uefi.tables.ConfigurationTable;

const acpi = @import("../acpi/acpi.zig");
const io = @import("../io.zig");
const print = io.print;
const println = io.println;
const printGuid = io.printGuid;

pub fn dumpUefiConfigurationTable(st: *SystemTable) void {
    dumpConfigTableNames(st);
}

pub fn dumpConfigTableNames(st: *SystemTable) void {
    println("", .{});
    println("UEFI Configuration Table [{}]", .{st.number_of_table_entries});

    var rdsp: *align(1) acpi.RSDP = undefined;

    var i: usize = 0;
    while (i < st.number_of_table_entries) : (i += 1) {
        const CT = ConfigurationTable;
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
}

pub fn getConfigurationTable(st: *SystemTable, guid: uefi.Guid) ?*ConfigurationTable {
    var table: ?*ConfigurationTable = null;

    var i: usize = 0;
    while (i < st.number_of_table_entries) : (i += 1) {
        if (guid.eql(st.configuration_table[i].vendor_guid)) {
            table = &st.configuration_table[i];
        }
    }

    return table;
}
