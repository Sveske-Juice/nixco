#include <libssh/libssh.h>
#include <iostream>

#include "include/config.h"
#include "include/transport.h"

#define HOST ""
#define USER ""

int main(int argc, char **argv) {
  SshConfig sshConfig{};
  sshConfig.host = HOST;
  sshConfig.user = USER;
  sshConfig.port = 22;

  SshTransport transport(sshConfig);
  auto err = transport.init();
  if (err.has_value()) {
    std::cerr << err.value() << std::endl;
    return -1;
  }

  err = transport.connect();
  if (err.has_value()) {
    std::cerr << err.value() << std::endl;
    return -1;
  }

  err = transport.write("ps aux\n");
  if (err.has_value()) {
    std::cerr << err.value() << std::endl;
    return -1;
  }

  auto res = transport.read(4096);
  if (res.has_value())
    std::cout << "res: " << res.value() << std::endl;
  else
    std::cerr << "rc: " << ssh_get_error(&res.error()) << std::endl;

  return 0;
}
