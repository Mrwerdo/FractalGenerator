import CLibTIFF

var tif = TIFFOpen("/Users/mrwerdo/Developer/Fractals/redesigned-palm-tree-fractals/Fractal.tiff", "w")
if tif != nil {
	var width: UInt32 = 100
	var height: UInt32 = 100
	let size = Int(width * height * 3)

	TIFFSetField_uint32(tif, UInt32(TIFFTAG_IMAGEWIDTH), width)
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_IMAGELENGTH), height)
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_BITSPERSAMPLE), 8)
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_SAMPLESPERPIXEL), 3)
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_ROWSPERSTRIP), 1)
	
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_PHOTOMETRIC), UInt32(PHOTOMETRIC_RGB))
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_PLANARCONFIG), UInt32(PLANARCONFIG_CONTIG))
	TIFFSetField_uint32(tif, UInt32(TIFFTAG_ORIENTATION), UInt32(ORIENTATION_TOPLEFT))

	var buffer = [[UInt8]](count: Int(height), repeatedValue: [UInt8](count: Int(width * 3), repeatedValue: 0))

	for y in 0..<Int(height) {
		for x in 0.stride(to: Int(width * 3), by: 3) {
			switch x % 9 {
			case 0:
				buffer[y][x] = 255
			case 3:
				buffer[y][x + 1] = 255
			case 6:
				buffer[y][x + 2] = 255
			default:
				break
			}
		}
	}

	for row in 0..<Int(height) {
		var k: [UInt8] = buffer[row]
		if TIFFWriteScanline(tif, &k, UInt32(row), 0) < 0 {
			print("Error!")
		}
	}

	print("The size is: \(width)x\(height)")
}
TIFFClose(tif)
