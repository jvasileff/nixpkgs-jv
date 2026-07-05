# Trivial test package proving the flake plumbing works end to end.
{
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hello-flake";
  version = "0.1.0";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    {
      echo '#!/bin/sh'
      echo 'echo "Hello from the personal package flake (v${finalAttrs.version})!"'
    } > $out/bin/hello-flake
    chmod +x $out/bin/hello-flake

    runHook postInstall
  '';

  meta = {
    description = "Hello-world test package for the personal package flake";
    license = lib.licenses.mit;
    mainProgram = "hello-flake";
    platforms = lib.platforms.all;
  };
})
