{ stdenv, lib, fetchurl, openssl, libtool, perl, libxml2
, enableSeccomp ? false, libseccomp ? null }:

assert enableSeccomp -> libseccomp != null;

let version = "9.12.1-P2"; in

stdenv.mkDerivation rec {
  name = "bind-${version}";

  src = fetchurl {
    url = "http://ftp.isc.org/isc/bind9/${version}/${name}.tar.gz";
    sha256 = "0a9dvyg1dk7vpqn9gz7p5jas3bz7z22bjd66b98g1qk16i2w7rqd";
  };

  outputs = [ "out" "lib" "dev" "man" "dnsutils" "host" ];

  patches = [ ./dont-keep-configure-flags.patch ./remove-mkdir-var.patch ] ++
    stdenv.lib.optional stdenv.isDarwin ./darwin-openssl-linking-fix.patch;

  nativeBuildInputs = [ perl ];
  buildInputs = [ openssl libtool libxml2 ] ++
    stdenv.lib.optional enableSeccomp libseccomp;

  STD_CDEFINES = [ "-DDIG_SIGCHASE=1" ]; # support +sigchase

  configureFlags = [
    "--localstatedir=/var"
    "--with-libtool"
    "--with-libxml2=${libxml2.dev}"
    "--with-openssl=${openssl.dev}"
    "--without-atf"
    "--without-dlopen"
    "--without-docbook-xsl"
    "--without-gssapi"
    "--without-idn"
    "--without-idnlib"
    "--without-lmdb"
    "--without-pkcs11"
    "--without-purify"
    "--without-python"
  ] ++ lib.optional enableSeccomp "--enable-seccomp";

  postInstall = ''
    moveToOutput bin/bind9-config $dev
    moveToOutput bin/isc-config.sh $dev

    moveToOutput bin/host $host

    moveToOutput bin/dig $dnsutils
    moveToOutput bin/nslookup $dnsutils
    moveToOutput bin/nsupdate $dnsutils

    for f in "$lib/lib/"*.la "$dev/bin/"{isc-config.sh,bind*-config}; do
      sed -i "$f" -e 's|-L${openssl.dev}|-L${openssl.out}|g'
    done
  '';

  meta = {
    homepage = http://www.isc.org/software/bind;
    description = "Domain name server";
    license = stdenv.lib.licenses.mpl20;

    maintainers = with stdenv.lib.maintainers; [viric peti];
    platforms = with stdenv.lib.platforms; unix;

    outputsToInstall = [ "out" "dnsutils" "host" ];
  };
}
