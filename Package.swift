import PackageDescription

let pacakge = Package(
	name: "redesigned-palm-tree-fractals",
	dependencies: [.Package(url: "git@github.com:Mrwerdo/LibTIFF.git", majorVersion: 0, minor: 1)],
	exclude: ["Sources", "LICENCE", "README.md", "Fractal.tiff", "bin/", "makefile"]
)
