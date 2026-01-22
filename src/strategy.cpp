#include <expected>
#include <fmt/format.h>
#include <iostream>
#include <iterator>
#include <memory>
#include <optional>
#include <ranges>
#include <spdlog/spdlog.h>
#include <sstream>
#include <stdexcept>
#include <string>
#include <regex>
#include <fmt/format.h>
#include <string_view>
#include <system_error>
#include <vector>

#include "include/strategy.h"
#include "include/transport.h"

#define CHUNK 4096

static std::regex ANYMODE(R"(^[A-Za-z0-9-]+(\(config(-[^\)]*)?\))?[>#]$)");
static std::regex UEXEC(R"(^[A-Za-z0-9-]+>$)");
static std::regex PEXEC(R"(^[A-Za-z0-9-]+#$)");
static std::regex GLOBALCONFIG(R"(^[A-Za-z0-9-]+\((config)\)#$)");

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

std::string_view trim_sv(std::string_view s) {
    size_t start = 0;
    while (start < s.size() && std::isspace(static_cast<unsigned char>(s[start]))) start++;

    size_t end = s.size();
    while (end > start && std::isspace(static_cast<unsigned char>(s[end - 1]))) end--;

    return s.substr(start, end - start);
}

bool Strategy::looks_like_prompt(const std::string &buffer, const std::regex &prompt) const {
  std::istringstream iss(buffer);
  std::vector<std::string> lines{std::istream_iterator<std::string>(iss), std::istream_iterator<std::string>()};

  for (auto& line : lines | std::views::reverse) {
    bool match = std::regex_match(line.c_str(), prompt);
    // spdlog::info("{}: {:s}", match, line);
    if (match) return true;
  }

  return false;
}

std::expected<std::string, int> Strategy::wait_for_prompt(Transport& transport, const std::regex &pattern) const {
  std::string buf;

  while (transport.is_open()) {
    auto chunk = transport.read(CHUNK);

    // Propagate error
    if (!chunk.has_value())
      return std::unexpected<int>(chunk.error());

    buf += chunk.value();

    if (buf.find("--More--") != std::string::npos) {
      spdlog::warn("Encounted paged output. Disable with \"terminal length 0\"\nRefusing to continue");
      return std::unexpected<int>(-1);
    }

    // HACK: Kind of a hack, but who cares
    if (buf.find("Enter TEXT message") != std::string::npos) {
      return "MULTILINE";
    }

    if (looks_like_prompt(buf, pattern)) {
      break;
    }
  }

  return buf;
}

std::optional<std::string> Strategy::apply(Transport &transport, const std::string &config, const bool print) const {
  std::string cmd;
  std::istringstream stream(config);

  // Get into global configuration mode
  auto err = get_to_global_config_mode(transport);
  if (err) return err;

  spdlog::info("Success! We are in global config mode");

  while (std::getline(stream, cmd)) {
    if (cmd.empty()) continue;
    if (cmd.front() == '!') continue;

    cmd += '\n';

    auto res = transport.write(cmd);
    if (res.has_value()) {
      return res.value();
    }

    // Wait for execution
    auto recvBuffer = wait_for_prompt(transport, ANYMODE);
    if (!recvBuffer.has_value()) {
      return std::string("Failed to wait for prompt after writing command.");
    }

    // HACK: handle this some other way bruh
    if (*recvBuffer == "MULTILINE") {
      spdlog::info("Multiline field detected, Sending until '#' encountered");
      while (std::getline(stream, cmd)) {
        auto err = transport.write(cmd + '\n');
        if (err) return err;

        if (cmd == "#")
          break;
      }
    }

    if (print)
      std::cout << recvBuffer.value() << std::endl;

    // TODO: catch + handle error in command
  }

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

std::optional<std::string> Strategy::get_to_global_config_mode(Transport &transport) const {
  auto err = transport.write("\n");
  if (err) return err;

  spdlog::info("Trying to enter Global Configuration Mode");
  auto initialState = wait_for_prompt(transport, ANYMODE);
  if (!initialState) return *initialState;

  spdlog::info("RX: {}",
    [&]{
        std::string s;
        for (unsigned char c : *initialState)
            fmt::format_to(std::back_inserter(s), "{:02X} ", c);
        return s;
    }()
  );
  spdlog::info("Initial state: {:s}", *initialState);


  // What should we do from initial state to get to global configuration mode?
  if (looks_like_prompt(*initialState, UEXEC)) { // Starting from User EXEC
    spdlog::info("Elevating from User Exec Mode");
    auto err = transport.write("enable\n");
    if (err) return err;

    auto pexState = wait_for_prompt(transport, PEXEC);
    if (!pexState) return *pexState;

    // Goto global config
    err = transport.write("config terminal\n");
    if (err) return err;

    auto endState = wait_for_prompt(transport, GLOBALCONFIG);
    if (!endState) return *endState;
  }
  else if (looks_like_prompt(*initialState, PEXEC)) { // Starting from Privelege EXEC
    spdlog::info("Going to global config from Privelege EXEC");
    err = transport.write("config terminal\n");
    if (err) return err;

    auto endState = wait_for_prompt(transport, GLOBALCONFIG);
    if (!endState) return *endState;
  }
  else if (looks_like_prompt(*initialState, GLOBALCONFIG)) { // Could already be in global config
  }
  else {
    return fmt::format("Unkown inital state. Dont know how to get to global config from:\n {:s}", *initialState);
  }

  return std::nullopt;
}
