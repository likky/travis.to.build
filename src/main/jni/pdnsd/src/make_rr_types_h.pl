#!/usr/bin/perl -w

# This Perl script is used to generate rr_types.h, using rr_types.in as input.
#
# Copyright (C) 2010, 2011 Paul A. Rombouts
#
# This file is part of the pdnsd package.
#

use strict;
use integer;

print << "END-OF-TEXT";
/* This file was generated by running '$0 @ARGV'.
   Modifications to this file may be lost the next time it is automatically
   regenerated.
*/

END-OF-TEXT

my %valdic;
my %namedic;
my %classdic;
my %muset;
my $nrr=0;
my $nmu=0;
my $minval;
my $maxval;
#my $maxmuval;

while(<>) {
    if(/\S/ && !/^\s*\#/) {
	if(/^\s*(?:([*+-])\s*)?([\w-]+)\s+(\d+)\s+(?:\((\w+)\))?/) {
	    my $mu = $1; my $name=$2; my $val=$3+0; my $class=$4;
	    $name =~ s/-/_/g;
	    if(defined($valdic{$name})) {warn "The name \"$name\" does not have a unique value.\n"}
	    if(defined($namedic{$val})) {warn "The value \"$val\" does not have a unique name.\n"}
	    $valdic{$name}=$val; $namedic{$val}=$name; $classdic{$val}=$class if defined($class);
	    if(defined($mu)) {
		if($mu eq '-') {next}
		$muset{$val}= 1;
		++$nmu;
		#if(!defined($maxmuval) || $val>$maxmuval) {$maxmuval=$val}
	    }
	    else {$muset{$val}= 0}
	    ++$nrr;
	    if(!defined($minval) || $val<$minval) {$minval=$val}
	    if(!defined($maxval) || $val>$maxval) {$maxval=$val}
	}
	else {die "Can't find name-value pair in following line:\n$_\n"}
    }
}

defined($minval) or die "No values defined.\n";
if($nrr>255) {warn "Warning: total number of cache-able RR types is greater than 255.\n"}

print << 'END-OF-TEXT';
/* rr_types.h - A header file with names & descriptions of
                all rr types known to pdnsd
   Copyright (C) 2000, 2001 Thomas Moestl
   Copyright (C) 2007, 2010, 2011 Paul A. Rombouts

  This file is part of the pdnsd package.

  pdnsd is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 3 of the License, or
  (at your option) any later version.

  pdnsd is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with pdnsd; see the file COPYING. If not, see
  <http://www.gnu.org/licenses/>.
*/

#ifndef _RR_TYPES_H_
#define _RR_TYPES_H_

#include <config.h>

END-OF-TEXT

print "#define T_MIN $minval\n";
foreach my $name (sort {$valdic{$a} <=> $valdic{$b} } (keys %valdic)) {
    printf("#define %-12s %2d\n", "T_$name", $valdic{$name});
}
print "#define T_MAX $maxval\n";
print("\n/* T_MAX - T_MIN + 1 */\n","#define T_NUM ",$maxval+1-$minval,"\n");
#print("\n/* Largest most frequently used type value. */\n","#define T_MAXMU $maxmuval\n");
print("\n/* Number of most frequently used rr types. */\n","#define NRRMU $nmu\n");
print("\n/* Number of remaining rr types. */\n","#define NRREXT ",$nrr-$nmu,"\n");
print("\n/* NRRMU + NRREXT */\n","#define NRRTOT $nrr\n");

print << 'END-OF-TEXT';

/* Lookup table for converting rr type values to internally used indices. */
extern const unsigned short int rrlkuptab[T_NUM];
#if DEFINE_RR_TYPE_ARRAYS && !defined(CLIENT_ONLY)
const unsigned short int rrlkuptab[T_NUM] = {
END-OF-TEXT
my @rrtpval=();
for(my $val=$minval, my $i=0, my $j=$nmu, my $k=$nrr; $val<=$maxval; ++$val) {
    my $idx;
    if(defined($muset{$val})) {
	if($muset{$val}) {
	    $idx = $i++;
	}
	else {
	    $idx =  $j++;
	}
	$rrtpval[$idx]=$val;
    }
    else {
	$idx = $k++;
    }

    printf('%4d', $idx);
    if(defined($namedic{$val})) {
	print "  /* $namedic{$val} */";
    }
    print ',' if $val<$maxval;
    print "\n";
}
#print << 'END-OF-TEXT';
#};
##endif
#
#/* Table for converting internally used indices to rr type values.
#   This is more or less the inverse of the rrlkuptab[] mapping. */
#extern const unsigned short int rrtpval[NRRTOT];
##if DEFINE_RR_TYPE_ARRAYS && !defined(CLIENT_ONLY)
#const unsigned short int rrtpval[NRRTOT] = {
#END-OF-TEXT
#for(my $i=0; $i<$nrr; ++$i) {
#    if($i ==0) {
#	print "  /* Most frequently used types. */\n";
#    }
#    else {
#	print ",\n";
#    }
#    print "  /* Remaining (less frequently used) types. */\n"
#	if $i == $nmu;
#    my $val= $rrtpval[$i];
#    print("  ",defined($namedic{$val})? "T_$namedic{$val}": $val);
#}
print << 'END-OF-TEXT';
};
#endif

/* List of most frequently used RR types in ascending order. */
extern const unsigned short int rrmuiterlist[NRRMU];
#if DEFINE_RR_TYPE_ARRAYS && !defined(CLIENT_ONLY)
const unsigned short int rrmuiterlist[NRRMU] = {
END-OF-TEXT
for(my $val=$minval, my $i=0; $val<=$maxval; ++$val) {
    if(defined($muset{$val}) && $muset{$val}) {
	print ",\n" if $i++;
	print("  ",defined($namedic{$val})? "T_$namedic{$val}": $val);
    }
}
print << 'END-OF-TEXT';

};
#endif

/* List of the cache-able RR types in ascending order. */
extern const unsigned short int rrcachiterlist[NRRTOT];
#if DEFINE_RR_TYPE_ARRAYS
const unsigned short int rrcachiterlist[NRRTOT] = {
END-OF-TEXT
for(my $val=$minval, my $i=0; $val<=$maxval; ++$val) {
    if(defined($muset{$val})) {
	print ",\n" if $i++;
	print("  ",defined($namedic{$val})? "T_$namedic{$val}": $val);
    }
}
print << 'END-OF-TEXT';

};
#endif

/* Optimized getrrset macros for fixed rr types. */
END-OF-TEXT
for(my $val=$minval, my $i=0, my $j=0; $val<=$maxval; ++$val) {
    if(defined($muset{$val})) {
	my $name = $namedic{$val};
	my $mdef;
	if($muset{$val}) {
	    $mdef= "GET_RRSMU(cent,$i)";
	    ++$i;
	}
	else {
	    $mdef= "GET_RRSEXT(cent,$j)";
	    ++$j;
	}
	printf("#define %-25s %s\n", "getrrset_$name(cent)", $mdef)
	    if defined($name);
    }
}
print << 'END-OF-TEXT';

/* have_rr macros for fixed rr types. */
END-OF-TEXT
for(my $val=$minval, my $i=0, my $j=0; $val<=$maxval; ++$val) {
    my $name = $namedic{$val};
    my $mdef = '0';
    if(defined($muset{$val})) {
	if($muset{$val}) {
	    $mdef= "HAVE_RRMU(cent,$i)";
	    ++$i;
	}
	else {
	    $mdef= "HAVE_RREXT(cent,$j)";
	    ++$j;
	}
    }
    printf("#define %-25s %s\n", "have_rr_$name(cent)", $mdef)
	if defined($name);
}
print << 'END-OF-TEXT';

/* These macros specify which RR types are cached by pdnsd. */
END-OF-TEXT
for(my $val=$minval; $val<=$maxval; ++$val) {
    if(defined($muset{$val})) {
	my $name = $namedic{$val};
	printf("#define IS_CACHED_%-10s 1\n", defined($name)? $name: "TYPE$val")
    }
}
print << 'END-OF-TEXT';

/* Array indices for most frequently used rr types. */
END-OF-TEXT
for(my $val=$minval, my $i=0; $val<=$maxval; ++$val) {
    if(defined($muset{$val}) && $muset{$val}) {
	printf("#define %-18s %2d\n", "RRMUINDEX_$namedic{$val}", $i)
	    if defined($namedic{$val});
	++$i;
    }
}
print << 'END-OF-TEXT';

/* Table of rr names. */
extern const char *const rrnames[T_NUM];
#if DEFINE_RR_TYPE_ARRAYS
const char *const rrnames[T_NUM] = {
END-OF-TEXT
for(my $val=$minval; $val<=$maxval; ++$val) {
    my $name = $namedic{$val};
    print('  "', defined($name)? $name: "TYPE$val", '"');
    print ',' if $val<$maxval;
    print "\n";
}
print << 'END-OF-TEXT';
};
#endif

/* Structure for rr information */
struct rr_infos {
	unsigned short class;		/* class (values see below) */
	unsigned short excludes;	/* relations to other classes.
					   Mutual exclusion is marked by or'ing the
					   respective RRCL value in this field.
					   Exclusions should be symmetric. */
};

/* Class values */
#define RRCL_ALIAS	1	/* for CNAMES, conflicts with RRCL_RECORD */
#define RRCL_RECORD	2	/* normal direct record */
#define RRCL_IDEM	4	/* types that conflict with no others (MX, CNAME, ...) */
#define RRCL_PTR	8	/* PTR */

/* Standard excludes for the classes */
#define RRX_ALIAS	(RRCL_RECORD|RRCL_PTR)
#define	RRX_RECORD	(RRCL_ALIAS|RRCL_PTR)
#define	RRX_IDEM	0
#define	RRX_PTR		(RRCL_ALIAS|RRCL_RECORD)

/* There could be a separate table detailing the relationship of types, but this
 * is slightly more flexible, as it allows a finer granularity of exclusion. Also,
 * Membership in multiple classes could be added.
 * Index by internally used RR-set indices, not RR type values!
 */
extern const struct rr_infos rr_info[NRRTOT];
#if DEFINE_RR_TYPE_ARRAYS && !defined(CLIENT_ONLY)
const struct rr_infos rr_info[NRRTOT] = {
END-OF-TEXT
for(my $i=0; $i<$nrr; ++$i) {
    print ",\n" if $i;
    my $val=$rrtpval[$i];
    my $class = (defined($classdic{$val})? $classdic{$val}: 'IDEM');
    printf('  %-16s %-15s %s',"{RRCL_$class,", "RRX_$class}", defined($namedic{$val})?"/* $namedic{$val} */":"");
}
print << 'END-OF-TEXT';

};
#endif

int rr_tp_byname(char *name);
const char *loc2str(const void *binary, char *ascii, size_t asclen);

#endif
END-OF-TEXT

exit
