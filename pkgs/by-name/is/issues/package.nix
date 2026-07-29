{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "issues";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "jvasileff";
    repo = "issues";
    tag = "v${finalAttrs.version}";
    hash = "sha256-opRQfx8JNx/LMvbYUe7baC8QzyEnCxJGQ5XTjTi31O4=";
  };

  cargoHash = "sha256-8ASxnH1MciL96+nAE/67EE7cp4v6t63fgcqwDjVDpoQ=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Project-local issue tracker for rapid AI-assisted development";
    homepage = "https://github.com/jvasileff/issues";
    license = lib.licenses.mit;
    mainProgram = "issues";
    # The editor launch shells out to `sh -c`, so Windows is out of scope.
    platforms = lib.platforms.unix;
  };
})
