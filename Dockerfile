FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-runtime

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
        wget \
        git \
        curl \
        unzip \
        ca-certificates \
        libglib2.0-0 \
        libxext6 \
        libsm6 \
        libxrender1 \
        build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p checkpoints/protgps checkpoints/esm2 checkpoints/drbert \
    && echo "conda activate protgps" >> ~/.bashrc

# Copy environment.yml to take advantage of Docker cache
COPY environment.yml .
RUN conda env create -f environment.yml \
    && conda clean --all -f -y \
    && conda run -n protgps pip install jupyterlab \
    && conda run -n protgps pip cache purge \
    && wget -q "https://zenodo.org/records/14795445/files/checkpoints.zip?download=1" -O checkpoints.zip \
    && unzip checkpoints.zip -d . \
    && mv checkpoints/protgps/* checkpoints/protgps/ \
    && rm -rf checkpoints.zip

# 复制所有项目文件
COPY . /app/

# 暴露JupyterLab端口
EXPOSE 8888

# 设置入口点为启动JupyterLab
ENTRYPOINT ["/bin/bash", "-c", "conda activate protgps && jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''"]
