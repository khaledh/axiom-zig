const std = @import("std");
const fmt = std.fmt;
const uefi = std.os.uefi;
const T = uefi.tables;

const cpu = @import("cpu.zig");
const acpi = @import("acpi/acpi.zig");
const system = @import("system.zig");
const io = @import("io.zig");
const print = io.print;
const println = io.println;
const printGuid = io.printGuid;

// UEFI
const dumpUefiFirmwareVersion = @import("uefi/firmware_version.zig").dumpUefiFirmwareVersion;
const dumpUefiMemoryMap = @import("uefi/memory_map.zig").dumpUefiMemoryMap;
const dumpUefiConfigurationTable = @import("uefi/config_table.zig").dumpUefiConfigurationTable;
const dumpUefiVariables = @import("uefi/variables.zig").dumpUefiVariables;
const getConfigurationTable = @import("uefi/config_table.zig").getConfigurationTable;
// SMBIOS
const SmbiosEntryPoint32 = @import("smbios/entry_point.zig").SmbiosEntryPoint32;
const dumpSmbiosEntryPoint32 = @import("smbios/entry_point.zig").dumpSmbiosEntryPoint32;

pub fn main() usize {
    const st = uefi.system_table;
    // const bs = st.boot_services.?;
    // const rs = st.runtime_services;
    const con_out = st.con_out.?;

    _ = con_out.reset(false);
    println(
        \\    _          _                    ___  ____  
        \\   / \   __  _(_) ___  _ __ ___    / _ \/ ___| 
        \\  / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ 
        \\ / ___ \  >  <| | (_) | | | | | | | |_| |___) |
        \\/_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ 
    , .{});

    //
    // UEFI
    //
    // dumpUefiFirmwareVersion(st);
    // dumpUefiMemoryMap(bs);
    // dumpUefiConfigurationTable(st);
    // dumpUefiVariables(rs);
    // dumpUefiHandleProtocols(bs);

    //
    // ACPI
    //
    if (getConfigurationTable(st, T.ConfigurationTable.acpi_20_table_guid)) |acpi_table| {
        const rsdp = @ptrCast(*acpi.RSDP, acpi_table.vendor_table);
        acpi.dumpAcpiTables(rsdp);
    }

    //
    // SMBIOS
    //
    // if (getConfigurationTable(st, T.ConfigurationTable.smbios_table_guid)) |smbios_table| {
    //     const smbios_entry32 = @ptrCast(*SmbiosEntryPoint32, smbios_table.vendor_table);
    //     dumpSmbiosEntryPoint32(smbios_entry32);
    // }

    //
    // Shutdown
    //
    println("\nShutdown", .{});
    system.shutdown();
    // cpu.halt();
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    _ = error_return_trace;
    println("\n\npanic: {s}\n", .{msg});

    cpu.halt();
}
