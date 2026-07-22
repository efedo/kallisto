#pragma once

// kallisto historically uses the GNU getopt_long interface.  POSIX systems
// provide it; MSVC does not, so keep a small compatible implementation local
// to the executable rather than making the Windows build depend on a POSIX
// compatibility layer.
#ifndef _WIN32
#include <getopt.h>
#else

#include <cstring>

constexpr int no_argument = 0;
constexpr int required_argument = 1;
constexpr int optional_argument = 2;

struct option {
  const char* name;
  int has_arg;
  int* flag;
  int val;
};

#if __cplusplus >= 201703L
inline char* optarg = nullptr;
inline int optind = 1;
inline int opterr = 1;
inline int optopt = 0;
#else
static char* optarg = nullptr;
static int optind = 1;
static int opterr = 1;
static int optopt = 0;
#endif

inline int getopt_long(int argc, char* const argv[], const char* short_options,
                       const option* long_options, int* long_index) {
  optarg = nullptr;

  if (optind >= argc || argv[optind] == nullptr || argv[optind][0] != '-' ||
      argv[optind][1] == '\0') {
    return -1;
  }

  const char* argument = argv[optind];
  if (std::strcmp(argument, "--") == 0) {
    ++optind;
    return -1;
  }

  if (argument[1] == '-') {
    const char* name = argument + 2;
    const char* value = std::strchr(name, '=');
    const std::size_t name_length = value == nullptr ? std::strlen(name)
                                                     : static_cast<std::size_t>(value - name);
    for (int i = 0; long_options[i].name != nullptr; ++i) {
      const option& candidate = long_options[i];
      if (std::strlen(candidate.name) != name_length ||
          std::strncmp(candidate.name, name, name_length) != 0) {
        continue;
      }

      if (long_index != nullptr) {
        *long_index = i;
      }
      ++optind;
      if (candidate.has_arg == required_argument) {
        if (value != nullptr) {
          optarg = const_cast<char*>(value + 1);
        } else if (optind < argc) {
          optarg = argv[optind++];
        } else {
          optopt = candidate.val;
          return ':';
        }
      } else if (candidate.has_arg == optional_argument && value != nullptr) {
        optarg = const_cast<char*>(value + 1);
      } else if (value != nullptr) {
        optopt = candidate.val;
        return '?';
      }

      if (candidate.flag != nullptr) {
        *candidate.flag = candidate.val;
        return 0;
      }
      return candidate.val;
    }
    ++optind;
    return '?';
  }

  const char short_option = argument[1];
  const char* specification = std::strchr(short_options, short_option);
  ++optind;
  if (specification == nullptr || short_option == ':') {
    optopt = short_option;
    return '?';
  }
  if (specification[1] == ':') {
    if (argument[2] != '\0') {
      optarg = const_cast<char*>(argument + 2);
    } else if (optind < argc) {
      optarg = argv[optind++];
    } else {
      optopt = short_option;
      return ':';
    }
  }
  return short_option;
}

#endif
