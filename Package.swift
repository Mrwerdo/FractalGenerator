import PackageDescription

let pacakge = Package(
	name: "The Fractol Generator",
	targets: [ // ]
		Target(name: "Support"),
		Target(name: "Process", dependencies: ["Support"]),
		Target(name: "Generators", dependencies: ["Process", "Support"]),
		Target(name: "Sample", dependencies: ["Support", "Process", "Generators"])
	],
	dependencies: [.Package(url: "https://github.com/Mrwerdo/LibTIFF.git", majorVersion: 0, minor: 1)],
	exclude: ["Sources", "LICENCE", "README.md", "Fractal.tiff"]
)
