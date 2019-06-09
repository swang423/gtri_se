#!/bin/bash

#sc. 6/7/2019
set -eu
[ -f path.sh ] && . ./path.sh
stage=${1:-99}

# Get vocab
tmp=$(mktemp -d /tmp/gtri_lm.XXXXXX)
export IRSTLM=$HOME/kaldi17/tools/irstlm/
trap "echo '# Removing tmpdir $tmp @ $(hostname)'; rm -r $tmp" EXIT
if [ $stage -le 0 ]; then
    train_txt=data/train.txt
    cat $train_txt | tr " " "\n" | sort | uniq | tail -n+2 > data/words.list || exit 1
    #necessary?
    echo "#0" >> data/words.list #append disambiguous symbol
    word_size=$(cat data/words.list | wc -l)
    awk "BEGIN {for (i=1; i<= $word_size; i++) print i}" |\
    paste -d ' ' data/words.list - > data/words.txt || exit 1

    echo "IRSTLM path: $IRSTLM"    
    $IRSTLM/bin/build-lm.sh -i $train_txt -n 2 -o $tmp/lm_bg.ilm.gz || exit 1
    $IRSTLM/bin/compile-lm $tmp/lm_bg.ilm.gz -t=yes /dev/stdout |\
    grep -v unk | gzip -c > data/lm_bg.arpa.gz  || exit 1
    gunzip -c data/lm_bg.arpa.gz |\
    arpa2fst --disambig-symbol=#0 \
        --read-symbol-table=data/words.txt - data/G.fst
fi

