import PackageDescription

let remote = false

let sourceLocation: String

if remote {
	sourceLocation = "https://github.com/Mrwerdo/CLibTIFF.git"
} else {
	sourceLocation = "../CLibTIFF"
}

let pacakge = Package(name: "redesigned-palm-tree-fractals",
					  dependencies: [.Package(url: sourceLocation, majorVersion: 1)]
)
