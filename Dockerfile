# https://github.com/alseambusher/crontab-ui

ARG ROOT_CONTAINER=ubuntu:22.04

FROM $ROOT_CONTAINER

LABEL maintainer="Jobs Scheduler"
ARG NB_USER="csah2k"
ARG NB_UID="1000"
ARG NB_GID="100"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]


USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends locales && \
    echo "pt_PT.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    apt-get install --yes --no-install-recommends \
    build-essential \
    ca-certificates \
    openssh-client \
    gcc \
    g++ \
    make \
    sudo \
    tini \
    less \
    wget \
    curl \
    git \
    cron \
    vim-tiny \
    nano-tiny \
    tzdata \
    unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create alternative for nano -> nano-tiny
RUN update-alternatives --install /usr/bin/nano nano /bin/nano-tiny 10

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=pt_PT.UTF-8 \
    LANG=pt_PT.UTF-8 \
    LANGUAGE=pt_PT.UTF-8 \
    TZ=America/Sao_Paulo
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}" \
    CRON_DB_PATH="/home/${NB_USER}/crontab-db"

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions healthcheck.sh start.sh /usr/local/bin/
RUN chmod a+rx /usr/local/bin/fix-permissions && \
    chmod a+rx /usr/local/bin/healthcheck.sh && \
    chmod a+rx /usr/local/bin/start.sh

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Create NB_USER with name csah2k user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}" && \
    usermod -a -G sudo "$NB_USER" && \
    echo "$NB_USER:d34kfdi19h" | chpasswd && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${HOME}" && \
    fix-permissions "${CONDA_DIR}" && \
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash - && \
    apt-get install --yes nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    npm install -g npm && \
    npm install -g crontab-ui && \
    chown -R ${NB_UID}:${NB_GID} "${HOME}/.npm"
    
USER ${NB_UID}
ARG PYTHON_VERSION=default

# Install conda as csah2k and check the sha256 sum provided on the download site
WORKDIR /tmp


# CONDA_MIRROR is a mirror prefix to speed up downloading
ARG CONDA_MIRROR=https://github.com/conda-forge/miniforge/releases/latest/download

RUN set -x && \
    # Miniforge installer
    miniforge_arch=$(uname -m) && \
    miniforge_installer="Mambaforge-Linux-${miniforge_arch}.sh" && \
    wget --quiet "${CONDA_MIRROR}/${miniforge_installer}" && \
    /bin/bash "${miniforge_installer}" -f -b -p "${CONDA_DIR}" && \
    rm "${miniforge_installer}" && \
    # Conda configuration see https://conda.io/projects/conda/en/latest/configuration.html
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    if [[ "${PYTHON_VERSION}" != "default" ]]; then mamba install --quiet --yes python="${PYTHON_VERSION}"; fi && \
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    # Using conda to update all packages: https://github.com/mamba-org/mamba/issues/1092
    conda update --all --quiet --yes && \
    conda clean --all -f -y && \
    rm -rf "${HOME}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "${HOME}"

RUN mamba install --quiet --yes \
    'conda-forge::blas=*=openblas' \
    'cython' \
    'numba' \
    'numexpr' \
    'pandas' \
    'pytables' \
    'scikit-image' \
    'scikit-learn' \
    'scipy' \
    'sqlalchemy' \
    'xlrd' \
    'nltk' \
    'pandas' \
    'xlrd' && \
    mamba clean --all -f -y && \
    npm cache clean --force && \
    pip3 install \
    'retry' \
    'tweepy' \
    'verticapy' \
    'python-binance' \
    'telegram_send' \
    'snscrape' \
    'sklearn' && \
    rm -rf "${HOME}/.cache/yarn" && \
    mkdir -p "${HOME}/.certs" && \
    mkdir -p "${CRON_DB_PATH}" && \
    mkdir -p "${CRON_DB_PATH}/logs" && \
    mkdir -p "${HOME}/project" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start.sh"]

ARG GIT_REPO="<your_git_repository_url_here>"
ARG DATA_MNT="${HOME}/data"
ARG HOST=0.0.0.0
ARG PORT=8888 
ARG BASE_URL=/
EXPOSE ${PORT}

HEALTHCHECK  --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD healthcheck.sh

# Switch back to csah2k to avoid accidental container runs as root
USER ${NB_UID}
WORKDIR "${HOME}/project"    
VOLUME [ "${CRON_DB_PATH}" ]
