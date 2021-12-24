const std = @import("std");
const fmt = std.fmt;
const io = @import("../io.zig");

pub const SmbiosEntryPoint32 = packed struct {
    anchor: [4]u8,
    checksum: u8,
    length: u8,
    major_version: u8,
    minor_version: u8,
    max_struct_size: u16,
    revision: u8,
    formatted_area: [5]u8,
    intermediate_anchor: [5]u8,
    intermediate_checksum: u8,
    struct_table_len: u16,
    struct_table_addr: u32,
    struct_count: u16,
    revision_bcd: u8,
};

pub const SmbiosStructHeader = packed struct {
    type_: u8,
    length: u8,
    handle: u16,
};

pub const BiosInformation = packed struct {
    hdr: SmbiosStructHeader,
    vendor: u8,
    version: u8,
    starting_address_segment: u16,
    release_date: u8,
    rom_size: u8,
    characteristics: u64,
    characteristics_extension_byte1: u8,
    characteristics_extension_byte2: u8,
    system_bios_major_release: u8,
    system_bios_minor_release: u8,
    embedded_controller_fw_major_release: u8,
    embedded_controller_fw_minor_release: u8,
};

pub const SystemInformation = packed struct {
    hdr: SmbiosStructHeader,
    manufacturer: u8,
    product_name: u8,
    version: u8,
    serial_no: u8,
    uuid: [16]u8,
    wakeup_type: u8,
    sku: u8,
    family: u8,
};

pub const SystemEnclosure = packed struct {
    hdr: SmbiosStructHeader,
    manufacturer: u8,
    type_: u8,
    version: u8,
    serial_no: u8,
    asset_tag: u8,
    bootup_state: u8,
    power_supply_state: u8,
    thermal_state: u8,
    security_status: u8,
    oem_defined: u32,
    height: u8,
    num_power_cords: u8,
    contained_element_count: u8,
    contained_element_record_len: u8,
    // contained_elements: [?]u8,
    // sku: u8,
};

pub const ProcessorInformation = packed struct {
    hdr: SmbiosStructHeader,
    socket_designation: u8,
    proc_type: u8,
    proc_family: u8,
    proc_manufacturer: u8,
    proc_id: u64,
    proc_version: u8,
    voltage: u8,
    external_clock: u16,
    max_speed: u16,
    current_speed: u16,
    status: u8,
    proc_upgrade: u8,
    l1_cache_handle: u16,
    l2_cache_handle: u16,
    l3_cache_handle: u16,
    serial_no: u8,
    asset_tag: u8,
    part_no: u8,
    core_count: u8,
    core_enabled: u8,
    thread_count: u8,
    proc_characteristics: u16,
    proc_family2: u16,
    // SMBIOS 3.0 fields
    // core_count2: u16,
    // core_enabled2: u16,
    // thread_count2: u16,
};

pub const PhysicalMemoryArray = packed struct {
    hdr: SmbiosStructHeader,
    location: u8,
    use: u8,
    error_correction: u8,
    max_capacity_kb: u32,
    error_info_handle: u16,
    memory_device_count: u16,
    extended_max_capacity: u64,
};

pub const MemoryDevice = packed struct {
    hdr: SmbiosStructHeader,
    physical_memory_array_handle: u16,
    error_information_handle: u16,
    total_width: u16,
    data_width: u16,
    size: u16,
    form_factor: u8,
    device_set: u8,
    device_locator: u8,
    bank_locator: u8,
    memory_type: u8,
    type_detail: u16,
    // SMBIOS 2.3+
    speed: u16,
    manufacturer: u8,
    serial_no: u8,
    asset_tag: u8,
    part_no: u8,
    // SMBIOS 2.6+
    attributes: u8,
    // SMBIOS 2.7+
    extended_size: u32,
    configured_memory_speed: u16,
    // SMBIOS 2.8+
    min_voltage: u16,
    max_voltage: u16,
    configured_voltage: u16,
    // SMBIOS 3.2+
    memory_technology: u8,
    memory_op_mode_capability: u16,
    firmware_version: u8,
    module_manufacturer_id: u16,
    module_product_id: u16,
    memory_subsystem_controller_manufacturer_id: u16,
    memory_subsystem_controller_product_id: u16,
    nonvolatile_size: u64,
    volatile_size: u64,
    cache_size: u64,
    logical_size: u64,
    // SMBIOS 3.3+
    extended_speed: u32,
    extended_configured_memory_speed: u32,
};

pub const MemoryArrayMappedAddress = packed struct {
    hdr: SmbiosStructHeader,
    starting_address: u32,
    ending_address: u32,
    memory_array_handle: u16,
    partition_width: u8,
    extended_starting_address: u32,
    extended_ending_address: u32,
};

pub const SystemBootInformation = packed struct {
    hdr: SmbiosStructHeader,
    reserved: [6]u8,
    status: u8,
};

pub fn dumpSmbiosEntryPoint32(entry_point32: *const SmbiosEntryPoint32) void {
    io.println("\nSMBIOS", .{});

    io.println("  Version: {}.{}", .{entry_point32.major_version, entry_point32.minor_version});
    // io.println("  Revision: 0x{x:0>2}", .{entry_point32.revision});
    io.println("  Maximum Structure Size: {}", .{entry_point32.max_struct_size});
    io.println("  Structure Table Length: {}", .{entry_point32.struct_table_len});
    io.println("  Structure Count: {}", .{entry_point32.struct_count});

    var hdr = @intToPtr(*SmbiosStructHeader, entry_point32.struct_table_addr);
    var i: usize = 0;
    while (i < entry_point32.struct_count) : (i += 1) {
        io.println("", .{});
        // io.println("    Struct Type: {: >3}, Handle: {x:0>4}", .{hdr.type_, hdr.handle});
        var strings: [16][]const u8 = undefined;
        const string_bytes = @intToPtr([*]const u8, @ptrToInt(hdr) + hdr.length);
        const strings_len = parseStrings(string_bytes, &strings);
        // io.dumpHex(@ptrCast([*]const u8, hdr), hdr.length + strings_len);
        switch (hdr.type_) {
            0 => dumpBiosInformation(@ptrCast(*BiosInformation, hdr), strings),
            1 => dumpSystemInformation(@ptrCast(*SystemInformation, hdr), strings),
            3 => dumpSystemEnclosure(@ptrCast(*SystemEnclosure, hdr), strings),
            4 => dumpProcessorInformation(@ptrCast(*ProcessorInformation, hdr), strings),
            16 => dumpPhysicalMemoryArray(@ptrCast(*PhysicalMemoryArray, hdr), strings),
            17 => dumpMemoryDevice(@ptrCast(*MemoryDevice, hdr), strings),
            19 => dumpMemoryArrayMappedAddress(@ptrCast(*MemoryArrayMappedAddress, hdr), strings),
            32 => dumpSystemBootInformation(@ptrCast(*SystemBootInformation, hdr), strings),
            else => {},
        }
        // io.println("", .{});
        hdr = @intToPtr(*SmbiosStructHeader, @ptrToInt(hdr) + hdr.length + strings_len);
    }
}

fn parseStrings(string_bytes: [*]const u8, strings: *[16][]const u8) usize {
    if (string_bytes[0] == 0) {
        return 2;
    }
    strings[0] = "";

    var string_index: usize = 1;
    var start: usize = 0;
    var end: usize = 0;
    while (string_bytes[start] != 0 and string_index < 16) : (string_index += 1) {
        end = start;
        while (string_bytes[end] != 0) {
            end += 1;
        }
        strings[string_index] = string_bytes[start..end];
        start = end + 1;
    }
    // io.dumpHex(string_bytes, start + 1);
    return start + 1;
}

fn dumpBiosInformation(table: *BiosInformation, strings: [16][]const u8) void {
    io.println("    BIOS Information (Type: {}, Handle: {x:0>4})", .{table.hdr.type_, table.hdr.handle});
    io.println("      Vendor:                          {s}", .{strings[table.vendor]});
    io.println("      Version:                         {s}", .{strings[table.version]});
    io.println("      Release Date:                    {s}", .{strings[table.release_date]});
    io.println("      Starting Address Segment:        {x:0>4}", .{table.starting_address_segment});
    io.println("      ROM Size:                        {s}", .{fmt.fmtIntSizeBin((@intCast(u64, table.rom_size) + 1) * 64 * 1024)});
    io.println("      Characteristics:                 {x:0>16}", .{table.characteristics});
    io.println("      Characteristics Extension:       {x:0>2} {x:0>2}", .{table.characteristics_extension_byte1, table.characteristics_extension_byte2});
    io.println("      System BIOS Release:             {}.{}", .{table.system_bios_major_release, table.system_bios_minor_release});
    io.println("      Embedded Controller FW Release:  {}.{}", .{table.embedded_controller_fw_major_release, table.embedded_controller_fw_minor_release});
}

fn dumpSystemInformation(table: *SystemInformation, strings: [16][]const u8) void {
    io.println("    System Information (Type: {}, Handle: {x:0>4})", .{table.hdr.type_, table.hdr.handle});
    io.println("      Manufacturer:                    {s}", .{strings[table.manufacturer]});
    io.println("      Product Name:                    {s}", .{strings[table.product_name]});
    io.println("      Version:                         {s}", .{strings[table.version]});
    io.println("      Serial No:                       {s}", .{strings[table.serial_no]});
    io.println("      Wake-up Type:                    {}", .{table.wakeup_type});
    io.println("      SKU:                             {s}", .{strings[table.sku]});
    io.println("      Family:                          {s}", .{strings[table.family]});
}

fn dumpSystemEnclosure(table: *SystemEnclosure, strings: [16][]const u8) void {
    io.println("    System Enclosure or Chassis (Type: {}, Handle: {x:0>4})", .{table.hdr.type_, table.hdr.handle});
    io.println("      Manufacturer:                    {s}", .{strings[table.manufacturer]});
    io.println("      Type:                            {}", .{table.type_});
    io.println("      Version:                         {s}", .{strings[table.version]});
    io.println("      Serial No:                       {s}", .{strings[table.serial_no]});
    io.println("      Asset Tag No:                    {s}", .{strings[table.asset_tag]});
    io.println("      Boot-up State:                   {}", .{table.bootup_state});
    io.println("      Power Supply State:              {}", .{table.power_supply_state});
    io.println("      Thermal State:                   {}", .{table.thermal_state});
    io.println("      Security Status:                 {}", .{table.security_status});
    io.println("      OEM-defined:                     {}", .{table.oem_defined});
    io.println("      Height:                          {}", .{table.height});
    io.println("      # Power Cords:                   {}", .{table.num_power_cords});
    io.println("      # Contained Elements:            {}", .{table.contained_element_count});
    io.println("      Contained Element Record Length: {}", .{table.contained_element_record_len});
}

fn dumpProcessorInformation(table: *ProcessorInformation, strings: [16][]const u8) void {
    io.println("    Processor Information (Type: {}, Handle: {x:0>4})", .{table.hdr.type_, table.hdr.handle});
    io.println("      Socket Designation:              {s}", .{strings[table.socket_designation]});
    io.println("      Procssor Type:                   {}", .{table.proc_type});
    io.println("      Procssor Family:                 {}", .{table.proc_family});
    io.println("      Processor Manufacturer:          {s}", .{strings[table.proc_manufacturer]});
    io.println("      Processor ID:                    {x:0>16}", .{table.proc_id});
    io.println("      Processor Version:               {s}", .{strings[table.proc_version]});
    io.println("      Voltage:                         {}", .{table.voltage});
    io.println("      Max Speed:                       {} MHz", .{table.max_speed});
    io.println("      Current Speed:                   {} MHz", .{table.current_speed});
    io.println("      Status:                          0x{x:0>2}", .{table.status});
    io.println("      Processor Upgrade:               {}", .{table.proc_upgrade});
    io.println("      L1 Cache Handle:                 {x:0>4}", .{table.l1_cache_handle});
    io.println("      L2 Cache Handle:                 {x:0>4}", .{table.l2_cache_handle});
    io.println("      L3 Cache Handle:                 {x:0>4}", .{table.l3_cache_handle});
    io.println("      Serial No:                       {s}", .{strings[table.serial_no]});
    io.println("      Asset Tag:                       {s}", .{strings[table.asset_tag]});
    io.println("      Part No:                         {s}", .{strings[table.part_no]});
    io.println("      Core Count:                      {}", .{table.core_count});
    io.println("      Core Enabled:                    {}", .{table.core_enabled});
    io.println("      Thread Count:                    {}", .{table.thread_count});
    io.println("      Processor Characteristics:       {x:0>4}", .{table.proc_characteristics});
    io.println("      Procssor Family 2:               {}", .{table.proc_family2});
    // SMBIOS 3.0 fields
    // io.println("      Core Count 2:              {}", .{table.core_count2});
    // io.println("      Core Enabled 2:            {}", .{table.core_enabled2});
    // io.println("      Thread Count 2:            {}", .{table.thread_count2});
}

fn dumpPhysicalMemoryArray(table: *PhysicalMemoryArray, strings: [16][]const u8) void {
    _ = strings;
    io.println("    Physical Memory Array (Type: {}, Handle: {x:0>4})", .{table.hdr.type_, table.hdr.handle});
    io.println("      Location:                        {}", .{table.location});
    io.println("      Use:                             {}", .{table.use});
    io.println("      Error Correction:                {}", .{table.error_correction});
    io.println("      Maximum Capacity:                {s}", .{fmt.fmtIntSizeBin(table.max_capacity_kb * 1024)});
    io.println("      Error Information Handle:        {x:0>4}", .{table.error_info_handle});
    io.println("      Number of Memory Devices:        {}", .{table.memory_device_count});
    io.println("      Extended Maximum Capacity:       {}", .{table.extended_max_capacity});
}

fn dumpMemoryDevice(table: *MemoryDevice, strings: [16][]const u8) void {
    _ = strings;
    io.println("    Memory Device (Type: {}, Handle: {x:0>4})", .{table.hdr.type_, table.hdr.handle});
    io.println("      Physical Memory Array Handle:    {x:0>4}", .{table.physical_memory_array_handle});
    io.println("      Memory Error Information Handle: {x:0>4}", .{table.error_information_handle});
    io.println("      Total Width:                     {x:0>4}", .{table.total_width});
    io.println("      Data Width:                      {x:0>4}", .{table.data_width});
    io.println("      Size:                            {s}", .{fmt.fmtIntSizeBin(@intCast(u64, table.size) * 1024 * 1024)});
    io.println("      Form Factor:                     {}", .{table.form_factor});
    io.println("      Device Set:                      {}", .{table.device_set});
    io.println("      Device Locator:                  {s}", .{strings[table.device_locator]});
    io.println("      Bank Locator:                    {s}", .{strings[table.bank_locator]});
    io.println("      Memory Type:                     {}", .{table.memory_type});
    io.println("      Type Detail:                     {}", .{table.type_detail});
    io.println("      Speed:                           {x:0>4}", .{table.speed});
    io.println("      Manufacturer:                    {s}", .{strings[table.manufacturer]});
    io.println("      Serial Number:                   {s}", .{strings[table.serial_no]});
    io.println("      Asset Tag:                       {s}", .{strings[table.asset_tag]});
    io.println("      Part Number:                     {s}", .{strings[table.part_no]});
    io.println("      Attributes:                      {x:0>2}", .{table.attributes});
    io.println("      Extended Size:                   {}", .{table.extended_size});
    io.println("      Configured Speed:                {x:0>4}", .{table.configured_memory_speed});
    io.println("      Minimum Voltage:                 {}", .{table.min_voltage});
    io.println("      Maximum Voltage:                 {}", .{table.max_voltage});
    io.println("      Configured Voltage:              {}", .{table.configured_voltage});
}

fn dumpMemoryArrayMappedAddress(table: *MemoryArrayMappedAddress, strings: [16][]const u8) void {
    _ = strings;
    io.println("    Memory Array Mapped Address (Type: {}, Handle: {x:0>4})", .{table.hdr.type_, table.hdr.handle});
    io.println("      Starting Address:                {x:0>8} ({s})", .{table.starting_address, fmt.fmtIntSizeBin(table.starting_address * 1024)});
    io.println("      Ending Address:                  {x:0>8} ({s})", .{table.ending_address, fmt.fmtIntSizeBin((table.ending_address + 1) * 1024)});
    io.println("      Physical Memory Array Handle:    {x:0>4}", .{table.memory_array_handle});
    io.println("      Partition Width:                 {}", .{table.partition_width});
    io.println("      Extended Starting Address:       {x:0>16}", .{table.extended_starting_address});
    io.println("      Extended Ending Address:         {x:0>16}", .{table.extended_ending_address});
}

fn dumpSystemBootInformation(table: *SystemBootInformation, strings: [16][]const u8) void {
    _ = strings;
    io.println("    System Boot Information (Type: {}, Handle: {x:0>4})", .{table.hdr.type_, table.hdr.handle});
    io.println("      Status:                          {}", .{table.status});
}
