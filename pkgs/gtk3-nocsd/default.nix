{ stdenv, fetchFromGitHub, gtk3, pkgconfig, gobject-introspection }:

stdenv.mkDerivation rec {
  pname = "gtk3-nocsd";
  version = "3.0.4";
  src = fetchFromGitHub {
    owner = "ZaWertun";
    repo = "gtk3-nocsd";
    rev = "v${version}";
    sha256 = "1nb5zay2y83b087bv17nvmd569b8chds0l7ajkrwpq0da8zymqya";
  };
  buildInputs = [ gtk3 gobject-introspection ];
  nativeBuildInputs = [ pkgconfig ];
  makeFlags = [ "prefix=${placeholder "out"}" ];
  meta = with stdenv.lib; {
    description = "A hack to disable gtk+ 3 client side decoration";
    license = licenses.lgpl21;
    homepage = src.meta.homepage;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
