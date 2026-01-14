#include <expected>
#include <libssh/libssh.h>
#include <iostream>
#include <sysexits.h>

#include "include/strategy.h"
#include "include/transport.h"
#include "include/cli_parser.h"

#define HOST "192.168.2.129"
#define USER "admin"

void printUsage() {
}

int main(int argc, char **argv) {
  CliParser cliparser(argc, argv);

  if (cliparser.cmdOptionExists("-h") || cliparser.cmdOptionExists("--help")) {
    printUsage();
    return EX_OK;
  }

  // Build Transport and Strategy from CLI Args
  auto transportPtr = Transport::create_from_cliargs(cliparser);
  if (!transportPtr) {
    std::cerr << transportPtr.error() << std::endl;
    return EX_USAGE;
  }
  Transport &transport = *transportPtr.value();

  auto strategyPtr = Strategy::create_from_cliargs(cliparser);
  if (!strategyPtr) {
    std::cerr << strategyPtr.error() << std::endl;
    return EX_USAGE;
  }
  const Strategy &strategy = *strategyPtr.value();

  // Setup transport
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
  auto prompt = strategy.wait_for_prompt(transport);
  if (!prompt.has_value())
    return -1;


  // Run strategy
  std::string config = "terminal length 0\nshow vlan brief\n";
  auto res = strategy.apply(transport, config);
  if (res.has_value()) {
    std::cerr << res.value() << std::endl;
    return -1;
  }

  return EX_OK;
}
