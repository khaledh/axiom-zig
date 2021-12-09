const std = @import("std");
const fmt = std.fmt;
const uefi = std.os.uefi;
const T = uefi.tables;

const cpu = @import("cpu.zig");
const acpi = @import("acpi/acpi.zig");
const system = @import("system.zig");
const getMemoryMap = @import("uefi/memory.zig").getMemoryMap;
const dumpConfigTableNames = @import("uefi/config.zig").dumpConfigTableNames;
const CompnentName2Protocol = @import("uefi/component_name_protocol.zig").ComponentName2Protocol;
const DevicePathToTextProtocol = @import("uefi/device_path_to_text_protocol.zig").DevicePathToTextProtocol;
const io = @import("io.zig");
const print = io.print;
const println = io.println;
const printGuid = io.printGuid;

pub fn main() usize {
    const con_out = uefi.system_table.con_out.?;
    _ = con_out.reset(false);

    println("Axiom OS", .{});

    const bs = uefi.system_table.boot_services.?;

    getMemoryMap(bs);
    getConfigurationTable();

    var handle_count: usize = undefined;
    var handles: [*]uefi.Handle = undefined;

    _ = bs.locateHandleBuffer(
        T.LocateSearchType.AllHandles,
        null, // *Protocol
        null, // *SearchKey
        &handle_count,
        &handles,
    );

    var dev_path_to_text: ?*c_void = null;
    _ = bs.locateProtocol(@alignCast(8, &UefiGuid.EFI_DEVICE_PATH_TO_TEXT_PROTOCOL), null, &dev_path_to_text);
    const dptt = @ptrCast(*const align(1) DevicePathToTextProtocol, dev_path_to_text.?);

    println("", .{});
    println("UEFI Handles = {}", .{handle_count});
    var i: usize = 0;
    while (i < handle_count) : (i += 1) {
        var proto_count: usize = undefined;
        var proto_guids: [*]*align(8) const uefi.Guid = undefined;

        _ = bs.protocolsPerHandle(handles[i], &proto_guids, &proto_count);
        println("Protocols = {}", .{proto_count});

        var j: usize = 0;
        while (j < proto_count) : (j += 1) {
            print("  ", .{});
            printGuid(proto_guids[j].*);
            print("   ", .{});
            if (getProtocolName(proto_guids[j])) |name| {
                print("{s}", .{name});
            }
            else {
                print(".............................", .{});
            }

            if (proto_guids[j].eql(UefiGuid.EFI_DEVICE_PATH_PROTOCOL) or
                proto_guids[j].eql(UefiGuid.EFI_LOADED_IMAGE_DEVICE_PATH_PROTOCOL))
            {
                var dev_path_i: ?*c_void = undefined;
                _ = bs.openProtocol(handles[i], proto_guids[j], &dev_path_i, uefi.handle, null, .{ .get_protocol = true });
                var dev_path = @ptrCast(*align(1) uefi.protocols.DevicePathProtocol, dev_path_i);
                const dev_path_text = dptt.convertDevicePathToText(dev_path, true, true);
                print("    ", .{});
                _ = con_out.outputString(dev_path_text);
            }
            else if (proto_guids[j].eql(UefiGuid.EFI_COMPONENT_NAME2_PROTOCOL)) {
                var comp_name_i: ?*c_void = undefined;
                _ = bs.openProtocol(handles[i], proto_guids[j], &comp_name_i, uefi.handle, null, .{ .get_protocol = true });
                var comp_name = @ptrCast(*align(1) CompnentName2Protocol, comp_name_i);
                var comp_name_text: [*:0]const u16 = undefined;
                _ = comp_name.getDriverName("en", &comp_name_text);
                print("    ", .{});
                _ = con_out.outputString(comp_name_text);
            }
            println("", .{});
        }
    }

    println("\nShutdown", .{});
    system.shutdown();
    // cpu.halt();
}

fn getProtocolName(guid: *align(8) const uefi.Guid) ?[]const u8 {
    var name: ?[]const u8 = null;

    for (UefiGuids) |g| {
        if (guid.eql(g.guid)) {
            name =g.name;
            break;
        }
    }
    
    return name;
}

pub const UefiGuid = struct {
    pub const EFI_DEVICE_PATH_UTILITIES_PROTOCOL = parseGuid("0379be4e-d706-437D-B037-edb82fb772a4");
    pub const EFI_DEVICE_PATH_PROTOCOL = parseGuid("09576e91-6d3f-11D2-8E39-00a0c969723b");
    pub const EFI_CONFIG_KEYWORD_HANDLER_PROTOCOL = parseGuid("0a8badd5-03b8-4D19-B128-7b8f0edaa596");
    pub const EFI_EBC_PROTOCOL = parseGuid("13ac6dd1-73d0-11D4-B06B-00aa00bd6de7");
    pub const EFI_EXT_SCSI_PASS_THRU_PROTOCOL = parseGuid("143b7632-b81b-4CB7-ABD3-b625a5b9bffe");
    pub const EFI_DISK_INFO_PROTOCOL = parseGuid("d432a67f-14dc-484b-b3bb-3f0291849327");
    pub const EFI_DISK_IO2_PROTOCOL = parseGuid("151c8eae-7f2c-472C-9E54-9828194f6a88");
    pub const EFI_DEFERRED_IMAGE_LOAD_PROTOCOL = parseGuid("15853d7c-3ddf-43E0-A1CB-ebf85b8f872c");
    pub const EFI_DRIVER_BINDING_PROTOCOL = parseGuid("18a031ab-b443-4D1A-A5C0-0c09261e9f71");
    pub const EFI_HII_IMAGE_EX_PROTOCOL = parseGuid("1a1241e6-8f19-41A9-BC0E-e8ef39e06546");
    pub const EFI_ATA_PASS_THRU_PROTOCOL = parseGuid("1d3de7f0-0807-424F-AA69-11a54e19a46f");
    pub const EFI_DEBUG_SUPPORT_PROTOCOL = parseGuid("2755590c-6f3c-42FA-9EA4-a3ba543cda25");
    pub const EFI_PCI_ROOT_BRIDGE_IO_PROTOCOL = parseGuid("2f707ebb-4a1a-11D4-9A38-0090273fc14d");
    pub const EFI_SIMPLE_POINTER_PROTOCOL = parseGuid("31878c87-0b75-11D5-9A4F-0090273fc14d");
    pub const EFI_HII_IMAGE_PROTOCOL = parseGuid("31a6406a-6bdf-4E46-B2A2-ebaa89c40920");
    pub const EFI_HII_CONFIG_ACCESS_PROTOCOL = parseGuid("330d4706-f2a0-4E4F-A369-b66fa8d54385");
    pub const EFI_SIMPLE_TEXT_INPUT_PROTOCOL = parseGuid("387477c1-69c7-11D2-8E39-00a0c969723b");
    pub const EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL = parseGuid("387477c2-69c7-11D2-8E39-00a0c969723b");
    pub const EFI_HTTP_UTILITIES_PROTOCOL = parseGuid("3e35c163-4074-45DD-431E-23989dd86b32");
    pub const EFI_HII_POPUP_PROTOCOL = parseGuid("4311edc0-6054-46D4-9E40-893ea952fccc");
    pub const EDKII_FORM_DISPLAY_ENGINE_PROTOCOL = parseGuid("9bbe29e9-fda1-41EC-AD52-452213742d2e");
    pub const EFI_PCI_IO_PROTOCOL = parseGuid("4cf5b200-68b8-4CA5-9EEC-b23e3f50029a");
    pub const EFI_HII_CONFIG_ROUTING_PROTOCOL = parseGuid("587e72d7-cc50-4F79-8209-ca291fc1a10f");
    pub const EFI_ISCSI_INITIATOR_NAME_PROTOCOL = parseGuid("59324945-ec44-4C0D-B1CD-9db139df070c");
    pub const EFI_LOADED_IMAGE_PROTOCOL = parseGuid("5b1b31a1-9562-11D2-8E3F-00a0c969723b");
    pub const EFI_DRIVER_SUPPORTED_EFI_VERSION_PROTOCOL = parseGuid("5c198761-16a8-4E69-972C-89d67954f81d");
    pub const EFI_HII_PACKAGE_LIST_PROTOCOL = parseGuid("6a1ee763-d47a-43B4-AABE-ef1de2ab56fc");
    pub const EFI_COMPONENT_NAME_PROTOCOL = parseGuid("107a772c-d5e1-11D4-9A46-0090273fc14d");
    pub const EFI_COMPONENT_NAME2_PROTOCOL = parseGuid("6a7a5cff-e8d9-4F70-BADA-75ab3025ce14");
    pub const EFI_AUTHENTICATION_INFO_PROTOCOL = parseGuid("7671d9d0-53db-4173-AA69-2327f21f0bc7");
    pub const EFI_DEVICE_PATH_TO_TEXT_PROTOCOL = parseGuid("8b843e20-8132-4852-90CC-551a4e4a7f1c");
    pub const EFI_DEVICE_PATH_FROM_TEXT_PROTOCOL = parseGuid("05c99a21-c70f-4AD2-8A5F-35df3343f51e");
    pub const EFI_PARTITION_INFO_PROTOCOL = parseGuid("8cf2f62c-bc9b-4821-808D-ec9ec421a1a0");
    pub const EFI_ABSOLUTE_POINTER_PROTOCOL = parseGuid("8d59d32b-c655-4AE9-9B15-f25904992a43");
    pub const EFI_GRAPHICS_OUTPUT_PROTOCOL = parseGuid("9042a9de-23dc-4A38-96FB-7aded080516a");
    pub const EFI_SCSI_IO_PROTOCOL = parseGuid("932f47e6-2362-4002-803E-3cd54b138f85");
    pub const FI_TLS_SERVICE_BINDING_PROTOCOL = parseGuid("952cb795-ff36-48CF-A249-4df486d6ab8d");
    pub const EFI_BLOCK_IO_PROTOCOL = parseGuid("964e5b21-6459-11D2-8E39-00a0c969723b");
    pub const EFI_SIMPLE_FILE_SYSTEM_PROTOCOL = parseGuid("964e5b22-6459-11D2-8E39-00a0c969723b");
    pub const EFI_RESET_NOTIFICATION_PROTOCOL = parseGuid("9da34ae0-eaf9-4BBF-8EC3-fd60226c44be");
    pub const EFI_UNICODE_COLLATION_PROTOCOL = parseGuid("1d85cd7f-f43d-11D2-9A0C-0090273fc14d");
    pub const EFI_UNICODE_COLLATION_PROTOCOL2 = parseGuid("a4c751fc-23ae-4C3E-92E9-4964cf63f349");
    pub const EFI_BLOCK_IO2_PROTOCOL = parseGuid("a77b2472-e282-4E9F-A245-c2c0e27bbcc1");
    pub const EFI_RAM_DISK_PROTOCOL = parseGuid("ab38a0df-6873-44A9-87E6-d4eb56148449");
    pub const EFI_FORM_BROWSER2_PROTOCOL = parseGuid("b9d4c360-bcfb-4F9B-9298-53c136982258");
    pub const EFI_SERIAL_IO_PROTOCOL = parseGuid("bb25cf6f-f1d4-11D2-9A0C-0090273fc1fd");
    pub const EFI_LOADED_IMAGE_DEVICE_PATH_PROTOCOL = parseGuid("bc62157e-3e33-4FEC-9920-2d3b36d750df"); 
    pub const EFI_STORAGE_SECURITY_COMMAND_PROTOCOL = parseGuid("c88b0b6d-0dfc-49A7-9CB4-49074b4c3a78");
    pub const EFI_DISK_IO_PROTOCOL = parseGuid("ce345171-ba0b-11D2-8E4F-00a0c969723b");
    pub const EFI_DECOMPRESS_PROTOCOL = parseGuid("d8117cfe-94a6-11D4-9A3A-0090273fc14d");
    pub const EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL = parseGuid("dd9e7534-7762-4698-8C14-f58517a625aa");
    pub const EFI_HII_FONT_PROTOCOL = parseGuid("e9ca4775-8657-47FC-97E7-7ed65a084324");
    pub const EFI_HII_DATABASE_PROTOCOL = parseGuid("ef9fc172-a1b2-4693-B327-6d32fc416042");
    pub const EFI_ACPI_TABLE_PROTOCOL = parseGuid("ffe06bdd-6107-46A6-7BB2-5a9c7ec5275c");
    pub const EFI_CONSOLE_IN_DEVICE = parseGuid("d3b36f2b-d551-11d4-9a46-0090273fc14d");
    pub const EFI_CONSOLE_OUT_DEVICE = parseGuid("d3b36f2c-d551-11d4-9a46-0090273fc14d");
    pub const EFI_STANDARD_ERROR_DEVICE = parseGuid("d3b36f2d-d551-11d4-9a46-0090273fc14d");
    pub const EFI_SIO_PROTOCOL = parseGuid("215fdd18-bd50-4feb-890b-58ca0b4739e9");
    pub const EFI_FIRMWARE_VOLUME2_PROTOCOL = parseGuid("220e73b6-6bdb-4413-8405-b974b108619a");
    pub const EFI_FIRMWARE_VOLUME_BLOCK2_PROTOCOL = parseGuid("8f644fa9-e850-4DB1-9CE2-0b44698e8da4");
    pub const LZMA_CUSTOM_DECOMPRESS = parseGuid("ee4e5898-3914-4259-9d6e-dc7bd79403cf");
    pub const PCD_PROTOCOL = parseGuid("11b34006-d85b-4D0A-A290-d5a571310ef7");
    pub const GET_PCD_INFO_PROTOCOL = parseGuid("5be40f57-fa68-4610-BBBF-e9c5fcdad365");
    pub const EFI_PCD_PROTOCOL = parseGuid("13a3f0f6-264a-3EF0-F2E0-dec512342f34");
    pub const EFI_GET_PCD_INFO_PROTOCOL = parseGuid("fd0f4478-0efd-461D-BA2D-e58c45fd5f5e");
    pub const EFI_STATUS_CODE_RUNTIME_PROTOCOL = parseGuid("d2b2b828-0826-48a7-b3df-983c006024f0");
    pub const EFI_RSC_HANDLER_PROTOCOL = parseGuid("86212936-0e76-41c8-a03a-2af2fc1c39e2");
    pub const EFI_RUNTIME_ARCH_PROTOCOL = parseGuid("b7dfb4e1-052f-449F-87BE-9818fc91b733");
    pub const EFI_SECURITY2_ARCH_PROTOCOL = parseGuid("a46423e3-4617-49f1-b9ff-d1bfa9115839");
    pub const EFI_SECURITY_ARCH_PROTOCOL = parseGuid("94ab2f58-1438-4ef1-9152-18941a3a0e68");
    pub const EDKII_PECOFF_IMAGE_EMULATOR_PROTOCOL = parseGuid("96f46153-97a7-4793-ACC1-fa19bf78ea97");
    pub const EFI_EBC_VM_TEST_PROTOCOL = parseGuid("aaeaccfd-f27b-4C17-B610-75ca1f2dfb52");
    pub const EFI_LEGACY_8259_PROTOCOL = parseGuid("38321dba-4fe0-4E17-8AEC-413055eaedc1");
    pub const EFI_CPU_ARCH_PROTOCOL = parseGuid("26baccb1-6f42-11D4-BCE7-0080c73c8881");
    pub const EFI_CPU_IO2_PROTOCOL = parseGuid("ad61f191-ae5f-4C0E-B9FA-e869d288c64f");
    pub const EFI_MP_SERVICES_PROTOCOL = parseGuid("3fdda605-a76e-4F46-AD29-12f4531b3d08");
    pub const EFI_INCOMPATIBLE_PCI_DEVICE_SUPPORT_PROTOCOL = parseGuid("eb23f55a-7863-4AC2-8D3D-956535de0375");
    pub const EFI_PCI_HOT_PLUG_INIT_PROTOCOL = parseGuid("aa0e8bc1-dabc-46B0-A844-37b8169b2bea");
    pub const EFI_PCI_HOTPLUG_REQUEST_PROTOCOL = parseGuid("19cb87ab-2cb9-4665-8360-ddcf6054f79d");
    pub const EDKII_PLATFORM_SPECIFIC_RESET_HANDLER_PROTOCOL = parseGuid("2df6ba0b-7092-440D-BD04-fb091ec3f3c1");
    pub const EDKII_PLATFORM_SPECIFIC_RESET_FILTER_PROTOCOL = parseGuid("695d7835-8d47-4C11-AB22-fa8acce7ae7a");
    pub const EFI_RESET_ARCH_PROTOCOL = parseGuid("27cfac88-46cc-11D4-9A38-0090273fc14d");
    pub const EFI_METRONOME_ARCH_PROTOCOL = parseGuid("26baccb2-6f42-11D4-BCE7-0080c73c8881");
    pub const EFI_PRINT2S_PROTOCOL = parseGuid("0cc252d2-c106-4661-B5BD-3147a4f81f92");
    pub const EFI_PRINT2_PROTOCOL = parseGuid("f05976ef-83f1-4F3D-8619-f7595d41e538");
    pub const EFI_HII_STRING_PROTOCOL = parseGuid("0fd96974-23aa-4CDC-B9CB-98d17750322a");
    pub const EFI_GENERIC_MEMORY_TEST_PROTOCOL = parseGuid("309de7f1-7f5e-4ACE-B49C-531be5aa95ef");
    pub const EFI_ACPI_SDT_PROTOCOL = parseGuid("eb97088e-cfdf-49C6-BE4B-d906a5b20e86");
    pub const EFI_DPC_PROTOCOL = parseGuid("480f8ae9-0c46-4AA9-BC89-db9fba619806");
    pub const IOMMU_ABSENT_PROTOCOL = parseGuid("f8775d50-8abd-4ADF-92AC-853e51f6c8dc");
    pub const EFI_VARIABLE_WRITE_ARCH_PROTOCOL = parseGuid("6441f818-6362-4E44-B570-7dba31dd2453");
    pub const EDKII_VARIABLE_POLICY_PROTOCOL = parseGuid("81d1675c-86f6-48DF-BD95-9a6e4f0925c3");
    pub const EFI_VARIABLE_ARCH_PROTOCOL = parseGuid("1e5668e2-8481-11D4-BCF1-0080c73c8881");
    pub const EDKII_VAR_CHECK_PROTOCOL = parseGuid("af23b340-97b4-4685-8D4F-a3f28169b21d");
    pub const EDKII_VARIABLE_LOCK_PROTOCOL = parseGuid("cd3d0a05-9e24-437C-A891-1ee053db7638");
    pub const EFI_TIMER_ARCH_PROTOCOL = parseGuid("26baccb3-6f42-11D4-BCE7-0080c73c8881");
    pub const EFI_PCI_ENUMERATION_COMPLETE = parseGuid("30cfe3e7-3de1-4586-BE20-deaba1b3b793");
    pub const EFI_PCI_HOST_BRIDGE_RESOURCE_ALLOCATION_PROTOCOL = parseGuid("cf8034be-6768-4D8B-B739-7cce683a9fbe");
    pub const FORM_BROWSER_EXTENSION_PROTOCOL = parseGuid("1f73b18d-4630-43C1-A1DE-6f80855d7da4");
    pub const EDKII_FORM_BROWSER_EXTENSION2_PROTOCOL = parseGuid("a770c357-b693-4E6D-A6CF-d21c728e550b");
    pub const EFI_SMBIOS_PROTOCOL = parseGuid("03583ff6-cb36-4940-947E-b9b39f4afaf7");
    pub const EFI_LOCK_BOX_PROTOCOL = parseGuid("bd445d79-b7ad-4F04-9AD8-29bd2040eb3c");
    pub const EFI_S3_SAVE_STATE_PROTOCOL = parseGuid("e857caf6-c046-45DC-BE3F-ee0765fba887");
    pub const EFI_SHELL_DYNAMIC_COMMAND_PROTOCOL = parseGuid("3c7200e9-005f-4EA4-87DE-a3dfac8a27c3");
    pub const EDKII_PLATFORM_LOGO_PROTOCOL = parseGuid("53cd299f-2bc1-40C0-8C07-23f64fdb30e0");
    pub const EFI_FAULT_TOLERANT_WRITE_PROTOCOL = parseGuid("3ebd9e82-2c78-4DE6-9786-8d4bfcb7c881");
    pub const EFI_REAL_TIME_CLOCK_ARCH_PROTOCOL = parseGuid("27cfac87-46cc-11D4-9A38-0090273fc14d");
    pub const EFI_DXE_MM_READY_TO_LOCK_PROTOCOL = parseGuid("60ff8964-e906-41D0-AFED-f241e974e08e");
    pub const EFI_IDE_CONTROLLER_INIT_PROTOCOL = parseGuid("a1e37052-80d9-4E65-A317-3e9a55c43ec9");
    pub const EDKII_BOOT_LOGO2_PROTOCOL = parseGuid("4b5dc1df-1eaa-48B2-A7E9-eac489a00b5c");
    pub const EDKII_BOOT_LOGO_PROTOCOL = parseGuid("cdea2bd3-fc25-4C1C-B97C-b31186064990");
    pub const EFI_BDS_ARCH_PROTOCOL = parseGuid("665e3ff6-46cc-11D4-9A38-0090273fc14d");
    pub const EFI_CAPSULE_ARCH_PROTOCOL = parseGuid("5053697e-2cbc-4819-90D9-0580deee5754");
    pub const EFI_MONOTONIC_COUNTER_ARCH_PROTOCOL = parseGuid("1da97072-bddc-4B30-99F1-72a0b56fff2a");
    pub const EFI_WATCHDOG_TIMER_ARCH_PROTOCOL = parseGuid("665e3ff5-46cc-11D4-9A38-0090273fc14d");
};

const GuidName = struct {
    guid: uefi.Guid,
    name: []const u8,
};

const UefiGuids = [_]GuidName{
    .{ .guid = UefiGuid.EFI_DEVICE_PATH_UTILITIES_PROTOCOL, .name = "EFI_DEVICE_PATH_UTILITIES_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DEVICE_PATH_PROTOCOL, .name = "EFI_DEVICE_PATH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_CONFIG_KEYWORD_HANDLER_PROTOCOL, .name = "EFI_CONFIG_KEYWORD_HANDLER_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_EBC_PROTOCOL, .name = "EFI_EBC_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_EXT_SCSI_PASS_THRU_PROTOCOL, .name = "EFI_EXT_SCSI_PASS_THRU_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DISK_INFO_PROTOCOL, .name = "EFI_DISK_INFO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DISK_IO2_PROTOCOL, .name = "EFI_DISK_IO2_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DEFERRED_IMAGE_LOAD_PROTOCOL, .name = "EFI_DEFERRED_IMAGE_LOAD_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DRIVER_BINDING_PROTOCOL, .name = "EFI_DRIVER_BINDING_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HII_IMAGE_EX_PROTOCOL, .name = "EFI_HII_IMAGE_EX_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_ATA_PASS_THRU_PROTOCOL, .name = "EFI_ATA_PASS_THRU_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DEBUG_SUPPORT_PROTOCOL, .name = "EFI_DEBUG_SUPPORT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_PCI_ROOT_BRIDGE_IO_PROTOCOL, .name = "EFI_PCI_ROOT_BRIDGE_IO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SIMPLE_POINTER_PROTOCOL, .name = "EFI_SIMPLE_POINTER_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HII_IMAGE_PROTOCOL, .name = "EFI_HII_IMAGE_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HII_CONFIG_ACCESS_PROTOCOL, .name = "EFI_HII_CONFIG_ACCESS_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SIMPLE_TEXT_INPUT_PROTOCOL, .name = "EFI_SIMPLE_TEXT_INPUT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL, .name = "EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HTTP_UTILITIES_PROTOCOL, .name = "EFI_HTTP_UTILITIES_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HII_POPUP_PROTOCOL, .name = "EFI_HII_POPUP_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_FORM_DISPLAY_ENGINE_PROTOCOL, .name = "EDKII_FORM_DISPLAY_ENGINE_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_PCI_IO_PROTOCOL, .name = "EFI_PCI_IO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HII_CONFIG_ROUTING_PROTOCOL, .name = "EFI_HII_CONFIG_ROUTING_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_ISCSI_INITIATOR_NAME_PROTOCOL, .name = "EFI_ISCSI_INITIATOR_NAME_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_LOADED_IMAGE_PROTOCOL, .name = "EFI_LOADED_IMAGE_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DRIVER_SUPPORTED_EFI_VERSION_PROTOCOL, .name = "EFI_DRIVER_SUPPORTED_EFI_VERSION_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HII_PACKAGE_LIST_PROTOCOL, .name = "EFI_HII_PACKAGE_LIST_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_COMPONENT_NAME_PROTOCOL, .name = "EFI_COMPONENT_NAME_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_COMPONENT_NAME2_PROTOCOL, .name = "EFI_COMPONENT_NAME2_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_AUTHENTICATION_INFO_PROTOCOL, .name = "EFI_AUTHENTICATION_INFO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DEVICE_PATH_TO_TEXT_PROTOCOL, .name = "EFI_DEVICE_PATH_TO_TEXT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DEVICE_PATH_FROM_TEXT_PROTOCOL, .name = "EFI_DEVICE_PATH_FROM_TEXT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_PARTITION_INFO_PROTOCOL, .name = "EFI_PARTITION_INFO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_ABSOLUTE_POINTER_PROTOCOL, .name = "EFI_ABSOLUTE_POINTER_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_GRAPHICS_OUTPUT_PROTOCOL, .name = "EFI_GRAPHICS_OUTPUT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SCSI_IO_PROTOCOL, .name = "EFI_SCSI_IO_PROTOCOL" },
    .{ .guid = UefiGuid.FI_TLS_SERVICE_BINDING_PROTOCOL, .name = "FI_TLS_SERVICE_BINDING_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_BLOCK_IO_PROTOCOL, .name = "EFI_BLOCK_IO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SIMPLE_FILE_SYSTEM_PROTOCOL, .name = "EFI_SIMPLE_FILE_SYSTEM_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_RESET_NOTIFICATION_PROTOCOL, .name = "EFI_RESET_NOTIFICATION_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_UNICODE_COLLATION_PROTOCOL, .name = "EFI_UNICODE_COLLATION_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_UNICODE_COLLATION_PROTOCOL2, .name = "EFI_UNICODE_COLLATION_PROTOCOL2" },
    .{ .guid = UefiGuid.EFI_BLOCK_IO2_PROTOCOL, .name = "EFI_BLOCK_IO2_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_RAM_DISK_PROTOCOL, .name = "EFI_RAM_DISK_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_FORM_BROWSER2_PROTOCOL, .name = "EFI_FORM_BROWSER2_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SERIAL_IO_PROTOCOL, .name = "EFI_SERIAL_IO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_LOADED_IMAGE_DEVICE_PATH_PROTOCOL, .name = "EFI_LOADED_IMAGE_DEVICE_PATH_PROTOCOL" }, 
    .{ .guid = UefiGuid.EFI_STORAGE_SECURITY_COMMAND_PROTOCOL, .name = "EFI_STORAGE_SECURITY_COMMAND_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DISK_IO_PROTOCOL, .name = "EFI_DISK_IO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DECOMPRESS_PROTOCOL, .name = "EFI_DECOMPRESS_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL, .name = "EFI_SIMPLE_TEXT_INPUT_EX_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HII_FONT_PROTOCOL, .name = "EFI_HII_FONT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HII_DATABASE_PROTOCOL, .name = "EFI_HII_DATABASE_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_ACPI_TABLE_PROTOCOL, .name = "EFI_ACPI_TABLE_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_CONSOLE_IN_DEVICE, .name = "EFI_CONSOLE_IN_DEVICE" },
    .{ .guid = UefiGuid.EFI_CONSOLE_OUT_DEVICE, .name = "EFI_CONSOLE_OUT_DEVICE" },
    .{ .guid = UefiGuid.EFI_STANDARD_ERROR_DEVICE, .name = "EFI_STANDARD_ERROR_DEVICE" },
    .{ .guid = UefiGuid.EFI_SIO_PROTOCOL, .name = "EFI_SIO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_FIRMWARE_VOLUME2_PROTOCOL, .name = "EFI_FIRMWARE_VOLUME2_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_FIRMWARE_VOLUME_BLOCK2_PROTOCOL, .name = "EFI_FIRMWARE_VOLUME_BLOCK2_PROTOCOL" },
    .{ .guid = UefiGuid.LZMA_CUSTOM_DECOMPRESS, .name = "LZMA_CUSTOM_DECOMPRESS" },
    .{ .guid = UefiGuid.GET_PCD_INFO_PROTOCOL, .name = "GET_PCD_INFO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_GET_PCD_INFO_PROTOCOL, .name = "EFI_GET_PCD_INFO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_PCD_PROTOCOL, .name = "EFI_PCD_PROTOCOL" },
    .{ .guid = UefiGuid.PCD_PROTOCOL, .name = "PCD_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_STATUS_CODE_RUNTIME_PROTOCOL, .name = "EFI_STATUS_CODE_RUNTIME_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_RSC_HANDLER_PROTOCOL, .name = "EFI_RSC_HANDLER_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_RUNTIME_ARCH_PROTOCOL, .name = "EFI_RUNTIME_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SECURITY_ARCH_PROTOCOL, .name = "EFI_SECURITY_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SECURITY2_ARCH_PROTOCOL, .name = "EFI_SECURITY2_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_PECOFF_IMAGE_EMULATOR_PROTOCOL, .name = "EDKII_PECOFF_IMAGE_EMULATOR_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_EBC_VM_TEST_PROTOCOL, .name = "EFI_EBC_VM_TEST_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_LEGACY_8259_PROTOCOL, .name = "EFI_LEGACY_8259_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_CPU_ARCH_PROTOCOL, .name = "EFI_CPU_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_CPU_IO2_PROTOCOL, .name = "EFI_CPU_IO2_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_MP_SERVICES_PROTOCOL, .name = "EFI_MP_SERVICES_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_INCOMPATIBLE_PCI_DEVICE_SUPPORT_PROTOCOL, .name = "EFI_INCOMPATIBLE_PCI_DEVICE_SUPPORT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_PCI_HOT_PLUG_INIT_PROTOCOL, .name = "EFI_PCI_HOT_PLUG_INIT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_PCI_HOTPLUG_REQUEST_PROTOCOL, .name = "EFI_PCI_HOTPLUG_REQUEST_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_PLATFORM_SPECIFIC_RESET_HANDLER_PROTOCOL, .name = "EDKII_PLATFORM_SPECIFIC_RESET_HANDLER_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_PLATFORM_SPECIFIC_RESET_FILTER_PROTOCOL, .name = "EDKII_PLATFORM_SPECIFIC_RESET_FILTER_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_RESET_ARCH_PROTOCOL, .name = "EFI_RESET_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_METRONOME_ARCH_PROTOCOL, .name = "EFI_METRONOME_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_PRINT2S_PROTOCOL, .name = "EFI_PRINT2S_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_PRINT2_PROTOCOL, .name = "EFI_PRINT2_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_HII_STRING_PROTOCOL, .name = "EFI_HII_STRING_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_GENERIC_MEMORY_TEST_PROTOCOL, .name = "EFI_GENERIC_MEMORY_TEST_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_ACPI_SDT_PROTOCOL, .name = "EFI_ACPI_SDT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DPC_PROTOCOL, .name = "EFI_DPC_PROTOCOL" },
    .{ .guid = UefiGuid.IOMMU_ABSENT_PROTOCOL, .name = "IOMMU_ABSENT_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_VARIABLE_WRITE_ARCH_PROTOCOL, .name = "EFI_VARIABLE_WRITE_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_VARIABLE_POLICY_PROTOCOL, .name = "EDKII_VARIABLE_POLICY_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_VARIABLE_ARCH_PROTOCOL, .name = "EFI_VARIABLE_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_VAR_CHECK_PROTOCOL, .name = "EDKII_VAR_CHECK_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_VARIABLE_LOCK_PROTOCOL, .name = "EDKII_VARIABLE_LOCK_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_TIMER_ARCH_PROTOCOL, .name = "EFI_TIMER_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_PCI_ENUMERATION_COMPLETE, .name = "EFI_PCI_ENUMERATION_COMPLETE" },
    .{ .guid = UefiGuid.EFI_PCI_HOST_BRIDGE_RESOURCE_ALLOCATION_PROTOCOL, .name = "EFI_PCI_HOST_BRIDGE_RESOURCE_ALLOCATION_PROTOCOL" },
    .{ .guid = UefiGuid.FORM_BROWSER_EXTENSION_PROTOCOL, .name = "FORM_BROWSER_EXTENSION_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_FORM_BROWSER_EXTENSION2_PROTOCOL, .name = "EDKII_FORM_BROWSER_EXTENSION2_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SMBIOS_PROTOCOL, .name = "EFI_SMBIOS_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_LOCK_BOX_PROTOCOL, .name = "EFI_LOCK_BOX_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_S3_SAVE_STATE_PROTOCOL, .name = "EFI_S3_SAVE_STATE_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_SHELL_DYNAMIC_COMMAND_PROTOCOL, .name = "EFI_SHELL_DYNAMIC_COMMAND_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_PLATFORM_LOGO_PROTOCOL, .name = "EDKII_PLATFORM_LOGO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_FAULT_TOLERANT_WRITE_PROTOCOL, .name = "EFI_FAULT_TOLERANT_WRITE_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_REAL_TIME_CLOCK_ARCH_PROTOCOL, .name = "EFI_REAL_TIME_CLOCK_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_DXE_MM_READY_TO_LOCK_PROTOCOL, .name = "EFI_DXE_MM_READY_TO_LOCK_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_IDE_CONTROLLER_INIT_PROTOCOL, .name = "EFI_IDE_CONTROLLER_INIT_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_BOOT_LOGO2_PROTOCOL, .name = "EDKII_BOOT_LOGO2_PROTOCOL" },
    .{ .guid = UefiGuid.EDKII_BOOT_LOGO_PROTOCOL, .name = "EDKII_BOOT_LOGO_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_BDS_ARCH_PROTOCOL, .name = "EFI_BDS_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_CAPSULE_ARCH_PROTOCOL, .name = "EFI_CAPSULE_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_MONOTONIC_COUNTER_ARCH_PROTOCOL, .name = "EFI_MONOTONIC_COUNTER_ARCH_PROTOCOL" },
    .{ .guid = UefiGuid.EFI_WATCHDOG_TIMER_ARCH_PROTOCOL, .name = "EFI_WATCHDOG_TIMER_ARCH_PROTOCOL" },
};

// fn createGuid(p1: u32, p2: u16, p3: u16, p4: u8, p5: u8, p6: [6]u8) uefi.Guid {
//     return uefi.Guid{
//         .time_low = p1,
//         .time_mid = p2,
//         .time_high_and_version = p3,
//         .clock_seq_high_and_reserved = p4,
//         .clock_seq_low = p5,
//         .node = p6,
//     };
// }

fn parseGuid(comptime str: []const u8) uefi.Guid {
    @setEvalBranchQuota(4000);
    const p1 = fmt.parseUnsigned(u32, str[0..8], 16) catch unreachable;
    const p2 = fmt.parseUnsigned(u16, str[9..13], 16) catch unreachable;
    const p3 = fmt.parseUnsigned(u16, str[14..18], 16) catch unreachable;
    const p4 = fmt.parseUnsigned(u8, str[19..21], 16) catch unreachable;
    const p5 = fmt.parseUnsigned(u8, str[21..23], 16) catch unreachable;
    const p6a = fmt.parseUnsigned(u8, str[24..26], 16) catch unreachable;
    const p6b = fmt.parseUnsigned(u8, str[26..28], 16) catch unreachable;
    const p6c = fmt.parseUnsigned(u8, str[28..30], 16) catch unreachable;
    const p6d = fmt.parseUnsigned(u8, str[30..32], 16) catch unreachable;
    const p6e = fmt.parseUnsigned(u8, str[32..34], 16) catch unreachable;
    const p6f = fmt.parseUnsigned(u8, str[34..36], 16) catch unreachable;
    const p6 = .{ p6a, p6b, p6c, p6d, p6e, p6f };
    // const p6 = arr: {
    //     var bytes: [6]u8 = undefined;
    //     for (bytes) |*b, i| {
    //         if (i == 5) break;
    //         b.* = fmt.parseUnsigned(u8, str[(24+i*2)..(24+i*2)+2], 16) catch unreachable;
    //     }
    //     break :arr bytes;
    // };

    return uefi.Guid{
        .time_low = p1,
        .time_mid = p2,
        .time_high_and_version = p3,
        .clock_seq_high_and_reserved = p4,
        .clock_seq_low = p5,
        // .node = arr: {
        //     var bytes: [6]u8 = undefined;
        //     for (bytes) |*b, i| {
        //         b.* = fmt.parseUnsigned(u8, str[(24+i*2)..(24+i*2)+2], 16) catch unreachable;
        //     }
        //     break :arr bytes;
        // },
        .node = p6,
    };
}

fn p(str: *const [36:0]u8, start: usize) u8 {
    return fmt.parseUnsigned(u8, str[start..(start+2)], 16) catch unreachable;
}


fn getConfigurationTable() void {
    const st = uefi.system_table;

    dumpConfigTableNames(st);

    // ACPI 2.0

    // if (rdsp != undefined) {

    //     println("", .{});
    //     println("### ACPI 2.0 Tables ###", .{});

    //     dumpRsdp(rsdp);

    //     const xdst = @intToPtr(*acpi.XSDT, rdsp.xsdt_address);

    //     dumpXdst(xdst);

    //     dumpFadt(fadt);
    //     dumpFacs(facs);
    //     dumpDsdt(dsdt);
    //     dumpMadt(madt);
    //     dumpBgrt(bgrt);
        
    //     println("", .{});
    // }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    _ = error_return_trace;
    println("\n\npanic: {s}\n", .{msg});

    cpu.halt();
}
