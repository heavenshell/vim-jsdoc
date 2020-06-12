#!/bin/sh

set -e

LIBDIR=$(cd $(dirname $0); pwd)

if [ -x "$(command -v yarn)" ]; then
  yarn --cwd "${LIBDIR}"
  ln -fs "${LIBDIR}/node_modules/.bin/lehre" "${LIBDIR}/lehre"
elif [ -x "$(command -v npm)" ]; then
  cd "$LIBDIR"
  npm install
  ln -fs "${LIBDIR}/node_modules/.bin/lehre" "${LIBDIR}/lehre"
else
  echo 'Neither yarn nor npm was found on your path' >&2
  exit 1
fi

