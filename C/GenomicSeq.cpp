#include <iostream>
#include <fstream>
#include <cstdio>
#include <string>
#include <zlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "loader.h"

std::string RevComp(std::string &seq) {
  std::string rc_seq;
  for(int i = seq.length() - 1; i >= 0; -- i) {
    switch(seq[i])  {
      case 'a': rc_seq += 't'; break;
      case 'c': rc_seq += 'g'; break;
      case 'g': rc_seq += 'c'; break;
      case 't': rc_seq += 'a'; break;
      case 'A': rc_seq += 'T'; break;
      case 'C': rc_seq += 'G'; break;
      case 'G': rc_seq += 'C'; break;
      case 'T': rc_seq += 'A'; break;
      default: rc_seq += 'N'; break;
    }
  }
  return rc_seq;
}

char* in_file = new char [1000];
char* gloc_list = new char [1000];
char* out_file = new char [1000];

int main(int argc, char **argv)  {

  in_file[0] = '\0';
  gloc_list[0] = '\0';
  out_file[0] = '\0';

  int copt;	
	extern char *optarg;
  extern int optind;
  while ((copt=getopt(argc,argv,"i:l:o:h")) != EOF)	{
    switch(copt) {
      case 'i':
        sscanf(optarg, "%s", in_file);
        continue;
      case 'l':
        sscanf(optarg, "%s", gloc_list);
        continue;
      case 'o':
        sscanf(optarg, "%s", out_file);
        continue;
			case 'h':
			default:
        std::cout << "==================================================" << std::endl;
        std::cout << "\tGenomicSeq: retriving genomic location" << std::endl;
        std::cout << "==================================================" << std::endl;
        std::cout << std::endl;
        std::cout << "usage: GenomicSeq -i [GENOME_SEQ] -l [LOC_LIST] -o [OUT_FILE]" << std::endl;
        std::cout << std::endl;
        std::cout << "\ti: the reference genome sequence in FASTA format (mandatory)" << std::endl;
        std::cout << "\tl: the file contain a list of requested genomic location; one location per line, format: chromosome:begin-end for plus strand OR chromosome:end-begin for minus strand (mandatory)" << std::endl;
        std::cout << "\to: the file to write the output (mandatory)" << std::endl;
        std::cout << "\th: print this help message" << std::endl;
        exit(0);
		}
		optind--;
	}	

  // check argument setting
  if(strlen(in_file) <= 0 || strlen(gloc_list) <= 0 || strlen(out_file) <= 0)  {
    std::cout << "Mandatory argument missing; please type \"GenomicSeq -h\" to view the help information." << std::endl;
    std::cout << "Abort." << std::endl;
    exit(0);
  }

  
  // loading database sequence
  Loader seq_loader;
  int num_seqs = seq_loader.CountFastaNumSeqs(in_file);
  char **header = new char* [num_seqs];
  char **seqs = new char* [num_seqs];
  num_seqs = seq_loader.LoadFasta(in_file, header, seqs);

  // read genomic location line-by-line
  std::ifstream ifstrm(gloc_list, std::ios_base::in);
  std::ofstream ofstrm(out_file, std::ios_base::out);
  std::string line;
  while (std::getline(ifstrm, line)) {
    // look for positions to partition the ID
    int comma_loc = -1, dash_loc = -1;
    for(int i = 0; i < line.length(); ++ i) {
      // parsing the genomic location
      if(line[i] == ':')  comma_loc = i;
      else if(line[i] == '-') dash_loc = i;
    }
    if(comma_loc < 0 || dash_loc < 0 || comma_loc >= dash_loc) {
      std::cerr << "Warning 1: " << line << " does not have expected format, skipping..." << std::endl;
      continue;
    }    
    
    std::string chrom = line.substr(0, comma_loc);
    std::string left = line.substr(comma_loc + 1, dash_loc - comma_loc - 1);
    std::string right = line.substr(dash_loc + 1, line.length() - dash_loc);

    // search for chromosome ID and output sequence
    char *pl, *pr;
    long int left_num = strtol(left.c_str(), &pl, 10);
    long int right_num = strtol(right.c_str(), &pr, 10);
    //std::cout << chrom << std::endl;
    //std::cout << left << std::endl;
    //std::cout << right << std::endl;
    if(*pl != 0 || *pr != 0)  {
      std::cerr << "Warning 2: " << line << " does not have expected format, skipping..." << std::endl;
      continue;
    }
    bool found = false;
    for(int j = 0; j < num_seqs; ++ j) {
      if(std::string(header[j]) == chrom)  {
        found = true;
        std::string g_seq;
        if(left_num < right_num)  {
          g_seq = std::string(seqs[j]).substr(left_num - 1, right_num - left_num + 1);
        } else  {
          g_seq = std::string(seqs[j]).substr(right_num - 1, left_num - right_num + 1);
          g_seq = RevComp(g_seq);
        }
        // wirte sequence to file
        ofstrm << ">" << line << std::endl << g_seq << std::endl;
      }
    }
    if(!found)  {
      std::cerr << "Warning: " << line << " the designated chromosome is not in the database, skipping..." << std::endl;
    }
  }
  ifstrm.close();	
  ofstrm.close();

  for(int i = 0; i < num_seqs; ++ i) {
    delete [] header[i]; delete [] seqs[i];
  }
  delete [] header; delete [] seqs;
  return 0;
}
