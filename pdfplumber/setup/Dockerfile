# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

FROM gcr.io/oss-fuzz-base/base-builder-python
RUN apt-get update && apt-get install -y ghostscript
RUN pip3 install pytest
RUN pip3 install --upgrade pip
RUN pip3 install \
    pdfminer.six==20260107 \
    Pillow>=9.1 \
    pypdfium2>=4.18.0 \
    pandas>=2.2.2
RUN mkdir $SRC/corpus

# Upstream wants fuzzers hosted elsewhere, so pull them from fork (https://github.com/jsvine/pdfplumber/pull/1245#issuecomment-2581682100)
RUN git clone https://github.com/ennamarie19/pdfplumber.git pdfplumber_fuzzer

RUN git clone --branch develop https://github.com/jsvine/pdfplumber.git pdfplumber \
        && rm -rf pdfplumber/fuzz  # Remove the directory, if it exists
RUN cp -r pdfplumber_fuzzer/fuzz pdfplumber \
        && cp pdfplumber/fuzz/build.sh $SRC/
WORKDIR $SRC/pdfplumber
