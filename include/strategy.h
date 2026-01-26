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
protected:
  std::string strip_ansi(const std::string &s) const;
  bool looks_like_prompt(const std::string &buffer, const std::regex &prompt) const;
  std::optional<std::string> get_to_global_config_mode(Transport &transport) const;
  std::optional<std::string> get_to_PEXEC(Transport &transport) const;
public:
  virtual ~Strategy() = default;
  std::optional<std::string> reload_device(Transport &transport) const;
  std::expected<std::string, int> wait_for_prompt(Transport &transport, const std::regex &pattern) const;
  std::expected<std::string, int> wait_for_prompt(Transport &transport, const std::string &pattern) const;
  virtual std::optional<std::string> apply(Transport &transport, const CliParser &cliparser, const std::string &config, const bool print) const;
  static std::expected<std::unique_ptr<Strategy>, std::string> create_from_cliargs(const CliParser &cliparser);
};

class TclReloadStrategy : public Strategy {
public:
  std::optional<std::string> apply(Transport &transport, const CliParser &cliparser, const std::string &config, const bool print) const override;
};


#endif
