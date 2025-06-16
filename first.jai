OUTPUT_EXECUTABLE_NAME := "Jelly";

#run {
    set_build_options_dc(.{do_output = false});

    args := get_build_options().compile_time_command_line;

    target_x64     := array_find(args, "-x64");
    target_arm     := array_find(args, "-arm64");

    cpu_target := CPU;
    os_target  := OS;
    if target_x64  cpu_target = .X64;
    if target_arm  cpu_target = .ARM64;

    target_triple_with_sdk: string;
    sdk_lib_path: string;

    log("Compiling for % %", os_target, cpu_target);

    build_output_directory := "";

    w := compiler_create_workspace("Target workspace");
    options := get_build_options(w);
    copy_commonly_propagated_fields(get_build_options(), *options);
    options.cpu_target = cpu_target;
    options.os_target  = os_target;
    options.output_executable_name = OUTPUT_EXECUTABLE_NAME;
    if cpu_target == .ARM64 {
        options.backend = .LLVM;
        options.llvm_options.target_system_features = "+lse";
    }

    options.output_path = build_output_directory;

    set_build_options(options, w);

    compiler_begin_intercept(w);
    add_build_file("source/example.jai", w);
    //add_build_file("source/jelly.jai", w);
    compiler_end_intercept(w);

};


//#import "Toolchains/Android";
#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";
#import "Process";
