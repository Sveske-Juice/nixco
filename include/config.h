#ifndef CONFIG_H
#define CONFIG_H

#include <cstdint>
#include <libssh/libssh.h>
#include <string>

struct SshConfig {
  std::string host;
  std::string user;
  std::string identityFile;
  int16_t port;
  int verbosity = SSH_OPTIONS_LOG_VERBOSITY;
  int timeout = 5;
};

#endif
