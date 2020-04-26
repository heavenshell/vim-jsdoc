#!/bin/sh

set -e

LIBDIR=$(cd $(dirname $0); pwd)

yarn --cwd ${LIBDIR}
ln -s "${LIBDIR}/node_modules/.bin/lehre" "${LIBDIR}/lehre"
