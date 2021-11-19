const io = @import("../io.zig");
const print = io.print;
const println = io.println;
const std = @import("std");
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const AllocationError = std.mem.Allocator.Error;

const Prefix = enum(u8) {
    BytePrefix         = 0x0A,
    WordPrefix         = 0x0B,
    DWordPrefix        = 0x0C,
    StringPrefix       = 0x0D,
    QWordPrefix        = 0x0E,
    DualNamePrefix     = 0x2E, // ('.')
    MultiNamePrefix    = 0x2F, // ('/')
    ExtOpPrefix        = 0x5B, // ('[')'
};

const Char = enum(u8) {
    Null               = 0x00,
    DigitChar_Start    = 0x30, // ('0'-'9')
    DigitChar_End      = 0x39, // ('0'-'9')
    AlphaChar_Start    = 0x41, // ('A'-'Z')
    AlphaChar_End      = 0x5A, // ('A'-'Z')
    RootChar           = 0x5C, // ('\')
    ParentPrefixChar   = 0x5E, // ('^')
    UnderscoreChar     = 0x5F, // ('_')
};

const OpCodeByte = enum(u8) {
    ZeroOp             = 0x00,
    OneOp              = 0x01,
    AliasOp            = 0x06,
    NameOp             = 0x08,
    ScopeOp            = 0x10,
    BufferOp           = 0x11,
    PackageOp          = 0x12,
    VarPackageOp       = 0x13,
    MethodOp           = 0x14,
    ExternalOp         = 0x15,
    Local0Op           = 0x60, // ('`')
    Local1Op           = 0x61, // ('a')
    Local2Op           = 0x62, // ('b')
    Local3Op           = 0x63, // ('c')
    Local4Op           = 0x64, // ('d')
    Local5Op           = 0x65, // ('e')
    Local6Op           = 0x66, // ('f')
    Local7Op           = 0x67, // ('g')
    Arg0Op             = 0x68, // ('h')
    Arg1Op             = 0x69, // ('i')
    Arg2Op             = 0x6A, // ('j')
    Arg3Op             = 0x6B, // ('k')
    Arg4Op             = 0x6C, // ('l')
    Arg5Op             = 0x6D, // ('m')
    Arg6Op             = 0x6E, // ('n')
    StoreOp            = 0x70,
    RefOfOp            = 0x71,
    AddOp              = 0x72,
    ConcatOp           = 0x73,
    SubtractOp         = 0x74,
    IncrementOp        = 0x75,
    DecrementOp        = 0x76,
    MultiplyOp         = 0x77,
    DivideOp           = 0x78,
    ShiftLeftOp        = 0x79,
    ShiftRightOp       = 0x7A,
    AndOp              = 0x7B,
    NandOp             = 0x7C,
    OrOp               = 0x7D,
    NorOp              = 0x7E,
    XorOp              = 0x7F,
    NotOp              = 0x80,
    FindSetLeftBitOp   = 0x81,
    FindSetRightBitOp  = 0x82,
    DerefOfOp          = 0x83,
    ConcatResOp        = 0x84,
    ModOp              = 0x85,
    NotifyOp           = 0x86,
    SizeOfOp           = 0x87,
    IndexOp            = 0x88,
    MatchOp            = 0x89,
    CreateDWordFieldOp = 0x8A,
    CreateWordFieldOp  = 0x8B,
    CreateByteFieldOp  = 0x8C,
    CreateBitFieldOp   = 0x8D,
    ObjectTypeOp       = 0x8E,
    CreateQWordFieldOp = 0x8F,
    LandOp             = 0x90,
    LorOp              = 0x91,
    LnotOp             = 0x92,
    LEqualOp           = 0x93,
    LGreaterOp         = 0x94,
    LLessOp            = 0x95,
    ToBufferOp         = 0x96,
    ToDecimalStringOp  = 0x97,
    ToHexStringOp      = 0x98,
    ToIntegerOp        = 0x99,
    ToStringOp         = 0x9C,
    CopyObjectOp       = 0x9D,
    MidOp              = 0x9E,
    ContinueOp         = 0x9F,
    IfOp               = 0xA0,
    ElseOp             = 0xA1,
    WhileOp            = 0xA2,
    NoopOp             = 0xA3,
    ReturnOp           = 0xA4,
    BreakOp            = 0xA5,
    BreakPointOp       = 0xCC,
    OnesOp             = 0xFF,
};

const OpCodeWord = enum(u16) {
    MutexOp            = 0x01_5B,
    EventOp            = 0x02_5B,
    CondRefOfOp        = 0x12_5B,
    CreateFieldOp      = 0x13_5B,
    LoadTableOp        = 0x1F_5B,
    LoadOp             = 0x20_5B,
    StallOp            = 0x21_5B,
    SleepOp            = 0x22_5B,
    AcquireOp          = 0x23_5B,
    SignalOp           = 0x24_5B,
    WaitOp             = 0x25_5B,
    ResetOp            = 0x26_5B,
    ReleaseOp          = 0x27_5B,
    FromBCDOp          = 0x28_5B,
    ToBCD              = 0x29_5B,
    Reserved           = 0x2A_5B,
    RevisionOp         = 0x30_5B,
    DebugOp            = 0x31_5B,
    FatalOp            = 0x32_5B,
    TimerOp            = 0x33_5B,
    OpRegionOp         = 0x80_5B,
    FieldOp            = 0x81_5B,
    DeviceOp           = 0x82_5B,
    PowerResOp         = 0x84_5B,
    ThermalZoneOp      = 0x85_5B,
    IndexFieldOp       = 0x86_5B,
    BankFieldOp        = 0x87_5B,
    DataRegionOp       = 0x88_5B,

    LNotEqualOp        = 0x93_92,
    LLessEqualOp       = 0x94_92,
    LGreaterEqualOp    = 0x95_92,
};

var buf: [100 * 1024]u8 = undefined;
var allocator = FixedBufferAllocator.init(&buf).allocator;

// AST

const TermObj = union(enum) {
    obj: *Object,
    stmt_opcode: *StatementOpcode,
    expr_opcode: *ExpressionOpcode,
};

const StatementOpcode = struct {
    // break_: *Break,
    // break_point: *BreakPoint,
    // continue_: *Continue,
    // fatal: *Fatal,
    // if_else: *IfElse,
    // noop: *Noop,
    // notify: *Notify,
    // release: *Release,
    // reset: *Reset,
    // return_: *Return,
    // signal: *Signal,
    // sleep: *Sleep,
    // stall: *Stall,
    while_: *While
};

const While = struct {
    predicate: *TermArg,
    terms: []TermObj,
};

const ExpressionOpcode = union(enum) {
    // DefAcquire,
    // DefAdd,
    // DefAnd,
    // DefBuffer,
    // DefConcat,
    // DefConcatRes,
    // DefCondRefOf,
    // DefCopyObject,
    // DefDecrement,
    deref_of: *DerefOf,
    // DefDivide,
    // DefFindSetLeftBit,
    // DefFindSetRightBit,
    // DefFromBCD,
    increment: *Increment,
    index: *Index,
    // DefLAnd,
    // DefLEqual,
    // DefLGreater,
    // DefLGreaterEqual,
    lless: *LLess,
    // DefLLessEqual,
    // DefMid,
    // DefLNot,
    // DefLNotEqual,
    // DefLoadTable,
    // DefLOr,
    // DefMatch,
    // DefMod,
    // DefMultiply,
    // DefNAnd,
    // DefNOr,
    // DefNot,
    // DefObjectType,
    // DefOr,
    // DefPackage,
    // DefVarPackage,
    // DefRefOf,
    // DefShiftLeft,
    // DefShiftRight,
    size_of: *SizeOf,
    store: *Store,
    subtract: *Subtract,
    // DefTimer,
    // DefToBCD,
    to_buffer: *ToBuffer,
    // DefToDecimalString,
    to_hex_string: *ToHexString,
    // DefToInteger,
    // DefToString,
    // DefWait,
    // DefXOr,
    // MethodInvocation,
};

const DerefOf = struct {
    obj_ref: *TermArg,
};

const Increment = struct {
    operand: *SuperName,
};

const Index = struct {
    obj: *TermArg,
    index: *TermArg,
    target: ?*SuperName,
};

const LLess = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

const SizeOf = struct {
    operand: *SuperName,
};

const Store = struct {
    operand: *TermArg,
    target: *SuperName,
};

const Subtract = struct {
    operand1: *TermArg,
    operand2: *TermArg,
    target: ?*SuperName,
};

const ToBuffer = struct {
    operand: *TermArg,
    target: ?*SuperName,
};

const ToHexString = struct {
    operand: *TermArg,
    target: ?*SuperName,
};

const SuperName = union(enum) {
    simple_name: *SimpleName,
    // debug_obj: DebugObj,
    // ref_type_opcode: ReferenceTypeOpcode,
};

const SimpleName = union(enum) {
    name: *NameString,
    arg: ArgObj,
    local: LocalObj
};

const Object = union(enum) {
    ns_mod_obj: *NameSpaceModifierObj,
    named_obj: *NamedObj,
};

const NameSpaceModifierObj = union(enum) {
    // def_alias: *DefAlias,
    // def_name: *DefName,
    def_scope: *DefScope,
};

const DefScope = struct {
    name: *NameString,
    terms: []TermObj,
};

const NameString = union(enum) {
    abs_name: []const u8,
    rel_name: []const u8,
};

const NamedObj = union(enum) {
    def_op_region: *DefOpRegion,
    def_field: *DefField,
    def_method: *DefMethod,
};

const DefOpRegion = struct {
    name: *NameString,
    space: u8,
    offset: *TermArg,
    len: *TermArg,
};

const DefField = struct {
    name: *NameString,
    flags: u8,
    field_list: []FieldElement,
};

const FieldElement = union(enum) {
    named_fld: *NamedField,
    // reserved_fld: ReservedField,
    // access_fld: AccessField,
    // ext_access_fld: ExtendedAccessField,
    // connect_fld: ConnectField,
};

const NamedField = struct {
    name: NameSeg,
    bits: u32,
};

const NameSeg = [4]u8;

const DefMethod = struct {
    name: *NameString,
    flags: u8,
    terms: []TermObj,
};

const TermArg = union(enum) {
    expr_opcode: *ExpressionOpcode,
    data_obj: *DataObject,
    arg_obj: ArgObj,
    local_obj: LocalObj,
};

const DataObject = union(enum) {
    comp_data: *ComputationalData,
    // DefPackage,
    // DefVarPackage,
};

const ArgObj = enum(u8) {
    arg0 = @enumToInt(OpCodeByte.Arg0Op),
    arg1 = @enumToInt(OpCodeByte.Arg1Op),
    arg2 = @enumToInt(OpCodeByte.Arg2Op),
    arg3 = @enumToInt(OpCodeByte.Arg3Op),
    arg4 = @enumToInt(OpCodeByte.Arg4Op),
    arg5 = @enumToInt(OpCodeByte.Arg5Op),
    arg6 = @enumToInt(OpCodeByte.Arg6Op),
};

const LocalObj = enum(u8) {
    local0 = @enumToInt(OpCodeByte.Local0Op),
    local1 = @enumToInt(OpCodeByte.Local1Op),
    local2 = @enumToInt(OpCodeByte.Local2Op),
    local3 = @enumToInt(OpCodeByte.Local3Op),
    local4 = @enumToInt(OpCodeByte.Local4Op),
    local5 = @enumToInt(OpCodeByte.Local5Op),
    local6 = @enumToInt(OpCodeByte.Local6Op),
    local7 = @enumToInt(OpCodeByte.Local7Op)
};

const ComputationalData = union(enum) {
    byte_const: u8,
    word_const: u16,
    // DWordConst,
    // QWordConst,
    // String,
    const_obj: u8,
    // RevisionOp,
    // DefBuffer,
};

// Parser

var block: []const u8 = undefined;
var loc: usize = 0;
var indent: usize = 0;

fn printIndented(comptime str: [:0]const u8, args: anytype) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        print(" ", .{});
    }
    println(str, args);
}

pub fn parse(aml_block: []const u8) void {
    block = aml_block;
    _ = terms(0) catch void;
}

fn terms(len: usize) AllocationError![]TermObj {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: []TermObj = undefined;

    const start_loc = loc;
    var list = std.ArrayList(TermObj).init(&allocator);
    while (try termObj()) |term_obj| {
        try list.append(term_obj.*);
        if (len > 0 and loc - start_loc >= len) {
            break;
        }
    }

    result = list.items;

    indent -= 2;
    return result;
}

fn termObj() !?*TermObj {
    // printIndented(@src().fn_name);
    indent += 2;

    const result = blk: {
        if (try object()) |obj| {
            var term_obj = try allocator.create(TermObj);
            term_obj.* = TermObj{
                .obj = obj,
            };
            break :blk term_obj;
        }

        if (try statementOpCode()) |stmt_opcode| {
            var term_obj = try allocator.create(TermObj);
            term_obj.* = TermObj{
                .stmt_opcode = stmt_opcode,
            };
            break :blk term_obj;
        }

        if (try expressionOpCode()) |expr_opcode| {
            var term_obj = try allocator.create(TermObj);
             term_obj.* = TermObj{
                .expr_opcode = expr_opcode,
            };
            break :blk term_obj;
        }

        break :blk null;
    };
    indent -= 2;
    return result;
}

fn object() !?*Object {
    // printIndented(@src().fn_name);
    indent += 2;

    const result = blk: {
        if (try namespaceModifierObj()) |ns_mod_obj| {
            var obj = try allocator.create(Object);
            obj.* = Object{
                .ns_mod_obj = ns_mod_obj,
            };
            break :blk obj;
        }

        if (try namedObj()) |named_obj| {
            var obj = try allocator.create(Object);
            obj.* = Object{
                .named_obj = named_obj,
            };
            break :blk obj;
        }

        break :blk null;
    };

    indent -= 2;
    return result;
}

fn statementOpCode() !?*StatementOpcode {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*StatementOpcode = null;

    if (matchOpCodeByte(.WhileOp)) {
        const start_loc = loc;
        if (pkgLength()) |pkglen| {
            printIndented("While()", .{});
            if (try termArg()) |predicate| {
                const len = pkglen - (loc - start_loc);
                var while_ = try allocator.create(While);
                while_.* = While{
                    .predicate = predicate,
                    .terms = try terms(len),
                };

                var stmt_opcode = try allocator.create(StatementOpcode);
                stmt_opcode.* = StatementOpcode{
                    .while_ = while_,
                };

                result = stmt_opcode;

            }
        }
    }

    indent -= 2;
    return result;
}

fn expressionOpCode() !?*ExpressionOpcode {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*ExpressionOpcode = null;

    if (matchOpCodeByte(.DerefOfOp)) {
        printIndented("DerefOf()", .{});
        if (try termArg()) |obj_ref| {
            var deref_of = try allocator.create(DerefOf);
            deref_of.* = DerefOf{
                .obj_ref = obj_ref,
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .deref_of = deref_of,
            };

            result = expr_opcode;

        }
    }
    else if (matchOpCodeByte(.LLessOp)) {
        printIndented("LLess()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                var lless = try allocator.create(LLess);
                lless.* = LLess{
                    .operand1 = operand1,
                    .operand2 = operand2,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .lless = lless,
                };

                result = expr_opcode;

            }
        }
    }
    else if (matchOpCodeByte(.IncrementOp)) {
        printIndented("Increment()", .{});
        if (try superName()) |operand| {
            var increment = try allocator.create(Increment);
            increment.* = Increment{
                .operand = operand,
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .increment = increment,
            };

            result = expr_opcode;

        }
    }
    else if (matchOpCodeByte(.IndexOp)) {
        printIndented("Index()", .{});
        if (try termArg()) |obj| {
            if (try termArg()) |index_val| {
                var index = try allocator.create(Index);
                index.* = Index{
                    .obj = obj,
                    .index = index_val,
                    .target = try superName(),
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .index = index,
                };

                result = expr_opcode;

            }
        }
    }
    else if (matchOpCodeByte(.SizeOfOp)) {
        printIndented("SizeOf()", .{});
        if (try superName()) |operand| {
            var size_of = try allocator.create(SizeOf);
            size_of.* = SizeOf{
                .operand = operand,
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .size_of = size_of,
            };

            result = expr_opcode;

        }
    }
    else if (matchOpCodeByte(.StoreOp)) {
        printIndented("Store()", .{});
        if (try termArg()) |operand| {
            if (try superName()) |target| {
                var store = try allocator.create(Store);
                store.* = Store{
                    .operand = operand,
                    .target = target,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .store = store,
                };

                result = expr_opcode;

            }
        }
    }
    else if (matchOpCodeByte(.SubtractOp)) {
        printIndented("Subtract()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                var subtract = try allocator.create(Subtract);
                subtract.* = Subtract{
                    .operand1 = operand1,
                    .operand2 = operand2,
                    .target = try superName(),
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .subtract = subtract,
                };

                result = expr_opcode;

            }
        }
    }
    else if (matchOpCodeByte(.ToHexStringOp)) {
        printIndented("ToHexString()", .{});
        if (try termArg()) |operand| {
            var to_hex_string = try allocator.create(ToHexString);
            to_hex_string.* = ToHexString{
                .operand = operand,
                .target = try superName(),
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .to_hex_string = to_hex_string,
            };

            result = expr_opcode;

        }
    }
    else if (matchOpCodeByte(.ToBufferOp)) {
        printIndented("ToBuffer()", .{});
        if (try termArg()) |operand| {
            var to_buffer = try allocator.create(ToBuffer);
            to_buffer.* = ToBuffer{
                .operand = operand,
                .target = try superName(),
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .to_buffer = to_buffer,
            };

            result = expr_opcode;

        }
    }

    indent -= 2;
    return result;
}

fn superName() !?*SuperName {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*SuperName = null;

    if (try simpleName()) |simple_name| {
        var super_name = try allocator.create(SuperName);
        super_name.* = SuperName{
            .simple_name = simple_name,
        };
        result = super_name;
    }

    indent -= 2;
    return result;
}

fn simpleName() !?*SimpleName {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*SimpleName = null;

    if (try nameString()) |name_str| {
        var simple_name = try allocator.create(SimpleName);
        simple_name.* = SimpleName{
            .name = name_str,
        };
        result = simple_name;
    }
    else if (argObj()) |arg| {
        var simple_name = try allocator.create(SimpleName);
        simple_name.* = SimpleName{
            .arg = arg,
        };
        result = simple_name;
    }
    else if (localObj()) |local| {
        var simple_name = try allocator.create(SimpleName);
        simple_name.* = SimpleName{
            .local = local,
        };
        result = simple_name;
    }

    indent -= 2;
    return result;
}

fn namespaceModifierObj() !?*NameSpaceModifierObj {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*NameSpaceModifierObj = null;

    result = blk: {
        // const def_alise = try defAlias();
        // if (def_alise != null) {
        //     break :blk try allocator.create(NameSpaceModifierObj){
        //         .def_alise = def_alise,
        //     };
        // }

        // const def_name = try defName();
        // if (def_name != null) {
        //     break :blk try allocator.create(NameSpaceModifierObj){
        //         .def_name = def_name,
        //     };
        // }

        if (try defScope()) |def_scope| {
            var ns_mod_obj = try allocator.create(NameSpaceModifierObj);
            ns_mod_obj.* = NameSpaceModifierObj{
                .def_scope = def_scope,
            };
            break :blk ns_mod_obj;
        }

        break :blk null;
    };

    indent -= 2;
    return result;
}

fn namedObj() !?*NamedObj {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*NamedObj = null;

    if (try defOpRegion()) |def_op_region| {
        var named_obj = try allocator.create(NamedObj);
        named_obj.* = NamedObj{
            .def_op_region = def_op_region,
        };
        result = named_obj;
    }
    else if (try defField()) |def_field| {
        var named_obj = try allocator.create(NamedObj);
        named_obj.* = NamedObj{
            .def_field = def_field,
        };
        result = named_obj;
    }
    else if (try defMethod()) |def_method| {
        var named_obj = try allocator.create(NamedObj);
        named_obj.* = NamedObj{
            .def_method = def_method,
        };
        result = named_obj;
    }
        // defBankField() or
        // defCreateBitField() or defCreateByteField() or defCreateDWordField() or
        // defCreateField() or defCreateQWordField() or defCreateWordField() or
        // defDataRegion or defDevice() or DefEvent() or defExternal() or
        // defField() or defIndexField() or defMethod() or defMutex() or
        // defOpRegion() or defPowerRes() or defThermalZone();

    indent -= 2;
    return result;
}

fn defOpRegion() !?*DefOpRegion {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*DefOpRegion = null;

    if (matchOpCodeWord(.OpRegionOp)) {
        if (try nameString()) |name_str| {
            const region_space = advance();
            if (try termArg()) |region_offset| {
                if (try termArg()) |region_len| {
                    switch (name_str.*) {
                        .abs_name => printIndented("OperationRegion ({s})", .{name_str.abs_name}),
                        .rel_name => printIndented("OperationRegion ({s})", .{name_str.rel_name}),
                    }
                    var def_op_region = try allocator.create(DefOpRegion);
                    def_op_region.* = DefOpRegion{
                        .name = name_str,
                        .space = region_space,
                        .offset = region_offset,
                        .len = region_len,
                    };
                    result = def_op_region;

                }
            }
        }
    }

    // const result =
    //     opRegionOp() and
    //     nameString() and
    //     regionSpace() and
    //     regionOffset() and
    //     regionLen();

    indent -= 2;
    return result;
}

// fn regionSpace() bool {
//     // printIndented(@src().fn_name);
//     // TODO: read ByteData
//     // ByteData
//     //   0x00 SystemMemory
//     //   0x01 SystemIO
//     //   0x02 PCI_Config
//     //   0x03 EmbeddedControl
//     //   0x04 SMBus
//     //   0x05 System CMOS
//     //   0x06 PciBarTarget
//     //   0x07 IPMI
//     //   0x08 GeneralPurposeIO
//     //   0x09 GenericSerialBus
//     //   0x0A PCC
//     //   0x80-0xFF: OEM Defined

//     _ = advance();
//     return true;
// }

// fn regionOffset() bool {
//     // printIndented(@src().fn_name);
//     indent += 2;

//     const result = termArg();

//     indent -= 2;
//     return result;
// }

// fn regionLen() bool {
//     // printIndented(@src().fn_name);
//     indent += 2;

//     const result = termArg();

//     indent -= 2;
//     return result;
// }

fn defField() !?*DefField {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*DefField = null;
    const start_loc = loc;

    if (matchOpCodeWord(.FieldOp)) {
        if (pkgLength()) |pkglen| {
            if (try nameString()) |name_str| {
                _ = pkglen - (loc - start_loc);
                switch (name_str.*) {
                    .abs_name => printIndented("Field ({s})", .{name_str.abs_name}),
                    .rel_name => printIndented("Field ({s})", .{name_str.rel_name}),
                }

                const flags = advance();
                if(try fieldList()) |field_list| {
                    var def_field = try allocator.create(DefField);
                    def_field.* = DefField{
                        .name = name_str,
                        .flags = flags,
                        .field_list = field_list,
                    };
                    result = def_field;
                }
            }
        }
    }

    // const result =
    //     opRegionOp() and
    //     nameString() and
    //     regionSpace() and
    //     regionOffset() and
    //     regionLen();

    indent -= 2;
    return result;
}

fn fieldList() !?[]FieldElement {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?[]FieldElement = null;

    var list = std.ArrayList(FieldElement).init(&allocator);

    if (try namedField()) |named_fld| {
        // var field_element = try allocator.create(FieldElement);
        // field_element.* = FieldElement{
        //     .named_fld = named_fld,
        // };
        try list.append(FieldElement{
            .named_fld = named_fld,
        });
    }

    result = list.items;

    indent -= 2;
    return result;
}

fn namedField() !?*NamedField {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*NamedField = null;

    if (nameSeg()) |name_seg| {
        var named_fld = try allocator.create(NamedField);
        named_fld.* = NamedField{
            .name = name_seg,
            .bits = pkgLength() orelse 0,
        };
        std.mem.copy(u8, named_fld.name[0..], name_seg[0..]);
        
        result = named_fld;

        printIndented("NamedField ({s}, {})", .{named_fld.name, named_fld.bits});
    }

    indent -= 2;
    return result;
}

fn defMethod() !?*DefMethod {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*DefMethod = null;
    if (matchOpCodeByte(.MethodOp)) {
        const start_loc = loc;
        if (pkgLength()) |pkglen| {
            if (try nameString()) |name_str| {
                switch (name_str.*) {
                    .abs_name => printIndented("Method ({s})", .{name_str.abs_name}),
                    .rel_name => printIndented("Method ({s})", .{name_str.rel_name}),
                }
                const flags = advance();
                const len = pkglen - (loc - start_loc);
                var def_method = try allocator.create(DefMethod);
                def_method.* = DefMethod{
                    .name = name_str,
                    .flags = flags,
                    .terms = try terms(len),
                };
                result = def_method;

            }
        }
    }

    // const result =
    //     opRegionOp() and
    //     nameString() and
    //     regionSpace() and
    //     regionOffset() and
    //     regionLen();

    indent -= 2;
    return result;
}

fn termArg() AllocationError!?*TermArg {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*TermArg = null;

    if (try expressionOpCode()) |expr_opcode| {
        var term_arg = try allocator.create(TermArg);
        term_arg.* = TermArg{
            .expr_opcode = expr_opcode,
        };
        result = term_arg;
    }
    else if (try dataObject()) |data_obj| {
        var term_arg = try allocator.create(TermArg);
        term_arg.* = TermArg{
            .data_obj = data_obj,
        };
        result = term_arg;
    }
    else if (argObj()) |arg_obj| {
        var term_arg = try allocator.create(TermArg);
        term_arg.* = TermArg{
            .arg_obj = arg_obj,
        };
        result = term_arg;
    }
    else if (localObj()) |local_obj| {
        var term_arg = try allocator.create(TermArg);
        term_arg.* = TermArg{
            .local_obj = local_obj,
        };
        result = term_arg;
    }

    indent -= 2;
    return result;
}

fn dataObject() !?*DataObject {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*DataObject = null;

    if (try computationalData()) |comp_data| {
        var data_obj = try allocator.create(DataObject);
        data_obj.* = DataObject{
            .comp_data = comp_data,
        };
        result = data_obj;
    }
    // const result =
    //     computationalData();
    //     defPackage() or
    //     defVarPackage();

    indent -= 2;
    return result;
}

fn computationalData() !?*ComputationalData {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*ComputationalData = null;

    if (byteConst()) |byte_const| {
        var comp_data = try allocator.create(ComputationalData);
        comp_data.* = ComputationalData{
            .byte_const = byte_const,
        };
        result = comp_data;
    }
    else if (wordConst()) |word_const| {
        var comp_data = try allocator.create(ComputationalData);
        comp_data.* = ComputationalData{
            .word_const = word_const,
        };
        result = comp_data;
    }
    else if (constObj()) |const_obj| {
        var comp_data = try allocator.create(ComputationalData);
        comp_data.* = ComputationalData{
            .const_obj = const_obj,
        };
        result = comp_data;
    }
    // const result =
    //     byteConst() or wordConst() or // dWordConst() or qWordConst() or
    //     // string() or
    //     constObj(); // or revisionOp() or defBuffer();

    indent -= 2;
    return result;
}

// fn byteConst() bool {
//     // printIndented(@src().fn_name);
//     return false;
// }

fn byteConst() ?u8 {
    // printIndented(@src().fn_name);
    
    var result: ?u8 = null;

    if (matchPrefix(.BytePrefix)) {
        result = advance();
    }

    return result;
}

fn wordConst() ?u16 {
    // printIndented(@src().fn_name);
    
    var result: ?u16 = null;

    if (matchPrefix(.WordPrefix)) {
        result = @intCast(u16, advance()) | @intCast(u16, advance()) << 8;
    }

    return result;
}

fn constObj() ?u8 {
    // printIndented(@src().fn_name);
    
    var result: ?u8 = null;

    if (matchOpCodeByte(.ZeroOp)) {
        result = 0x00;
    } else if (matchOpCodeByte(.OneOp)) {
        result = 0x01;
    } else if (matchOpCodeByte(.OnesOp)) {
        result = 0xFF;
    }

    return result;
}

fn argObj() ?ArgObj {
    // printIndented(@src().fn_name);
    
    var result: ?ArgObj = null;

    if (matchByteRange(@enumToInt(OpCodeByte.Arg0Op), @enumToInt(OpCodeByte.Arg6Op))) |arg| {
        result = @intToEnum(ArgObj, arg);
    }

    return result;
}

fn localObj() ?LocalObj {
    // printIndented(@src().fn_name);
    
    var result: ?LocalObj = null;

    if (matchByteRange(@enumToInt(OpCodeByte.Local0Op), @enumToInt(OpCodeByte.Local7Op))) |local| {
        result = @intToEnum(LocalObj, local);
    }

    return result;
}

// fn defAlias() !*DefAlias {
//     // printIndented(@src().fn_name);
//     return null;
// }

// fn defName() bool {
//     // printIndented(@src().fn_name);
//     return false;
// }

fn defScope() !?*DefScope {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*DefScope = null;

    if (matchOpCodeByte(.ScopeOp)) {
        const start_loc = loc;
        if (pkgLength()) |pkglen| {
            if (try nameString()) |name_str| {
                switch (name_str.*) {
                    .abs_name => printIndented("Scope ({s})", .{name_str.abs_name}),
                    .rel_name => printIndented("Scope ({s})", .{name_str.rel_name}),
                }
                const len = pkglen - (loc - start_loc);
                var def_scope = try allocator.create(DefScope);
                def_scope.* = DefScope{
                    .name = name_str,
                    .terms = try terms(len),
                };
                result = def_scope;

            }
        }
    }

    indent -= 2;
    return result;
}

fn pkgLength() ?u32 {
    // printIndented(@src().fn_name);
    return matchPkgLength();
}

fn nameString() !?*NameString {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?*NameString = null;

    if(rootChar()) {
        if (try namePath()) |name_path| {
            var name_string = try allocator.create(NameString);
            name_string.* = NameString{
                .abs_name = try std.mem.concat(&allocator, u8, &[_][]const u8{ "\\", name_path }),
            };
            result = name_string;
            // printIndented("{s}", .{name_string.abs_name});
        }
    } else if (try prefixPath()) |prefix_path| {
        if (try namePath()) |name_path| {
            var name_string = try allocator.create(NameString);
            name_string.* = NameString{
                .rel_name = try std.mem.concat(&allocator, u8, &[_][]const u8{ prefix_path, name_path }),
            };
            result = name_string;
            // printIndented("{s}", .{name_string.rel_name});
        }
    }

    indent -= 2;
    return result;
}

fn rootChar() bool {
    // printIndented(@src().fn_name);
    return matchChar(.RootChar);
}

fn prefixPath() !?[]u8 {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?[]u8 = null;

    var count: usize = 0;
    while (matchChar(.ParentPrefixChar)) {
        count += 1;
    }
    if (count > 0) {
        var prefix_path = try allocator.alloc(u8, count);
        std.mem.set(u8, prefix_path, '^');
        result = prefix_path;
    } else {
        result = "";
    }

    indent -= 2;
    return result;
}

fn namePath() !?[]const u8 {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?[]const u8 = null;

    if(nameSeg()) |name_seg| {
        var name_path = try allocator.alloc(u8, name_seg.len);
        std.mem.copy(u8, name_path, name_seg[0..]);
        result = name_path;
    } else if (try dualNamePath()) |dual_name_path| {
        result = dual_name_path;
    // } else if (multiNamePath()) |multi_name_path| {
    //     result = multi_name_path;
    } else if (nullName()) {
        result = &[_]u8{};
    }

    indent -= 2;
    return result;
}

fn nameSeg() ?[4]u8 {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?[4]u8 = null;

    if (leadNameChar()) |ch1| {
        if (nameChar()) |ch2| {
            if (nameChar()) |ch3| {
                if (nameChar()) |ch4| {
                    result = [_]u8{ ch1, ch2, ch3, ch4 };
                }
            }
        }
    }

    indent -= 2;
    return result;
}

fn leadNameChar() ?u8 {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?u8 = null;

    if (matchCharRange(.AlphaChar_Start, .AlphaChar_End)) |ch| {
        result = ch;
    }
    else if (matchChar(.UnderscoreChar)) {
        result = '_';
    }

    indent -= 2;
    return result;
}

fn nameChar() ?u8 {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?u8 = null;

    if (leadNameChar()) |ch| {
        result = ch;
    }
    else if (matchCharRange(.DigitChar_Start, .DigitChar_End)) |ch| {
        result = ch;
    }

    indent -= 2;
    return result;
}

fn dualNamePath() !?[]const u8 {
    // printIndented(@src().fn_name);
    indent += 2;

    var result: ?[]const u8 = null;

    if (matchPrefix(.DualNamePrefix)) {
        if (nameSeg()) |seg1| {
            if (nameSeg()) |seg2| {
                result = try std.mem.concat(&allocator, u8, &[_][]const u8{ seg1[0..], ".", seg2[0..] });
            }
        }
    }

    indent -= 2;
    return result;
}

// fn multiNamePath() bool {
//     // printIndented(@src().fn_name);
//     indent += 2;

//     if (!matchPrefix(.MultiNamePrefix)) {
//         indent -= 2;
//         return false;
//     }
//     var seg_count = advance();
//     var result = true;
//     while (seg_count > 0 and result) : (seg_count -= 1) {
//         result = result and nameSeg();
//     }

//     indent -= 2;
//     return result;
// }

fn nullName() bool {
    // printIndented(@src().fn_name);
    return matchChar(.Null);
}

//
// matching routines
//

fn matchOpCodeByte(opCode: OpCodeByte) bool {
    // // printIndented(@src().fn_name);
    if (peekByte() == @enumToInt(opCode)) {
        _ = advance();
        return true;
    }
    return false;
}

fn matchOpCodeWord(opCode: OpCodeWord) bool {
    // // printIndented(@src().fn_name);
    if (peekWord() == @enumToInt(opCode)) {
        _ = advance();
        _ = advance();
        return true;
    }
    return false;
}

fn matchPrefix(prefix: Prefix) bool {
    // // printIndented(@src().fn_name);
    return matchByte(@enumToInt(prefix));
}

fn matchChar(ch: Char) bool {
    // // printIndented(@src().fn_name);
    return matchByte(@enumToInt(ch));
}

fn matchCharRange(start: Char, end: Char) ?u8 {
    // // printIndented(@src().fn_name);
    return matchByteRange(@enumToInt(start), @enumToInt(end));
}

fn matchByte(byte: u8) bool {
    // // printIndented(@src().fn_name);
    if (peekByte() == byte) {
        _ = advance();
        return true;
    }
    return false;
}

fn matchByteRange(start: u8, end: u8) ?u8 {
    // // printIndented(@src().fn_name);
    const byte = peekByte();
    if (byte >= start and byte <= end) {
        return advance();
    }
    return null;
}

fn matchPkgLength() ?u32 {
    // printIndented(@src().fn_name);

    var length: ?u32 = null;

    const lead_byte = peekByte();
    var count = lead_byte >> 6;
    if (count == 0) {
        length = @intCast(u32, advance() & 0x3F);
    }
    else if (lead_byte & 0b00110000 == 0) {
        var len = @intCast(u32, advance() & 0x0F);
        var i: usize = 1;
        while (i < count + 1) : (i += 1) {
            len |= @intCast(u32, advance()) << @intCast(u5, i * 8 - 4);
        }
        length = len;
    }

    return length;
}

fn peekByte() u8 {
    // // printIndented(@src().fn_name);
    return block[loc];
}

fn peekWord() u16 {
    // // printIndented(@src().fn_name);
    return block[loc] | @intCast(u16, block[loc + 1]) << 8;
}

fn advance() u8 {
    // printIndented(@src().fn_name);
    loc += 1;
    return block[loc - 1];
}
