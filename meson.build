project(
  'nixco',
  'cpp',
  default_options : ['cpp_std=c++23'])

conf = configuration_data()
conf.set('PROJECT_VERSION', run_command('cat', 'VERSION', check : true).stdout().strip())

configure_file(
  input: 'include/version.h.in',
  output: 'version.h',
  configuration: conf
)

# Find via pkg-config
libssh = dependency('libssh', method: 'pkg-config', required : true)
fmt = dependency('fmt', method: 'pkg-config', required : true)
spdlog = dependency('spdlog', method: 'pkg-config', required : true)

srcs = [
  'src/main.cpp',
  'src/sshtransport.cpp',
  'src/serialtransport.cpp',
  'src/strategy.cpp',
  'src/cli_parser.cpp',
]

executable('nixco',
  srcs,
  dependencies : [libssh, fmt, spdlog],
  include_directories: include_directories('include'),
  install : true
)
