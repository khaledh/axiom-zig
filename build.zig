const std = @import("std");
const builtin = @import("builtin");
const CrossTarget = std.zig.CrossTarget;

pub fn build(b: *std.build.Builder) void {
    const exe = b.addExecutable("bootx64", "src/main.zig");
    exe.setBuildMode(b.standardReleaseOptions());
    exe.setTarget(CrossTarget{
        .cpu_arch = .x86_64,
        .os_tag = .uefi,
        .abi = .msvc,
    });
    exe.setOutputDir("disk-img/efi/boot");
    b.default_step.dependOn(&exe.step);
}
