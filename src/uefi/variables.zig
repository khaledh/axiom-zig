const std = @import("std");
const uefi = std.os.uefi;
const RuntimeServices = uefi.tables.RuntimeServices;
const io = @import("../io.zig");
const parseGuid = @import("../guid.zig").parseGuid;
const UefiGuid = @import("protocols.zig").UefiGuid;
const DevicePathToTextProtocol = @import("device_path_to_text_protocol.zig").DevicePathToTextProtocol;

const OsIndications = packed struct {
    BOOT_TO_FW_UI: bool,
    TIMESTAMP_REVOCATION: bool,
    FILE_CAPSULE_DELIVERY: bool,
    FMP_CAPSULE: bool,
    CAPSULE_RESULT_VAR: bool,
    START_OS_RECOVERY: bool,
    START_PLATFORM_RECOVERY: bool,
    JSON_CONFIG_DATA_REFRESH: bool,
};

const BootOptionSupport = packed struct {
    BOOT_OPTION_SUPPORT_KEY: bool,
    BOOT_OPTION_SUPPORT_APP: bool,
    _1: u2,
    BOOT_OPTION_SUPPORT_SYSPREP: bool,
    _2: u3,
    BOOT_OPTION_SUPPORT_COUNT: u2,
    _3: u6,
};

const EfiLoadOption = packed struct {
    attributes: EfiLoadOptionAttribute,
    file_path_list_length: u16,
//  description: [_:0]u8,
//  file_path_list: [_]DevicePathProtocol,
//  optional_data: [_]u8,
};

const EfiLoadOptionAttribute = packed struct {
    active:          bool,        // 0x0001
    force_reconnect: bool,        // 0x0002
    _1:              u1,
    hidden:          bool,        // 0x0008
    _2:              u4,
    category: packed union(u5) {  // 0x1f00
        boot: 0,
        app:  1,
    },
};

const EfiKeyOption = packed struct {
    key_data: u32,
    boot_option_crc: u32,
    boot_option: u16,
//  keys: [_]EfiInputKey,
};

const EfiBootKeyData = packed struct {
    revision: u8,
    shift: u1,
    ctrl: u1,
    alt: u1,
    logo: u1,
    menu: u1,
    sysreq: u1,
    reserved: u16,
    input_key_count: u2,
};

pub fn dumpUefiVariables(rs: *RuntimeServices) void {
    io.println("", .{});
    io.println("UEFI Variables", .{});

    var var_name: [256:0]u16 = undefined;
    var_name[0] = 0;
    var var_name_size: usize = 256;
    var var_data: [4096]u8 = undefined;
    var var_data_size: usize = 4096;
    var vendor_guid: uefi.Guid align(8) = undefined;
    var status = rs.getNextVariableName(&var_name_size, &var_name, &vendor_guid);
    while (status != uefi.Status.NotFound) {
        io.print("  ", .{});
        if (vendor_guid.eql(parseGuid("8be4df61-93ca-11D2-AA0D-00e098032b8c"))) {
            io.print("EFI_GLOBAL_VARIABLE:                  ", .{});
        } else if (vendor_guid.eql(parseGuid("d9bee56e-75dc-49D9-B4D7-b534210f637a"))) {
            io.print("EFI_CERT_DB:                          ", .{});
        } else if (vendor_guid.eql(parseGuid("c076ec0c-7028-4399-A072-71ee5c448b9f"))) {
            io.print("EFI_CUSTOM_MODE_ENABLE:               ", .{});
        } else if (vendor_guid.eql(parseGuid("9073e4e0-60ec-4B6E-9903-4c223c260f3c"))) {
            io.print("EFI_VENDOR_KEYS_NV:                   ", .{});
        } else if (vendor_guid.eql(parseGuid("eb704011-1402-11D3-8E77-00a0c969723b"))) {
            io.print("MTC_VENDOR:                           ", .{});
        } else if (vendor_guid.eql(parseGuid("59324945-ec44-4C0D-B1CD-9db139df070c"))) {
            io.print("EFI_ISCSI_INITIATOR_NAME_PROTOCOL:    ", .{});
        } else if (vendor_guid.eql(parseGuid("4b47d616-a8d6-4552-9D44-ccad2e0f4cf9"))) {
            io.print("ISCSI_CONFIG:                         ", .{});
        } else if (vendor_guid.eql(parseGuid("04b37fe8-f6ae-480B-BDD5-37d98c5e89aa"))) {
            io.print("EDKII_VAR_ERROR_FLAG:                 ", .{});
        } else if (vendor_guid.eql(parseGuid("964e5b22-6459-11D2-8E39-00a0c969723b"))) {
            io.print("EFI_SIMPLE_FILE_SYSTEM_PROTOCOL:      ", .{});
        } else if (vendor_guid.eql(parseGuid("4c19049f-4137-4DD3-9C10-8b97a83ffdfa"))) {
            io.print("EFI_MEMORY_TYPE_INFORMATION:          ", .{});
        } else {
            io.printGuid(vendor_guid);
            io.print(":", .{});
        }
        io.print16(&var_name);

        var_data_size = 4096;
        const stgv = rs.getVariable(&var_name, &vendor_guid, null, &var_data_size, &var_data);
        if (stgv == uefi.Status.Success) {
            if (varnameEql(var_name, "SetupMode")) {
                io.print("               = {}", .{var_data[0]});
            } else if (varnameEql(var_name, "CustomMode")) {
                io.print("              = {}", .{var_data[0]});
            } else if (varnameEql(var_name, "BootCurrent")) {
                io.print("             = {}", .{@bitCast(u16, var_data[0..2].*)});
            } else if (varnameEql(var_name, "SecureBoot")) {
                io.print("              = {}", .{var_data[0]});
            } else if (varnameEql(var_name, "VendorKeysNv")) {
                io.print("            = {}", .{var_data[0]});
            } else if (varnameEql(var_name, "VendorKeys")) {
                io.print("              = {}", .{var_data[0]});
            } else if (varnameEql(var_name, "Timeout")) {
                io.print("                 = {} seconds", .{@bitCast(u16, var_data[0..2].*)});
            } else if (varnameEql(var_name, "ConIn") or varnameEql(var_name, "ConOut") or varnameEql(var_name, "ErrOut")) {
                io.print("                 = ", .{});
                var device_path = @ptrCast(*align(1) uefi.protocols.DevicePathProtocol, var_data[0..var_data_size]);
                io.print16(devicePathToText(device_path));
            } else if (varnameEql(var_name, "OsIndicationsSupported")) {
                const flags = @bitCast(OsIndications, var_data[0]);
                io.print("  = ", .{});
                if (flags.BOOT_TO_FW_UI) io.print("BOOT_TO_FW_UI", .{});
                if (flags.TIMESTAMP_REVOCATION) io.print(", TIMESTAMP_REVOCATION", .{});
                if (flags.FILE_CAPSULE_DELIVERY) io.print(", FILE_CAPSULE_DELIVERY", .{});
                if (flags.FMP_CAPSULE) io.print(", FMP_CAPSULE", .{});
                if (flags.CAPSULE_RESULT_VAR) io.print(", CAPSULE_RESULT_VAR", .{});
                if (flags.START_OS_RECOVERY) io.print(", START_OS_RECOVERY", .{});
                if (flags.START_PLATFORM_RECOVERY) io.print(", START_PLATFORM_RECOVERY", .{});
                if (flags.JSON_CONFIG_DATA_REFRESH) io.print(", JSON_CONFIG_DATA_REFRESH", .{});
            } else if (varnameEql(var_name, "BootOptionSupport")) {
                const flags = @bitCast(BootOptionSupport, var_data[0..2].*);
                io.print("       = ", .{});
                if (flags.BOOT_OPTION_SUPPORT_KEY) io.print("BOOT_OPTION_SUPPORT_KEY", .{});
                if (flags.BOOT_OPTION_SUPPORT_APP) io.print(", BOOT_OPTION_SUPPORT_APP", .{});
                if (flags.BOOT_OPTION_SUPPORT_SYSPREP) io.print(", BOOT_OPTION_SUPPORT_SYSPREP", .{});
                if (flags.BOOT_OPTION_SUPPORT_COUNT == 3) io.print(", BOOT_OPTION_SUPPORT_COUNT", .{});
            } else if (varnameEql(var_name, "PlatformLangCodes")) {
                io.print("       = ", .{});
                io.print("{s}", .{var_data[0 .. var_data_size - 1 :0]});
            } else if (varnameEql(var_name, "PlatformLang")) {
                io.print("            = ", .{});
                io.print("{s}", .{var_data[0 .. var_data_size - 1 :0]});
            } else if (varnameEql(var_name, "LangCodes")) {
                io.print("               = ", .{});
                io.print("{s}", .{var_data[0 .. var_data_size - 1 :0]});
            } else if (varnameEql(var_name, "Lang")) {
                io.print("                    = ", .{});
                io.print("{s}", .{var_data[0 .. var_data_size - 1 :0]});
            } else if (varnameEql(var_name, "SignatureSupport")) {
                io.print("        = ", .{});
                var i: usize = 0;
                while (i < var_data_size) : (i += 16) {
                    const guid_bytes = var_data[i..(i + 16)];
                    const guid = @bitCast(uefi.Guid, guid_bytes[0..16].*);
                    if (guid.eql(parseGuid("826ca512-cf10-4AC9-B187-be01496631bd"))) {
                        io.print("EFI_CERT_SHA1", .{});
                    } else if (guid.eql(parseGuid("c1c41626-504c-4092-ACA9-41f936934328"))) {
                        io.print("EFI_CERT_SHA256", .{});
                    } else if (guid.eql(parseGuid("3c5766e8-269c-4E34-AA14-ed776e85b3b6"))) {
                        io.print("EFI_CERT_RSA2048", .{});
                    } else if (guid.eql(parseGuid("a5c059a1-94e4-4AA7-87B5-ab155c2bf072"))) {
                        io.print("EFI_CERT_X509", .{});
                    } else {
                        io.printGuid(guid);
                    }
                    if (i + 16 < var_data_size) {
                        io.print(", ", .{});
                    }
                }
            } else if (varnameEql(var_name, "Attempt")) {
                // skip
            } else if (varnameEql(var_name, "Boot00") or varnameEql(var_name, "PlatformRecovery00")) {
                const desc = @intToPtr([*:0]const u16, @ptrToInt(&var_data) + 6);
                io.print("                = ", .{});
                io.print16(desc);
            // } else if (varnameEql(var_name, "Key00")) {
            //     const key_opt = @ptrCast(*EfiKeyOption, &var_data);
            //     io.print("                = {x:0>8}", .{key_opt.key_data});
            //     // io.print16(desc);
            } else {
                if (var_data_size < 16) {
                    io.print("                    ", .{});
                } else {
                    io.println("", .{});
                }
                io.dumpHex(&var_data, if (var_data_size > 32) 32 else var_data_size);
            }
        } else if (stgv == uefi.Status.BufferTooSmall) {
            io.print("  {} => {}", .{ stgv, var_data_size });
        } else {
            io.print("  {}", .{stgv});
        }
        io.println("", .{});

        var_name_size = 256;
        status = rs.getNextVariableName(&var_name_size, &var_name, &vendor_guid);
    }
}

fn varnameEql(a: [256:0]u16, comptime b: []const u8) bool {
    return std.mem.eql(u16, a[0..b.len], std.unicode.utf8ToUtf16LeStringLiteral(b));
}

pub fn devicePathToText(device_path: *const uefi.protocols.DevicePathProtocol) [*:0]const u16 {
    const st = uefi.system_table;

    var dev_path_to_text: ?*c_void = null;
    _ = st.boot_services.?.locateProtocol(@alignCast(8, &UefiGuid.EFI_DEVICE_PATH_TO_TEXT_PROTOCOL), null, &dev_path_to_text);
    const dptt = @ptrCast(*align(1) const DevicePathToTextProtocol, dev_path_to_text.?);
    return dptt.convertDevicePathToText(device_path, false, true);
}
