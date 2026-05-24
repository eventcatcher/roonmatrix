export SERIOUS_PYTHON_SITE_PACKAGES=$(pwd)/app/src/__pypackages__  
cd packages/python_backend
fvm dart run serious_python:main package ../../app/src -p Linux --asset assets/backend/roonmatrix.zip -r -r -r ../../app/src/requirements.txt
cd ../../
