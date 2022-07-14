#import "Compiler";
#import "Basic";

#run build();

build :: () {
  w := compiler_create_workspace();
  
  options := get_build_options();
  options.output_executable_name = "tetris";

  set_build_options(options, w);

  add_build_file("src/tetris.jai", w);

  set_build_options_dc(.{do_output = false});
}
