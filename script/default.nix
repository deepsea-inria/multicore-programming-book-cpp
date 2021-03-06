{ pkgs   ? import <nixpkgs> {},
  stdenv ? pkgs.stdenv,
  sources ? import ./default-sources.nix,
  gperftools ? pkgs.gperftools,
  useHwloc ? false,
  hwloc ? pkgs.hwloc,
  libunwind ? pkgs.libunwind,
  useLibunwind ? false,
  gcc ? pkgs.gcc,
  pathToResults ? "",
  pathToData ? "",
  buildDocs ? false
}:

let

  callPackage = pkgs.lib.callPackageWith (pkgs // sources // self);

  self = {

    hwloc = hwloc;
    useHwloc = useHwloc;

    libunwind = libunwind;
    useLibunwind = useLibunwind;

    gperftools = gperftools;

    gcc = gcc;

    buildDocs = buildDocs;

    # pbench = callPackage "${sources.pbenchSrc}/script/default.nix" { };
    # cmdline = callPackage "${sources.cmdlineSrc}/script/default.nix" { };
    # cilk-plus-rts-with-stats = callPackage "${sources.cilkRtsSrc}/script/default.nix" { };
    # chunkedseq = callPackage "${sources.chunkedseqSrc}/script/default.nix" { };
    # sptl = callPackage "${sources.sptlSrc}/script/default.nix" { };
    # pbbs-include = callPackage "${sources.pbbsIncludeSrc}/default.nix" { };
    # pbbsSptlSrc = sources.pbbsSptlSrc;
    tapopcSrc = sources.tapopcSrc;
    
  };

in

with self;

stdenv.mkDerivation rec {
  name = "tapopc";

  src = tapopcSrc;

  buildInputs =
    let pandocCiteproc = pkgs.haskellPackages.ghcWithPackages (pkgs: with pkgs; [pandoc-citeproc]);
    in
    let lu =
      if useLibunwind then [ libunwind ] else [];
    in
    [
#      pbench sptl pbbs-include cmdline chunkedseq
      pkgs.makeWrapper pkgs.R pkgs.texlive.combined.scheme-small
      pkgs.ocaml gcc pkgs.wget pandocCiteproc
    ] ++ lu;

  configurePhase =
    let hwlocConfig =
      if useHwloc then ''
        USE_HWLOC=1
        USE_MANUAL_HWLOC_PATH=1
        MY_HWLOC_FLAGS=-I ${hwloc.dev}/include/
        MY_HWLOC_LIBS=-L ${hwloc.lib}/lib/ -lhwloc
      '' else "";
    in
    let settingsScript = pkgs.writeText "settings.sh" ''
      PBENCH_PATH=../pbench/
#      CMDLINE_PATH={cmdline}/include/
#      CHUNKEDSEQ_PATH={chunkedseq}/include/
#      SPTL_PATH={sptl}/include/
      USE_32_BIT_WORD_SIZE=1
      USE_FIBRIL=1
      CUSTOM_MALLOC_PREFIX=-ltcmalloc -L${gperftools}/lib
      ${hwlocConfig}    
    '';
    in
    ''
#    cp ${settingsScript} bench/settings.sh
    '';

  buildPhase =
    # let getNbCoresScript = pkgs.writeScript "get-nb-cores.sh" ''
    #   #!/usr/bin/env bash
    #   ${sptl}/bin/get-nb-cores.sh
    # '';
    # in
    ''
    make -C book
#    mkdir -p bench
#    make -C bench bench.pbench
    '';  

  installPhase =
    let hw =
        if useHwloc then
          ''--prefix LD_LIBRARY_PATH ":" ${hwloc.lib}/lib''
        else "";
    in
    let nmf = "-skip make";
    in
    let rf =
      if pathToResults != "" then
        "-path_to_results ${pathToResults}"
      else "";
    in
    let df =
      if pathToResults != "" then
        "-path_to_data ${pathToData}"
      else "";
    in
    let flags = "${nmf} ${rf} ${df}";
    in
    ''
    mkdir -p $out/bench/
    # cp bench/bench.pbench bench/timeout.out $out/bench/
    # wrapProgram $out/bench/bench.pbench --prefix PATH ":" ${pkgs.R}/bin \
    #    --prefix PATH ":" ${pkgs.texlive.combined.scheme-small}/bin \
    #    --prefix PATH ":" ${gcc}/bin \
    #    --prefix PATH ":" ${pkgs.wget}/bin \
    #    --prefix PATH ":" $out/bench \
    #    --prefix LD_LIBRARY_PATH ":" ${gcc}/lib \
    #    --prefix LD_LIBRARY_PATH ":" ${gcc}/lib64 \
    #    --prefix LD_LIBRARY_PATH ":" ${gperftools}/lib \
    #    --prefix LD_LIBRARY_PATH ":" {cilk-plus-rts-with-stats}/lib \
    #    --set TCMALLOC_LARGE_ALLOC_REPORT_THRESHOLD 100000000000 \
    #    ${hw} \
#       --add-flags "${flags}"
#    pushd bench
#    $out/bench/bench.pbench compare -only make
#    $out/bench/bench.pbench bfs -only make
#    popd
#    cp bench/sptl_config.txt $out/bench/sptl_config.txt
#    cp bench/*.sptl bench/*.sptl_elision $out/bench/
    mkdir -p $out/book
    cp book/book.* $out/book/
    mkdir -p $out/book/images/
    cp -r book/images/*.jpg $out/book/images/
    '';

  meta = {
    description = "Student coding environment for a course on multicore programming.";
    license = "MIT";
    homepage = http://deepsea.inria.fr/oracular/;
  };
}
