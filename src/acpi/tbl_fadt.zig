const acpi = @import("acpi.zig");
const io = @import("io.zig");
const print = io.print;
const println = io.println;

pub fn dumpFadt(fadt: acpi.FADT) void {
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
