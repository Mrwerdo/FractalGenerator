import PackageDescription

let pacakge = Package(
	name: "redesigned-palm-tree-fractals",
	targets: [ // ]
		Target(name: "Support"),
		Target(name: "Process", dependencies: ["Support"]),
		Target(name: "Sample", dependencies: ["Support", "Process"])
	],
	dependencies: [.Package(url: "https://github.com/Mrwerdo/LibTIFF.git", majorVersion: 0, minor: 1)],
	exclude: ["Sources", "LICENCE", "README.md", "Fractal.tiff"]
)
