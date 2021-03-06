{ fetchurl
, lib
, stdenv
, darwin
, openglSupport ? true
, libX11
, wxGTK
, wxmac
, pkgconfig
, buildPythonPackage
, pyopengl
, isPy3k
, isPyPy
, python
}:

assert wxGTK.unicode;

buildPythonPackage rec {
  name = "wxPython-${version}";
  version = "3.0.2.0";

  disabled = isPy3k || isPyPy;
  doCheck = false;

  src = fetchurl {
    url = "mirror://sourceforge/wxpython/wxPython-src-${version}.tar.bz2";
    sha256 = "0qfzx3sqx4mwxv99sfybhsij4b5pc03ricl73h4vhkzazgjjjhfm";
  };

  hardeningDisable = [ "format" ];

  propagatedBuildInputs = [ pkgconfig ]
    ++ (lib.optional openglSupport pyopengl)
    ++ (lib.optionals (!stdenv.isDarwin) [ wxGTK (wxGTK.gtk) libX11 ])
    ++ (lib.optionals stdenv.isDarwin [ wxmac darwin.apple_sdk.frameworks.Cocoa ])
    ;
  preConfigure = ''
    cd wxPython
    # remove wxPython's darwin hack that interference with python-2.7-distutils-C++.patch
    substituteInPlace config.py \
      --replace "distutils.unixccompiler.UnixCCompiler = MyUnixCCompiler" ""
    # this check is supposed to only return false on older systems running non-framework python
    substituteInPlace src/osx_cocoa/_core_wrap.cpp \
      --replace "return wxPyTestDisplayAvailable();" "return true;"
  '';

  NIX_LDFLAGS = lib.optionalString (!stdenv.isDarwin) "-lX11 -lgdk-x11-2.0";

  buildPhase = "";

  installPhase = ''
    ${python.interpreter} setup.py install WXPORT=${if stdenv.isDarwin then "osx_cocoa" else "gtk2"} NO_HEADERS=1 BUILD_GLCANVAS=${if openglSupport then "1" else "0"} UNICODE=1 --prefix=$out
    wrapPythonPrograms
  '';

  passthru = { inherit wxGTK openglSupport; };
}
