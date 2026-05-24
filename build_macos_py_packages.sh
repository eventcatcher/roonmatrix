export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/app/src/__pypackages__  
rm -rf app/src/__pypackages__/.pod
cd packages/python_backend
fvm dart run serious_python:main package ../../app/src -p Darwin --asset assets/backend/roonmatrix.zip -r -r -r ../../app/src/requirements.txt
cd ../../

find app/src/__pypackages__ -type d -name 'charset_normalizer*' -exec rm -r {} \;
find app/src/__pypackages__/websockets -type f -name '*.so' -exec rm {} \;
