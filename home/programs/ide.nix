{
  pkgs,
  config,
  username,
  ...
}: {
  programs = {
    #vscode = {
      #enable = true;
      #extensions =  with pkgs.vscode-extensions;[
        # {id = "";}  // extension id, query from chrome web store
      #];
    #};
  };
}
