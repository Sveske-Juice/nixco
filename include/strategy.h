#ifndef STRATEGY_H
#define STRATEGY_H

#include "include/cli_parser.h"
#include "include/transport.h"
#include <expected>
#include <memory>
#include <optional>
#include <regex>
#include <string>

class Strategy {
private:
  std::string strip_ansi(const std::string &s) const;
  bool looks_like_prompt(const std::string &buffer, const std::regex &prompt) const;
  std::optional<std::string> get_to_global_config_mode(Transport &transport) const;
public:
  virtual ~Strategy() = default;
  std::expected<std::string, int> wait_for_prompt(Transport &transport, const std::regex &pattern) const;
  virtual std::optional<std::string> apply(Transport &transport, const std::string &config, const bool print) const;
  static std::expected<std::unique_ptr<Strategy>, std::string> create_from_cliargs(const CliParser &cliparser);
};

// TODO: ERASE_RELOAD strat

#endif
