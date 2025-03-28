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
    && mkdir -p checkpoints/protgps checkpoints/esm2 checkpoints/drbert

# Copy environment.yml to take advantage of Docker cache
COPY environment.yml .
RUN conda env create -f environment.yml \
    && conda clean --all -f -y \
    && conda run -n protgps pip install jupyterlab \
    && conda run -n protgps pip cache purge \
    && conda init bash \
    && echo "conda activate protgps" >> ~/.bashrc

# Checkpoints changes quickly, add a layer to keep the cache
RUN wget -q "https://zenodo.org/records/14795445/files/checkpoints.zip?download=1" -O checkpoints.zip \
    && unzip checkpoints.zip -d . \
    && rm -rf checkpoints.zip

# Copy the rest of the application code
COPY . /app/

# Expose the port of JupyterLab
EXPOSE 8888

# Set entrypoint to run JupyterLab
ENTRYPOINT ["/opt/conda/envs/protgps/bin/jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]
