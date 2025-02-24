// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/builtin_conversions/no_prelude/fail_todo_convert_facet_value_value_to_blanket_impl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/builtin_conversions/no_prelude/fail_todo_convert_facet_value_value_to_blanket_impl.carbon

// --- core.carbon

package Core;

interface ImplicitAs(T:! type) {
  fn Convert[self: Self]() -> T;
}

// --- fail_todo_convert_facet_value_value_to_blanket_impl.carbon

library "[[@TEST_NAME]]";

import Core;

interface Eats {}
interface Animal {}

impl forall [A:! Animal] A as Eats {}

fn Feed[T:! Eats](e: T) {}

// CHECK:STDERR: fail_todo_convert_facet_value_value_to_blanket_impl.carbon:[[@LINE+17]]:37: error: semantics TODO: `Facet value converting to facet value` [SemanticsTodo]
// CHECK:STDERR: fn HandleAnimal[T:! Animal](a: T) { Feed(a); }
// CHECK:STDERR:                                     ^~~~~~~
// CHECK:STDERR: fail_todo_convert_facet_value_value_to_blanket_impl.carbon:[[@LINE-5]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Feed[T:! Eats](e: T) {}
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_todo_convert_facet_value_value_to_blanket_impl.carbon:[[@LINE+10]]:37: error: cannot implicitly convert from `type` to `Eats` [ImplicitAsConversionFailure]
// CHECK:STDERR: fn HandleAnimal[T:! Animal](a: T) { Feed(a); }
// CHECK:STDERR:                                     ^~~~~~~
// CHECK:STDERR: fail_todo_convert_facet_value_value_to_blanket_impl.carbon:[[@LINE+7]]:37: note: type `type` does not implement interface `Core.ImplicitAs(Eats)` [MissingImplInMemberAccessNote]
// CHECK:STDERR: fn HandleAnimal[T:! Animal](a: T) { Feed(a); }
// CHECK:STDERR:                                     ^~~~~~~
// CHECK:STDERR: fail_todo_convert_facet_value_value_to_blanket_impl.carbon:[[@LINE-15]]:1: note: while deducing parameters of generic declared here [DeductionGenericHere]
// CHECK:STDERR: fn Feed[T:! Eats](e: T) {}
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn HandleAnimal[T:! Animal](a: T) { Feed(a); }

// CHECK:STDOUT: --- core.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %T: type = bind_symbolic_name T, 0 [symbolic]
// CHECK:STDOUT:   %T.patt: type = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.96f: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.96f = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.07f: type = facet_type <@ImplicitAs, @ImplicitAs(%T)> [symbolic]
// CHECK:STDOUT:   %Self: %ImplicitAs.type.07f = bind_symbolic_name Self, 1 [symbolic]
// CHECK:STDOUT:   %Self.as_type: type = facet_access_type %Self [symbolic]
// CHECK:STDOUT:   %Convert.type: type = fn_type @Convert, @ImplicitAs(%T) [symbolic]
// CHECK:STDOUT:   %Convert: %Convert.type = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.assoc_type: type = assoc_entity_type %ImplicitAs.type.07f [symbolic]
// CHECK:STDOUT:   %assoc0: %ImplicitAs.assoc_type = assoc_entity element0, @ImplicitAs.%Convert.decl [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .ImplicitAs = %ImplicitAs.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %ImplicitAs.decl: %ImplicitAs.type.96f = interface_decl @ImplicitAs [concrete = constants.%ImplicitAs.generic] {
// CHECK:STDOUT:     %T.patt.loc4_22.1: type = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_22.2 (constants.%T.patt)]
// CHECK:STDOUT:     %T.param_patt: type = value_param_pattern %T.patt.loc4_22.1, runtime_param<none> [symbolic = %T.patt.loc4_22.2 (constants.%T.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.param: type = value_param runtime_param<none>
// CHECK:STDOUT:     %T.loc4_22.1: type = bind_symbolic_name T, 0, %T.param [symbolic = %T.loc4_22.2 (constants.%T)]
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic interface @ImplicitAs(%T.loc4_22.1: type) {
// CHECK:STDOUT:   %T.loc4_22.2: type = bind_symbolic_name T, 0 [symbolic = %T.loc4_22.2 (constants.%T)]
// CHECK:STDOUT:   %T.patt.loc4_22.2: type = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc4_22.2 (constants.%T.patt)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %ImplicitAs.type: type = facet_type <@ImplicitAs, @ImplicitAs(%T.loc4_22.2)> [symbolic = %ImplicitAs.type (constants.%ImplicitAs.type.07f)]
// CHECK:STDOUT:   %Self.2: %ImplicitAs.type.07f = bind_symbolic_name Self, 1 [symbolic = %Self.2 (constants.%Self)]
// CHECK:STDOUT:   %Convert.type: type = fn_type @Convert, @ImplicitAs(%T.loc4_22.2) [symbolic = %Convert.type (constants.%Convert.type)]
// CHECK:STDOUT:   %Convert: @ImplicitAs.%Convert.type (%Convert.type) = struct_value () [symbolic = %Convert (constants.%Convert)]
// CHECK:STDOUT:   %ImplicitAs.assoc_type: type = assoc_entity_type @ImplicitAs.%ImplicitAs.type (%ImplicitAs.type.07f) [symbolic = %ImplicitAs.assoc_type (constants.%ImplicitAs.assoc_type)]
// CHECK:STDOUT:   %assoc0.loc5_32.2: @ImplicitAs.%ImplicitAs.assoc_type (%ImplicitAs.assoc_type) = assoc_entity element0, %Convert.decl [symbolic = %assoc0.loc5_32.2 (constants.%assoc0)]
// CHECK:STDOUT:
// CHECK:STDOUT:   interface {
// CHECK:STDOUT:     %Self.1: @ImplicitAs.%ImplicitAs.type (%ImplicitAs.type.07f) = bind_symbolic_name Self, 1 [symbolic = %Self.2 (constants.%Self)]
// CHECK:STDOUT:     %Convert.decl: @ImplicitAs.%Convert.type (%Convert.type) = fn_decl @Convert [symbolic = @ImplicitAs.%Convert (constants.%Convert)] {
// CHECK:STDOUT:       %self.patt: @Convert.%Self.as_type.loc5_20.1 (%Self.as_type) = binding_pattern self
// CHECK:STDOUT:       %self.param_patt: @Convert.%Self.as_type.loc5_20.1 (%Self.as_type) = value_param_pattern %self.patt, runtime_param0
// CHECK:STDOUT:       %return.patt: @Convert.%T (%T) = return_slot_pattern
// CHECK:STDOUT:       %return.param_patt: @Convert.%T (%T) = out_param_pattern %return.patt, runtime_param1
// CHECK:STDOUT:     } {
// CHECK:STDOUT:       %T.ref: type = name_ref T, @ImplicitAs.%T.loc4_22.1 [symbolic = %T (constants.%T)]
// CHECK:STDOUT:       %self.param: @Convert.%Self.as_type.loc5_20.1 (%Self.as_type) = value_param runtime_param0
// CHECK:STDOUT:       %.loc5_20.1: type = splice_block %.loc5_20.3 [symbolic = %Self.as_type.loc5_20.1 (constants.%Self.as_type)] {
// CHECK:STDOUT:         %.loc5_20.2: @Convert.%ImplicitAs.type (%ImplicitAs.type.07f) = specific_constant @ImplicitAs.%Self.1, @ImplicitAs(constants.%T) [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:         %Self.ref: @Convert.%ImplicitAs.type (%ImplicitAs.type.07f) = name_ref Self, %.loc5_20.2 [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:         %Self.as_type.loc5_20.2: type = facet_access_type %Self.ref [symbolic = %Self.as_type.loc5_20.1 (constants.%Self.as_type)]
// CHECK:STDOUT:         %.loc5_20.3: type = converted %Self.ref, %Self.as_type.loc5_20.2 [symbolic = %Self.as_type.loc5_20.1 (constants.%Self.as_type)]
// CHECK:STDOUT:       }
// CHECK:STDOUT:       %self: @Convert.%Self.as_type.loc5_20.1 (%Self.as_type) = bind_name self, %self.param
// CHECK:STDOUT:       %return.param: ref @Convert.%T (%T) = out_param runtime_param1
// CHECK:STDOUT:       %return: ref @Convert.%T (%T) = return_slot %return.param
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %assoc0.loc5_32.1: @ImplicitAs.%ImplicitAs.assoc_type (%ImplicitAs.assoc_type) = assoc_entity element0, %Convert.decl [symbolic = %assoc0.loc5_32.2 (constants.%assoc0)]
// CHECK:STDOUT:
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = %Self.1
// CHECK:STDOUT:     .Convert = %assoc0.loc5_32.1
// CHECK:STDOUT:     witness = (%Convert.decl)
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Convert(@ImplicitAs.%T.loc4_22.1: type, @ImplicitAs.%Self.1: @ImplicitAs.%ImplicitAs.type (%ImplicitAs.type.07f)) {
// CHECK:STDOUT:   %T: type = bind_symbolic_name T, 0 [symbolic = %T (constants.%T)]
// CHECK:STDOUT:   %ImplicitAs.type: type = facet_type <@ImplicitAs, @ImplicitAs(%T)> [symbolic = %ImplicitAs.type (constants.%ImplicitAs.type.07f)]
// CHECK:STDOUT:   %Self: %ImplicitAs.type.07f = bind_symbolic_name Self, 1 [symbolic = %Self (constants.%Self)]
// CHECK:STDOUT:   %Self.as_type.loc5_20.1: type = facet_access_type %Self [symbolic = %Self.as_type.loc5_20.1 (constants.%Self.as_type)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn[%self.param_patt: @Convert.%Self.as_type.loc5_20.1 (%Self.as_type)]() -> @Convert.%T (%T);
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ImplicitAs(constants.%T) {
// CHECK:STDOUT:   %T.loc4_22.2 => constants.%T
// CHECK:STDOUT:   %T.patt.loc4_22.2 => constants.%T
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Convert(constants.%T, constants.%Self) {
// CHECK:STDOUT:   %T => constants.%T
// CHECK:STDOUT:   %ImplicitAs.type => constants.%ImplicitAs.type.07f
// CHECK:STDOUT:   %Self => constants.%Self
// CHECK:STDOUT:   %Self.as_type.loc5_20.1 => constants.%Self.as_type
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ImplicitAs(@Convert.%T) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ImplicitAs(%T.loc4_22.2) {}
// CHECK:STDOUT:
// CHECK:STDOUT: --- fail_todo_convert_facet_value_value_to_blanket_impl.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %Eats.type: type = facet_type <@Eats> [concrete]
// CHECK:STDOUT:   %Self.1b5: %Eats.type = bind_symbolic_name Self, 0 [symbolic]
// CHECK:STDOUT:   %Animal.type: type = facet_type <@Animal> [concrete]
// CHECK:STDOUT:   %Self.fd4: %Animal.type = bind_symbolic_name Self, 0 [symbolic]
// CHECK:STDOUT:   %A: %Animal.type = bind_symbolic_name A, 0 [symbolic]
// CHECK:STDOUT:   %A.patt: %Animal.type = symbolic_binding_pattern A, 0 [symbolic]
// CHECK:STDOUT:   %A.as_type: type = facet_access_type %A [symbolic]
// CHECK:STDOUT:   %impl_witness: <witness> = impl_witness (), @impl(%A) [symbolic]
// CHECK:STDOUT:   %T.1b5: %Eats.type = bind_symbolic_name T, 0 [symbolic]
// CHECK:STDOUT:   %T.patt.6be: %Eats.type = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.27d: type = facet_access_type %T.1b5 [symbolic]
// CHECK:STDOUT:   %Feed.type: type = fn_type @Feed [concrete]
// CHECK:STDOUT:   %Feed: %Feed.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.c75: <witness> = require_complete_type %T.as_type.27d [symbolic]
// CHECK:STDOUT:   %T.fd4: %Animal.type = bind_symbolic_name T, 0 [symbolic]
// CHECK:STDOUT:   %T.patt.a9c: %Animal.type = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %T.as_type.2ad: type = facet_access_type %T.fd4 [symbolic]
// CHECK:STDOUT:   %HandleAnimal.type: type = fn_type @HandleAnimal [concrete]
// CHECK:STDOUT:   %HandleAnimal: %HandleAnimal.type = struct_value () [concrete]
// CHECK:STDOUT:   %require_complete.234: <witness> = require_complete_type %T.as_type.2ad [symbolic]
// CHECK:STDOUT:   %T.8b3: type = bind_symbolic_name T, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.d62: type = facet_type <@ImplicitAs, @ImplicitAs(%T.8b3)> [symbolic]
// CHECK:STDOUT:   %Self.519: %ImplicitAs.type.d62 = bind_symbolic_name Self, 1 [symbolic]
// CHECK:STDOUT:   %T.patt.e01: type = symbolic_binding_pattern T, 0 [symbolic]
// CHECK:STDOUT:   %Convert.type.275: type = fn_type @Convert, @ImplicitAs(%T.8b3) [symbolic]
// CHECK:STDOUT:   %Convert.42e: %Convert.type.275 = struct_value () [symbolic]
// CHECK:STDOUT:   %Self.as_type: type = facet_access_type %Self.519 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.assoc_type.837: type = assoc_entity_type %ImplicitAs.type.d62 [symbolic]
// CHECK:STDOUT:   %assoc0.43db8b.1: %ImplicitAs.assoc_type.837 = assoc_entity element0, imports.%Core.import_ref.207961.1 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.af9: type = facet_type <@ImplicitAs, @ImplicitAs(%Eats.type)> [concrete]
// CHECK:STDOUT:   %Convert.type.9a9: type = fn_type @Convert, @ImplicitAs(%Eats.type) [concrete]
// CHECK:STDOUT:   %Convert.35d: %Convert.type.9a9 = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.assoc_type.9a7: type = assoc_entity_type %ImplicitAs.type.af9 [concrete]
// CHECK:STDOUT:   %assoc0.152: %ImplicitAs.assoc_type.9a7 = assoc_entity element0, imports.%Core.import_ref.207961.1 [concrete]
// CHECK:STDOUT:   %assoc0.43db8b.2: %ImplicitAs.assoc_type.837 = assoc_entity element0, imports.%Core.import_ref.207961.2 [symbolic]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     import Core//default
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.f6b058.1: type = import_ref Core//default, loc4_22, loaded [symbolic = @ImplicitAs.%T (constants.%T.8b3)]
// CHECK:STDOUT:   %Core.import_ref.ff5 = import_ref Core//default, inst26 [no loc], unloaded
// CHECK:STDOUT:   %Core.import_ref.630: @ImplicitAs.%ImplicitAs.assoc_type (%ImplicitAs.assoc_type.837) = import_ref Core//default, loc5_32, loaded [symbolic = @ImplicitAs.%assoc0 (constants.%assoc0.43db8b.2)]
// CHECK:STDOUT:   %Core.Convert = import_ref Core//default, Convert, unloaded
// CHECK:STDOUT:   %Core.import_ref.f6b058.2: type = import_ref Core//default, loc4_22, loaded [symbolic = @ImplicitAs.%T (constants.%T.8b3)]
// CHECK:STDOUT:   %Core.import_ref.ce1: @ImplicitAs.%ImplicitAs.type (%ImplicitAs.type.d62) = import_ref Core//default, inst26 [no loc], loaded [symbolic = @ImplicitAs.%Self (constants.%Self.519)]
// CHECK:STDOUT:   %Core.import_ref.207961.1 = import_ref Core//default, loc5_32, unloaded
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   package: <namespace> = namespace [concrete] {
// CHECK:STDOUT:     .Core = imports.%Core
// CHECK:STDOUT:     .Eats = %Eats.decl
// CHECK:STDOUT:     .Animal = %Animal.decl
// CHECK:STDOUT:     .Feed = %Feed.decl
// CHECK:STDOUT:     .HandleAnimal = %HandleAnimal.decl
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import = import Core
// CHECK:STDOUT:   %Eats.decl: type = interface_decl @Eats [concrete = constants.%Eats.type] {} {}
// CHECK:STDOUT:   %Animal.decl: type = interface_decl @Animal [concrete = constants.%Animal.type] {} {}
// CHECK:STDOUT:   impl_decl @impl [concrete] {
// CHECK:STDOUT:     %A.patt.loc9_14.1: %Animal.type = symbolic_binding_pattern A, 0 [symbolic = %A.patt.loc9_14.2 (constants.%A.patt)]
// CHECK:STDOUT:     %A.param_patt: %Animal.type = value_param_pattern %A.patt.loc9_14.1, runtime_param<none> [symbolic = %A.patt.loc9_14.2 (constants.%A.patt)]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %A.ref: %Animal.type = name_ref A, %A.loc9_14.1 [symbolic = %A.loc9_14.2 (constants.%A)]
// CHECK:STDOUT:     %A.as_type.loc9_26.1: type = facet_access_type %A.ref [symbolic = %A.as_type.loc9_26.2 (constants.%A.as_type)]
// CHECK:STDOUT:     %.loc9: type = converted %A.ref, %A.as_type.loc9_26.1 [symbolic = %A.as_type.loc9_26.2 (constants.%A.as_type)]
// CHECK:STDOUT:     %Eats.ref: type = name_ref Eats, file.%Eats.decl [concrete = constants.%Eats.type]
// CHECK:STDOUT:     %A.param: %Animal.type = value_param runtime_param<none>
// CHECK:STDOUT:     %Animal.ref: type = name_ref Animal, file.%Animal.decl [concrete = constants.%Animal.type]
// CHECK:STDOUT:     %A.loc9_14.1: %Animal.type = bind_symbolic_name A, 0, %A.param [symbolic = %A.loc9_14.2 (constants.%A)]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %impl_witness: <witness> = impl_witness (), @impl(constants.%A) [symbolic = @impl.%impl_witness (constants.%impl_witness)]
// CHECK:STDOUT:   %Feed.decl: %Feed.type = fn_decl @Feed [concrete = constants.%Feed] {
// CHECK:STDOUT:     %T.patt.loc11_9.1: %Eats.type = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc11_9.2 (constants.%T.patt.6be)]
// CHECK:STDOUT:     %T.param_patt: %Eats.type = value_param_pattern %T.patt.loc11_9.1, runtime_param<none> [symbolic = %T.patt.loc11_9.2 (constants.%T.patt.6be)]
// CHECK:STDOUT:     %e.patt: @Feed.%T.as_type.loc11_22.2 (%T.as_type.27d) = binding_pattern e
// CHECK:STDOUT:     %e.param_patt: @Feed.%T.as_type.loc11_22.2 (%T.as_type.27d) = value_param_pattern %e.patt, runtime_param0
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.param: %Eats.type = value_param runtime_param<none>
// CHECK:STDOUT:     %Eats.ref: type = name_ref Eats, file.%Eats.decl [concrete = constants.%Eats.type]
// CHECK:STDOUT:     %T.loc11_9.1: %Eats.type = bind_symbolic_name T, 0, %T.param [symbolic = %T.loc11_9.2 (constants.%T.1b5)]
// CHECK:STDOUT:     %e.param: @Feed.%T.as_type.loc11_22.2 (%T.as_type.27d) = value_param runtime_param0
// CHECK:STDOUT:     %.loc11_22.1: type = splice_block %.loc11_22.2 [symbolic = %T.as_type.loc11_22.2 (constants.%T.as_type.27d)] {
// CHECK:STDOUT:       %T.ref: %Eats.type = name_ref T, %T.loc11_9.1 [symbolic = %T.loc11_9.2 (constants.%T.1b5)]
// CHECK:STDOUT:       %T.as_type.loc11_22.1: type = facet_access_type %T.ref [symbolic = %T.as_type.loc11_22.2 (constants.%T.as_type.27d)]
// CHECK:STDOUT:       %.loc11_22.2: type = converted %T.ref, %T.as_type.loc11_22.1 [symbolic = %T.as_type.loc11_22.2 (constants.%T.as_type.27d)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %e: @Feed.%T.as_type.loc11_22.2 (%T.as_type.27d) = bind_name e, %e.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %HandleAnimal.decl: %HandleAnimal.type = fn_decl @HandleAnimal [concrete = constants.%HandleAnimal] {
// CHECK:STDOUT:     %T.patt.loc30_17.1: %Animal.type = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc30_17.2 (constants.%T.patt.a9c)]
// CHECK:STDOUT:     %T.param_patt: %Animal.type = value_param_pattern %T.patt.loc30_17.1, runtime_param<none> [symbolic = %T.patt.loc30_17.2 (constants.%T.patt.a9c)]
// CHECK:STDOUT:     %a.patt: @HandleAnimal.%T.as_type.loc30_32.2 (%T.as_type.2ad) = binding_pattern a
// CHECK:STDOUT:     %a.param_patt: @HandleAnimal.%T.as_type.loc30_32.2 (%T.as_type.2ad) = value_param_pattern %a.patt, runtime_param0
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %T.param: %Animal.type = value_param runtime_param<none>
// CHECK:STDOUT:     %Animal.ref: type = name_ref Animal, file.%Animal.decl [concrete = constants.%Animal.type]
// CHECK:STDOUT:     %T.loc30_17.1: %Animal.type = bind_symbolic_name T, 0, %T.param [symbolic = %T.loc30_17.2 (constants.%T.fd4)]
// CHECK:STDOUT:     %a.param: @HandleAnimal.%T.as_type.loc30_32.2 (%T.as_type.2ad) = value_param runtime_param0
// CHECK:STDOUT:     %.loc30_32.1: type = splice_block %.loc30_32.2 [symbolic = %T.as_type.loc30_32.2 (constants.%T.as_type.2ad)] {
// CHECK:STDOUT:       %T.ref: %Animal.type = name_ref T, %T.loc30_17.1 [symbolic = %T.loc30_17.2 (constants.%T.fd4)]
// CHECK:STDOUT:       %T.as_type.loc30_32.1: type = facet_access_type %T.ref [symbolic = %T.as_type.loc30_32.2 (constants.%T.as_type.2ad)]
// CHECK:STDOUT:       %.loc30_32.2: type = converted %T.ref, %T.as_type.loc30_32.1 [symbolic = %T.as_type.loc30_32.2 (constants.%T.as_type.2ad)]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %a: @HandleAnimal.%T.as_type.loc30_32.2 (%T.as_type.2ad) = bind_name a, %a.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: interface @Eats {
// CHECK:STDOUT:   %Self: %Eats.type = bind_symbolic_name Self, 0 [symbolic = constants.%Self.1b5]
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = %Self
// CHECK:STDOUT:   witness = ()
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: interface @Animal {
// CHECK:STDOUT:   %Self: %Animal.type = bind_symbolic_name Self, 0 [symbolic = constants.%Self.fd4]
// CHECK:STDOUT:
// CHECK:STDOUT: !members:
// CHECK:STDOUT:   .Self = %Self
// CHECK:STDOUT:   witness = ()
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic interface @ImplicitAs(imports.%Core.import_ref.f6b058.1: type) [from "core.carbon"] {
// CHECK:STDOUT:   %T: type = bind_symbolic_name T, 0 [symbolic = %T (constants.%T.8b3)]
// CHECK:STDOUT:   %T.patt: type = symbolic_binding_pattern T, 0 [symbolic = %T.patt (constants.%T.patt.e01)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %ImplicitAs.type: type = facet_type <@ImplicitAs, @ImplicitAs(%T)> [symbolic = %ImplicitAs.type (constants.%ImplicitAs.type.d62)]
// CHECK:STDOUT:   %Self: %ImplicitAs.type.d62 = bind_symbolic_name Self, 1 [symbolic = %Self (constants.%Self.519)]
// CHECK:STDOUT:   %Convert.type: type = fn_type @Convert, @ImplicitAs(%T) [symbolic = %Convert.type (constants.%Convert.type.275)]
// CHECK:STDOUT:   %Convert: @ImplicitAs.%Convert.type (%Convert.type.275) = struct_value () [symbolic = %Convert (constants.%Convert.42e)]
// CHECK:STDOUT:   %ImplicitAs.assoc_type: type = assoc_entity_type @ImplicitAs.%ImplicitAs.type (%ImplicitAs.type.d62) [symbolic = %ImplicitAs.assoc_type (constants.%ImplicitAs.assoc_type.837)]
// CHECK:STDOUT:   %assoc0: @ImplicitAs.%ImplicitAs.assoc_type (%ImplicitAs.assoc_type.837) = assoc_entity element0, imports.%Core.import_ref.207961.1 [symbolic = %assoc0 (constants.%assoc0.43db8b.1)]
// CHECK:STDOUT:
// CHECK:STDOUT:   interface {
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     .Self = imports.%Core.import_ref.ff5
// CHECK:STDOUT:     .Convert = imports.%Core.import_ref.630
// CHECK:STDOUT:     witness = (imports.%Core.Convert)
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic impl @impl(%A.loc9_14.1: %Animal.type) {
// CHECK:STDOUT:   %A.loc9_14.2: %Animal.type = bind_symbolic_name A, 0 [symbolic = %A.loc9_14.2 (constants.%A)]
// CHECK:STDOUT:   %A.patt.loc9_14.2: %Animal.type = symbolic_binding_pattern A, 0 [symbolic = %A.patt.loc9_14.2 (constants.%A.patt)]
// CHECK:STDOUT:   %A.as_type.loc9_26.2: type = facet_access_type %A.loc9_14.2 [symbolic = %A.as_type.loc9_26.2 (constants.%A.as_type)]
// CHECK:STDOUT:   %impl_witness: <witness> = impl_witness (), @impl(%A.loc9_14.2) [symbolic = %impl_witness (constants.%impl_witness)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:
// CHECK:STDOUT:   impl: %.loc9 as %Eats.ref {
// CHECK:STDOUT:   !members:
// CHECK:STDOUT:     witness = file.%impl_witness
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Feed(%T.loc11_9.1: %Eats.type) {
// CHECK:STDOUT:   %T.loc11_9.2: %Eats.type = bind_symbolic_name T, 0 [symbolic = %T.loc11_9.2 (constants.%T.1b5)]
// CHECK:STDOUT:   %T.patt.loc11_9.2: %Eats.type = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc11_9.2 (constants.%T.patt.6be)]
// CHECK:STDOUT:   %T.as_type.loc11_22.2: type = facet_access_type %T.loc11_9.2 [symbolic = %T.as_type.loc11_22.2 (constants.%T.as_type.27d)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type @Feed.%T.as_type.loc11_22.2 (%T.as_type.27d) [symbolic = %require_complete (constants.%require_complete.c75)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn[%T.param_patt: %Eats.type](%e.param_patt: @Feed.%T.as_type.loc11_22.2 (%T.as_type.27d)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @HandleAnimal(%T.loc30_17.1: %Animal.type) {
// CHECK:STDOUT:   %T.loc30_17.2: %Animal.type = bind_symbolic_name T, 0 [symbolic = %T.loc30_17.2 (constants.%T.fd4)]
// CHECK:STDOUT:   %T.patt.loc30_17.2: %Animal.type = symbolic_binding_pattern T, 0 [symbolic = %T.patt.loc30_17.2 (constants.%T.patt.a9c)]
// CHECK:STDOUT:   %T.as_type.loc30_32.2: type = facet_access_type %T.loc30_17.2 [symbolic = %T.as_type.loc30_32.2 (constants.%T.as_type.2ad)]
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %require_complete: <witness> = require_complete_type @HandleAnimal.%T.as_type.loc30_32.2 (%T.as_type.2ad) [symbolic = %require_complete (constants.%require_complete.234)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn[%T.param_patt: %Animal.type](%a.param_patt: @HandleAnimal.%T.as_type.loc30_32.2 (%T.as_type.2ad)) {
// CHECK:STDOUT:   !entry:
// CHECK:STDOUT:     %Feed.ref: %Feed.type = name_ref Feed, file.%Feed.decl [concrete = constants.%Feed]
// CHECK:STDOUT:     %a.ref: @HandleAnimal.%T.as_type.loc30_32.2 (%T.as_type.2ad) = name_ref a, %a
// CHECK:STDOUT:     %.loc30_43: %Eats.type = converted constants.%T.as_type.2ad, <error> [concrete = <error>]
// CHECK:STDOUT:     return
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generic fn @Convert(imports.%Core.import_ref.f6b058.2: type, imports.%Core.import_ref.ce1: @ImplicitAs.%ImplicitAs.type (%ImplicitAs.type.d62)) [from "core.carbon"] {
// CHECK:STDOUT:   %T: type = bind_symbolic_name T, 0 [symbolic = %T (constants.%T.8b3)]
// CHECK:STDOUT:   %ImplicitAs.type: type = facet_type <@ImplicitAs, @ImplicitAs(%T)> [symbolic = %ImplicitAs.type (constants.%ImplicitAs.type.d62)]
// CHECK:STDOUT:   %Self: %ImplicitAs.type.d62 = bind_symbolic_name Self, 1 [symbolic = %Self (constants.%Self.519)]
// CHECK:STDOUT:   %Self.as_type: type = facet_access_type %Self [symbolic = %Self.as_type (constants.%Self.as_type)]
// CHECK:STDOUT:
// CHECK:STDOUT:   fn[%self.param_patt: @Convert.%Self.as_type (%Self.as_type)]() -> @Convert.%T (%T.8b3);
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @impl(constants.%A) {
// CHECK:STDOUT:   %A.loc9_14.2 => constants.%A
// CHECK:STDOUT:   %A.patt.loc9_14.2 => constants.%A
// CHECK:STDOUT:   %A.as_type.loc9_26.2 => constants.%A.as_type
// CHECK:STDOUT:   %impl_witness => constants.%impl_witness
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @impl(%A.loc9_14.2) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Feed(constants.%T.1b5) {
// CHECK:STDOUT:   %T.loc11_9.2 => constants.%T.1b5
// CHECK:STDOUT:   %T.patt.loc11_9.2 => constants.%T.1b5
// CHECK:STDOUT:   %T.as_type.loc11_22.2 => constants.%T.as_type.27d
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @HandleAnimal(constants.%T.fd4) {
// CHECK:STDOUT:   %T.loc30_17.2 => constants.%T.fd4
// CHECK:STDOUT:   %T.patt.loc30_17.2 => constants.%T.fd4
// CHECK:STDOUT:   %T.as_type.loc30_32.2 => constants.%T.as_type.2ad
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ImplicitAs(constants.%T.8b3) {
// CHECK:STDOUT:   %T => constants.%T.8b3
// CHECK:STDOUT:   %T.patt => constants.%T.8b3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ImplicitAs(%T) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ImplicitAs(@Convert.%T) {}
// CHECK:STDOUT:
// CHECK:STDOUT: specific @Convert(constants.%T.8b3, constants.%Self.519) {
// CHECK:STDOUT:   %T => constants.%T.8b3
// CHECK:STDOUT:   %ImplicitAs.type => constants.%ImplicitAs.type.d62
// CHECK:STDOUT:   %Self => constants.%Self.519
// CHECK:STDOUT:   %Self.as_type => constants.%Self.as_type
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: specific @ImplicitAs(constants.%Eats.type) {
// CHECK:STDOUT:   %T => constants.%Eats.type
// CHECK:STDOUT:   %T.patt => constants.%Eats.type
// CHECK:STDOUT:
// CHECK:STDOUT: !definition:
// CHECK:STDOUT:   %ImplicitAs.type => constants.%ImplicitAs.type.af9
// CHECK:STDOUT:   %Self => constants.%Self.519
// CHECK:STDOUT:   %Convert.type => constants.%Convert.type.9a9
// CHECK:STDOUT:   %Convert => constants.%Convert.35d
// CHECK:STDOUT:   %ImplicitAs.assoc_type => constants.%ImplicitAs.assoc_type.9a7
// CHECK:STDOUT:   %assoc0 => constants.%assoc0.152
// CHECK:STDOUT: }
// CHECK:STDOUT:
