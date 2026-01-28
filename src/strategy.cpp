#include <expected>
#include <fmt/format.h>
#include <iostream>
#include <iterator>
#include <memory>
#include <optional>
#include <ranges>
#include <spdlog/spdlog.h>
#include <sstream>
#include <string>
#include <regex>
#include <fmt/format.h>
#include <string_view>
#include <vector>

#include "include/strategy.h"
#include "cli_parser.h"
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


std::expected<std::string, int> Strategy::wait_for_prompt(Transport &transport, const std::string &pattern) const {
  std::string buf;

  while (transport.is_open()) {
    auto chunk = transport.read(CHUNK);
    if (!chunk) return std::unexpected<int>(chunk.error());

    buf += chunk.value();

    if (buf.contains(pattern))
      return buf;
  }

  return std::unexpected<int>(-1);
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

    if (buf.find("Password:") != std::string::npos) {
      spdlog::warn("Password required!");
      std::string pass;
      std::cout << "Password: ";
      std::cin >> pass;

      auto err = transport.write(fmt::format("{:s}\n", pass));
      if (err) return std::unexpected<int>(-1);

      buf.clear();
    }

    if (looks_like_prompt(buf, pattern)) {
      break;
    }
  }

  return buf;
}

std::optional<std::string> Strategy::apply(Transport &transport, const CliParser &cliparser, const std::string &config, const bool print) const {
  std::string cmd;
  std::istringstream stream(config);

  // Get into global configuration mode
  auto mode = get_to_mode(transport, GCFG);
  if (!mode) return mode.error();

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
    auto recvBuffer = wait_for_prompt(transport, std::regex(modePatterns[ANYMODE]));
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
  else if (strategy == "tclreload") {
    return std::make_unique<TclReloadStrategy>();
  }

  return std::unexpected<std::string>(fmt::format("Unrecognized strategy: {:s}", strategy));
}

std::expected<MODE, std::string> Strategy::get_to_mode(Transport &transport, MODE mode) const {
  // We must poke serial sometimes
  auto err = transport.write("\n");
  if (err) return std::unexpected<std::string>(*err);

  spdlog::info("Tring to enter {:s}", modeNames[mode]);

  auto initialState = wait_for_prompt(transport, std::regex(modePatterns[ANYMODE]));
  if (!initialState) return std::unexpected<std::string>(*initialState);

  spdlog::info("Initial state: {:s}", *initialState);
  // Already in mode
  if (looks_like_prompt(*initialState, std::regex(modePatterns[mode])))
    return mode;

  switch (mode) {
    case PEXEC: {
      if (looks_like_prompt(*initialState, std::regex(modePatterns[UEXEC]))) {
        err = transport.write("enable\n");
        auto prompt = wait_for_prompt(transport, std::regex(modePatterns[PEXEC]));
        if (!prompt) return std::unexpected<std::string>("err");
        return mode;
      }
      else if (looks_like_prompt(*initialState, std::regex(modePatterns[GCFG]))) {
        err = transport.write("end\n");
        auto prompt = wait_for_prompt(transport, std::regex(modePatterns[PEXEC]));
        if (!prompt) return std::unexpected<std::string>("err");
        return mode;
      }
      break;
    }
    case GCFG: {
      if (looks_like_prompt(*initialState, std::regex(modePatterns[UEXEC]))) {
        err = transport.write("enable\n");
        initialState = wait_for_prompt(transport, std::regex(modePatterns[PEXEC]));
        if (!initialState) return std::unexpected<std::string>("err");
      }

      if (looks_like_prompt(*initialState, std::regex(modePatterns[PEXEC]))) {
        err = transport.write("configure terminal\n");
        auto prompt = wait_for_prompt(transport, std::regex(modePatterns[GCFG]));
        if (!prompt) return std::unexpected<std::string>("err");
        return mode;
      }
      break;
    }
    default:
      break;
  }
  return std::unexpected<std::string>(fmt::format("Dont know how to get to {:s} from {:s}", modeNames[mode], *initialState));
}

std::string escape_tcl_line(const std::string &line) {
    std::string out;
    out.reserve(line.size());
    for (char c : line) {
        switch (c) {
            case '$': out += "\\$"; break;    // prevent variable expansion
            case '[': out += "\\["; break;    // prevent command execution
            case ']': out += "\\]"; break;
            case '"': out += "\\\""; break;   // escape quotes
            case '\\': out += "\\\\"; break;  // escape backslash
            default: out += c; break;
        }
    }
    return out;
}

std::optional<std::string> TclReloadStrategy::apply(Transport &transport, const CliParser &cliparser, const std::string &config, const bool print) const {
  auto mode = get_to_mode(transport, PEXEC);
  if (!mode) return mode.error();

  spdlog::info("Sucess! We are in PEXEC Mode");
  spdlog::info("Entering TCL Scripting");

  // Initial TCL setup to write bootstrap script
  auto err = transport.write("tclsh\n");
  if (err) return err;
  auto prompt = wait_for_prompt(transport, std::regex(modePatterns[ANYMODE]));
  if (!prompt) return "Failed to get into TCL prompt";

  err = transport.write("set filename \"flash:bootstrap.cfg\"\n");
  if (err) return err;
  err = transport.write("set f [open $filename w]\n");
  if (err) return err;

  spdlog::info("Writing config into boostrap script");
  std::string cmd;
  std::istringstream stream(config);
  while (std::getline(stream, cmd)) {
    err = transport.write(fmt::format("puts $f \"{:s}\"\n", escape_tcl_line(cmd)));
    if (err) return err;
  }

  err = transport.write("close $f\n");
  if (err) return err;
  err = transport.write("tclquit\n");
  if (err) return err;

  prompt = wait_for_prompt(transport, std::regex(modePatterns[PEXEC]));
  if (!prompt) return "Failed to return from TCL to PEXEC";

  if (print)
    std::cout << *prompt << std::endl;

  spdlog::info("Config written. Copying to startup-config...");

  err = transport.write("copy flash:bootstrap.cfg startup-config\n\n");
  if (err) return err;

  // Should return to prompt after copying
  prompt = wait_for_prompt(transport, std::regex(modePatterns[ANYMODE]));
  if (!prompt) return "Failed to return to prompt after copying to running-config";
  if (print)
    std::cout << *prompt << std::endl;

  if (cliparser.cmdOptionExists("--replace")) {
    err = transport.write("copy flash:bootstrap.cfg running-config\n\n");
    if (err) return err;
    spdlog::info("Copying config to running-config...");

    // Should return to prompt after copying into running-config
    prompt = wait_for_prompt(transport, std::regex(modePatterns[ANYMODE]));
    if (!prompt) return "Failed to return to prompt after copying to running-config";

    if (print)
      std::cout << *prompt << std::endl;
  }

  return std::nullopt;
}

std::optional<std::string> Strategy::reload_device(Transport &transport) const {
  auto err = transport.write("reload\n\n");
  if (err) return err;

  auto prompt = wait_for_prompt(transport, "System configuration has been modified");
  if (!prompt) return err;
  err = transport.write("n\n");
  if (err) return err;

  prompt = wait_for_prompt(transport, "Proceed with reload");
  if (!prompt) return err;
  err = transport.write("\n");
  if (err) return err;

  spdlog::info("Device is reloading now (might take a while)");
  return std::nullopt;
}
