import CLibTIFF

private let size = Size(100, 100)
private var buffer = [UInt8](repeating: 0, count: size.height * size.width * 3)

//var counter = 0
//for y in 0..<size.height {
//	for x in 0.stride(to: size.height, by: 4) {
//		switch counter % 4 {
//		case 0: buffer[y * size.width + x + 0] = 255 // Red
//		case 1: buffer[y * size.width + x + 1] = 255 // Green
//		case 2: buffer[y * size.width + x + 2] = 255 // Blue
//		default: break
//		}
//	}
//}

for y in 0..<size.height {
    for x in stride(from: 0, to: Int(size.width * 3), by: 3) {
        switch x % 9 {
        case 0:
            buffer[y * size.width * 3 + x] = 255
        case 3:
            buffer[y * size.width * 3 + x + 1] = 255
        case 6:
            buffer[y * size.width * 3 + x + 2] = 255
        default:
            break
        }
    }
}
private let path = "/Users/mrwerdo/Developer/Fractals/redesigned-palm-tree-fractals/Fractal.tiff"
private var image: TIFFImage = try TIFFImage(writeAt: path, &buffer, size, hasAlpha: false)
image.ownsBuffer = false
try image.write()
