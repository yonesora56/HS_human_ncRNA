# Use the official DevContainers Python image (Python 3.13 on Debian Bookworm)
# Note: Old path 'mcr.microsoft.com/vscode/devcontainers/' is deprecated
# New path: 'mcr.microsoft.com/devcontainers/'
# https://github.com/devcontainers/images/tree/main/src/python
FROM mcr.microsoft.com/devcontainers/python:3.13-bookworm

COPY fix-dind.sh /usr/local/share/fix-dind.sh
RUN chmod +x /usr/local/share/fix-dind.sh

# Fix for expired Yarn GPG key in the base image
# Remove the problematic Yarn repository before apt-get update
RUN rm -f /etc/apt/sources.list.d/yarn.list || true

# linux settings
# `-y` option is used to automatically answer yes to all prompts
RUN apt-get update && apt-get -y upgrade && apt-get install -y --no-install-recommends \
    byobu \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    build-essential \
    libgmp-dev \
    libmagick++-dev \
    libglpk-dev \
    openjdk-17-jdk \
    bedtools \
    wget2

# install uv (used only as a faster pip-compatible installer)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Install packages into the image Python (including CWL tool)
# version update 2025-11-12
# uv uses system python by default; `--system` flag is used to install packages into the system python (base image is Python 3.13)
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache -r /tmp/requirements.txt

RUN pipx install benten==2021.1.5

# Jupyter Notebook settings
RUN python3 -m ipykernel install --user --name=python3
RUN jupyter notebook --generate-config

# Install Nextflow
# Download and install Nextflow using self-installing package
RUN curl -s https://get.nextflow.io | bash && \
    chmod +x nextflow && \
    mv nextflow /usr/local/bin/ && \
    nextflow info

# Install Juicer Tools 2.20.00 (HIC v9; use with h1d --juicertool)
# https://github.com/aidenlab/Juicebox/releases/tag/v2.20.00
# RUN curl -fsSL -o /usr/local/lib/juicer_tools.2.20.00.jar \
#     https://github.com/aidenlab/Juicebox/releases/download/v2.20.00/juicer_tools.2.20.00.jar && \
#     printf '%s\n' \
#       '#!/bin/bash' \
#       'exec java -jar /usr/local/lib/juicer_tools.2.20.00.jar "$@"' \
#       > /usr/local/bin/juicer_tools && \
#     chmod +x /usr/local/bin/juicer_tools

# Text2Term settings: uncomment text2term in requirements.txt if needed