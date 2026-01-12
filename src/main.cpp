#include <libssh/libssh.h>
#include <iostream>
#include <sys/socket.h>

#include "include/config.h"
#include "include/transport.h"

#define HOST "192.168.2.129"
#define USER "admin"

int main(int argc, char **argv) {
  SshConfig sshConfig{};
  sshConfig.host = HOST;
  sshConfig.user = USER;
  sshConfig.port = 22;

  std::cout << "Password: ";
  std::cin >> sshConfig.password;
  std::cout << "trying: " << sshConfig.password << std::endl;

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
