#!/bin/bash
function usage {
    echo ""
    echo "pyftsubset.sh"
    echo ""
    echo "usage: pyftsubset.sh -g [glyphs] -o [outfile] font-file"
    echo ""
    exit 1
}

while getopts "g:o:" opt; do
    case "${opt}" in
	g)
	    GLYPHS=${OPTARG}
	    ;;
	o)
	    OUTFILE=${OPTARG}
	    ;;
	\?)
	    echo "invalid option -$OPTARG" >&2
	    ;;
	:)
	    echo "option $OPTARG requires an argument" >&2
	    ;;
    esac
done
shift $((OPTIND-1))

if [[ -z $1 ]]; then
  echo "no font as argument"
  usage
fi

FILE=$(readlink -f $1)

if [[ ! -f $FILE ]]; then
    echo "$FILE not found"
    usage
fi

if [[ -z $OUTFILE ]]; then
    OUTFILE=$FILE.subset.otf
    echo "write output to $OUTFILE"
fi

echo "file: $FILE"
echo "glyphs (unicode): $GLYPHS"
echo "output: $OUTFILE"

pyftsubset $FILE --unicodes=$GLYPHS --output-file=$OUTFILE --ignore-missing-glyphs
