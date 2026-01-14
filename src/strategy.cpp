#include <expected>
#include <fmt/format.h>
#include <iostream>
#include <memory>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <regex>

#include "include/strategy.h"
#include "include/transport.h"

#define CHUNK 4096

std::string Strategy::strip_ansi(const std::string &s) const {
  // This is ChatGPT, too lazy to do it myself
  std::string res = s;

  static const std::regex csi("\x1B\\[[0-9;?]*[A-Za-z]");
  res = std::regex_replace(res, csi, "");

  static const std::regex osc("\x1BP.*?\x1B\\\\");
  res = std::regex_replace(res, osc, "");

  static const std::regex esc("\x1B.");
  res = std::regex_replace(res, esc, "");

  return res;
}

bool Strategy::looks_like_prompt(const std::string &buffer) const {
  auto s = strip_ansi(buffer);

  while (!s.empty() && (s.back() == '\n' || s.back() == '\r' || s.back() == ' '))
    s.pop_back();

  if (s.empty())
    return false;

  static const std::string prompt_chars = "$#>%";
  return !s.empty() && prompt_chars.find(s.back()) != std::string::npos;
}

std::expected<std::string, int> Strategy::wait_for_prompt(Transport &transport) const {
  std::string emptyEcho;
  return wait_for_prompt(transport, emptyEcho);
}

std::expected<std::string, int> Strategy::wait_for_prompt(Transport& transport, std::string &cmd) const {
  std::string buf;

  while (transport.is_open()) {
    auto chunk = transport.read(CHUNK);

    // Propagate error
    if (!chunk.has_value())
      return std::unexpected<int>(chunk.error());

    buf += chunk.value();

    if (buf.find("--More--") != std::string::npos) {
      std::cerr << "WARNING: Encounted paged output. Disable with \"terminal length 0\"\nRefusing to continue" << std::endl;
      return std::unexpected<int>(-1);
    }

    if (looks_like_prompt(buf)) {
      break;
    }
  }

  return buf;
}

std::optional<std::string> Strategy::apply(Transport &transport, const std::string &config) const {
  std::string cmd;
  std::istringstream stream(config);
  while (std::getline(stream, cmd)) {
    if (cmd.empty()) continue;

    cmd += '\n';

    auto res = transport.write(cmd);
    if (res.has_value()) {
      return res.value();
    }

    // Wait for execution
    auto recvBuffer = wait_for_prompt(transport, cmd);
    if (!recvBuffer.has_value()) {
      return std::string("Failed to wait for prompt after writing command.");
    }

    std::cout << recvBuffer.value();

    // TODO: catch + handle error in command
  }

  std::cout << std::endl;

  return std::nullopt;
}

std::expected<std::unique_ptr<Strategy>, std::string> Strategy::create_from_cliargs(const CliParser &cliparser) {
  auto strategy = cliparser.getCmdOption("-s").value_or(cliparser.getCmdOption("--strategy").value_or(""));
  if (strategy.empty()) {
    strategy = "runcmds"; // default
  }

  if (strategy == "runcmds") {
    return std::make_unique<Strategy>();
  }
  else if (strategy == "erasereload") {
    throw std::runtime_error("not impl");
  }

  return std::unexpected<std::string>(fmt::format("Unrecognized strategy: {:s}", strategy));
}
