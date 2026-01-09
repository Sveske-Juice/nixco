project(
  'nixco',
  'cpp',
  default_options : ['cpp_std=c++20'])

# Find libssh via pkg-config
libssh_dep = dependency('libssh', required : true)

executable('nixco',
  'src/main.cpp',
  dependencies : libssh_dep
)
