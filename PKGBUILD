# This is an example PKGBUILD file. Use this as a start to creating your own,
# and remove these comments. For more information, see 'man PKGBUILD'.
# NOTE: Please fill out the license field for your package! If it is unknown,
# then please put 'unknown'.

# Maintainer: Your Name <youremail@domain.com>
pkgname=openflexos-configs
pkgver=1.0.2
pkgrel=1
pkgdesc="Default configuration files for OpenFlexOS (test version)"
arch=(any)
url="https://github.com/chriskevinlee/TestRepo-OpenFlexOS-Configs"
license=('GPL')
backup=('etc/openflexos/*')
#source=(openflexos-configs.tar.gz)
source=(https://github.com/chriskevinlee/TestRepo-OpenFlexOS-Configs/raw/refs/heads/main/testrepo-openflexos-configs.tar.gz)
md5sums=('SKIP') #generate with 'makepkg -g'

package() {
  install -d "$pkgdir/etc/openflexos"
  cp -r etc/openflexos/* "$pkgdir/etc/openflexos/"
}
	
