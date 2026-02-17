#ifndef STRATEGY_H
#define STRATEGY_H

#include "include/cli_parser.h"
#include "include/transport.h"
#include <expected>
#include <memory>
#include <optional>
#include <regex>
#include <string>
#include <unordered_map>

enum MODE {
  ANYMODE,
  UEXEC,
  PEXEC,
  GCFG, // global config
  TCL_CONTINUATION,
};

static std::unordered_map<MODE, std::string> modeNames = {
  { ANYMODE, "Any Mode" },
  { UEXEC, "User Exec Mode"},
  { PEXEC, "Privelege Exec Mode"},
  { GCFG, "Global Configuration Mode"},
  { TCL_CONTINUATION, "TCL Continuation"},
};

static std::unordered_map<MODE, std::string> modePatterns = {
  { ANYMODE, R"(^[A-Za-z0-9-]+(\((config(-[^\)]*)?|tcl)\))?[>#]$)" },
  { UEXEC, R"(^[A-Za-z0-9-]+>$)" },
  { PEXEC, R"(^[A-Za-z0-9-]+#$)" },
  { GCFG, R"(^[A-Za-z0-9-]+\((config)\)#$)" },
  { TCL_CONTINUATION, R"(^\s*\+>\s*$)" }
};

class Strategy {
protected:
  std::string strip_ansi(const std::string &s) const;
  bool looks_like_prompt(const std::string &buffer, const std::regex &prompt) const;
  std::expected<MODE, std::string> get_to_mode(Transport &transport, MODE mode, bool print) const;
  std::optional<std::string> uploadFile(Transport &transport, const std::string &file, std::string path) const;
  std::optional<std::string> deleteFile(Transport &transport, const std::string &path) const;
public:
  virtual ~Strategy() = default;
  std::optional<std::string> reload_device(Transport &transport) const;
  std::expected<std::string, int> wait_for_prompt(Transport &transport, const std::regex &pattern, bool printOutput = false) const;
  std::expected<std::string, int> wait_for_prompt(Transport &transport, const std::string &pattern, bool printOutput = false) const;
  virtual std::optional<std::string> apply(Transport &transport, const CliParser &cliparser, const std::string &config, const bool print) const;
  static std::expected<std::unique_ptr<Strategy>, std::string> create_from_cliargs(const CliParser &cliparser);
};

class TclStartStrategy : public Strategy {
public:
  std::optional<std::string> apply(Transport &transport, const CliParser &cliparser, const std::string &config, const bool print) const override;
};


#endif
