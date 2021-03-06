const acpi = @import("acpi.zig");
const aml = @import("amlparser.zig");
const io = @import("../io.zig");
const print = io.print;
const println = io.println;

pub fn dumpDsdt(dsdt: *const acpi.TableDescriptionHeader) void {
    println("", .{});
    println("  ### DSDT (Differentiated System Description Table) ###", .{});
    println("", .{});

    acpi.printTableDescHeader(dsdt);
    const aml_block_len = dsdt.length - 36;
    println("  - Definition Block: {} bytes (AML encoded)", .{aml_block_len});

    const aml_block = @intToPtr([*]const u8, @ptrToInt(dsdt) + 36);
    var aml_parser = aml.AmlParser().init();
    aml_parser.parse(aml_block[0..aml_block_len]);

    // io.dumpHex(@intToPtr([*]const u8, (fadt.dsdt + 36)), (dsdt.length - 36));
    // println("", .{});
}
