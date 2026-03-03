# 2026-02-26
# L Bell, A Callahan
# install and use fluxnet package to download all available fluxnet data

#fluxnet package repo: https://github.com/EcosystemEcologyLab/fluxnet-package
#fluxnet shuttle package: https://github.com/fluxnet/shuttle

#if error "tools insufficient," update RTools (https://cran.r-project.org/bin/windows/Rtools/)
#download/update python manager through console prompt: reticulate::install_python(version = '3.11') 

#install.packages("pak")
pak::pak("EcosystemEcologyLab/fluxnet-package")

library(fluxnet)

#List all sites available for download
sites <- flux_listall()
#Download sites to server folder
flux_download(
  download_dir = "X:/moore/FluxDataTest"
)

