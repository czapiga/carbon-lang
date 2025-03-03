// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_CONTEXT_H_
#define CARBON_TOOLCHAIN_CHECK_CONTEXT_H_

#include "common/map.h"
#include "llvm/ADT/FoldingSet.h"
#include "llvm/ADT/SmallVector.h"
#include "toolchain/check/decl_introducer_state.h"
#include "toolchain/check/decl_name_stack.h"
#include "toolchain/check/diagnostic_helpers.h"
#include "toolchain/check/full_pattern_stack.h"
#include "toolchain/check/generic_region_stack.h"
#include "toolchain/check/global_init.h"
#include "toolchain/check/inst_block_stack.h"
#include "toolchain/check/node_stack.h"
#include "toolchain/check/param_and_arg_refs_stack.h"
#include "toolchain/check/region_stack.h"
#include "toolchain/check/scope_index.h"
#include "toolchain/check/scope_stack.h"
#include "toolchain/parse/node_ids.h"
#include "toolchain/parse/tree.h"
#include "toolchain/parse/tree_and_subtrees.h"
#include "toolchain/sem_ir/file.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/import_ir.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/name_scope.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// Context and shared functionality for semantics handlers.
class Context {
 public:
  using DiagnosticEmitter = Carbon::DiagnosticEmitter<SemIRLoc>;
  using DiagnosticBuilder = DiagnosticEmitter::DiagnosticBuilder;

  // A function that forms a diagnostic for some kind of problem. The
  // DiagnosticBuilder is returned rather than emitted so that the caller can
  // add contextual notes as appropriate.
  using BuildDiagnosticFn = llvm::function_ref<auto()->DiagnosticBuilder>;

  // Stores references for work.
  explicit Context(DiagnosticEmitter* emitter,
                   Parse::GetTreeAndSubtreesFn tree_and_subtrees_getter,
                   SemIR::File* sem_ir, int imported_ir_count,
                   int total_ir_count, llvm::raw_ostream* vlog_stream);

  // Marks an implementation TODO. Always returns false.
  auto TODO(SemIRLoc loc, std::string label) -> bool;

  // Runs verification that the processing cleanly finished.
  auto VerifyOnFinish() -> void;

  // Adds an instruction to the current block, returning the produced ID.
  auto AddInst(SemIR::LocIdAndInst loc_id_and_inst) -> SemIR::InstId {
    auto inst_id = AddInstInNoBlock(loc_id_and_inst);
    inst_block_stack_.AddInstId(inst_id);
    return inst_id;
  }

  // Convenience for AddInst with typed nodes.
  template <typename InstT, typename LocT>
  auto AddInst(LocT loc, InstT inst)
      -> decltype(AddInst(SemIR::LocIdAndInst(loc, inst))) {
    return AddInst(SemIR::LocIdAndInst(loc, inst));
  }

  // Returns a LocIdAndInst for an instruction with an imported location. Checks
  // that the imported location is compatible with the kind of instruction being
  // created.
  template <typename InstT>
    requires SemIR::Internal::HasNodeId<InstT>
  auto MakeImportedLocAndInst(SemIR::ImportIRInstId imported_loc_id, InstT inst)
      -> SemIR::LocIdAndInst {
    if constexpr (!SemIR::Internal::HasUntypedNodeId<InstT>) {
      CheckCompatibleImportedNodeKind(imported_loc_id, InstT::Kind);
    }
    return SemIR::LocIdAndInst::UncheckedLoc(imported_loc_id, inst);
  }

  // Adds an instruction in no block, returning the produced ID. Should be used
  // rarely.
  auto AddInstInNoBlock(SemIR::LocIdAndInst loc_id_and_inst) -> SemIR::InstId {
    auto inst_id = sem_ir().insts().AddInNoBlock(loc_id_and_inst);
    CARBON_VLOG("AddInst: {0}\n", loc_id_and_inst.inst);
    FinishInst(inst_id, loc_id_and_inst.inst);
    return inst_id;
  }

  // Convenience for AddInstInNoBlock with typed nodes.
  template <typename InstT, typename LocT>
  auto AddInstInNoBlock(LocT loc, InstT inst)
      -> decltype(AddInstInNoBlock(SemIR::LocIdAndInst(loc, inst))) {
    return AddInstInNoBlock(SemIR::LocIdAndInst(loc, inst));
  }

  // If the instruction has an implicit location and a constant value, returns
  // the constant value's instruction ID. Otherwise, same as AddInst.
  auto GetOrAddInst(SemIR::LocIdAndInst loc_id_and_inst) -> SemIR::InstId;

  // Convenience for GetOrAddInst with typed nodes.
  template <typename InstT, typename LocT>
  auto GetOrAddInst(LocT loc, InstT inst)
      -> decltype(GetOrAddInst(SemIR::LocIdAndInst(loc, inst))) {
    return GetOrAddInst(SemIR::LocIdAndInst(loc, inst));
  }

  // Adds an instruction to the current block, returning the produced ID. The
  // instruction is a placeholder that is expected to be replaced by
  // `ReplaceInstBeforeConstantUse`.
  auto AddPlaceholderInst(SemIR::LocIdAndInst loc_id_and_inst) -> SemIR::InstId;

  // Adds an instruction in no block, returning the produced ID. Should be used
  // rarely. The instruction is a placeholder that is expected to be replaced by
  // `ReplaceInstBeforeConstantUse`.
  auto AddPlaceholderInstInNoBlock(SemIR::LocIdAndInst loc_id_and_inst)
      -> SemIR::InstId;

  // Adds an instruction to the current pattern block, returning the produced
  // ID.
  // TODO: Is it possible to remove this and pattern_block_stack, now that
  // we have BeginSubpattern etc. instead?
  auto AddPatternInst(SemIR::LocIdAndInst loc_id_and_inst) -> SemIR::InstId {
    auto inst_id = AddInstInNoBlock(loc_id_and_inst);
    pattern_block_stack_.AddInstId(inst_id);
    return inst_id;
  }

  // Convenience for AddPatternInst with typed nodes.
  template <typename InstT>
    requires(SemIR::Internal::HasNodeId<InstT>)
  auto AddPatternInst(decltype(InstT::Kind)::TypedNodeId node_id, InstT inst)
      -> SemIR::InstId {
    return AddPatternInst(SemIR::LocIdAndInst(node_id, inst));
  }

  // Pushes a parse tree node onto the stack, storing the SemIR::Inst as the
  // result.
  template <typename InstT>
    requires(SemIR::Internal::HasNodeId<InstT>)
  auto AddInstAndPush(decltype(InstT::Kind)::TypedNodeId node_id, InstT inst)
      -> void {
    node_stack_.Push(node_id, AddInst(node_id, inst));
  }

  // Replaces the instruction at `inst_id` with `loc_id_and_inst`. The
  // instruction is required to not have been used in any constant evaluation,
  // either because it's newly created and entirely unused, or because it's only
  // used in a position that constant evaluation ignores, such as a return slot.
  auto ReplaceLocIdAndInstBeforeConstantUse(SemIR::InstId inst_id,
                                            SemIR::LocIdAndInst loc_id_and_inst)
      -> void;

  // Replaces the instruction at `inst_id` with `inst`, not affecting location.
  // The instruction is required to not have been used in any constant
  // evaluation, either because it's newly created and entirely unused, or
  // because it's only used in a position that constant evaluation ignores, such
  // as a return slot.
  auto ReplaceInstBeforeConstantUse(SemIR::InstId inst_id, SemIR::Inst inst)
      -> void;

  // Replaces the instruction at `inst_id` with `inst`, not affecting location.
  // The instruction is required to not change its constant value.
  auto ReplaceInstPreservingConstantValue(SemIR::InstId inst_id,
                                          SemIR::Inst inst) -> void;

  // Sets only the parse node of an instruction. This is only used when setting
  // the parse node of an imported namespace. Versus
  // ReplaceInstBeforeConstantUse, it is safe to use after the namespace is used
  // in constant evaluation. It's exposed this way mainly so that `insts()` can
  // remain const.
  auto SetNamespaceNodeId(SemIR::InstId inst_id, Parse::NodeId node_id)
      -> void {
    sem_ir().insts().SetLocId(inst_id, SemIR::LocId(node_id));
  }

  // Adds an exported name.
  auto AddExport(SemIR::InstId inst_id) -> void { exports_.push_back(inst_id); }

  auto Finalize() -> void;

  // Prints information for a stack dump.
  auto PrintForStackDump(llvm::raw_ostream& output) const -> void;

  // Prints the the formatted sem_ir to stderr.
  LLVM_DUMP_METHOD auto DumpFormattedFile() const -> void;

  // Get the Lex::TokenKind of a node for diagnostics.
  auto token_kind(Parse::NodeId node_id) -> Lex::TokenKind {
    return tokens().GetKind(parse_tree().node_token(node_id));
  }

  auto emitter() -> DiagnosticEmitter& { return *emitter_; }

  auto parse_tree_and_subtrees() -> const Parse::TreeAndSubtrees& {
    return tree_and_subtrees_getter_();
  }

  auto sem_ir() -> SemIR::File& { return *sem_ir_; }
  auto sem_ir() const -> const SemIR::File& { return *sem_ir_; }

  auto parse_tree() const -> const Parse::Tree& {
    return sem_ir_->parse_tree();
  }

  auto tokens() const -> const Lex::TokenizedBuffer& {
    return parse_tree().tokens();
  }

  auto vlog_stream() -> llvm::raw_ostream* { return vlog_stream_; }

  auto node_stack() -> NodeStack& { return node_stack_; }

  auto inst_block_stack() -> InstBlockStack& { return inst_block_stack_; }
  auto pattern_block_stack() -> InstBlockStack& { return pattern_block_stack_; }

  auto param_and_arg_refs_stack() -> ParamAndArgRefsStack& {
    return param_and_arg_refs_stack_;
  }

  auto args_type_info_stack() -> InstBlockStack& {
    return args_type_info_stack_;
  }

  auto struct_type_fields_stack() -> ArrayStack<SemIR::StructTypeField>& {
    return struct_type_fields_stack_;
  }

  auto field_decls_stack() -> ArrayStack<SemIR::InstId>& {
    return field_decls_stack_;
  }

  auto decl_name_stack() -> DeclNameStack& { return decl_name_stack_; }

  auto decl_introducer_state_stack() -> DeclIntroducerStateStack& {
    return decl_introducer_state_stack_;
  }

  auto scope_stack() -> ScopeStack& { return scope_stack_; }

  auto return_scope_stack() -> llvm::SmallVector<ScopeStack::ReturnScope>& {
    return scope_stack().return_scope_stack();
  }

  auto break_continue_stack()
      -> llvm::SmallVector<ScopeStack::BreakContinueScope>& {
    return scope_stack().break_continue_stack();
  }

  auto generic_region_stack() -> GenericRegionStack& {
    return generic_region_stack_;
  }

  auto vtable_stack() -> InstBlockStack& { return vtable_stack_; }

  auto check_ir_map() -> llvm::MutableArrayRef<SemIR::ImportIRId> {
    return check_ir_map_;
  }

  auto import_ir_constant_values()
      -> llvm::SmallVector<SemIR::ConstantValueStore, 0>& {
    return import_ir_constant_values_;
  }

  // Directly expose SemIR::File data accessors for brevity in calls.

  auto identifiers() -> SharedValueStores::IdentifierStore& {
    return sem_ir().identifiers();
  }
  auto ints() -> SharedValueStores::IntStore& { return sem_ir().ints(); }
  auto reals() -> SharedValueStores::RealStore& { return sem_ir().reals(); }
  auto floats() -> SharedValueStores::FloatStore& { return sem_ir().floats(); }
  auto string_literal_values() -> SharedValueStores::StringLiteralStore& {
    return sem_ir().string_literal_values();
  }
  auto entity_names() -> SemIR::EntityNameStore& {
    return sem_ir().entity_names();
  }
  auto functions() -> ValueStore<SemIR::FunctionId>& {
    return sem_ir().functions();
  }
  auto classes() -> ValueStore<SemIR::ClassId>& { return sem_ir().classes(); }
  auto interfaces() -> ValueStore<SemIR::InterfaceId>& {
    return sem_ir().interfaces();
  }
  auto associated_constants() -> ValueStore<SemIR::AssociatedConstantId>& {
    return sem_ir().associated_constants();
  }
  auto facet_types() -> CanonicalValueStore<SemIR::FacetTypeId>& {
    return sem_ir().facet_types();
  }
  auto impls() -> SemIR::ImplStore& { return sem_ir().impls(); }
  auto generics() -> SemIR::GenericStore& { return sem_ir().generics(); }
  auto specifics() -> SemIR::SpecificStore& { return sem_ir().specifics(); }
  auto import_irs() -> ValueStore<SemIR::ImportIRId>& {
    return sem_ir().import_irs();
  }
  auto import_ir_insts() -> ValueStore<SemIR::ImportIRInstId>& {
    return sem_ir().import_ir_insts();
  }
  auto names() -> SemIR::NameStoreWrapper { return sem_ir().names(); }
  auto name_scopes() -> SemIR::NameScopeStore& {
    return sem_ir().name_scopes();
  }
  auto struct_type_fields() -> SemIR::StructTypeFieldsStore& {
    return sem_ir().struct_type_fields();
  }
  auto types() -> SemIR::TypeStore& { return sem_ir().types(); }
  auto type_blocks() -> SemIR::BlockValueStore<SemIR::TypeBlockId>& {
    return sem_ir().type_blocks();
  }
  // Instructions should be added with `AddInst` or `AddInstInNoBlock`. This is
  // `const` to prevent accidental misuse.
  auto insts() -> const SemIR::InstStore& { return sem_ir().insts(); }
  auto constant_values() -> SemIR::ConstantValueStore& {
    return sem_ir().constant_values();
  }
  auto inst_blocks() -> SemIR::InstBlockStore& {
    return sem_ir().inst_blocks();
  }
  auto constants() -> SemIR::ConstantStore& { return sem_ir().constants(); }

  auto definitions_required() -> llvm::SmallVector<SemIR::InstId>& {
    return definitions_required_;
  }

  auto global_init() -> GlobalInit& { return global_init_; }

  auto import_ref_ids() -> llvm::SmallVector<SemIR::InstId>& {
    return import_ref_ids_;
  }

  // Map from an AnyBindingPattern inst to precomputed parts of the
  // pattern-match SemIR for it.
  //
  // TODO: Consider putting this behind a narrower API to guard against emitting
  // multiple times.
  struct BindingPatternInfo {
    // The corresponding AnyBindName inst.
    SemIR::InstId bind_name_id;
    // The region of insts that computes the type of the binding.
    SemIR::ExprRegionId type_expr_region_id;
  };
  auto bind_name_map() -> Map<SemIR::InstId, BindingPatternInfo>& {
    return bind_name_map_;
  }

  auto var_storage_map() -> Map<SemIR::InstId, SemIR::InstId>& {
    return var_storage_map_;
  }

  auto region_stack() -> RegionStack& { return region_stack_; }

  auto full_pattern_stack() -> FullPatternStack& {
    return scope_stack_.full_pattern_stack();
  }

 private:
  // A FoldingSet node for a type.
  class TypeNode : public llvm::FastFoldingSetNode {
   public:
    explicit TypeNode(const llvm::FoldingSetNodeID& node_id,
                      SemIR::TypeId type_id)
        : llvm::FastFoldingSetNode(node_id), type_id_(type_id) {}

    auto type_id() -> SemIR::TypeId { return type_id_; }

   private:
    SemIR::TypeId type_id_;
  };

  // Checks that the provided imported location has a node kind that is
  // compatible with that of the given instruction.
  auto CheckCompatibleImportedNodeKind(SemIR::ImportIRInstId imported_loc_id,
                                       SemIR::InstKind kind) -> void;

  // Finish producing an instruction. Set its constant value, and register it in
  // any applicable instruction lists.
  auto FinishInst(SemIR::InstId inst_id, SemIR::Inst inst) -> void;

  // Handles diagnostics.
  DiagnosticEmitter* emitter_;

  // Returns a lazily constructed TreeAndSubtrees.
  Parse::GetTreeAndSubtreesFn tree_and_subtrees_getter_;

  // The SemIR::File being added to.
  SemIR::File* sem_ir_;

  // Whether to print verbose output.
  llvm::raw_ostream* vlog_stream_;

  // The stack during Build. Will contain file-level parse nodes on return.
  NodeStack node_stack_;

  // The stack of instruction blocks being used for general IR generation.
  InstBlockStack inst_block_stack_;

  // The stack of instruction blocks that contain pattern instructions.
  InstBlockStack pattern_block_stack_;

  // The stack of instruction blocks being used for param and arg ref blocks.
  ParamAndArgRefsStack param_and_arg_refs_stack_;

  // The stack of instruction blocks being used for type information while
  // processing arguments. This is used in parallel with
  // param_and_arg_refs_stack_. It's currently only used for struct literals,
  // where we need to track names for a type separate from the literal
  // arguments.
  InstBlockStack args_type_info_stack_;

  // The stack of StructTypeFields for in-progress StructTypeLiterals.
  ArrayStack<SemIR::StructTypeField> struct_type_fields_stack_;

  // The stack of FieldDecls for in-progress Class definitions.
  ArrayStack<SemIR::InstId> field_decls_stack_;

  // The stack used for qualified declaration name construction.
  DeclNameStack decl_name_stack_;

  // The stack of declarations that could have modifiers.
  DeclIntroducerStateStack decl_introducer_state_stack_;

  // The stack of scopes we are currently within.
  ScopeStack scope_stack_;

  // The stack of generic regions we are currently within.
  GenericRegionStack generic_region_stack_;

  // Contains a vtable block for each `class` scope which is currently being
  // defined, regardless of whether the class can have virtual functions.
  InstBlockStack vtable_stack_;

  // Cache of reverse mapping from type constants to types.
  //
  // TODO: Instead of mapping to a dense `TypeId` space, we could make `TypeId`
  // be a thin wrapper around `ConstantId` and only perform the lookup only when
  // we want to access the completeness and value representation of a type. It's
  // not clear whether that would result in more or fewer lookups.
  //
  // TODO: Should this be part of the `TypeStore`?
  Map<SemIR::ConstantId, SemIR::TypeId> type_ids_for_type_constants_;

  // The list which will form NodeBlockId::Exports.
  llvm::SmallVector<SemIR::InstId> exports_;

  // Maps CheckIRId to ImportIRId.
  llvm::SmallVector<SemIR::ImportIRId> check_ir_map_;

  // Per-import constant values. These refer to the main IR and mainly serve as
  // a lookup table for quick access.
  //
  // Inline 0 elements because it's expected to require heap allocation.
  llvm::SmallVector<SemIR::ConstantValueStore, 0> import_ir_constant_values_;

  // Declaration instructions of entities that should have definitions by the
  // end of the current source file.
  llvm::SmallVector<SemIR::InstId> definitions_required_;

  // State for global initialization.
  GlobalInit global_init_;

  // A list of import refs which can't be inserted into their current context.
  // They're typically added during name lookup or import ref resolution, where
  // the current block on inst_block_stack_ is unrelated.
  //
  // These are instead added here because they're referenced by other
  // instructions and needs to be visible in textual IR.
  // FinalizeImportRefBlock() will produce an inst block for them.
  llvm::SmallVector<SemIR::InstId> import_ref_ids_;

  Map<SemIR::InstId, BindingPatternInfo> bind_name_map_;

  // Map from VarPattern insts to the corresponding VarStorage insts. The
  // VarStorage insts are allocated, emitted, and stored in the map after
  // processing the enclosing full-pattern.
  Map<SemIR::InstId, SemIR::InstId> var_storage_map_;

  // Stack of single-entry regions being built.
  RegionStack region_stack_;
};

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_CONTEXT_H_
