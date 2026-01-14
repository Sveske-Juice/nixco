project(
  'nixco',
  'cpp',
  default_options : ['cpp_std=c++23'])

# Find libssh via pkg-config
libssh_dep = dependency('libssh', required : true)

srcs = [
  'src/main.cpp',
  'src/transport.cpp',
  'src/strategy.cpp',
  'src/cli_parser.cpp',
]

executable('nixco',
  srcs,
  dependencies : libssh_dep,
  install : true
)
