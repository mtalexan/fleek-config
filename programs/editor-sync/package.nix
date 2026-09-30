{ stdenv, python3 }:

stdenv.mkDerivation {
  pname = "editor-sync";
  version = "0.1.0";
  src = ./.;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    install -Dm755 editor_sync.py $out/bin/editor-sync
    sed -i '1s|.*|#!${python3}/bin/python3|' $out/bin/editor-sync
    install -Dm644 completions/editor-sync.bash \
      $out/share/bash-completion/completions/editor-sync
    install -Dm644 completions/_editor-sync \
      $out/share/zsh/site-functions/_editor-sync
  '';
  meta.mainProgram = "editor-sync";
}
