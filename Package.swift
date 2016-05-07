import PackageDescription

let pacakge = Package(
	name: "redesigned-palm-tree-fractals",
	dependencies: [.Package(url: "../CLibTIFF/.git", majorVersion: 1)],
	exclude: ["Sources", "LICENCE", "README.md", "Fractal.tiff", "bin/", "makefile"]
)
