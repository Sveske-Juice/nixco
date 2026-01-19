#ifndef CONFIG_H
#define CONFIG_H

#include <cstdint>
#include <libssh/libssh.h>
#include <string>
#include <termios.h>

struct SerialConfig {
  std::string portname;
  speed_t speed = B9600;
};

struct SshConfig {
  std::string host;
  std::string user;
  std::string identityFile;
  int16_t port = 22;
  int verbosity = SSH_LOG_NOLOG;
  int timeout = 5;
};

#endif
