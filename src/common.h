#ifndef KALLISTO_COMMON_H
#define KALLISTO_COMMON_H

#define KALLISTO_VERSION "0.48.0"

#include <string>
#include <vector>
#include <iostream>

#ifdef _WIN64
typedef unsigned int uint;
#endif

// Added by Laura
#include <map>                                                                                                                                                                                       
#include <algorithm>
// Create map cfc_code as a look-up table for the comma-free code
// nucleotide triplet -> comma-free triplet
std::map<std::string, std::string>cfc_code = {
  {"TTT", "ACC"},
  {"TTC", "ACC"},
  {"TTA", "ACA"},
  {"TTG", "ACA"},
  {"CTT", "ACA"},
  {"CTC", "ACA"},
  {"CTA", "ACA"},
  {"CTG", "ACA"},
  {"ATT", "ATA"},
  {"ATC", "ATA"},
  {"ATA", "ATA"},
  {"ATG", "ATC"},
  {"GTT", "ATT"},
  {"GTC", "ATT"},
  {"GTA", "ATT"},
  {"GTG", "ATT"},
  {"TCT", "CTA"},
  {"TCC", "CTA"},
  {"TCA", "CTA"},
  {"TCG", "CTA"},
  {"AGT", "CTA"},
  {"AGC", "CTA"},
  {"CCT", "CTC"},
  {"CCC", "CTC"},
  {"CCA", "CTC"},
  {"CCG", "CTC"},
  {"ACT", "CTT"},
  {"ACC", "CTT"},
  {"ACA", "CTT"},
  {"ACG", "CTT"},
  {"GCT", "AGA"},
  {"GCC", "AGA"},
  {"GCA", "AGA"},
  {"GCG", "AGA"},
  {"TAT", "AGC"},
  {"TAC", "AGC"},
  {"CAT", "AGT"},
  {"CAC", "AGT"},
  {"CAA", "AGG"},
  {"CAG", "AGG"},
  {"AAT", "CGA"},
  {"AAC", "CGA"},
  {"AAA", "CGC"},
  {"AAG", "CGC"},
  {"GAT", "CGT"},
  {"GAC", "CGT"},
  {"GAA", "CGG"},
  {"GAG", "CGG"},
  {"TGT", "TGA"},
  {"TGC", "TGA"},
  {"TGG", "TGC"},
  {"CGT", "TGT"},
  {"CGC", "TGT"},
  {"CGA", "TGT"},
  {"CGG", "TGT"},
  {"AGA", "TGT"},
  {"AGG", "TGT"},
  {"GGT", "TGG"},
  {"GGC", "TGG"},
  {"GGA", "TGG"},
  {"GGG", "TGG"}
};

// function to transform nucleotide seq to its complement
char complement(char n)
{   
    switch(n)
    {   
    case 'A':
        return 'T';
        break;
    case 'T':
        return 'A';
        break;
    case 'G':
        return 'C';
        break;
    case 'C':
        return 'G';
        break;
    case 'N':
        return 'N';
        break;
    case 'a':
        return 't';
        break;
    case 't':
        return 'a';
        break;
    case 'g':
        return 'c';
        break;
    case 'c':
        return 'g';
        break;
    case 'n':
        return 'n';
        break;
    default:
        return 'N';
    }
};
// End Laura

struct BUSOptionSubstr {
  BUSOptionSubstr() : fileno(-1), start(0), stop(0) {}
  BUSOptionSubstr(int f, int a, int b) : fileno(f), start(a), stop(b) {}
  int fileno;
  int start;
  int stop;
};

struct BUSOptions {
  int nfiles;

  std::vector<BUSOptionSubstr> umi;
  std::vector<BUSOptionSubstr> bc;
  std::vector<BUSOptionSubstr> seq;

  bool paired;

  int getBCLength() const {
    int r =0 ;
    if (!bc.empty()) {
      for (auto& b : bc) {
        if (b.start < 0) {
          return 0;
        } else if (b.stop == 0) {
          return 0;
        } else {
          r += b.stop - b.start;
        }
      }
    }
    return r;
  }

  int getUMILength() const {
    int r =0 ;
    if (!umi.empty()) {
      for (auto& u : umi) {
        if (u.start < 0) {
          return 0;
        } else if (u.stop == 0) {
          return 0;
        } else {
          r += u.stop - u.start;
        }
      }
    }
    return r;
  }
};

// Laura: Added cfc option and defined as false by default
struct ProgramOptions {
  bool cfc;
  bool verbose;
  int threads;
  std::string index;
  int k;
  int g;
  int max_ec_size;
  int iterations;
  std::string output;
  int skip;
  size_t seed;
  double fld;
  double sd;
  int min_range;
  int bootstrap;
  std::vector<std::string> transfasta;
  bool batch_mode;
  bool pseudo_read_files_supplied;
  bool bus_mode;
  BUSOptions busOptions;
  bool pseudo_quant;
  bool bam;
  bool num;
  std::string batch_file_name;
  std::vector<std::vector<std::string> > batch_files;
  std::vector<std::string> batch_ids;
  std::vector<std::string> files;
  std::vector<std::string> umi_files;
  bool plaintext;
  bool write_index;
  bool single_end;
  bool strand_specific;
  bool peek; // only used for H5Dump
  bool bias;
  bool pseudobam;
  bool genomebam;
  bool make_unique;
  bool fusion;
  enum class StrandType {None, FR, RF};
  StrandType strand;
  bool umi;
  bool batch_bus_write;
  bool batch_bus;
  std::string gfa; // used for inspect
  bool inspect_thorough;
  bool single_overhang;
  std::string gtfFile;
  std::string chromFile;
  std::string bedFile;
  std::string technology;
  std::string tagsequence;
  std::string tccFile;
  std::string ecFile;
  std::string fldFile;
  std::string transcriptsFile;
  std::string genemap;
  std::string offlist;

ProgramOptions() :
  verbose(false),
  threads(1),
  k(31),
  g(0),
  max_ec_size(0),
  iterations(500),
  skip(1),
  seed(42),
  fld(0.0),
  sd(0.0),
  min_range(1),
  bootstrap(0),
  batch_mode(false),
  pseudo_read_files_supplied(false),
  bus_mode(false),
  pseudo_quant(false),
  bam(false),
  num(false),
  plaintext(false),
  write_index(false),
  single_end(false),
  strand_specific(false),
  peek(false),
  bias(false),
  pseudobam(false),
  genomebam(false),
  make_unique(false),
  fusion(false),
  strand(StrandType::None),
  umi(false),
  batch_bus_write(false),
  batch_bus(false),
  inspect_thorough(false),
  single_overhang(false),
  cfc(false)
  {}
};

std::string pretty_num(size_t num);
std::string pretty_num(int64_t num);
std::string pretty_num(int num);




#endif // KALLISTO_COMMON_H
