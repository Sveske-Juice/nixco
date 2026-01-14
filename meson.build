project(
  'nixco',
  'cpp',
  default_options : ['cpp_std=c++23'])

# Find via pkg-config
libssh = dependency('libssh', method: 'pkg-config', required : true)
fmt = dependency('fmt', method: 'pkg-config', required : true)

srcs = [
  'src/main.cpp',
  'src/transport.cpp',
  'src/strategy.cpp',
  'src/cli_parser.cpp',
]

executable('nixco',
  srcs,
  dependencies : [libssh, fmt ],
  install : true
)
