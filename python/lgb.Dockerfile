FROM --platform=linux/amd64 python:3.7-slim as intermediate

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        cmake \
        build-essential \
        gcc \
        g++ \
        curl \
        git

RUN git clone --recursive --branch 5244-reapply-categorical-backport --depth 1 https://github.com/johnpaulett/LightGBM

RUN cd LightGBM/python-package && python setup.py bdist_wheel


FROM --platform=linux/amd64 python:3.7-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY kserve kserve
COPY lgbserver lgbserver
COPY third_party third_party

RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -e ./kserve
# WARN: re-uses version from upstream
COPY --from=intermediate /LightGBM/python-package/dist/lightgbm-3.3.2-py3-none-any.whl /
RUN pip install --no-cache-dir /lightgbm-3.3.2-py3-none-any.whl -e ./lgbserver
RUN rm /lightgbm-3.3.2-py3-none-any.whl

RUN useradd kserve -m -u 1000 -d /home/kserve
USER 1000
ENTRYPOINT ["python", "-m", "lgbserver"]
