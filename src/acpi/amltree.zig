const std = @import("std");
const ast = @import("amlparser.zig");
const io = @import("../io.zig");


// Visitor interface
const AmlTreeVisitor = struct {
    const Self = @This();

    visitTerms: fn (*Self, []const ast.TermObj) void,
    visitTermObj: fn (*Self, *const ast.TermObj) void,
    visitObject: fn (*Self, *const ast.Object) void,
    visitStatementOpcode: fn (*Self, *const ast.StatementOpcode) void,
    visitExpressionOpcode: fn (*Self, *const ast.ExpressionOpcode) void,
    visitNameSpaceModifierObj: fn (*Self, *const ast.NameSpaceModifierObj) void,
    visitNamedObj: fn (*Self, *const ast.NamedObj) void,
    visitDefScope: fn (*Self, *const ast.DefScope) void,
    visitDefName: fn (*Self, *const ast.DefName) void,
    visitDataObject: fn (*Self, *const ast.DataObject) void,
    visitComputationalData: fn (*Self, *const ast.ComputationalData) void,
    visitByteConst: fn (*Self, u8) void,
    visitWordConst: fn (*Self, u16) void,
    visitDWordConst: fn (*Self, u32) void,
    visitQWordConst: fn (*Self, u64) void,
    visitConstObj: fn (*Self, u8) void,
    visitRevision: fn (*Self, u64) void,
    visitString: fn (*Self, [:0]const u8) void,
    visitBuffer: fn (*Self, *const ast.Buffer) void,
    visitBufferResourceDescriptors: fn (*Self, []const ast.ResourceDescriptor) void,
    visitDefDevice: fn (*Self, *const ast.DefDevice) void,
    visitDefOpRegion: fn (*Self, *const ast.DefOpRegion) void,
    visitDefField: fn (*Self, *const ast.DefField) void,
    visitFieldElement: fn (*Self, *const ast.FieldElement) void,
    visitNamedField: fn (*Self, *const ast.NamedField) void,
    visitReservedField: fn (*Self, *const ast.ReservedField) void,
    visitDefMethod: fn (*Self, *const ast.DefMethod) void,
    visitDefMutex: fn (*Self, *const ast.DefMutex) void,
    visitPackage: fn (*Self, *const ast.Package) void,
    visitDataRefObject: fn (*Self, *const ast.DataRefObject) void,
    visitNameString: fn (*Self, *const ast.NameString) void,

    fn acceptTerms(self: *Self, terms: []const ast.TermObj) void {
        for (terms) |*term_obj| {
            self.visitTermObj(self, term_obj);
        }
    }

    fn acceptTermObj(self: *Self, term_obj: *const ast.TermObj) void {
        switch (term_obj.*) {
            .obj => |obj| self.visitObject(self, obj),
            .stmt_opcode => |stmt_opcode| self.visitStatementOpcode(self, stmt_opcode),
            .expr_opcode => |expr_opcode| self.visitExpressionOpcode(self, expr_opcode),
        }
    }

    fn acceptTermArg(self: *Self, term_arg: *const ast.TermArg) void {
        switch (term_arg.*) {
            .expr_opcode => |expr_opcode| self.visitExpressionOpcode(self, expr_opcode),
            .data_obj => |data_obj| self.visitDataObject(self, data_obj),
            // .arg_obj => |arg_obj| self.visitArgObj(self, arg_obj),
            // .local_obj => |local_obj| self.visitLocalObj(self, local_obj),
            .name_str => |name_str| self.visitNameString(self, name_str),
            else => {},
        }
    }

    fn acceptObject(self: *Self, obj: *const ast.Object) void {
        switch (obj.*) {
            .ns_mod_obj => |ns_mod_obj| self.visitNameSpaceModifierObj(self, ns_mod_obj),
            .named_obj => |named_obj| self.visitNamedObj(self, named_obj),
        }
    }

    fn acceptStatementOpcode(_: *Self, stmt_opcode: *const ast.StatementOpcode) void {
        switch (stmt_opcode.*) {
            else => {},
        }
    }

    fn acceptExpressionOpcode(_: *Self, expr_opcode: *const ast.ExpressionOpcode) void {
        switch (expr_opcode.*) {
            else => {},
        }
    }

    fn acceptNameSpaceModifierObj(self: *Self, ns_mod_obj: *const ast.NameSpaceModifierObj) void {
        switch (ns_mod_obj.*) {
            .def_scope => |def_scope| self.visitDefScope(self, def_scope),
            .def_name => |def_name| self.visitDefName(self, def_name),
        }
    }

    fn acceptDefScope(self: *Self, def_scope: *const ast.DefScope) void {
        self.acceptTerms(def_scope.terms);
    }

    fn acceptDefName(self: *Self, def_name: *const ast.DefName) void {
        switch (def_name.data_ref_obj.*) {
            .data_obj => |data_obj| self.visitDataObject(self, data_obj),
            .obj_ref => {},
        }
    }

    fn acceptDataObject(self: *Self, data_obj: *const ast.DataObject) void {
        switch (data_obj.*) {
            .comp_data => |comp_data| self.visitComputationalData(self, comp_data),
            .package => |pkg| self.visitPackage(self, pkg),
        }
    }

    fn acceptComputationalData(self: *Self, comp_data: *const ast.ComputationalData) void {
        switch (comp_data.*) {
            .byte_const => |byte_const| self.visitByteConst(self, byte_const),
            .word_const => |word_const| self.visitWordConst(self, word_const),
            .dword_const => |dword_const| self.visitDWordConst(self, dword_const),
            .qword_const => |qword_const| self.visitQWordConst(self, qword_const),
            .const_obj => |const_obj| self.visitConstObj(self, const_obj),
            .revision => |revision| self.visitRevision(self, revision),
            .string => |str| self.visitString(self, str),
            .buffer => |buff| self.visitBuffer(self, buff),
        }
    }

    fn acceptBufferPayload(self: *Self, buff_payload: *ast.BufferPayload) void {
        switch (buff_payload.*) {
            // .bytes => |bytes| self.visitBufferBytes(self, bytes),
            .res_desc => |res_desc| self.visitBufferResourceDescriptors(self, res_desc),
            else => {},
        }
    }

    fn acceptNamedObj(self: *Self, named_obj: *const ast.NamedObj) void {
        switch (named_obj.*) {
            .def_device => |def_device| self.visitDefDevice(self, def_device),
            .def_op_region => |def_op_region| self.visitDefOpRegion(self, def_op_region),
            .def_field => |def_field| self.visitDefField(self, def_field),
            .def_method => |def_method| self.visitDefMethod(self, def_method),
            .def_mutex => |def_mutex| self.visitDefMutex(self, def_mutex),
            else => {},
        }
    }

    fn acceptDefDevice(self: *Self, def_device: *const ast.DefDevice) void {
        self.acceptTerms(def_device.terms);
    }

    fn acceptDefField(self: *Self, def_field: *const ast.DefField) void {
        for (def_field.field_elements) |*field_elem| {
            self.visitFieldElement(self, field_elem);
        }
    }

    fn acceptFieldElement(self: *Self, field_elem: *const ast.FieldElement) void {
        switch (field_elem.*) {
            .named_fld => |named_fld| self.visitNamedField(self, named_fld),
            .reserved_fld => |reserved_fld| self.visitReservedField(self, reserved_fld),
        }
    }

    fn acceptPackageElement(self: *Self, pkg_elem: *const ast.PackageElement) void {
        switch (pkg_elem.*) {
            .data_ref_obj => |data_ref_obj| self.visitDataRefObject(self, data_ref_obj),
            .name => |name_str| self.visitNameString(self, name_str),
        }
    }

    fn acceptDataRefObject(self: *Self, data_ref_obj: *const ast.DataRefObject) void {
        switch (data_ref_obj.*) {
            .data_obj => |data_obj| self.visitDataObject(self, data_obj),
            .obj_ref => {},
        }
    }

};

pub const AmlTreePrinter = struct {
    const Self = @This();

    visitor: AmlTreeVisitor,
    indent: usize = 0,

    pub fn init() Self {
        return .{
            .visitor = AmlTreeVisitor{
                .visitTerms = visitTerms,
                .visitTermObj = visitTermObj,
                .visitObject = visitObject,
                .visitStatementOpcode = visitStatementOpcode,
                .visitExpressionOpcode = visitExpressionOpcode,
                .visitNameSpaceModifierObj = visitNameSpaceModifierObj,
                .visitNamedObj = visitNamedObj,
                .visitDefScope = visitDefScope,
                .visitDefName = visitDefName,
                .visitDataObject = visitDataObject,
                .visitComputationalData = visitComputationalData,
                .visitByteConst = visitByteConst,
                .visitWordConst = visitWordConst,
                .visitDWordConst = visitDWordConst,
                .visitQWordConst = visitQWordConst,
                .visitConstObj = visitConstObj,
                .visitRevision = visitRevision,
                .visitString = visitString,
                .visitBuffer = visitBuffer,
                .visitBufferResourceDescriptors = visitBufferResourceDescriptors,
                .visitDefDevice = visitDefDevice,
                .visitDefOpRegion = visitDefOpRegion,
                .visitDefField = visitDefField,
                .visitFieldElement = visitFieldElement,
                .visitNamedField = visitNamedField,
                .visitReservedField = visitReservedField,
                .visitDefMethod = visitDefMethod,
                .visitDefMutex = visitDefMutex,
                .visitPackage = visitPackage,
                .visitDataRefObject = visitDataRefObject,
                .visitNameString = visitNameString,
            },
        };
    }

    pub fn print(self: *Self, terms: []const ast.TermObj) void {
        visitTerms(&self.visitor, terms);
    }

    fn visitTerms(visitor: *AmlTreeVisitor, terms: []const ast.TermObj) void {
        visitor.acceptTerms(terms);
    }

    fn visitTermObj(visitor: *AmlTreeVisitor, term_obj: *const ast.TermObj) void {
        visitor.acceptTermObj(term_obj);
    }

    fn visitTermArg(visitor: *AmlTreeVisitor, term_arg: *const ast.TermArg) void {
        visitor.acceptTermArg(term_arg);
    }

    fn visitObject(visitor: *AmlTreeVisitor, obj: *const ast.Object) void {
        visitor.acceptObject(obj);
    }

    fn visitStatementOpcode(visitor: *AmlTreeVisitor, stmt_opcode: *const ast.StatementOpcode) void {
        visitor.acceptStatementOpcode(stmt_opcode);
    }

    fn visitExpressionOpcode(visitor: *AmlTreeVisitor, stmt_opcode: *const ast.ExpressionOpcode) void {
        visitor.acceptExpressionOpcode(stmt_opcode);
    }

    fn visitNameSpaceModifierObj(visitor: *AmlTreeVisitor, ns_mod_obj: *const ast.NameSpaceModifierObj) void {
        visitor.acceptNameSpaceModifierObj(ns_mod_obj);
    }

    fn visitNamedObj(visitor: *AmlTreeVisitor, named_obj: *const ast.NamedObj) void {
        visitor.acceptNamedObj(named_obj);
    }

    fn visitDefScope(visitor: *AmlTreeVisitor, def_scope: *const ast.DefScope) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Scope ({s})", .{def_scope.name.name});

        self.indent += 2;
        visitor.acceptDefScope(def_scope);
        self.indent -= 2;
    }

    fn visitDefName(visitor: *AmlTreeVisitor, def_name: *const ast.DefName) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printIndented(self.indent, "Name ({s}, ", .{def_name.name.name});
        visitor.acceptDefName(def_name);
        io.println(")", .{});
    }

    fn visitDataObject(visitor: *AmlTreeVisitor, data_obj: *const ast.DataObject) void {
        visitor.acceptDataObject(data_obj);
    }

    fn visitComputationalData(visitor: *AmlTreeVisitor, comp_data: *const ast.ComputationalData) void {
        visitor.acceptComputationalData(comp_data);
    }

    fn visitByteConst(_: *AmlTreeVisitor, byte_const: u8) void {
        io.print("0x{x:0>2}", .{byte_const});
    }

    fn visitWordConst(_: *AmlTreeVisitor, word_const: u16) void {
        io.print("0x{x:0>4}", .{word_const});
    }

    fn visitDWordConst(_: *AmlTreeVisitor, dword_const: u32) void {
        // handle EISAID-encoded values
        const v1: u8 = @intCast(u8, (dword_const >> 2) & 0x1F) + 0x40;
        const v2: u8 = @intCast(u8, (dword_const >> 13 & 0x07) | @intCast(u8, (dword_const & 0x03) << 3)) + 0x40;
        const v3: u8 = @intCast(u8, (dword_const >> 8) & 0x1F) + 0x40;
        var p1: u8 = @intCast(u8, (dword_const >> 20) & 0x0F) + 0x30;
        var p2: u8 = @intCast(u8, (dword_const >> 16) & 0x0F) + 0x30;
        var p3: u8 = @intCast(u8, (dword_const >> 28) & 0x0F) + 0x30;
        var p4: u8 = @intCast(u8, (dword_const >> 24) & 0x0F) + 0x30;

        if (p1 > '9') { p1 += 0x7; }
        if (p2 > '9') { p2 += 0x7; }
        if (p3 > '9') { p3 += 0x7; }
        if (p4 > '9') { p4 += 0x7; }

        if (v1 >= 'A' and v1 <= 'Z' and
            v2 >= 'A' and v2 <= 'Z' and
            v3 >= 'A' and v3 <= 'Z' and
            (p1 >= '0' and p1 <= '9' or p1 >= 'A' and p1 <= 'F') and
            (p2 >= '0' and p2 <= '9' or p2 >= 'A' and p2 <= 'F') and
            (p3 >= '0' and p3 <= '9' or p3 >= 'A' and p3 <= 'F') and
            (p4 >= '0' and p4 <= '9' or p4 >= 'A' and p4 <= 'F'))
        {
            io.print("EISAID(\"{c}{c}{c}{c}{c}{c}{c}\")", .{v1, v2, v3, p1, p2, p3, p4});
        } else {
            io.print("0x{x:0>8}", .{dword_const});
        }
    }

    fn visitQWordConst(_: *AmlTreeVisitor, qword_const: u64) void {
        io.print("0x{x:0>16}", .{qword_const});
    }

    fn visitConstObj(_: *AmlTreeVisitor, const_obj: u8) void {
        io.print("0x{x:0>2}", .{const_obj});
    }

    fn visitRevision(_: *AmlTreeVisitor, revision: u64) void {
        io.print("{}", .{revision});
    }

    fn visitString(_: *AmlTreeVisitor, str: [:0]const u8) void {
        io.print("\"{s}\"", .{str});
    }

    fn visitBuffer(visitor: *AmlTreeVisitor, buff: *const ast.Buffer) void {
        // const self = @fieldParentPtr(Self, "visitor", visitor);

        if (buff.payload.* == .bytes) {
            io.print("Buffer[", .{});
            visitor.acceptTermArg(buff.size);
            io.print("]", .{});
        }
        visitor.acceptBufferPayload(buff.payload);
    }

    fn getAddressSpaceResourceType(resource_type: u8) []const u8 {
        return switch (resource_type) {
            0 => "Memory range",
            1 => "I/O range",
            2 => "Bus number range",
            3...191 => "Reserved (invalid resource type)",
            else => "Hardware vendor defined"
        };
    }

    fn visitBufferResourceDescriptors(visitor: *AmlTreeVisitor, res_desc: []const ast.ResourceDescriptor) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);
        _ = visitor;

        if (res_desc.len > 1) {
            io.println("ResourceTemplate () {{", .{});
            self.indent += 2;
        }
        for (res_desc) |res| {
            if (res_desc.len > 1) {
                io.printIndented(self.indent, "", .{});
            }
            switch (res) {
                .word_addr_space => |word_space| self.printWordAddressSpace(word_space),
                .dword_addr_space => |dword_space| self.printDWordAddressSpace(dword_space),
                .memory32_fixed => |memory32_fixed| self.printMemory32Fixed(memory32_fixed),
                .ext_interrupt => |ext_interrupt| self.printExtendedInterrupt(ext_interrupt),
                .io => |io_desc| self.printIo(io_desc),
            }
            if (res_desc.len > 1) {
                io.println("", .{});
            }
        }
        if (res_desc.len > 1) {
            self.indent -= 2;
            io.printIndented(self.indent, "}}", .{});
        }
    }

    fn visitDefDevice(visitor: *AmlTreeVisitor, def_device: *const ast.DefDevice) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Device ({s})", .{def_device.name.name});

        self.indent += 2;
        visitor.acceptDefDevice(def_device);
        self.indent -= 2;
    }

    fn visitDefOpRegion(visitor: *AmlTreeVisitor, def_op_region: *const ast.DefOpRegion) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "OperationRegion ({s})", .{def_op_region.name.name});

        self.indent += 2;
        // visitor.acceptDefField(def_op_region);
        self.indent -= 2;
    }

    fn visitDefField(visitor: *AmlTreeVisitor, def_field: *const ast.DefField) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Field ({s})", .{def_field.name.name});

        self.indent += 2;
        visitor.acceptDefField(def_field);
        self.indent -= 2;
    }

    fn visitFieldElement(visitor: *AmlTreeVisitor, field_elem: *const ast.FieldElement) void {
        visitor.acceptFieldElement(field_elem);
    }

    fn visitNamedField(visitor: *AmlTreeVisitor, named_fld: *const ast.NamedField) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "{s}, {}", .{named_fld.name, named_fld.bits});
    }

    fn visitReservedField(visitor: *AmlTreeVisitor, reserved_fld: *const ast.ReservedField) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Reserved, {}", .{reserved_fld.len});
    }

    fn visitDefMethod(visitor: *AmlTreeVisitor, def_method: *const ast.DefMethod) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Method ({s})", .{def_method.name.name});

        self.indent += 2;
        // visitor.acceptDefMethod(def_method);
        self.indent -= 2;
    }

    fn visitDefMutex(visitor: *AmlTreeVisitor, def_mutex: *const ast.DefMutex) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Mutex ({s})", .{def_mutex.name.name});
    }

    fn visitPackage(visitor: *AmlTreeVisitor, pkg: *const ast.Package) void {
        io.print("[", .{});
        var i: usize = 0;
        while (i < pkg.elements.len) : (i += 1) {
            visitor.acceptPackageElement(&pkg.elements[i]);
            if (i < pkg.elements.len - 1) {
                io.print(", ", .{});
            }
        }
        io.print("]", .{});
    }

    fn visitDataRefObject(visitor: *AmlTreeVisitor, data_ref_obj: *const ast.DataRefObject) void {
        visitor.acceptDataRefObject(data_ref_obj);
    }

    fn visitNameString(_: *AmlTreeVisitor, name_str: *const ast.NameString) void {
        io.print("{s}", .{name_str.name});
    }

    fn printWordAddressSpace(self: *Self, word_space: *ast.WordAddressSpaceDesc) void {
        _ = self;
        _ = word_space;
        io.print("WordSpace (...)", .{});
    }

    fn printDWordAddressSpace(self: *Self, dword_space: *ast.DWordAddressSpaceDesc) void {
        const resource_type = getAddressSpaceResourceType(dword_space.resource_type);
        const usage = if (dword_space.general_flags.resource_usage == 0) "ResourceProducer" else "ResourceConsumer";
        const decode = if (dword_space.general_flags.decode_type == 0) "PosDecode" else "SubDecode";
        const mif = if (dword_space.general_flags.min_addr_fixed == 0) "MinNotFixed" else "MinFixed";
        const maf = if (dword_space.general_flags.max_addr_fixed == 0) "MaxNotFixed" else "MaxFixed";
        const flags_rw = if ((dword_space.type_flags & 0x01) == 0) "ReadOnly" else "ReadWrite";
        const flags_mt = switch (@intCast(u2, dword_space.type_flags >> 1 & 0x03)) {
            0 => "NonCacheable",
            1 => "Cacheable",
            2 => "WriteCombining",
            3 => "Prefetchable",
        };
        const flags_mrt = switch (@intCast(u2, dword_space.type_flags >> 3 & 0x03)) {
            0 => "AddressRangeMemory",
            1 => "AddressRangeReserved",
            2 => "AddressRangeACPI",
            3 => "AddressRangeNVS",
        };
        const flags_tt = if (dword_space.type_flags >> 5 & 0x01 == 0) "TypeStatic" else "TypeTranslation";

        io.println("DWordSpace (", .{});
        self.indent += 2;
        io.printlnIndented(self.indent, "0x{x:0>2}{s}, // ResourceType ({s})", .{dword_space.resource_type, " " ** 16, resource_type});
        // io.printlnIndented(self.indent, "// 0x{x:0>2}{s} // GeneralFlags", .{@bitCast(u8, dword_space.general_flags), " " ** 14});
        io.printlnIndented(self.indent, "{s: <20}, //   Bit    [0] ResourceUsage", .{usage});
        io.printlnIndented(self.indent, "{s: <20}, //   Bit    [1] Decode", .{decode});
        io.printlnIndented(self.indent, "{s: <20}, //   Bit    [2] IsMinFixed", .{mif});
        io.printlnIndented(self.indent, "{s: <20}, //   Bit    [3] IsMaxFixed", .{maf});
        io.printlnIndented(self.indent, "{s: <20}  //   Bits [7:4] Reserved", .{" "});
        io.printlnIndented(self.indent, "0x{x:0>2}{s}, // TypeSpecificFlags ({s})", .{dword_space.type_flags, " " ** 16, resource_type});
        io.printlnIndented(self.indent, "// {s: <18} //   Bit    [0] ReadWriteType", .{flags_rw});
        io.printlnIndented(self.indent, "// {s: <18} //   Bits [2:1] MemType", .{flags_mt});
        io.printlnIndented(self.indent, "// {s: <18} //   Bits [4:3] MemoryRangeType", .{flags_mrt});
        io.printlnIndented(self.indent, "// {s: <18} //   Bit    [5] TranslationType", .{flags_tt});
        io.printlnIndented(self.indent, "{s: <20}  //   Bits [7:6] Reserved", .{" "});
        io.printlnIndented(self.indent, "0x{x:0>16}{s}, // Granularity", .{dword_space.granularity, "  "});
        io.printlnIndented(self.indent, "0x{x:0>16}{s}, // AddressMinimum", .{dword_space.min, "  "});
        io.printlnIndented(self.indent, "0x{x:0>16}{s}, // AddressMaximum", .{dword_space.max, "  "});
        io.printlnIndented(self.indent, "0x{x:0>16}{s}, // AddressTranslation", .{dword_space.translation_offset, "  "});
        io.printlnIndented(self.indent, "0x{x:0>16}{s}, // RangeLength", .{dword_space.length, "  "});
        if (dword_space.res_source_index) |res_source_index| {
            io.printlnIndented(self.indent, "0x{x:0>16}{s}, // ResourceSourceIndex", .{res_source_index, " " ** 16});
        }
        if (dword_space.res_source) |res_source| {
            io.printlnIndented(self.indent, "{s: <20}, // ResourceSource", .{res_source});
        }
        //     )                   // DescriptorName

        self.indent -= 2;
        io.printIndented(self.indent, ")", .{});
    }

    fn printMemory32Fixed(self: *Self, memory32_fixed: *ast.Memory32FixedDesc) void {
        const info_rw = if (memory32_fixed.info.rw_type == .ReadOnly) "ReadOnly" else "ReadWrite";

        io.println("Memory32Fixed (", .{});
        self.indent += 2;
        io.printlnIndented(self.indent, "// 0x{x:0>2}{s}  // Information", .{@bitCast(u8, memory32_fixed.info), " " ** 13});
        io.printlnIndented(self.indent, "{s: <20}, //   Bit    [0] ReadWriteType", .{info_rw});
        io.printlnIndented(self.indent, "{s: <20}  //   Bits [7:6] Reserved", .{" "});
        io.printlnIndented(self.indent, "0x{x:0>16}{s}, // AddressBase", .{memory32_fixed.base, "  "});
        io.printlnIndented(self.indent, "0x{x:0>16}{s}, // RangeLength", .{memory32_fixed.length, "  "});
        //     )                   // DescriptorName

        self.indent -= 2;
        io.printIndented(self.indent, ")", .{});
    }

    fn printExtendedInterrupt(_: *Self, ext_interrupt: *ast.ExtendedInterruptDesc) void {
        const usage = if (ext_interrupt.int_vector_flags.usage == 0) "ResourceProducer" else "ResourceConsumer";
        const mode = if (ext_interrupt.int_vector_flags.mode == 0) "Level" else "Edges";
        const polarity = if (ext_interrupt.int_vector_flags.polarity == 0) "ActiveHigh" else "ActiveLow";
        const sharing = if (ext_interrupt.int_vector_flags.sharing == 0) "Exclusive" else "Shared";
        const wake_cap = if (ext_interrupt.int_vector_flags.wake_cap == 0) "NotWakeCapable" else "WakeCapable";

        io.print("Interrupt (", .{});
        io.print("{s}, {s}, {s}, {s}, {s}) {{", .{usage, mode, polarity, sharing, wake_cap});
        for (ext_interrupt.int_table) |int_num, i| {
            io.print("{}", .{int_num});
            if (i < ext_interrupt.int_table.len - 1) {
                io.print(", ", .{});
            }
        }
        io.print("}}", .{});
        //     )                   // DescriptorName
    }

    fn printIo(_: *Self, io_desc: *ast.IoDesc) void {
        const decode = if (io_desc.info.decode == 0) "Decode10" else "Decode16";

        io.print("IO (", .{});
        io.print("{s}, 0x{x:0>4}, 0x{x:0>4}, {}, {})", .{decode, io_desc.addr_min, io_desc.addr_max, io_desc.addr_align, io_desc.length});
        //     )                   // DescriptorName
    }

};
