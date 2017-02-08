#!/usr/bin/env bash

set -e -x

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    "${PYBIN}/pip" install "numpy>=1.9.2"
    "${PYBIN}/pip" install -r /io/requirements.txt
    "${PYBIN}/pip" install coveralls
    cython /io/src/*.pyx
    "${PYBIN}/pip" install -e /io/
    "${PYBIN}/pip" wheel /io/ -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    auditwheel repair "$whl" -w /io/wheelhouse/
done

# Install packages and test
for PYBIN in /opt/python/*/bin/; do
    "${PYBIN}/pytest" /io/tests --cov dedupe
    "${PYBIN}/python" /io/tests/canonical.py -vv
done

# If everything works, upload wheels to PyPi
travis=$( cat /io/.travis_tag )
PYBIN34="/opt/python/cp34-cp34mu/bin"
if [[ $travis ]]; then
    "${PYBIN34}/pip" install twine
    "${PYBIN34}/twine" upload --config-file /io/.pypirc /io/wheelhouse/*
fi
