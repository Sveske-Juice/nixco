#include <expected>
#include <libssh/libssh.h>
#include <iostream>
#include <regex>

#include "include/config.h"
#include "include/strategy.h"
#include "include/transport.h"

#define HOST "192.168.2.129"
#define USER "admin"

int main(int argc, char **argv) {
  SshConfig sshConfig{};
  sshConfig.host = HOST;
  sshConfig.user = USER;
  sshConfig.port = 22;
  // sshConfig.identityFile = "/home/CyberVPL/.ssh/id_ed25519";
  sshConfig.verbosity = SSH_LOG_WARN;

  Strategy defaultStrategy;
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

  // Wait for prompt
  auto prompt = defaultStrategy.wait_for_prompt(transport);
  if (!prompt.has_value())
    return -1;

  std::string config = "terminal length 0\nshow vlan brief\n";
  auto res = defaultStrategy.apply(transport, config);
  if (res.has_value()) {
    std::cerr << res.value() << std::endl;
    return -1;
  }

  return 0;
}

