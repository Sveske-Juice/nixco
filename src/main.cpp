#include <cerrno>
#include <expected>
#include <fmt/base.h>
#include <fmt/format.h>
#include <libssh/libssh.h>
#include <spdlog/spdlog.h>
#include <iostream>
#include <sysexits.h>
#include <fstream>
#include <system_error>

#include "include/strategy.h"
#include "include/transport.h"
#include "include/cli_parser.h"
#include "spdlog/common.h"
#include "version.h"

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
  const char* usage = R"(Usage: 
  ./nixco -t <transport> [options]

  Transports:
    -t, --transport { ssh | serial }  Transport type

  SSH Transport Options:
    --host <host>         required
    -u, --user <user>     required
    -p, --port <port>     optional (default: 22)
    -i, --identity <path> optional (private key to use)

  Serial Transport Options:
    TODO: impl

  Strategy:
    -s, --strategy { runcmds | erasereload } optional (default: runcmds)

  General:
    -f, --file            The configuration file to apply
    -h, --help            Show this help message
    -v, --version         Show version
    -d, --debug           Show response while applying)";

  std::cout << usage << std::endl;
}

int main(int argc, char **argv) {
  CliParser cliparser(argc, argv);
  spdlog::set_level(spdlog::level::info);
  spdlog::set_pattern("[%^%l%$] %v");

  if (cliparser.cmdOptionExists("-h") || cliparser.cmdOptionExists("--help")) {
    printUsage();
    return EX_OK;
  }

  if (cliparser.cmdOptionExists("-v") || cliparser.cmdOptionExists("--version")) {
    std::cout << PROJECT_VERSION << std::endl;
    return EX_OK;
  }

  // Build Transport and Strategy from CLI Args
  auto transportPtr = Transport::create_from_cliargs(cliparser);
  if (!transportPtr) {
    spdlog::error(transportPtr.error());
    return EX_USAGE;
  }
  Transport &transport = *transportPtr.value();

  auto strategyPtr = Strategy::create_from_cliargs(cliparser);
  if (!strategyPtr) {
    spdlog::error(strategyPtr.error());
    return EX_USAGE;
  }
  const Strategy &strategy = *strategyPtr.value();

  // Read config
  auto cfgPath = cliparser.getCmdOption("-f").value_or(cliparser.getCmdOption("--file").value_or(""));
  if (cfgPath.empty()) {
    spdlog::error("No config file provided");
    return EX_USAGE;
  }
  std::string config = read_file(cfgPath);

  // Setup transport
  auto err = transport.init();
  if (err) {
    spdlog::error(*err);
    return -1;
  }

  err = transport.connect();
  if (err) {
    spdlog::error(*err);
    return -1;
  }

  // Wait for prompt
  auto prompt = strategy.wait_for_prompt(transport);
  if (!prompt) {
    spdlog::error("Failed to get first PTY prompt from remote. rc = {:d}", prompt.error());
    return prompt.error();
  }

  // Run strategy
  bool printing = cliparser.cmdOptionExists("-d") || cliparser.cmdOptionExists("--debug");
  spdlog::info("Applying {:s}...", cfgPath);
  auto res = strategy.apply(transport, config, printing);
  if (res) {
    spdlog::error(*res);
    return -1;
  }
  spdlog::info("Done, no errors reported");

  return EX_OK;
}
