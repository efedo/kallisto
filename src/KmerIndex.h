#ifndef KALLISTO_KMERINDEX_H
#define KALLISTO_KMERINDEX_H

#include <iostream>
#include <fstream>
#include <vector>
#include <unordered_map>
#include <stdint.h>
#include <iostream>
#include <numeric>
#include <limits>

#include "common.h"
#include "Kmer.hpp"
#include "hash.hpp"
#include "CompactedDBG.hpp"
#include "Node.hpp"
#include "robin_hood.h"

std::string revcomp(const std::string s);

struct TRInfo {
  uint32_t trid;
  // denotes where the transcript begins, with respect to a given contig
  uint32_t start;
  // denotes where the transcript ends, with respect to a given contig
  // exclusive [start,stop)
  uint32_t stop;
  // denotes where the given contig starts with respect to the transcript
  // sense is encoded into MSB: 1 for sense, 0 for anti-sense
  uint32_t pos;
};

struct RoaringHasher {
  size_t operator()(const Roaring& rr) const {
    uint64_t r = 0;
    int i=0;
    for (auto x : rr) {
      uint64_t t;
      MurmurHash3_x64_64(&x, sizeof(x), 0, &t);
      t = (x>>i) | (x<<(64-i));
      r ^= t;
      i = (i+1)&63; // (i+1)%64
    }
    return r;
  }
};
typedef robin_hood::unordered_flat_map<Roaring, int32_t, RoaringHasher> EcMapInv;

struct KmerEntry {
  int32_t contig; // id of contig
  uint32_t _pos; // 0-based forward distance to EC-junction
  int32_t contig_length;

  KmerEntry() : contig(-1), _pos(0xFFFFFFF), contig_length(0) {}
  KmerEntry(int id, int length, int pos, bool isFw) : contig(id), contig_length(length) {
    setPos(pos);
    setDir(isFw);
  }

  inline int getPos() const {return (_pos & 0x0FFFFFFF);}
  inline int isFw() const  {return (_pos & 0xF0000000) == 0; }
  inline void setPos(int p) {_pos = (_pos & 0xF0000000) | (p & 0x0FFFFFFF);}
  inline void setDir(bool _isFw) {_pos = (_pos & 0x0FFFFFFF) | ((_isFw) ? 0 : 0xF0000000);}
  inline int getDist(bool fw) const {
    if (isFw() == fw) {
      return (contig_length - 1 - getPos());
    } else {
      return getPos();
    }
  }
};

struct KmerIndex {
  KmerIndex(const ProgramOptions& opt) : k(opt.k), num_trans(0), skip(opt.skip), target_seqs_loaded(false) {
    //LoadTranscripts(opt.transfasta);
    load_positional_info = opt.bias || opt.pseudobam || opt.genomebam || !opt.single_overhang;
  }

  ~KmerIndex() {}

  std::pair<size_t,size_t> getECInfo() const; // Get max EC size encountered and second element is the number of nodes in which an EC is empty (b/c it was discarded)
  void match(const char *s, int l, std::vector<std::pair<const_UnitigMap<Node>, int>>& v, bool cfc = false) const;

//  bool matchEnd(const char *s, int l, std::vector<std::pair<int, int>>& v, int p) const;
  int mapPair(const char *s1, int l1, const char *s2, int l2) const;
  Roaring intersect(const Roaring& ec, const Roaring& v) const;

  void BuildTranscripts(const ProgramOptions& opt, std::ofstream& out);
  void BuildDeBruijnGraph(const ProgramOptions& opt, const std::string& tmp_file, std::ofstream& out);

  // If off-list is supplied, add off-listed kmers flanking the common
  // sequences to the graph and append those sequences to the tmp_file
  void DListFlankingKmers(const ProgramOptions& opt, const std::string& tmp_file);
  void BuildEquivalenceClasses(const ProgramOptions& opt, const std::string& tmp_file);
  // Colors the unitigs based on transcript usage. Unitigs may be polychrome,
  // i.e. have more than one color.
  void PopulateMosaicECs(std::vector<std::vector<TRInfo> >& trinfos);

  // output methods
  void write(const std::string& index_out, bool writeKmerTable = true, int threads = 1);
  void write(std::ofstream& out, int threads=1);
  void writePseudoBamHeader(std::ostream &o) const;

  // note opt is not const
  // load methods
  void load(ProgramOptions& opt, bool loadKmerTable = true);
  void loadTranscriptSequences() const;
  void loadECsFromFile(const ProgramOptions& opt);
  void loadTranscriptsFromFile(const ProgramOptions& opt);
  void clear();

  // positional information
  std::pair<int,bool> findPosition(int tr, Kmer km, const_UnitigMap<Node>& um, int p = 0) const;
  std::pair<int,bool> findPosition(int tr, Kmer km, int p) const;

  int k; // k-mer size used
  int num_trans; // number of targets
  int skip;

  CompactedDBG<Node> dbg;
  EcMapInv ecmapinv;
  const size_t INDEX_VERSION = 12; // increase this every time you change the file format

  std::vector<uint32_t> target_lens_;

  std::vector<std::string> target_names_;
  std::vector<std::string> target_seqs_; // populated on demand
  bool target_seqs_loaded;
  bool load_positional_info; // when should we load positional info in addition to strandedness

  // Sequences not in off-list: 1
  // Sequences in off-list:     0
  Roaring onlist_sequences;
};

#endif // KALLISTO_KMERINDEX_H
