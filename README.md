# Europar 2016 - Public

This is our public repository for experiments log files and analysis.

## Log files

Every run we made has its log in the `logs` directory. They can be all compiled in one single R-friendly dataframe by running `format_data_plasma.py -b log_plasma`, which will be output in `rdata.log_plasma.dat`.
The dataframe we used for the paper is already included in this repository.

## Figures

Data analysis and figures creation is done by the `gen_graph.R` script from the `figures` directory.
A few R libraries are required :
* ggplot2
* plyr

One should be able to recreate the figures by running `Rscript gen_graph.R rdata.log_plasma.dat` within the `figures` directory.

## Reminder about the experimental setup

The compiler used for all programs was Gcc 5.2.0.

### OpenBLAS

We used version 2.15 (tag `v0.2.15`) from the [OpenBLAS repository](https://github.com/xianyi/OpenBLAS.git).
The parallelism is expressed within the Kastors benchmarks, we therefore used only the sequential BLAS (compiled with `USE_THREAD=0`).

### XKaapi
We used the git branch `public/europar2016`, from the [XKaapi repository](https://scm.gforge.inria.fr/anonscm/git/kaapi/kaapi.git).

XKaapi has a Gomp-compatible ABI, Komp, that need to be enabled, as well as the support for numa architecture.
We used the following configure line :
```bash
/path/to/kaapi/configure --enable-libkomp --prefix=/path/to/install --without-perfcounter --with-numa --enable-mode=release
```


### Kastors

We used the git version tagged `tag-europar16`, from the [Kastors repository](https://scm.gforge.inria.fr/anonscm/git/kastors/kastors.git).

To be able to use XKaapi's extension for task initialization, one must activate it and link with XKaapi's omp_ext library. For the record we used the following configure line with the correct paths :

```bash
/path/to/kastors/configure --with-blas=openblas --with-lapacke=openblas CFLAGS="-DUSE_OMPEXT -I/path/to/kaapi/install/include -O3 -march=native" LIBS="-L/path/to/kaapi/install/lib -lomp_ext"
```

Here is some example command lines to run the cholesky factorization on a 32K matrix, using a block size of 512, 192 cores :
* using the "sRand/pLoc" scheduling strategies :
```bash
OMP_NUM_THREADS=192 OMP_PLACES="threads(192)" OMP_DISPLAY_ENV=true KAAPI_WSSELECT="rand" KAAPI_WSPUSH="local" komp-run ./dpotrf_taskdep -i 1 -n 32768 -b 512
```
* using the "sNumaProc/pNumaWLoc" scheduling strategies, and a block cyclic initial distribution :
```bash
OMP_NUM_THREADS=192 OMP_PLACES="threads(192)" KAAPI_WSPUSH_INIT_DISTRIB=cyclicnumastrict OMP_DISPLAY_ENV=true KAAPI_WSSELECT="hws_N_P" KAAPI_WSPUSH="Whws" komp-run ./dpotrf_taskdep -i 2 -n 32768 -b 512
```

