# Copyright 2026 Google LLC
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
RUN apt-get update && apt-get install -y curl build-essential
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal --default-toolchain stable
RUN mkdir -p /rust/bin \
    && ln -sf /root/.cargo/bin/cargo /rust/bin/cargo \
    && ln -sf /root/.cargo/bin/rustc /rust/bin/rustc
RUN pip3 install pytest hypothesis setuptools-rust 'setuptools_scm[toml]'
RUN git clone https://github.com/agronholm/cbor2.git
WORKDIR cbor2
COPY build.sh $SRC/
