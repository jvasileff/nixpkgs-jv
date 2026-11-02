# Repackages the prebuilt GoReleaser release binaries — the same artifacts
# the thethingsnetwork/lorawan-stack homebrew tap installs. See ttn-lw-cli
# for the source build.
{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  versionCheckHook,
}:

let
  srcs = {
    x86_64-linux = {
      suffix = "linux_amd64";
      hash = "sha256-61AshMtJwOTRHgTbtDiWnrFd7M48slbYHZM2fe62KY0=";
    };
    aarch64-linux = {
      suffix = "linux_arm64";
      hash = "sha256-qDlKuzr8Or7pak7R9VW5nmbarhp4T+7fufr/37PE2ho=";
    };
    x86_64-darwin = {
      suffix = "darwin_amd64";
      hash = "sha256-5qimOBEFDvOs9LOAYCeqj19kbJRAEsI0rJwSBdNvWCs=";
    };
    aarch64-darwin = {
      suffix = "darwin_arm64";
      hash = "sha256-ig0+wb0Ct5WgtqIaBryOFF0etc7orqNkyGNUvbtlZ5w=";
    };
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ttn-lw-cli-bin";
  version = "3.36.2";

  src =
    let
      platform = srcs.${stdenvNoCC.hostPlatform.system};
    in
    fetchurl {
      url = "https://github.com/TheThingsNetwork/lorawan-stack/releases/download/v${finalAttrs.version}/lorawan-stack-cli_${finalAttrs.version}_${platform.suffix}.tar.gz";
      inherit (platform) hash;
    };

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ttn-lw-cli $out/bin/ttn-lw-cli
    installShellCompletion --cmd ttn-lw-cli \
      --bash config/completion/bash/ttn-lw-cli \
      --zsh config/completion/zsh/_ttn-lw-cli \
      --fish config/completion/fish/ttn-lw-cli.fish

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "version";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Command-line interface of The Things Stack for LoRaWAN (prebuilt release binaries)";
    homepage = "https://www.thethingsindustries.com/docs/tools/cli/";
    changelog = "https://github.com/TheThingsNetwork/lorawan-stack/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "ttn-lw-cli";
    platforms = builtins.attrNames srcs;
  };
})
