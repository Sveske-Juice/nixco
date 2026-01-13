#include <expected>
#include <iostream>
#include <optional>
#include <sstream>
#include <string>
#include <regex>

#include "include/strategy.h"
#include "include/transport.h"

#define CHUNK 4096

std::string Strategy::strip_ansi(const std::string &s) const {
    std::string res = s;
    // Remove CSI sequences: ESC [ ... letters
    static const std::regex csi("\x1B\\[[0-9;?]*[A-Za-z]");
    res = std::regex_replace(res, csi, "");

    // Remove DCS / OSC sequences: ESC P ... ESC
    static const std::regex osc("\x1BP.*?\x1B\\\\");
    res = std::regex_replace(res, osc, "");

    // Remove other ESC sequences
    static const std::regex esc("\x1B.");
    res = std::regex_replace(res, esc, "");

    return res;
}

bool Strategy::looks_like_prompt(const std::string &buffer) const {
    // Strip control sequences
    auto s = strip_ansi(buffer);

    // Trim trailing whitespace and newlines
    while (!s.empty() && (s.back() == '\n' || s.back() == '\r' || s.back() == ' '))
        s.pop_back();

    if (s.empty())
        return false;

    // Common prompt characters
    static const std::string prompt_chars = "$#>%";

    return !s.empty() && prompt_chars.find(s.back()) != std::string::npos;
}

std::expected<std::string, int> Strategy::wait_for_prompt(Transport& transport) const {
  std::string buf;

  while (true) {
    auto chunk = transport.read(CHUNK);

    // Propagate error
    if (!chunk.has_value())
      return std::unexpected<int>(chunk.error());
    
    for (unsigned char c : chunk.value()) {
      if (c >= 32 && c <= 126) {
        std::cout << c;           // printable ASCII
      } else if (c == '\n') {
        std::cout << "\\n\n";     // newline
      } else if (c == '\r') {
        std::cout << "\\r";       // carriage return
      } else {
        std::cout << "\\x" 
          << std::hex << (int)c 
          << std::dec;     // other non-printable bytes
      }
    }

    buf += chunk.value();

    if (buf.find("--More--") != std::string::npos) {
      std::cerr << "WARNING: Encounted paged output. Disable with \"terminal length 0\"\nRefusing to continue" << std::endl;
      return std::unexpected<int>(-1);
    }

    if (looks_like_prompt(buf)) {
      return buf;
    }
  }
}

std::optional<std::string> Strategy::apply(Transport &transport, const std::string &config) const {
  std::string cmd;
  std::istringstream stream(config);
  while (std::getline(stream, cmd)) {
    if (cmd.empty()) continue;

    auto res = transport.write(cmd + '\n');
    if (res.has_value()) {
      return res.value();
    }

    // Wait for execution
    auto recvBuffer = wait_for_prompt(transport);
    if (!recvBuffer.has_value()) {
      return std::string("Failed to wait for prompt after writing command.");
    }

    std::cout << recvBuffer.value() << std::endl;

    // TODO: catch + handle error in command
  }

  return std::nullopt;
}
