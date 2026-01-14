# Generate compile_commands
build:
  rm -rf build/
  rm -rf compile_commands.json

  meson setup build
  meson compile -C build
  ln -sf build/compile_commands.json compile_commands.json
