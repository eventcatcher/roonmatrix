export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/app/src/__pypackages__  
rm -rf app/src/__pypackages__/.pod
cd packages/python_backend
fvm dart run serious_python:main package ../../app/src -p iOS --asset assets/backend/roonmatrix.zip -r -r -r ../../app/src/requirements.txt
cd ../../
