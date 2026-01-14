#include <expected>
#include <fmt/format.h>
#include <libssh/libssh.h>
#include <iostream>
#include <sysexits.h>
#include <fstream>
#include <system_error>

#include "include/strategy.h"
#include "include/transport.h"
#include "include/cli_parser.h"

std::string read_file(const std::string& path) {
    std::ifstream f(path, std::ios::binary);
    if (!f) {
      throw std::system_error(errno, std::generic_category(), fmt::format("Failed to open: '{:s}'", path));
    }

    std::string data;
    f.seekg(0, std::ios::end);
    data.resize(f.tellg());
    f.seekg(0, std::ios::beg);

    f.read(data.data(), data.size());
    return data;
}

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

  // Read config
  auto cfgPath = cliparser.getCmdOption("-f").value_or(cliparser.getCmdOption("--file").value_or(""));
  if (cfgPath.empty()) {
    std::cerr << "No config file provided" << std::endl;
    return EX_USAGE;
  }
  std::string config = read_file(cfgPath);

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
  auto res = strategy.apply(transport, config);
  if (res.has_value()) {
    std::cerr << res.value() << std::endl;
    return -1;
  }
  return EX_OK;
}
