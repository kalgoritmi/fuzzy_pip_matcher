FROM debian:bookworm

RUN apt update \
    && apt install curl python3-pip python3-venv libxml2-utils jq -y --no-install-recommends \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --config python \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/fuzzy_match_pypi_package

COPY --chmod=765 . .

RUN python -m venv venv && . venv/bin/activate && pip install python-Levenshtein

ENV PATH="./venv/bin:$PATH"

SHELL ["bash", "-c"]
ENTRYPOINT ["./fuzzy_match_pypi_package.sh"]
CMD ["folium"]

