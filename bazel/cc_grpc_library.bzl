"""Generates and compiles C++ grpc stubs from proto_library rules."""

load("//:bazel/generate_cc.bzl", "generate_cc")

def cc_grpc_library(name, srcs, deps, proto_only, **kwargs):
  """Generates C++ grpc classes from a .proto file.

  Assumes the generated classes will be used in cc_api_version = 2.

  Arguments:
      name: name of rule.
      srcs: a single proto_library, which wraps the .proto files with services.
      deps: a list of C++ proto_library (or cc_proto_library) which provides
        the compiled code of any message that the services depend on.
      **kwargs: rest of arguments, e.g., compatible_with and visibility.
  """
  if len(srcs) > 1:
    fail("Only one srcs value supported", "srcs")

  proto_target = "_" + name + "_only"
  codegen_target = "_" + name + "_codegen"
  codegen_grpc_target = "_" + name + "_grpc_codegen"
  proto_deps = ["_" + dep + "_only" for dep in deps if dep.find(':') == -1]
  proto_deps += [dep.split(':')[0] + ':' + "_" + dep.split(':')[1] + "_only" for dep in deps if dep.find(':') != -1]

  native.proto_library(
      name = proto_target,
      srcs = srcs,
      deps = proto_deps,
      **kwargs
  )

  generate_cc(
      name = codegen_target,
      srcs = [proto_target],
      **kwargs
  )

  if not proto_only:
    generate_cc(
        name = codegen_grpc_target,
        srcs = [proto_target],
        plugin = "//:grpc_cpp_plugin",
        **kwargs
    )

    native.cc_library(
        name = name,
        srcs = [":" + codegen_grpc_target, ":" + codegen_target],
        hdrs = [":" + codegen_grpc_target, ":" + codegen_target],
        deps = deps + ["//:grpc++", "//:grpc++_codegen_proto", "//external:protobuf"],
        **kwargs
    )
  else:
    native.cc_library(
        name = name,
        srcs = [":" + codegen_target],
        hdrs = [":" + codegen_target],
        deps = deps + ["//external:protobuf"],
        **kwargs
    )
