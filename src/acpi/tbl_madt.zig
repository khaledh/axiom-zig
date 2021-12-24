const acpi = @import("acpi.zig");
const io = @import("../io.zig");
const print = io.print;
const println = io.println;
const printGuid = io.printGuid;

// Multiple APIC Description Table (MADT)
pub const MADT = packed struct {
    hdr: acpi.TableDescriptionHeader,

    local_apic_addr: u32,
    flags: u32,
};

pub const InterruptControllerHdr = packed struct {
    type: u8 = 0,
    len: u8,
};

pub const LAPIC = packed struct {
    hdr: InterruptControllerHdr,
    processor_uid: u8,
    lapic_id: u8,
    flags: u32,
};

pub const IOAPIC = packed struct {
    hdr: InterruptControllerHdr,
    ioapic_id: u8,
    reserved: u8,
    ioapic_addr: u32,
    gsi_base: u32,
};

pub const InterruptSourceOverride = packed struct {
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

pub fn dumpMadt(madt: *const MADT) void {
    println("", .{});
    println("  ### MADT (Multiple APIC Description Table) ###", .{});
    println("", .{});

    const hdr = @ptrCast(*const acpi.TableDescriptionHeader, &madt.hdr);
    acpi.printTableDescHeader(hdr);
    println("  - Local APIC Address:  0x{x:0>8}", .{madt.local_apic_addr});
    println("  - Flags:               0x{x:0>8}", .{madt.flags});
    println("", .{});
    // var p: usize = @ptrToInt(madt) + 36 + 8;
    var int_ctrl = @intToPtr(*const InterruptControllerHdr, (@ptrToInt(madt) + 36 + 8));
    while (@ptrToInt(int_ctrl) - @ptrToInt(madt) < hdr.length) {
        println("  - Interrupt Ctrl Type: {}", .{int_ctrl.type});
        println("  - Interrupt Ctrl Len:  {}", .{int_ctrl.len});
        switch (int_ctrl.type) {
            0 => {
                const lapic = @ptrCast(*align(1) const LAPIC, int_ctrl);
                println("    [Local APIC]", .{});
                println("      - ACPI Processor UID: {}", .{lapic.processor_uid});
                println("      - LAPIC ID:           {}", .{lapic.lapic_id});
                println("      - Flags:              0x{x:0>8}", .{lapic.flags});
            },
            1 => {
                const ioapic = @ptrCast(*align(1) const IOAPIC, int_ctrl);
                println("    [I/O APIC]", .{});
                println("      - IOAPIC ID:          {}", .{ioapic.ioapic_id});
                println("      - Address:            0x{x: >8}", .{ioapic.ioapic_addr});
                println("      - GSI Base:           {}", .{ioapic.gsi_base});

                const ioregsel = @intToPtr(*u32, ioapic.ioapic_addr);
                const iowin = @intToPtr(*u32, ioapic.ioapic_addr + 0x10);

                ioregsel.* = 0;
                println("      - IOAPICID:           0x{x:0>8}", .{iowin.*});
                ioregsel.* = 1;
                println("      - IOAPICVER:          0x{x:0>8}", .{iowin.*});
                ioregsel.* = 2;
                println("      - IOAPICARB:          0x{x:0>8}", .{iowin.*});

            },
            2 => {
                const int_src_override = @ptrCast(*align(1) const InterruptSourceOverride, int_ctrl);
                println("    [Interrupt Source Override]", .{});
                println("      - Bus:                {}", .{int_src_override.bus});
                println("      - Source:             {}", .{int_src_override.source});
                println("      - GSI:                {}", .{int_src_override.gsi});
                println("      - Flags:              0b{b:0>4}", .{int_src_override.flags});
            },
            4 => {
                const lapic = @ptrCast(*align(1) const LAPIC_NMI, int_ctrl);
                println("    [Local APIC NMI]", .{});
                println("      - ACPI Processor UID: 0x{x: >2}", .{lapic.processor_uid});
                println("      - Flags:              0x{x:0>4}", .{lapic.flags});
                println("      - LINT#:              {}", .{lapic.lapic_lint_n});
            },
            else => {},
        }
        int_ctrl = @intToPtr(*const InterruptControllerHdr, @ptrToInt(int_ctrl) + int_ctrl.len);
        println("", .{});
    }

    // dumpHex(@intToPtr([*]const u8, (@ptrToInt(madt) + 36 + 8)), 76);
}
