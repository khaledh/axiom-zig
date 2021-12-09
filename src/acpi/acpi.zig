const io = @import("../io.zig");
const print = io.print;
const println = io.println;

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

pub const GenericAddress = extern struct {
    addr_space_id: u8,
    reg_bit_width: u8,
    reg_bit_offset: u8,
    access_size: u8,
    address: u64,
};

// Fixed ACPI Description Table
pub const FADT = extern struct {
    hdr: TableDescriptionHeader,

    firmware_ctrl: u32,
    dsdt: u32,
    reserved1: u8,
    preferred_pm_profile: u8,
    sci_int: u16,
    smi_cmd: u32,
    acpi_enable: u8,
    acpi_disable: u8,
    s4bios_req: u8,
    pstate_cnt: u8,
    pm1a_evt_blk: u32,
    pm1b_evt_blk: u32,
    pm1a_cnt_blk: u32,
    pm1b_cnt_blk: u32,
    pm2_cnt_blk: u32,
    pm_tmr_blk: u32,
    gpe0_blk: u32,
    gpe1_blk: u32,
    pm1_evt_len: u8,
    pm1_cnt_len: u8,
    pm2_cnt_len: u8,
    pm_tmr_len: u8,
    gpe0_blk_len: u8,
    gpe1_blk_len: u8,
    gpe1_base: u8,
    cst_cnt: u8,
    p_lvl2_lat: u16,
    p_lvl3_lat: u16,
    flush_size: u16,
    flush_stride: u16,
    duty_offset: u8,
    duty_width: u8,
    day_alarm: u8,
    mon_alarm: u8,
    century: u8,
    iapc_boot_arch: u16,
    reserved2: u8,
    flags: u32,
    // end of ACPI 1.0 fields
    reset_reg: GenericAddress,
    reset_value: u8,
    arm_boot_arch: u16,
    fadt_minor_version: u8,
    x_firmware_ctrl: u64,
    x_dsdt: u64,
    x_pm1a_evt_blk: GenericAddress,
    x_pm1b_evt_blk: GenericAddress,
    x_pm1a_cnt_blk: GenericAddress,
    x_pm1b_cnt_blk: GenericAddress,
    x_pm2_cnt_blk: GenericAddress,
    x_pm_tmr_blk: GenericAddress,
    x_gpe0_blk: GenericAddress,
    x_gpe1_blk: GenericAddress,
    sleep_control_reg: GenericAddress,
    sleep_status_reg: GenericAddress,
    hypervisor_vendor_identity: u64,
};

// Firmware ACPI Control Structure (FACS)
pub const FACS = extern struct {
    signature: [4]u8,
    length: u32,
    hw_signature: u32,
    fw_walking_vector: u32,
    global_lock: u32,
    flags: u32,
    x_fw_walking_vector: u64,
    version: u8,
    reserved1: [3]u8,
    ospm_flags: u32,
    reserved2: [24]u8,
};

// Multiple APIC Description Table (MADT)
pub const MADT = extern struct {
    hdr: TableDescriptionHeader,

    local_apic_addr: u32,
    flags: u32,
};

pub const InterruptControllerHdr = extern struct {
    type: u8 = 0,
    len: u8,
};

pub const LAPIC = extern struct {
    hdr: InterruptControllerHdr,
    processor_uid: u8,
    lapic_id: u8,
    flags: u32,
};

pub const IOAPIC = extern struct {
    hdr: InterruptControllerHdr,
    ioapic_id: u8,
    reserved: u8,
    ioapic_addr: u32,
    gsi_base: u32,
};

pub const InterruptSourceOverride = extern struct {
    hdr: InterruptControllerHdr,
    bus: u8,
    source: u8,
    gsi: u32,
    flags: u16,
};

pub const LAPIC_NMI = packed struct {
    hdr: InterruptControllerHdr,
    processor_uid: u8,
    flags: u16,
    lapic_lint_n: u8,
};

// Boot Graphics Resource Table (BGRT)
pub const BGRT = extern struct {
    hdr: TableDescriptionHeader,

    version: u16,
    status: u8,
    image_type: u8,
    image_addr: u64,
    image_offset_x: u32,
    image_offset_y: u32,
};

fn printTableDescHeader(hdr: *const TableDescriptionHeader) void {
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
