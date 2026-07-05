{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  stdenv,
  versionCheckHook,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "ttn-lw-cli";
  version = "3.36.0";

  src = fetchFromGitHub {
    owner = "TheThingsNetwork";
    repo = "lorawan-stack";
    tag = "v${finalAttrs.version}";
    hash = "sha256-VICuWf4+OgbT2iJuUEeuBHymL88COXn4sh3YNZaEJxI=";
  };

  vendorHash = "sha256-tWjBNqbyF9xjjgvD/YSeQAnoayyHu5CBIR/taw34PsI=";

  subPackages = [ "cmd/ttn-lw-cli" ];

  env.CGO_ENABLED = 0;

  # Matches upstream's .goreleaser.release.yml, minus BuildDate/GitCommit
  # (not reproducible / not available from a tarball checkout).
  ldflags = [
    "-s"
    "-w"
    "-X go.thethings.network/lorawan-stack/v3/pkg/version.TTN=${finalAttrs.version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd ttn-lw-cli \
      --bash <($out/bin/ttn-lw-cli complete --shell bash) \
      --zsh <($out/bin/ttn-lw-cli complete --shell zsh) \
      --fish <($out/bin/ttn-lw-cli complete --shell fish)
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "version";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Command-line interface of The Things Stack for LoRaWAN";
    homepage = "https://www.thethingsindustries.com/docs/tools/cli/";
    changelog = "https://github.com/TheThingsNetwork/lorawan-stack/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "ttn-lw-cli";
    platforms = lib.platforms.unix;
  };
})
